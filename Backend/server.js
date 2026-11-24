require("dotenv").config();
const path = require("path");
const fs = require("fs");
const express = require("express");
const cors = require("cors");
const rateLimit = require("express-rate-limit");
const pool = require("./db");
const { runInit } = require("../scripts/init_database");

const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));
app.use(rateLimit({ windowMs: 60_000, limit: 120 }));

// Health check endpoint
app.get("/health", (_req, res) => res.json({ status: "ok", service: "MicroLedger API" }));

// API Routes
app.use("/api/auth", require("./routes/auth"));
app.use("/api/admin", require("./routes/admin"));
app.use("/api/dashboard", require("./routes/dashboard"));
app.use("/api/centers", require("./routes/centers"));
app.use("/api/borrowers", require("./routes/borrowers"));
app.use("/api/groups", require("./routes/groups"));
app.use("/api/loans", require("./routes/loans"));
app.use("/api/repayments", require("./routes/repayments"));
app.use("/api/transactions", require("./routes/transactions"));
app.use("/api/ledger", require("./routes/ledger"));
app.use("/api/reports", require("./routes/reports"));

// Static serving for production: serve built Vite single-page application
const frontendDist = path.join(__dirname, "../Frontend/dist");
if (fs.existsSync(frontendDist)) {
  app.use(express.static(frontendDist));
  app.get("*", (req, res, next) => {
    if (req.path.startsWith("/api") || req.path.startsWith("/health")) {
      return next();
    }
    res.sendFile(path.join(frontendDist, "index.html"));
  });
}

// Global error handler
app.use((err, _req, res, _next) => {
  console.error("Unhandled API error:", err);
  res.status(500).json({ error: "Internal server error" });
});

async function bootstrapDatabase() {
  try {
    const res = await pool.query("SELECT to_regclass('public.borrower') AS has_table");
    if (!res.rows[0].has_table) {
      console.log("No existing tables detected in PostgreSQL. Running automated initialization...");
      await runInit(process.env.DATABASE_URL);
      console.log("Automated schema initialization complete!");
    } else {
      console.log("PostgreSQL database tables detected and ready.");
    }
  } catch (err) {
    console.warn("Notice: Startup database check:", err.message);
  }
}

const port = process.env.PORT || 5000;
if (require.main === module) {
  bootstrapDatabase().finally(() => {
    app.listen(port, () => console.log(`MicroLedger running on port ${port}`));
  });
}

module.exports = app;
