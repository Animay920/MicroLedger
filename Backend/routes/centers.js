const router = require("express").Router();
const auth = require("../middleware/auth");
const withBranchContext = require("../middleware/withBranchContext");

router.use(auth);
router.use(withBranchContext);

router.get("/", async (req, res) => {
  try {
    const result = await req.db.query("SELECT * FROM center ORDER BY center_id");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
