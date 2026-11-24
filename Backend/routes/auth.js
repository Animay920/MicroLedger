const router = require("express").Router();
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const pool = require("../db");

router.post("/login", async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) return res.status(400).json({ error: "Email and password required" });

  try {
    const result = await pool.query(
      "SELECT * FROM public.login_lookup($1)",
      [email]
    );
    const user = result.rows[0];
    if (!user || !user.active || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    const token = jwt.sign({
      userId: user.user_id,
      branchId: user.branch_id,
      role: user.role,
      name: user.full_name
    }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || "8h" });

    res.json({ token, user: {
      userId: user.user_id, name: user.full_name, role: user.role, branchId: user.branch_id
    }});
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Login failed" });
  }
});

module.exports = router;
