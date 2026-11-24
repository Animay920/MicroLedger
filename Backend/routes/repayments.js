const router = require("express").Router();
const pool = require("../db");
const redis = require("../redis");
const auth = require("../middleware/auth");
const { authorize } = require("../middleware/auth");
const withBranchContext = require("../middleware/withBranchContext");

router.use(auth);
router.use(withBranchContext);

// List repayments
router.get("/", async (req, res) => {
  try {
    const result = await req.db.query(`
      SELECT r.repayment_id, r.loan_id, r.collected_by, r.amount, r.received_at, r.idempotency_key, r.channel,
             r.paid_by_name, r.payer_relation,
             b.full_name AS borrower_name, l.status AS loan_status, u.full_name AS collector_name
      FROM repayment r
      JOIN loan l ON l.loan_id = r.loan_id
      JOIN borrower b ON b.borrower_id = l.borrower_id
      LEFT JOIN app_user u ON u.user_id = r.collected_by
      ORDER BY r.repayment_id DESC
      LIMIT 100
    `);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Post single repayment
router.post("/", async (req, res) => {
  const { loanId, amount, channel = "FIELD", expectedVersion, paidByName, payerRelation = "SELF" } = req.body || {};
  const idempotencyKey = req.headers["idempotency-key"];

  if (!loanId || !amount || !idempotencyKey || expectedVersion === undefined) {
    return res.status(400).json({
      error: "loanId, amount, expectedVersion and Idempotency-Key header are required"
    });
  }

  const redisKey = `repayment:${idempotencyKey}`;
  let lockAcquired = false;

  try {
    // 1. Fast duplicate guard via Redis
    const cached = await redis.get(redisKey);
    if (cached) return res.status(200).json(JSON.parse(cached));

    const lock = await redis.set(`${redisKey}:lock`, "1", "NX", "EX", 30);
    if (!lock) return res.status(409).json({ error: "This payment is currently being processed" });
    lockAcquired = true;

    // Execute through req.db (already scoped in withBranchContext transaction)
    const result = await req.db.query(
      `SELECT * FROM post_repayment($1, $2, $3, $4, $5, $6, $7, $8)`,
      [loanId, req.user.userId, amount, idempotencyKey, channel, expectedVersion, paidByName || null, payerRelation || "SELF"]
    );

    const response = { message: "Repayment posted", ...result.rows[0] };
    await redis.set(redisKey, JSON.stringify(response), "EX", 86400);
    return res.status(201).json(response);
  } catch (err) {
    if (err.code === "23505") return res.status(409).json({ error: "Duplicate repayment idempotency key" });
    if (err.code === "40001") return res.status(409).json({ error: err.message });

    // Redis outage fallback: ensure post_repayment runs inside a proper BEGIN + set_config context
    if (err.message && (err.message.includes("Redis") || err.message.includes("connect") || err.message.includes("ECONNREFUSED"))) {
      console.error("Redis guard unavailable; executing with isolated PostgreSQL fallback context:", err.message);
      const fallbackClient = await pool.connect();
      try {
        await fallbackClient.query("BEGIN");
        await fallbackClient.query("SELECT set_config('app.branch_id', $1, true)", [String(req.user.branchId)]);
        await fallbackClient.query("SELECT set_config('app.role', $1, true)", [req.user.role]);

        const result = await fallbackClient.query(
          `SELECT * FROM post_repayment($1, $2, $3, $4, $5, $6, $7, $8)`,
          [loanId, req.user.userId, amount, idempotencyKey, channel, expectedVersion, paidByName || null, payerRelation || "SELF"]
        );
        await fallbackClient.query("COMMIT");
        return res.status(201).json({ message: "Repayment posted", ...result.rows[0] });
      } catch (fallbackErr) {
        await fallbackClient.query("ROLLBACK");
        if (fallbackErr.code === "23505") return res.status(409).json({ error: "Duplicate repayment idempotency key" });
        if (fallbackErr.code === "40001") return res.status(409).json({ error: fallbackErr.message });
        return res.status(400).json({ error: fallbackErr.message });
      } finally {
        fallbackClient.release();
      }
    }

    return res.status(400).json({ error: err.message });
  } finally {
    if (lockAcquired) {
      try {
        await redis.del(`${redisKey}:lock`);
      } catch {}
    }
  }
});

// Center Meeting Bulk Collection: submit entire JLG's weekly meeting collections
router.post("/batch", authorize("FIELD_OFFICER", "MANAGER", "ADMIN"), async (req, res) => {
  const { collections } = req.body || {};
  if (!Array.isArray(collections) || collections.length === 0) {
    return res.status(400).json({ error: "collections array is required" });
  }

  const results = [];
  let successCount = 0;
  let failCount = 0;

  for (let i = 0; i < collections.length; i++) {
    const item = collections[i];
    const { loanId, amount, channel = "FIELD", expectedVersion, idempotencyKey, paidByName, payerRelation } = item;
    const savepointName = `sp_batch_${i}`;

    if (!loanId || !amount || !idempotencyKey || expectedVersion === undefined) {
      results.push({
        loanId,
        idempotencyKey,
        success: false,
        error: "Missing required fields (loanId, amount, expectedVersion, idempotencyKey)"
      });
      failCount++;
      continue;
    }

    try {
      await req.db.query(`SAVEPOINT ${savepointName}`);

      const result = await req.db.query(
        `SELECT * FROM post_repayment($1, $2, $3, $4, $5, $6, $7, $8)`,
        [loanId, req.user.userId, amount, idempotencyKey, channel, expectedVersion, paidByName || null, payerRelation || "SELF"]
      );

      await req.db.query(`RELEASE SAVEPOINT ${savepointName}`);

      // Cache in Redis if available
      try {
        const redisKey = `repayment:${idempotencyKey}`;
        await redis.set(redisKey, JSON.stringify({ message: "Repayment posted", ...result.rows[0] }), "EX", 86400);
      } catch {}

      results.push({
        loanId,
        idempotencyKey,
        success: true,
        ...result.rows[0]
      });
      successCount++;
    } catch (itemErr) {
      await req.db.query(`ROLLBACK TO SAVEPOINT ${savepointName}`);
      results.push({
        loanId,
        idempotencyKey,
        success: false,
        error: itemErr.message
      });
      failCount++;
    }
  }

  res.status(failCount === 0 ? 200 : 207).json({
    totalProcessed: collections.length,
    successful: successCount,
    failed: failCount,
    results
  });
});

// Reversing-Entry Correction Workflow
router.post("/:repaymentId/reverse", authorize("MANAGER", "ADMIN"), async (req, res) => {
  const { repaymentId } = req.params;
  try {
    const result = await req.db.query(
      `SELECT * FROM reverse_repayment($1, $2)`,
      [repaymentId, req.user.userId]
    );

    res.json({
      message: "Repayment reversed successfully",
      ...result.rows[0]
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
