const router = require("express").Router();
const crypto = require("crypto");
const redis = require("../redis");
const auth = require("../middleware/auth");
const withBranchContext = require("../middleware/withBranchContext");

router.use(auth);
router.use(withBranchContext);

// 1. List transactions with borrower and loan details
router.get("/", async (req, res) => {
  const { status, loanId, limit = 100 } = req.query;
  try {
    let query = `
      SELECT pt.*,
             b.full_name AS borrower_name,
             b.phone AS borrower_phone,
             l.principal AS loan_principal,
             l.status AS loan_status,
             c.name AS center_name
      FROM payment_transaction pt
      LEFT JOIN loan l ON l.loan_id = pt.loan_id
      LEFT JOIN borrower b ON b.borrower_id = pt.borrower_id
      LEFT JOIN center c ON c.center_id = b.center_id
      WHERE 1=1
    `;
    const params = [];

    if (status && status !== "ALL") {
      params.push(status);
      query += ` AND pt.status = $${params.length}`;
    }

    if (loanId) {
      params.push(loanId);
      query += ` AND pt.loan_id = $${params.length}`;
    }

    query += ` ORDER BY pt.created_at DESC LIMIT $${params.length + 1}`;
    params.push(parseInt(limit, 10));

    const result = await req.db.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. Initiate a payment transaction (with active lock protection)
router.post("/initiate", async (req, res) => {
  const { loanId, amount, paymentMethod = "CASH" } = req.body || {};

  if (!loanId || !amount || parseFloat(amount) <= 0) {
    return res.status(400).json({ error: "loanId and a positive amount are required" });
  }

  const numAmount = parseFloat(amount);

  try {
    // A. Check if the loan exists and is open for repayment
    const loanRes = await req.db.query(
      `SELECT l.*, b.borrower_id, b.full_name AS borrower_name, c.branch_id
       FROM loan l
       JOIN borrower b ON b.borrower_id = l.borrower_id
       JOIN center c ON c.center_id = b.center_id
       WHERE l.loan_id = $1`,
      [loanId]
    );

    if (loanRes.rows.length === 0) {
      return res.status(404).json({ error: "Loan not found" });
    }

    const loan = loanRes.rows[0];
    if (!["ACTIVE", "DELINQUENT", "DEFAULTED"].includes(loan.status)) {
      return res.status(400).json({ error: `Loan is currently ${loan.status} and not open for repayment` });
    }

    // B. Check for existing in-flight (PENDING) transaction on this loan
    // "if payment is slow and network is slow it is not possible to start another transaction"
    const inFlightRes = await req.db.query(
      `SELECT * FROM payment_transaction
       WHERE loan_id = $1 AND status = 'PENDING'
       AND created_at > now() - INTERVAL '15 minutes'
       ORDER BY created_at DESC LIMIT 1`,
      [loanId]
    );

    if (inFlightRes.rows.length > 0) {
      return res.status(409).json({
        error: "A payment transaction is already in progress for this loan. Please wait for it to complete or cancel it.",
        inFlightTransaction: inFlightRes.rows[0]
      });
    }

    // C. Check Redis lock as secondary defense
    const redisLockKey = `lock:loan_txn:${loanId}`;
    try {
      const activeLock = await redis.get(redisLockKey);
      if (activeLock) {
        return res.status(409).json({
          error: "A payment lock is currently active on this loan. Please wait 30 seconds."
        });
      }
    } catch {}

    // D. Generate transaction and gateway references
    const transactionId = `TXN-${Date.now()}-${crypto.randomBytes(3).toString("hex").toUpperCase()}`;
    const gatewayReference = `pay_micro_${Date.now()}_${crypto.randomBytes(4).toString("hex")}`;

    // E. Insert transaction row with PENDING status
    await req.db.query(
      `INSERT INTO payment_transaction(
        transaction_id, transaction_type, loan_id, borrower_id, branch_id,
        amount, payment_method, gateway_reference, status
      ) VALUES ($1, 'REPAYMENT', $2, $3, $4, $5, $6, $7, 'PENDING')`,
      [
        transactionId,
        loan.loan_id,
        loan.borrower_id,
        loan.branch_id,
        numAmount,
        paymentMethod,
        gatewayReference
      ]
    );

    // Set Redis lock for 3 minutes
    try {
      await redis.set(redisLockKey, transactionId, "EX", 180);
    } catch {}

    res.status(201).json({
      transactionId,
      gatewayReference,
      status: "PENDING",
      loanId: loan.loan_id,
      borrowerId: loan.borrower_id,
      borrowerName: loan.borrower_name,
      amount: numAmount,
      paymentMethod,
      version: loan.version,
      outstandingPrincipal: loan.outstanding_principal
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 3. Complete payment transaction (SUCCESS)
router.post("/:transactionId/complete", async (req, res) => {
  const { transactionId } = req.params;
  const { paymentDetails } = req.body || {};

  try {
    // A. Fetch transaction
    const txnRes = await req.db.query(
      `SELECT pt.*, l.version, l.status AS loan_status
       FROM payment_transaction pt
       JOIN loan l ON l.loan_id = pt.loan_id
       WHERE pt.transaction_id = $1`,
      [transactionId]
    );

    if (txnRes.rows.length === 0) {
      return res.status(404).json({ error: "Transaction not found" });
    }

    const txn = txnRes.rows[0];
    if (txn.status === "SUCCESS") {
      return res.status(200).json({ message: "Transaction already completed", transaction: txn });
    }

    if (txn.status !== "PENDING") {
      return res.status(400).json({ error: `Cannot complete transaction in ${txn.status} state` });
    }

    const channel = txn.payment_method === "CASH" ? "FIELD" : "ONLINE";
    const idempotencyKey = `IDEMP-${txn.transaction_id}`;

    // B. Post repayment using stored procedure inside withBranchContext transaction
    const repRes = await req.db.query(
      `SELECT * FROM post_repayment($1, $2, $3, $4, $5, $6)`,
      [txn.loan_id, req.user.userId, txn.amount, idempotencyKey, channel, txn.version]
    );

    const repaymentResult = repRes.rows[0];

    // C. Update payment_transaction to SUCCESS
    await req.db.query(
      `UPDATE payment_transaction
       SET status = 'SUCCESS',
           repayment_id = $1,
           gateway_reference = COALESCE($2, gateway_reference),
           updated_at = now()
       WHERE transaction_id = $3`,
      [repaymentResult.repayment_id, paymentDetails?.gatewayPaymentId || null, transactionId]
    );

    // Release Redis lock
    try {
      await redis.del(`lock:loan_txn:${txn.loan_id}`);
    } catch {}

    // Fetch updated loan balance
    const updatedLoanRes = await req.db.query(
      "SELECT loan_id, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status FROM loan WHERE loan_id = $1",
      [txn.loan_id]
    );

    res.json({
      status: "SUCCESS",
      transactionId,
      repaymentId: repaymentResult.repayment_id,
      amount: txn.amount,
      paymentMethod: txn.payment_method,
      loan: updatedLoanRes.rows[0],
      allocations: repaymentResult,
      message: "Payment successfully confirmed and posted to cryptographic ledger"
    });
  } catch (err) {
    // If post_repayment fails (e.g. version conflict or balance exceeded), mark transaction as FAILED
    await req.db.query(
      `UPDATE payment_transaction
       SET status = 'FAILED', failure_reason = $1, updated_at = now()
       WHERE transaction_id = $2`,
      [err.message, transactionId]
    ).catch(() => {});

    try {
      const loanId = req.body?.loanId;
      if (loanId) await redis.del(`lock:loan_txn:${loanId}`);
    } catch {}

    res.status(400).json({ error: err.message, status: "FAILED" });
  }
});

// 4. Fail payment transaction (FAILED)
router.post("/:transactionId/fail", async (req, res) => {
  const { transactionId } = req.params;
  const { reason = "Payment declined by customer bank or card issuer" } = req.body || {};

  try {
    const txnRes = await req.db.query(
      "SELECT * FROM payment_transaction WHERE transaction_id = $1",
      [transactionId]
    );

    if (txnRes.rows.length === 0) {
      return res.status(404).json({ error: "Transaction not found" });
    }

    const txn = txnRes.rows[0];

    await req.db.query(
      `UPDATE payment_transaction
       SET status = 'FAILED', failure_reason = $1, updated_at = now()
       WHERE transaction_id = $2`,
      [reason, transactionId]
    );

    try {
      await redis.del(`lock:loan_txn:${txn.loan_id}`);
    } catch {}

    res.json({
      status: "FAILED",
      transactionId,
      failureReason: reason,
      message: "Transaction marked as failed"
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 5. Abort payment transaction due to network / timeout (NETWORK_ABORTED)
router.post("/:transactionId/abort", async (req, res) => {
  const { transactionId } = req.params;
  const { reason = "Transaction stopped due to network interruption or page reload" } = req.body || {};

  try {
    const txnRes = await req.db.query(
      "SELECT * FROM payment_transaction WHERE transaction_id = $1",
      [transactionId]
    );

    if (txnRes.rows.length === 0) {
      return res.status(404).json({ error: "Transaction not found" });
    }

    const txn = txnRes.rows[0];

    await req.db.query(
      `UPDATE payment_transaction
       SET status = 'NETWORK_ABORTED', failure_reason = $1, updated_at = now()
       WHERE transaction_id = $2`,
      [reason, transactionId]
    );

    try {
      await redis.del(`lock:loan_txn:${txn.loan_id}`);
    } catch {}

    res.json({
      status: "NETWORK_ABORTED",
      transactionId,
      failureReason: reason,
      message: "Transaction safely aborted due to network disruption"
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 6. Loan creation transaction simulation
router.post("/loan-create", async (req, res) => {
  const {
    borrowerId,
    groupId,
    cycleNo,
    principal,
    annualRate = 18.0,
    tenureWeeks = 52,
    simulateOutcome = "SUCCESS",
    failureReason = "Bank transfer failed: Account validation error"
  } = req.body || {};

  if (!borrowerId || !groupId || !principal) {
    return res.status(400).json({ error: "borrowerId, groupId and principal are required" });
  }

  const transactionId = `TXN-LOAN-${Date.now()}-${crypto.randomBytes(3).toString("hex").toUpperCase()}`;
  const numPrincipal = parseFloat(principal);

  try {
    // Fetch branch_id from borrower
    const borrowerRes = await req.db.query(
      `SELECT b.*, c.branch_id
       FROM borrower b
       JOIN center c ON c.center_id = b.center_id
       WHERE b.borrower_id = $1`,
      [borrowerId]
    );

    if (borrowerRes.rows.length === 0) {
      return res.status(404).json({ error: "Borrower not found" });
    }

    const borrower = borrowerRes.rows[0];

    // Handle Network Abort simulation
    if (simulateOutcome === "NETWORK_ABORTED") {
      await req.db.query(
        `INSERT INTO payment_transaction(
          transaction_id, transaction_type, borrower_id, branch_id,
          amount, payment_method, status, failure_reason
        ) VALUES ($1, 'LOAN_CREATION', $2, $3, $4, 'GATEWAY_SIMULATOR', 'NETWORK_ABORTED', $5)`,
        [
          transactionId,
          borrower.borrower_id,
          borrower.branch_id,
          numPrincipal,
          "Disbursement halted: Network timeout while contacting clearing bank"
        ]
      );
      return res.json({
        status: "NETWORK_ABORTED",
        transactionId,
        failureReason: "Disbursement halted: Network timeout while contacting clearing bank"
      });
    }

    // Handle Failure simulation
    if (simulateOutcome === "FAILED") {
      await req.db.query(
        `INSERT INTO payment_transaction(
          transaction_id, transaction_type, borrower_id, branch_id,
          amount, payment_method, status, failure_reason
        ) VALUES ($1, 'LOAN_CREATION', $2, $3, $4, 'GATEWAY_SIMULATOR', 'FAILED', $5)`,
        [transactionId, borrower.borrower_id, borrower.branch_id, numPrincipal, failureReason]
      );
      return res.status(400).json({
        status: "FAILED",
        transactionId,
        failureReason
      });
    }

    // Handle SUCCESS:
    // Check eligibility inside database
    await req.db.query("SELECT assert_group_eligible($1)", [groupId]);

    // Create loan
    const loanRes = await req.db.query(
      `INSERT INTO loan(borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks,
                        outstanding_principal, status)
       VALUES($1, $2, $3, $4, $5, $6, 0, 'PENDING') RETURNING *`,
      [borrowerId, groupId, cycleNo || 1, numPrincipal, annualRate, tenureWeeks]
    );
    const newLoan = loanRes.rows[0];

    // Disburse loan (generates schedule)
    await req.db.query("SELECT disburse_loan($1)", [newLoan.loan_id]);

    // Record success in payment_transaction
    await req.db.query(
      `INSERT INTO payment_transaction(
        transaction_id, transaction_type, loan_id, borrower_id, branch_id,
        amount, payment_method, gateway_reference, status
      ) VALUES ($1, 'LOAN_CREATION', $2, $3, $4, $5, $6, 'SUCCESS')`,
      [
        transactionId,
        newLoan.loan_id,
        borrower.borrower_id,
        borrower.branch_id,
        numPrincipal,
        "GATEWAY_SIMULATOR",
        `disb_micro_${newLoan.loan_id}`
      ]
    );

    res.status(201).json({
      status: "SUCCESS",
      transactionId,
      loan: newLoan,
      message: "Loan origination and instant disbursement successfully completed"
    });
  } catch (err) {
    // Record failure in payment_transaction
    await req.db.query(
      `INSERT INTO payment_transaction(
        transaction_id, transaction_type, borrower_id, branch_id,
        amount, payment_method, status, failure_reason
      ) VALUES ($1, 'LOAN_CREATION', $2, (SELECT branch_id FROM app_user WHERE user_id = $3), $4, 'GATEWAY_SIMULATOR', 'FAILED', $5)`,
      [transactionId, borrowerId, req.user.userId, numPrincipal, err.message]
    ).catch(() => {});

    res.status(400).json({
      status: "FAILED",
      transactionId,
      failureReason: err.message
    });
  }
});

module.exports = router;
