# MicroLedger

> **Production-grade, concurrency-safe Joint Liability Group (JLG) microfinance operations platform with double-entry cryptographic ledger, branch-isolated Row-Level Security, and RBI regulatory compliance.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-brightgreen.svg)](https://nodejs.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-blue.svg)](https://www.postgresql.org/)
[![React](https://img.shields.io/badge/React-18-61dafb.svg)](https://react.dev/)
[![Vite](https://img.shields.io/badge/Vite-6-646cff.svg)](https://vitejs.dev/)

---

## Table of Contents
1. [Overview & Core Architecture](#overview--core-architecture)
2. [Key Capabilities & Regulatory Compliance](#key-capabilities--regulatory-compliance)
3. [System Architecture Diagram](#system-architecture-diagram)
4. [Project Structure](#project-structure)
5. [Prerequisites](#prerequisites)
6. [Quick Start (Local Development)](#quick-start-local-development)
7. [Database Setup & Seeding](#database-setup--seeding)
8. [Production Deployment & Publishing](#production-deployment--publishing)
9. [API Endpoints Reference](#api-endpoints-reference)
10. [Documentation & Whitepaper](#documentation--whitepaper)

---

## Overview & Core Architecture

**MicroLedger** is a banking-grade financial ledger and field operations engine tailored for microfinance institutions (MFIs), Non-Banking Financial Companies (NBFC-MFIs), and Self-Help Group (SHG) networks operating under the Joint Liability Group model.

* **Append-Only Double-Entry Journal**: Every financial event records balanced debit and credit entries ($\sum \text{Debit} = \sum \text{Credit}$) across standardized account heads (`CASH`, `PRINCIPAL`, `CURRENT_INTEREST`, `OVERDUE_INTEREST`, `FEES`).
* **Cryptographic Tamper-Evidence**: Ledger entries are anchored in a branch-partitioned SHA-256 hash-chain:
  $$\text{Hash}_i = \text{SHA256}(\text{Hash}_{i-1} \parallel \text{BranchID} \parallel \text{RepaymentID} \parallel \text{AccountHead} \parallel \text{Amount} \parallel \text{Timestamp})$$
  Any direct modification of ledger rows is immediately flagged by `verify_ledger_hash_chain()`.
* **Zero Lost Updates Under High Concurrency**: Optimistic row-version checks combined with branch-scoped transactional advisory locks (`pg_advisory_xact_lock(branch_id)`) allow parallel repayments across branches without lock contention.
* **Database-Enforced Row-Level Security (RLS)**: Enforces `FORCE ROW LEVEL SECURITY` on all tables, isolating operational queries to the field officer's active branch context via session configuration (`app.branch_id`, `app.role`).

---

## Key Capabilities & Regulatory Compliance

1. **RBI Household FOIR Compliance**:
   - Automatic disbursement block inside `assert_group_eligible()` if a borrower's cumulative debt service exceeds **50% of monthly household income**.
2. **Mutual Guarantee Network & 3-Group Limit**:
   - Guarantors must be active members of the same JLG group; guarantee shares per loan cannot exceed 100%.
   - A single borrower may belong to a maximum of **3 active groups**.
   - Recursive peer liability propagation stays strictly confined to the defaulting loan's group; solo borrowers carry zero cross-group exposure.
3. **Repayment Payer Tracking**:
   - Single and weekly center meeting bulk collections record both **on whose behalf** (beneficiary borrower) and **who made the payment** (Borrower Self, JLG Co-Guarantor Peer, Family Member, or Group Leader).
4. **Waterfall Allocation Engine**:
   - Atomic collection distribution: $\text{Late Fees} \longrightarrow \text{Overdue Interest} \longrightarrow \text{Current Interest} \longrightarrow \text{Principal}$.
   - Open installment rows are updated chronologically (`PAID` / `PARTIAL`).
5. **Reversing-Entry Corrections**:
   - Full audit compliance: rather than deleting records, ledger corrections post mirror debit/credit entries, restore dues, and recalculate exposure.
6. **Payment Gateway & Terminal Desk**:
   - Unified collection terminal supporting cash desk and online payment gateway transitions with slow-network retry protection and complete state tracking (`SUCCESS`, `FAILED`, `ABORTED`).

---

## System Architecture Diagram

```mermaid
flowchart TD
    Client["React 18 + Vite Frontend\n(Dark/Light UI · Responsive Shell)"]
    API["Express.js API Gateway\n(Rate Limiting · JWT Auth · RLS Scoping)"]
    Redis[("Redis / Memurai\n(Fast Idempotency Guards)")]
    DB[("PostgreSQL 15+\n(Double-Entry Ledger · RLS · Stored Procedures)")]

    Client -->|HTTPS / REST| API
    API -->|Key Validation & Locks| Redis
    API -->|Session-Scoped withBranchContext| DB
    DB -->|Branch Advisory Locks| DB
    DB -->|Recursive Liability CTE| DB
```

---

## Project Structure

```
MicroLedger/
├── Backend/
│   ├── middleware/
│   │   ├── auth.js                 # JWT authentication & role-based authorization
│   │   └── withBranchContext.js    # Sets session context for Row-Level Security
│   ├── routes/                     # Domain API routes (borrowers, loans, repayments, etc.)
│   ├── db.js                       # PostgreSQL connection pool
│   ├── redis.js                    # Redis client with transactional database fallback
│   ├── server.js                   # Unified Express application & static server
│   ├── .env.example                # Backend environment template
│   └── package.json
├── Frontend/
│   ├── src/
│   │   ├── services/api.js         # Centralized API service client
│   │   ├── App.jsx                 # Full operations console (Borrowers, Loans, Collections, Ledger)
│   │   ├── PaymentTerminal.jsx     # Payment terminal & gateway simulation
│   │   ├── main.jsx
│   │   └── styles.css              # Modern design system & theme variables
│   ├── index.html
│   ├── vite.config.js
│   ├── .env.example
│   └── package.json
├── Database/
│   ├── 01_schema.sql               # Base tables, indexes, and branch partitioning
│   ├── 02_constraints_triggers.sql # Row-Level Security, check constraints, & triggers
│   ├── 03_stored_procedures.sql    # Atomic stored procedures (waterfall allocation, hash chain)
│   ├── 04_reports_and_security.sql # Analytical reporting views
│   ├── 05_integrity_checks.sql     # Cryptographic validation & balancing functions
│   └── 06_seed_kiva_nrlm.sql       # NRLM/Kiva field dataset (28 members, 10 JLGs, transactions)
├── Reports/
│   └── MicroLedger_Technical_Documentation_and_Schema_Whitepaper.pdf
├── scripts/
│   ├── init_database.js            # Automated database initializer
│   ├── verify_system.js            # Cryptographic & double-entry integrity check
│   └── render_pdf.js               # Technical whitepaper PDF generator
├── Dockerfile                      # Multi-stage production container
├── docker-compose.yml              # Local fullstack container orchestration
├── .gitignore                      # Security-first gitignore rules
├── package.json                    # Root orchestration scripts
└── README.md
```

---

## Prerequisites

* **Node.js**: v18.0.0 or higher
* **npm**: v9.0.0 or higher
* **PostgreSQL**: v15.0 or higher
* **Redis** *(Optional)*: Recommended for high-throughput distributed idempotency caching; application automatically falls back to PostgreSQL transactions if Redis is absent.

---

## Quick Start (Local Development)

### 1. Clone the repository
```bash
git clone https://github.com/your-username/microledger.git
cd microledger
```

### 2. Install all dependencies
```bash
npm run install:all
```

### 3. Configure environment variables
Create `Backend/.env` by copying `Backend/.env.example`:
```env
PORT=5000
DATABASE_URL=postgresql://microledger_app:your_password@localhost:5432/microledger
DATABASE_SUPERUSER_URL=postgresql://postgres:your_postgres_password@localhost:5432/microledger
REDIS_URL=redis://localhost:6379
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRES_IN=8h
```

Create `Frontend/.env` by copying `Frontend/.env.example`:
```env
VITE_API_BASE_URL=http://localhost:5000/api
```

### 4. Initialize Database
Run the automated initialization script to apply all schemas, triggers, stored procedures, and the NRLM dataset:
```bash
npm run init:db
```

### 5. Verify Cryptographic Integrity
Verify that the ledger hash-chains and double-entry accounts balance out of the box:
```bash
npm run verify
```

### 6. Start the Platform
In development, run the backend and frontend servers:

```bash
# Terminal 1 - Start Backend API
npm start

# Terminal 2 - Start Frontend UI
npm --prefix Frontend run dev
```

* Frontend UI: `http://localhost:5173`
* Backend API: `http://localhost:5000`
* Default Admin Login:
  * **Email**: `admin@microledger.com`
  * **Password**: `Admin@12345`

---

## Production Deployment & Publishing

### Option A: Unified Service (Render / Railway / Fly.io / Heroku)
MicroLedger's Express server automatically serves the compiled Vite frontend when `Frontend/dist` exists.

1. Build the frontend assets:
   ```bash
   npm run build
   ```
2. Start the unified production server:
   ```bash
   npm start
   ```
3. The application will serve both the React interface and all API routes from `http://localhost:5000`.

### Option B: Docker & Docker Compose
Run the entire stack (PostgreSQL + MicroLedger container) with one command:
```bash
docker compose up -d
```
Visit `http://localhost:5000` once the container is healthy.

### Option C: Decoupled Cloud Deployment (Vercel + Backend Host)
* **Frontend (Vercel / Netlify)**:
  * Root Directory: `Frontend`
  * Build Command: `npm run build`
  * Output Directory: `dist`
  * Environment Variable: `VITE_API_BASE_URL=https://your-api-domain.com/api`
* **Backend (Render / Railway / AWS)**:
  * Root Directory: `Backend`
  * Start Command: `node server.js`
  * Configure `DATABASE_URL`, `JWT_SECRET`, and `REDIS_URL`.

---

## API Endpoints Reference

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/health` | Service health status | No |
| `POST` | `/api/auth/login` | Authenticate user & issue JWT | No |
| `GET` | `/api/dashboard/summary` | Real-time portfolio metrics & branch PAR | Yes |
| `GET` | `/api/borrowers` | List borrowers in branch context | Yes |
| `POST` | `/api/borrowers` | Register borrower with strict validation | Yes |
| `DELETE` | `/api/borrowers/:id` | Permanently delete borrower (debt guarded) | Admin / Manager |
| `GET` | `/api/groups` | List JLG groups with member counts | Yes |
| `POST` | `/api/groups` | Create JLG group with auto standard ID | Admin / Manager |
| `POST` | `/api/groups/:id/members` | Add member with role (President/Secretary/Member) | Admin / Manager |
| `DELETE` | `/api/groups/:id/members/:bId` | Remove member from JLG group | Admin / Manager |
| `GET` | `/api/groups/:id/exposure` | Recursive JLG peer guarantee exposure | Yes |
| `GET` | `/api/loans` | List loans & reducing-balance schedules | Yes |
| `POST` | `/api/loans/:id/disburse` | Disburse loan with RBI FOIR validation | Admin / Manager |
| `GET` | `/api/repayments` | Audit list of repayments with payer details | Yes |
| `POST` | `/api/repayments` | Record single repayment with waterfall posting | Yes |
| `POST` | `/api/repayments/batch` | Submit weekly center meeting bulk collections | Field Officer / Admin |
| `POST` | `/api/repayments/:id/reverse` | Post reversing mirror entry to restore dues | Admin / Manager |
| `GET` | `/api/ledger` | Double-entry journal entries | Yes |
| `POST` | `/api/ledger/verify` | Execute SHA-256 ledger hash-chain audit | Yes |
| `POST` | `/api/transactions/initiate` | Initiate payment gateway transaction | Yes |
| `POST` | `/api/transactions/:id/complete`| Complete and settle gateway transaction | Yes |

---

## Publishing to GitHub

To push this codebase to your own GitHub repository:

```bash
# 1. Initialize git (if not already initialized)
git init

# 2. Add files and stage commit
git add .
git commit -m "feat: complete production-ready MicroLedger platform"

# 3. Connect to your GitHub repository
git branch -M main
git remote add origin https://github.com/<YOUR_GITHUB_USERNAME>/<YOUR_REPOSITORY_NAME>.git

# 4. Push to GitHub
git push -u origin main
```

---

## Documentation & Whitepaper

A technical whitepaper detailing the double-entry accounting schema, recursive CTE liability propagation, benchmark analysis, and mathematical normalization is included in the repository:

* [MicroLedger Technical Documentation & Schema Whitepaper (PDF)](file:///Reports/MicroLedger_Technical_Documentation_and_Schema_Whitepaper.pdf)

---

## License

Distributed under the MIT License. See `LICENSE` for more information.
