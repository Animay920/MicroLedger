const router = require("express").Router();
const auth = require("../middleware/auth");
const { authorize } = require("../middleware/auth");
const withBranchContext = require("../middleware/withBranchContext");

router.use(auth);
router.use(authorize("ADMIN"));
router.use(withBranchContext);

router.post("/eod-accrual", async (req, res) => {
  const { asOfDate } = req.body || {};
  try {
    const result = await req.db.query(
      "SELECT * FROM run_eod_accrual(COALESCE($1, CURRENT_DATE))",
      [asOfDate || null]
    );
    res.json({
      message: "End-of-Day accrual and delinquency engine completed successfully",
      ...result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
