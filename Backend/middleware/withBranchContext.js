const pool = require("../db");

module.exports = async function withBranchContext(req, res, next) {
  let client;

  try {
    client = await pool.connect();

    await client.query("BEGIN");

    if (req.user && req.user.branchId) {
      await client.query(
        "SELECT set_config('app.branch_id', $1, true)",
        [String(req.user.branchId)]
      );
    }

    if (req.user && req.user.role) {
      await client.query(
        "SELECT set_config('app.role', $1, true)",
        [req.user.role]
      );
    }

    req.db = client;

    let finished = false;

    const release = async (rollback = false) => {
      if (finished) return;
      finished = true;

      try {
        if (rollback) {
          await client.query("ROLLBACK");
        } else {
          await client.query("COMMIT");
        }
      } catch (err) {
        console.error("Database transaction cleanup error:", err);
        client.release(true);
        return;
      }

      client.release();
    };

    res.once("finish", () => {
      release(res.statusCode >= 400);
    });

    res.once("close", () => {
      if (!res.writableFinished) release(true);
    });

    next();
  } catch (err) {
    if (client) {
      try {
        await client.query("ROLLBACK");
      } catch {}
      client.release();
    }

    console.error("RLS context error:", err);
    res.status(500).json({ error: "Database context initialization failed" });
  }
};
