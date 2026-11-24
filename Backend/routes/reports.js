const router = require("express").Router();
const auth = require("../middleware/auth");
const { authorize } = require("../middleware/auth");
const withBranchContext = require("../middleware/withBranchContext");

router.use(auth);
router.use(authorize("MANAGER", "AUDITOR", "ADMIN"));
router.use(withBranchContext);

router.get("/collections", async (req, res) => {
  try {
    const result = await req.db.query("SELECT * FROM v_collection_report ORDER BY received_at DESC LIMIT 500");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/arrears", async (req, res) => {
  try {
    const result = await req.db.query("SELECT * FROM v_arrears_report ORDER BY total_arrears DESC");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/portfolio-risk", async (req, res) => {
  try {
    const result = await req.db.query("SELECT * FROM v_portfolio_at_risk ORDER BY group_id");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/integrity", async (req, res) => {
  try {
    const allocations = await req.db.query("SELECT * FROM check_repayment_allocations()");
    const ledger = await req.db.query("SELECT * FROM check_ledger_balance()");
    const chain = await req.db.query("SELECT verify_ledger_hash_chain() AS valid");
    res.json({
      allocationsBalanced: allocations.rows.length === 0,
      ledgerBalanced: ledger.rows.length === 0,
      hashChainLinked: chain.rows[0].valid === true,
      allocationErrors: allocations.rows,
      ledgerErrors: ledger.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/exposure", async (req, res) => {
  try {
    const result = await req.db.query("SELECT * FROM v_group_exposure ORDER BY group_id");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
