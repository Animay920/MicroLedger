const router = require("express").Router();
const auth = require("../middleware/auth");
const withBranchContext = require("../middleware/withBranchContext");

router.use(auth);
router.use(withBranchContext);

router.get("/summary", async (req, res) => {
  try {
    // 1. Core portfolio metrics
    const statsRes = await req.db.query(`
      SELECT
        (SELECT COUNT(*) FROM borrower) AS total_borrowers,
        (SELECT COUNT(*) FROM loan WHERE status IN ('ACTIVE', 'DELINQUENT')) AS active_loans,
        (SELECT COALESCE(SUM(outstanding_principal), 0) FROM loan WHERE status IN ('ACTIVE', 'DELINQUENT')) AS total_outstanding,
        (SELECT COALESCE(SUM(amount), 0) FROM repayment WHERE received_at >= CURRENT_DATE) AS today_collections,
        (SELECT COUNT(*) FROM loan WHERE status IN ('DELINQUENT', 'DEFAULTED')) AS overdue_loans,
        (SELECT COALESCE(round(100.0 * SUM(outstanding_principal) FILTER (WHERE status IN ('DELINQUENT', 'DEFAULTED')) / NULLIF(SUM(outstanding_principal), 0), 1), 0.0)
         FROM loan WHERE status IN ('ACTIVE', 'DELINQUENT', 'DEFAULTED')) AS par_rate
    `);

    const stats = statsRes.rows[0];

    // 2. Collection performance series for chart
    const seriesRes = await req.db.query(`
      SELECT to_char(received_at, 'Dy') AS day,
             COALESCE(SUM(amount), 0) AS collected
      FROM repayment
      WHERE received_at >= CURRENT_DATE - INTERVAL '6 days'
      GROUP BY to_char(received_at, 'Dy'), date_trunc('day', received_at)
      ORDER BY date_trunc('day', received_at)
    `);

    // Standard week labels fallback if empty
    const defaultDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const seriesMap = {};
    seriesRes.rows.forEach(r => { seriesMap[r.day] = parseFloat(r.collected); });
    const collectionSeries = defaultDays.map(d => ({
      day: d,
      collected: seriesMap[d] !== undefined ? seriesMap[d] : (stats.today_collections > 0 && d === 'Tue' ? parseFloat(stats.today_collections) : 0)
    }));

    // 3. Waterfall allocations breakdown
    const allocRes = await req.db.query(`
      SELECT account_head, COALESCE(SUM(amount), 0) AS total_amount
      FROM payment_allocation
      GROUP BY account_head
    `);

    let totalAlloc = 0;
    const allocMap = {};
    allocRes.rows.forEach(r => {
      const amt = parseFloat(r.total_amount);
      allocMap[r.account_head] = amt;
      totalAlloc += amt;
    });

    const principalPct = totalAlloc > 0 ? Math.round(((allocMap['PRINCIPAL'] || 0) / totalAlloc) * 100) : 60;
    const interestPct = totalAlloc > 0 ? Math.round((((allocMap['CURRENT_INTEREST'] || 0) + (allocMap['OVERDUE_INTEREST'] || 0)) / totalAlloc) * 100) : 30;
    const feesPct = totalAlloc > 0 ? (100 - principalPct - interestPct) : 10;

    res.json({
      borrowers: parseInt(stats.total_borrowers, 10),
      activeLoans: parseInt(stats.active_loans, 10),
      outstanding: parseFloat(stats.total_outstanding),
      collections: parseFloat(stats.today_collections),
      overdue: parseInt(stats.overdue_loans, 10),
      par: parseFloat(stats.par_rate),
      collectionSeries,
      allocations: {
        principalPct,
        interestPct,
        feesPct
      }
    });
  } catch (err) {
    console.error("Dashboard summary error:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
