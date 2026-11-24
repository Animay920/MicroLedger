const router = require("express").Router();
const auth = require("../middleware/auth");
const { authorize } = require("../middleware/auth");
const withBranchContext = require("../middleware/withBranchContext");

router.use(auth);
router.use(withBranchContext);

router.post("/", authorize("MANAGER", "ADMIN"), async (req, res) => {
  let { centerId, name, formedOn, maxExposure = 250000 } = req.body || {};
  if (!centerId) return res.status(400).json({ error: "centerId is required" });

  try {
    // If name is not provided or empty, auto-generate standard JLG ID: JLG-YYYY-XX
    if (!name || !name.trim()) {
      const countRes = await req.db.query("SELECT COUNT(*) FROM jlg_group");
      const nextNum = parseInt(countRes.rows[0].count, 10) + 1;
      const year = new Date().getFullYear();
      name = `JLG-${year}-${String(nextNum).padStart(2, '0')}`;
    }

    const result = await req.db.query(
      `INSERT INTO jlg_group(center_id, name, formed_on, max_exposure)
       VALUES($1, $2, COALESCE($3, CURRENT_DATE), $4) RETURNING *`,
      [centerId, name.trim(), formedOn || null, maxExposure]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.get("/", async (req, res) => {
  try {
    const result = await req.db.query(
      `SELECT g.*, c.name AS center_name, c.branch_id,
              COUNT(gm.borrower_id) AS member_count
       FROM jlg_group g
       JOIN center c ON c.center_id = g.center_id
       LEFT JOIN group_member gm ON gm.group_id = g.group_id AND gm.left_on IS NULL
       GROUP BY g.group_id, c.name, c.branch_id
       ORDER BY g.group_id DESC`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: "Could not fetch groups" });
  }
});

// Add member to group with role and maximum 3 groups validation
router.post("/:groupId/members", authorize("MANAGER", "ADMIN"), async (req, res) => {
  const { borrowerId, memberRole = "MEMBER" } = req.body || {};
  if (!borrowerId) return res.status(400).json({ error: "borrowerId is required" });

  // 1. Role validation
  const validRoles = ["PRESIDENT", "SECRETARY", "MEMBER"];
  const roleUpper = String(memberRole).toUpperCase().trim();
  if (!validRoles.includes(roleUpper)) {
    return res.status(400).json({ error: "Member role must be PRESIDENT, SECRETARY, or MEMBER." });
  }

  try {
    // 2. Check if borrower exists
    const bRes = await req.db.query("SELECT borrower_id, full_name, status FROM borrower WHERE borrower_id = $1", [borrowerId]);
    if (bRes.rows.length === 0) {
      return res.status(404).json({ error: "Borrower not found." });
    }
    const borrower = bRes.rows[0];

    // 3. Check if already an active member of this group
    const alreadyRes = await req.db.query(
      "SELECT 1 FROM group_member WHERE group_id = $1 AND borrower_id = $2 AND left_on IS NULL",
      [req.params.groupId, borrowerId]
    );
    if (alreadyRes.rows.length > 0) {
      return res.status(400).json({ error: `Borrower "${borrower.full_name}" is already an active member of this JLG group.` });
    }

    // 4. Check maximum 3 groups constraint
    const countRes = await req.db.query(
      "SELECT COUNT(*) FROM group_member WHERE borrower_id = $1 AND left_on IS NULL",
      [borrowerId]
    );
    const activeGroupCount = parseInt(countRes.rows[0].count, 10);
    if (activeGroupCount >= 3) {
      return res.status(400).json({
        error: `Borrower "${borrower.full_name}" is already an active member of ${activeGroupCount} groups. Maximum allowed is 3 groups per borrower.`
      });
    }

    // 5. Insert member
    const result = await req.db.query(
      `INSERT INTO group_member(group_id, borrower_id, member_role)
       VALUES($1, $2, $3) RETURNING *`,
      [req.params.groupId, borrowerId, roleUpper]
    );
    res.status(201).json({ ...result.rows[0], full_name: borrower.full_name });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Remove member from group
router.delete("/:groupId/members/:borrowerId", authorize("MANAGER", "ADMIN"), async (req, res) => {
  const { groupId, borrowerId } = req.params;
  try {
    // 1. Check if borrower has active unpaid loan in this group
    const loanCheck = await req.db.query(
      `SELECT loan_id, outstanding_principal
       FROM loan
       WHERE group_id = $1 AND borrower_id = $2 AND status IN ('ACTIVE', 'DELINQUENT', 'DEFAULTED') AND outstanding_principal > 0`,
      [groupId, borrowerId]
    );
    if (loanCheck.rows.length > 0) {
      const activeLoan = loanCheck.rows[0];
      return res.status(400).json({
        error: `Cannot remove member from group. Member has an active unpaid loan (#${activeLoan.loan_id}) with outstanding principal of ₹${parseFloat(activeLoan.outstanding_principal).toLocaleString('en-IN')}.`
      });
    }

    // 2. Mark member as left in group_member
    await req.db.query(
      "UPDATE group_member SET left_on = CURRENT_DATE WHERE group_id = $1 AND borrower_id = $2 AND left_on IS NULL",
      [groupId, borrowerId]
    );

    // 3. Deactivate any guarantees in this group
    await req.db.query(
      `UPDATE guarantee SET active = FALSE
       WHERE guarantor_id = $1 AND guaranteed_loan_id IN (SELECT loan_id FROM loan WHERE group_id = $2)`,
      [borrowerId, groupId]
    );

    res.json({ message: "Member removed from JLG group successfully." });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/:groupId/members", async (req, res) => {
  try {
    const result = await req.db.query(
      `SELECT gm.*, b.full_name, b.phone, b.monthly_household_income, b.status AS borrower_status
       FROM group_member gm
       JOIN borrower b ON b.borrower_id = gm.borrower_id
       WHERE gm.group_id = $1 AND gm.left_on IS NULL
       ORDER BY 
         CASE gm.member_role WHEN 'PRESIDENT' THEN 1 WHEN 'SECRETARY' THEN 2 ELSE 3 END,
         gm.joined_on`,
      [req.params.groupId]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: "Could not fetch group members" });
  }
});

router.get("/:groupId/exposure", async (req, res) => {
  try {
    const membersRes = await req.db.query(`
      SELECT gm.group_id, gm.borrower_id, b.full_name,
             COALESCE(ge.exposure_amount, 0) AS exposure_amount,
             ge.source_loan_id, ge.depth, ge.updated_at
      FROM group_member gm
      JOIN borrower b ON b.borrower_id = gm.borrower_id
      LEFT JOIN guarantee_exposure ge ON ge.borrower_id = gm.borrower_id
      WHERE gm.group_id = $1 AND gm.left_on IS NULL
      ORDER BY ge.exposure_amount DESC NULLS LAST
    `, [req.params.groupId]);

    const totalRes = await req.db.query(`
      SELECT jg.group_id, jg.name, jg.max_exposure,
             COALESCE(SUM(ge.exposure_amount), 0) AS total_group_exposure
      FROM jlg_group jg
      LEFT JOIN group_member gm ON gm.group_id = jg.group_id AND gm.left_on IS NULL
      LEFT JOIN guarantee_exposure ge ON ge.borrower_id = gm.borrower_id
      WHERE jg.group_id = $1
      GROUP BY jg.group_id, jg.name, jg.max_exposure
    `, [req.params.groupId]);

    if (totalRes.rows.length === 0) {
      return res.status(404).json({ error: "Group not found" });
    }

    const groupInfo = totalRes.rows[0];
    res.json({
      groupId: groupInfo.group_id,
      groupName: groupInfo.name,
      maxExposure: parseFloat(groupInfo.max_exposure),
      totalGroupExposure: parseFloat(groupInfo.total_group_exposure),
      members: membersRes.rows.map(m => ({
        borrowerId: m.borrower_id,
        fullName: m.full_name,
        exposureAmount: parseFloat(m.exposure_amount),
        sourceLoanId: m.source_loan_id,
        depth: m.depth,
        updatedAt: m.updated_at
      }))
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
