const router = require("express").Router();
const auth = require("../middleware/auth");
const { authorize } = require("../middleware/auth");
const withBranchContext = require("../middleware/withBranchContext");

router.use(auth);
router.use(withBranchContext);

router.post("/", authorize("MANAGER", "ADMIN"), async (req, res) => {
  const { borrowerId, groupId, cycleNo, principal, annualRate, tenureWeeks } = req.body || {};
  if (!borrowerId || !groupId || !cycleNo || !principal || !tenureWeeks) {
    return res.status(400).json({ error: "borrowerId, groupId, cycleNo, principal and tenureWeeks are required" });
  }

  try {
    const result = await req.db.query(
      `INSERT INTO loan(borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks,
                        outstanding_principal, status)
       VALUES($1, $2, $3, $4, $5, $6, 0, 'PENDING') RETURNING *`,
      [borrowerId, groupId, cycleNo, principal, annualRate || 0, tenureWeeks]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.get("/", async (req, res) => {
  try {
    const result = await req.db.query(
      `SELECT l.*, b.full_name AS borrower_name, g.name AS group_name
       FROM loan l
       JOIN borrower b ON b.borrower_id = l.borrower_id
       JOIN jlg_group g ON g.group_id = l.group_id
       ORDER BY l.loan_id DESC`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: "Could not fetch loans" });
  }
});

router.post("/:loanId/disburse", authorize("MANAGER", "ADMIN"), async (req, res) => {
  try {
    await req.db.query("SELECT disburse_loan($1)", [req.params.loanId]);
    res.json({ message: "Loan disbursed and repayment schedule generated" });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.get("/:loanId/installments", async (req, res) => {
  try {
    const result = await req.db.query(
      "SELECT * FROM installment WHERE loan_id=$1 ORDER BY seq_no",
      [req.params.loanId]
    );
    res.json(result.rows);
  } catch {
    res.status(500).json({ error: "Could not fetch installments" });
  }
});

// Guarantee edge management
router.post("/:loanId/guarantees", authorize("FIELD_OFFICER", "MANAGER", "ADMIN"), async (req, res) => {
  const { guarantorId, sharePct } = req.body || {};
  const loanId = req.params.loanId;

  if (!guarantorId || sharePct === undefined || parseFloat(sharePct) <= 0 || parseFloat(sharePct) > 100) {
    return res.status(400).json({ error: "guarantorId and valid sharePct (between 0 and 100) are required" });
  }

  try {
    // 1. Fetch loan details
    const loanRes = await req.db.query(
      "SELECT loan_id, borrower_id, group_id, status FROM loan WHERE loan_id = $1",
      [loanId]
    );
    const loan = loanRes.rows[0];
    if (!loan) return res.status(404).json({ error: "Loan not found" });

    // 2. Validate guarantor is not the borrower themselves
    if (String(loan.borrower_id) === String(guarantorId)) {
      return res.status(400).json({ error: "Borrower cannot guarantee their own loan" });
    }

    // 3. Validate guarantor is an active member of the same JLG group
    const memberRes = await req.db.query(
      `SELECT gm.borrower_id, b.status AS borrower_status
       FROM group_member gm
       JOIN borrower b ON b.borrower_id = gm.borrower_id
       WHERE gm.group_id = $1 AND gm.borrower_id = $2 AND gm.left_on IS NULL`,
      [loan.group_id, guarantorId]
    );
    if (memberRes.rows.length === 0) {
      return res.status(400).json({ error: "Guarantor must be an active member of the same JLG group" });
    }
    if (memberRes.rows[0].borrower_status !== "ACTIVE") {
      return res.status(400).json({ error: "Guarantor account is not active" });
    }

    // 4. Validate total share_pct per loan does not exceed 100%
    const currentSharesRes = await req.db.query(
      `SELECT COALESCE(SUM(share_pct), 0) AS total_share
       FROM guarantee
       WHERE guaranteed_loan_id = $1 AND active = TRUE AND guarantor_id <> $2`,
      [loanId, guarantorId]
    );
    const currentTotal = parseFloat(currentSharesRes.rows[0].total_share);
    if (currentTotal + parseFloat(sharePct) > 100.0) {
      return res.status(400).json({
        error: `Total guarantee share_pct cannot exceed 100%. Current active total: ${currentTotal}%, attempted addition: ${sharePct}%`
      });
    }

    // 5. Insert or update guarantee row
    const result = await req.db.query(
      `INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active)
       VALUES($1, $2, $3, TRUE)
       ON CONFLICT (guarantor_id, guaranteed_loan_id)
       DO UPDATE SET share_pct = EXCLUDED.share_pct, active = TRUE
       RETURNING *`,
      [guarantorId, loanId, sharePct]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.get("/:loanId/guarantees", async (req, res) => {
  try {
    const result = await req.db.query(
      `SELECT g.*, b.full_name AS guarantor_name, b.phone
       FROM guarantee g
       JOIN borrower b ON b.borrower_id = g.guarantor_id
       WHERE g.guaranteed_loan_id = $1 ORDER BY g.guarantee_id`,
      [req.params.loanId]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: "Could not fetch guarantees" });
  }
});

module.exports = router;
