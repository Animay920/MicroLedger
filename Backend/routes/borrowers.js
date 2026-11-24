const router = require("express").Router();
const crypto = require("crypto");
const auth = require("../middleware/auth");
const { authorize } = require("../middleware/auth");
const withBranchContext = require("../middleware/withBranchContext");

router.use(auth);
router.use(withBranchContext);

router.post("/", async (req, res) => {
  const { centerId, fullName, phone, monthlyHouseholdIncome, idType, idNumber, nationalIdHash } = req.body || {};

  // 1. Validate full name (max 50 chars, min 2 chars)
  if (!fullName || typeof fullName !== "string" || fullName.trim().length < 2 || fullName.trim().length > 50) {
    return res.status(400).json({ error: "Full Name is required and must be between 2 and 50 characters." });
  }

  // 2. Validate phone number (numeric only, strictly 10 digits)
  const cleanPhone = String(phone || "").trim();
  if (!/^\d{10}$/.test(cleanPhone)) {
    return res.status(400).json({ error: "Mobile number must be strictly 10 digits (numbers only)." });
  }

  // 3. Validate centerId
  if (!centerId) {
    return res.status(400).json({ error: "Meeting Center is required." });
  }

  // 4. Validate monthly household income
  const income = parseFloat(monthlyHouseholdIncome);
  if (isNaN(income) || income <= 0) {
    return res.status(400).json({ error: "Valid monthly household income (> 0) is required." });
  }

  // 5. Validate National ID reference & generate hash
  let finalHash = nationalIdHash;
  if (!finalHash) {
    if (!idType || !idNumber) {
      return res.status(400).json({ error: "National ID Type and ID Reference number are required." });
    }
    const cleanIdNumber = String(idNumber).trim();
    if (cleanIdNumber.length < 10) {
      return res.status(400).json({ error: "National ID Reference must be at least 10 characters long." });
    }
    finalHash = crypto.createHash("sha256").update(`${idType.toUpperCase()}:${cleanIdNumber.toUpperCase()}`).digest("hex");
  }

  try {
    const result = await req.db.query(
      `INSERT INTO borrower(center_id, full_name, national_id_hash, phone, monthly_household_income)
       VALUES($1, $2, $3, $4, $5) RETURNING *`,
      [centerId, fullName.trim(), finalHash, cleanPhone, income]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.code === "23505") {
      return res.status(400).json({ error: "A borrower with this National ID or Phone Number is already registered." });
    }
    res.status(400).json({ error: err.message });
  }
});

router.get("/", async (req, res) => {
  try {
    const result = await req.db.query(
      "SELECT borrower_id, center_id, full_name, phone, monthly_household_income, status, created_at FROM borrower ORDER BY borrower_id DESC"
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: "Could not fetch borrowers" });
  }
});

// Permanent delete of borrower
router.delete("/:borrowerId", authorize("MANAGER", "ADMIN"), async (req, res) => {
  const { borrowerId } = req.params;
  try {
    // 1. Check if borrower exists
    const bCheck = await req.db.query("SELECT borrower_id, full_name FROM borrower WHERE borrower_id = $1", [borrowerId]);
    if (bCheck.rows.length === 0) {
      return res.status(404).json({ error: "Borrower not found." });
    }
    const borrower = bCheck.rows[0];

    // 2. Check for active unpaid loans
    const loanCheck = await req.db.query(
      `SELECT loan_id, status, outstanding_principal
       FROM loan
       WHERE borrower_id = $1 AND status IN ('ACTIVE', 'DELINQUENT', 'DEFAULTED') AND outstanding_principal > 0`,
      [borrowerId]
    );
    if (loanCheck.rows.length > 0) {
      const activeLoan = loanCheck.rows[0];
      return res.status(400).json({
        error: `Cannot delete borrower "${borrower.full_name}". They have an active unpaid loan (#${activeLoan.loan_id}) with outstanding principal of ₹${parseFloat(activeLoan.outstanding_principal).toLocaleString('en-IN')}. Settle or close all loans before permanent deletion.`
      });
    }

    // 3. Clean cascade delete
    await req.db.query("DELETE FROM guarantee_exposure WHERE borrower_id = $1", [borrowerId]);

    await req.db.query(
      `DELETE FROM guarantee
       WHERE guarantor_id = $1 OR guaranteed_loan_id IN (SELECT loan_id FROM loan WHERE borrower_id = $1)`,
      [borrowerId]
    );

    await req.db.query("DELETE FROM group_member WHERE borrower_id = $1", [borrowerId]);

    const loansRes = await req.db.query("SELECT loan_id FROM loan WHERE borrower_id = $1", [borrowerId]);
    const loanIds = loansRes.rows.map(r => r.loan_id);

    if (loanIds.length > 0) {
      await req.db.query(
        "DELETE FROM payment_transaction WHERE borrower_id = $1 OR loan_id = ANY($2::BIGINT[])",
        [borrowerId, loanIds]
      );
      await req.db.query(
        `DELETE FROM payment_allocation
         WHERE repayment_id IN (SELECT repayment_id FROM repayment WHERE loan_id = ANY($1::BIGINT[]))`,
        [loanIds]
      );
      await req.db.query("DELETE FROM ledger_entry WHERE loan_id = ANY($1::BIGINT[])", [loanIds]);
      await req.db.query("DELETE FROM repayment WHERE loan_id = ANY($1::BIGINT[])", [loanIds]);
      await req.db.query("DELETE FROM installment WHERE loan_id = ANY($1::BIGINT[])", [loanIds]);
      await req.db.query("DELETE FROM loan WHERE borrower_id = $1", [borrowerId]);
    } else {
      await req.db.query("DELETE FROM payment_transaction WHERE borrower_id = $1", [borrowerId]);
    }

    await req.db.query("DELETE FROM borrower WHERE borrower_id = $1", [borrowerId]);

    res.json({ message: `Borrower "${borrower.full_name}" permanently deleted successfully.`, borrowerId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
