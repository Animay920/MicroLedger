require("dotenv").config({ path: require("path").resolve(__dirname, ".env") });
const { Pool } = require("pg");

const isRemote = process.env.DATABASE_URL && (
  process.env.DATABASE_URL.includes("render.com") ||
  process.env.DATABASE_URL.includes("neon.tech") ||
  process.env.DATABASE_URL.includes("supabase.co") ||
  process.env.DATABASE_URL.includes("railway.app") ||
  process.env.DATABASE_URL.includes("sslmode=require") ||
  process.env.NODE_ENV === "production"
);

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
  ssl: isRemote && !process.env.DATABASE_URL.includes("localhost") && !process.env.DATABASE_URL.includes("127.0.0.1")
    ? { rejectUnauthorized: false }
    : false
});

pool.on("error", (err) => {
  console.error("Unexpected PostgreSQL pool error:", err);
});

module.exports = pool;
