const router = require("express").Router();
const auth = require("../middleware/auth");
const withBranchContext = require("../middleware/withBranchContext");

router.use(auth);
router.use(withBranchContext);

router.get("/", async (req, res) => {
  try {
    const result = await req.db.query(`
      SELECT le.entry_id, le.branch_id, le.repayment_id, le.loan_id, le.account_head,
             le.debit, le.credit, le.posted_at, le.prev_hash, le.entry_hash,
             b.full_name AS borrower_name
      FROM ledger_entry le
      JOIN loan l ON l.loan_id = le.loan_id
      JOIN borrower b ON b.borrower_id = l.borrower_id
      ORDER BY le.entry_id DESC
      LIMIT 200
    `);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/verify", async (req, res) => {
  try {
    const allocations = await req.db.query("SELECT * FROM check_repayment_allocations()");
    const ledger = await req.db.query("SELECT * FROM check_ledger_balance()");
    const chain = await req.db.query("SELECT verify_ledger_hash_chain() AS valid");
    const countRes = await req.db.query("SELECT COUNT(*) AS total FROM ledger_entry");

    const valid = chain.rows[0].valid === true && allocations.rows.length === 0 && ledger.rows.length === 0;

    res.json({
      valid,
      checked: parseInt(countRes.rows[0].total, 10),
      message: valid
        ? "All ledger entries, branch hash chains, and double-entry allocations passed cryptographic verification."
        : "Integrity check failed: discrepancy detected in hash chain or double-entry balancing.",
      allocationsBalanced: allocations.rows.length === 0,
      ledgerBalanced: ledger.rows.length === 0,
      hashChainLinked: chain.rows[0].valid === true
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
