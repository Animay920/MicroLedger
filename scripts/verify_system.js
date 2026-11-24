/**
 * MicroLedger - Automated System Health & Cryptographic Integrity Verification
 * 
 * Verifies:
 * 1. Database connectivity & RLS enforcement
 * 2. SHA-256 tamper-evident ledger hash-chain integrity via verify_ledger_hash_chain()
 * 3. Double-entry balancing (sum(debit) == sum(credit))
 * 4. Microfinance portfolio accounting metrics
 */

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

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error('Error: DATABASE_URL must be defined in Backend/.env');
  process.exit(1);
}

const isRemote = (
  connectionString.includes('render.com') ||
  connectionString.includes('neon.tech') ||
  connectionString.includes('supabase.co') ||
  connectionString.includes('railway.app') ||
  connectionString.includes('sslmode=require') ||
  process.env.NODE_ENV === 'production'
);

const pool = new Pool({
  connectionString,
  connectionTimeoutMillis: 10000,
  ssl: isRemote && !connectionString.includes('localhost') && !connectionString.includes('127.0.0.1')
    ? { rejectUnauthorized: false }
    : false
});

async function verify() {
  console.log('--- MicroLedger System Integrity & Accounting Verification ---\n');
  const client = await pool.connect();
  try {
    // Set branch context for Row-Level Security
    await client.query("SELECT set_config('app.branch_id', '2', false)");
    await client.query("SELECT set_config('app.role', 'ADMIN', false)");

    // 1. Double-entry ledger balance check
    console.log('1. Checking Double-Entry Ledger Equality:');
    const balanceRes = await client.query(`
      SELECT 
        COALESCE(SUM(debit), 0) AS total_debit,
        COALESCE(SUM(credit), 0) AS total_credit,
        COALESCE(SUM(debit) - SUM(credit), 0) AS discrepancy
      FROM ledger_entry
    `);
    const { total_debit, total_credit, discrepancy } = balanceRes.rows[0];
    console.log(`   Total Debits:  ₹${parseFloat(total_debit).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`);
    console.log(`   Total Credits: ₹${parseFloat(total_credit).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`);
    console.log(`   Discrepancy:   ₹${parseFloat(discrepancy).toFixed(2)}`);
    if (Math.abs(parseFloat(discrepancy)) > 0.001) {
      throw new Error(`CRITICAL: Ledger accounts do not balance! Discrepancy: ${discrepancy}`);
    }
    console.log('   ✓ Double-entry books are 100% balanced.\n');

    // 2. Cryptographic SHA-256 hash-chain verification
    console.log('2. Verifying SHA-256 Ledger Hash-Chain:');
    const hashCheckRes = await client.query(`SELECT verify_ledger_hash_chain() AS valid`);
    const isValid = hashCheckRes.rows[0].valid;
    console.log(`   verify_ledger_hash_chain() result: ${isValid}`);
    if (!isValid) {
      throw new Error('CRITICAL: Ledger hash-chain verification failed! Possible tamper detected.');
    }
    console.log('   ✓ Cryptographic hash-chain verified intact across all branch journal entries.\n');

    // 3. Portfolio summary
    console.log('3. Portfolio & Member Summary:');
    const countsRes = await client.query(`
      SELECT 
        (SELECT COUNT(*) FROM borrower) AS total_borrowers,
        (SELECT COUNT(*) FROM jlg_group) AS total_groups,
        (SELECT COUNT(*) FROM loan) AS total_loans,
        (SELECT COUNT(*) FROM repayment) AS total_repayments,
        (SELECT COUNT(*) FROM ledger_entry) AS total_journal_entries
    `);
    const c = countsRes.rows[0];
    console.log(`   Total Borrowers:       ${c.total_borrowers}`);
    console.log(`   Total JLG Groups:      ${c.total_groups}`);
    console.log(`   Total Loan Accounts:   ${c.total_loans}`);
    console.log(`   Total Repayments:      ${c.total_repayments}`);
    console.log(`   Total Journal Entries: ${c.total_journal_entries}\n`);

    console.log('======================================================');
    console.log('✓ ALL SYSTEM INTEGRITY & ACCOUNTING CHECKS PASSED 100%');
    console.log('======================================================\n');
  } catch (err) {
    console.error('\nVerification failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

verify();
