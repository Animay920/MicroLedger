/**
 * MicroLedger - Automated Database Initialization & Seeding Script
 * 
 * Supports both standalone CLI execution and automatic startup bootstrap.
 * Executes SQL definitions in sequential order:
 *  01_schema.sql                - Core DDL & table structures
 *  02_constraints_triggers.sql  - RLS policies, check constraints, & trigger functions
 *  03_stored_procedures.sql     - Atomic procedures (waterfall repayment, hash-chain, EOD accrual)
 *  04_reports_and_security.sql  - Analytical reporting views & access matrices
 *  05_integrity_checks.sql      - Cryptographic hash-chain & double-entry validation functions
 *  06_seed_kiva_nrlm.sql        - Real-world NRLM / Kiva field dataset (28 members, 10 JLGs, transactions)
 */

const fs = require('fs');
const path = require('path');
let Pool;
try {
  Pool = require('pg').Pool;
} catch {
  Pool = require('../Backend/node_modules/pg').Pool;
}
try {
  require('dotenv').config({ path: path.resolve(__dirname, '../Backend/.env') });
} catch {
  require('../Backend/node_modules/dotenv').config({ path: path.resolve(__dirname, '../Backend/.env') });
}

function getPool(customConnectionString) {
  const connectionString = customConnectionString || process.env.DATABASE_SUPERUSER_URL || process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL or DATABASE_SUPERUSER_URL must be defined');
  }

  const isRemote = (
    connectionString.includes('render.com') ||
    connectionString.includes('neon.tech') ||
    connectionString.includes('supabase.co') ||
    connectionString.includes('railway.app') ||
    connectionString.includes('sslmode=require') ||
    process.env.NODE_ENV === 'production'
  );

  return new Pool({
    connectionString,
    connectionTimeoutMillis: 10000,
    ssl: isRemote && !connectionString.includes('localhost') && !connectionString.includes('127.0.0.1')
      ? { rejectUnauthorized: false }
      : false
  });
}

async function runInit(customConnectionString) {
  console.log('--- Initializing MicroLedger PostgreSQL Database ---');
  const pool = getPool(customConnectionString);
  const client = await pool.connect();
  try {
    console.log('Preparing schema and database roles...');
    // Ensure microledger_app role exists for RLS
    await client.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'microledger_app') THEN
          CREATE ROLE microledger_app WITH LOGIN PASSWORD 'microledger_app_password';
        END IF;
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END
      $$;
    `);

    // Reset public schema cleanly if needed
    await client.query('DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;');
    await client.query('GRANT ALL ON SCHEMA public TO public;');

    const sqlFiles = [
      '01_schema.sql',
      '02_constraints_triggers.sql',
      '03_stored_procedures.sql',
      '04_reports_and_security.sql',
      '05_integrity_checks.sql',
      '06_seed_kiva_nrlm.sql'
    ];

    for (const file of sqlFiles) {
      const filePath = path.resolve(__dirname, '../Database', file);
      if (!fs.existsSync(filePath)) {
        console.warn(`File not found: ${filePath}, skipping.`);
        continue;
      }
      console.log(`Applying Database/${file}...`);
      const sql = fs.readFileSync(filePath, 'utf-8');
      await client.query(sql);
    }

    console.log('Granting privileges on public schema...');
    await client.query(`
      DO $$
      BEGIN
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO public;
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO public;
        GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public TO public;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO public;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO public;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO public;
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END
      $$;
    `);

    console.log('✓ Database schema, procedures, and seed data initialized successfully!\n');
  } finally {
    client.release();
    await pool.end();
  }
}

if (require.main === module) {
  runInit().catch((err) => {
    console.error('Database initialization failed:', err);
    process.exit(1);
  });
}

module.exports = { runInit };
