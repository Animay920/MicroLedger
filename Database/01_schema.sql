-- MicroLedger 
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE branch (
  branch_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  region TEXT NOT NULL
);

CREATE TABLE center (
  center_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  branch_id BIGINT NOT NULL REFERENCES branch(branch_id),
  name TEXT NOT NULL,
  meeting_day SMALLINT CHECK (meeting_day BETWEEN 1 AND 7),
  frequency TEXT NOT NULL CHECK (frequency IN ('WEEKLY','FORTNIGHTLY','MONTHLY'))
);

CREATE TABLE app_user (
  user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  branch_id BIGINT NOT NULL REFERENCES branch(branch_id),
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('FIELD_OFFICER','CASHIER','MANAGER','AUDITOR','ADMIN')),
  password_hash TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE borrower (
  borrower_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  center_id BIGINT NOT NULL REFERENCES center(center_id),
  full_name TEXT NOT NULL,
  national_id_hash TEXT UNIQUE,
  phone TEXT,
  monthly_household_income NUMERIC(14,2) NOT NULL DEFAULT 25000 CHECK (monthly_household_income >= 0),
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE','BLOCKED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE jlg_group (
  group_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  center_id BIGINT NOT NULL REFERENCES center(center_id),
  name TEXT NOT NULL,
  formed_on DATE NOT NULL DEFAULT CURRENT_DATE,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','CLOSED')),
  max_exposure NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (max_exposure >= 0)
);

CREATE TABLE group_member (
  group_id BIGINT NOT NULL REFERENCES jlg_group(group_id),
  borrower_id BIGINT NOT NULL REFERENCES borrower(borrower_id),
  joined_on DATE NOT NULL DEFAULT CURRENT_DATE,
  left_on DATE,
  member_role TEXT NOT NULL DEFAULT 'MEMBER',
  PRIMARY KEY (group_id, borrower_id, joined_on),
  CHECK (left_on IS NULL OR left_on >= joined_on)
);

CREATE TABLE loan (
  loan_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  borrower_id BIGINT NOT NULL REFERENCES borrower(borrower_id),
  group_id BIGINT NOT NULL REFERENCES jlg_group(group_id),
  cycle_no INTEGER NOT NULL CHECK (cycle_no > 0),
  principal NUMERIC(14,2) NOT NULL CHECK (principal > 0),
  annual_rate NUMERIC(7,4) NOT NULL CHECK (annual_rate >= 0),
  tenure_weeks INTEGER NOT NULL CHECK (tenure_weeks > 0),
  disbursed_on DATE NOT NULL DEFAULT CURRENT_DATE,
  outstanding_principal NUMERIC(14,2) NOT NULL CHECK (outstanding_principal >= 0),
  fees_due NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (fees_due >= 0),
  overdue_interest_due NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (overdue_interest_due >= 0),
  current_interest_due NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (current_interest_due >= 0),
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','ACTIVE','DELINQUENT','CLOSED','DEFAULTED')),
  version BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE installment (
  installment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  loan_id BIGINT NOT NULL REFERENCES loan(loan_id),
  seq_no INTEGER NOT NULL,
  due_date DATE NOT NULL,
  fee_due NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (fee_due >= 0),
  arrears_interest_due NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (arrears_interest_due >= 0),
  current_interest_due NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (current_interest_due >= 0),
  principal_due NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (principal_due >= 0),
  paid_total NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (paid_total >= 0),
  status TEXT NOT NULL DEFAULT 'DUE' CHECK (status IN ('DUE','PARTIAL','PAID','OVERDUE')),
  UNIQUE (loan_id, seq_no)
);

CREATE TABLE guarantee (
  guarantee_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guarantor_id BIGINT NOT NULL REFERENCES borrower(borrower_id),
  guaranteed_loan_id BIGINT NOT NULL REFERENCES loan(loan_id),
  share_pct NUMERIC(5,2) NOT NULL CHECK (share_pct > 0 AND share_pct <= 100),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (guarantor_id, guaranteed_loan_id)
);

CREATE TABLE repayment (
  repayment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  loan_id BIGINT NOT NULL REFERENCES loan(loan_id),
  collected_by BIGINT NOT NULL REFERENCES app_user(user_id),
  amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  idempotency_key TEXT NOT NULL UNIQUE,
  channel TEXT NOT NULL DEFAULT 'FIELD' CHECK (channel IN ('FIELD','BRANCH','ONLINE')),
  paid_by_name TEXT,
  payer_relation TEXT DEFAULT 'SELF'
);

CREATE TABLE payment_allocation (
  allocation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  repayment_id BIGINT NOT NULL REFERENCES repayment(repayment_id),
  account_head TEXT NOT NULL CHECK (account_head IN ('FEES','OVERDUE_INTEREST','CURRENT_INTEREST','PRINCIPAL')),
  amount NUMERIC(14,2) NOT NULL CHECK (amount > 0)
);

CREATE TABLE ledger_entry (
  entry_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  branch_id BIGINT NOT NULL REFERENCES branch(branch_id),
  repayment_id BIGINT REFERENCES repayment(repayment_id),
  loan_id BIGINT NOT NULL REFERENCES loan(loan_id),
  account_head TEXT NOT NULL,
  debit NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (debit >= 0),
  credit NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (credit >= 0),
  posted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  prev_hash TEXT,
  entry_hash TEXT NOT NULL,
  CHECK (NOT (debit > 0 AND credit > 0)),
  CHECK (debit > 0 OR credit > 0)
);

CREATE TABLE guarantee_exposure (
  exposure_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  borrower_id BIGINT NOT NULL REFERENCES borrower(borrower_id),
  source_loan_id BIGINT NOT NULL REFERENCES loan(loan_id),
  exposure_amount NUMERIC(14,2) NOT NULL CHECK (exposure_amount >= 0),
  depth INTEGER NOT NULL CHECK (depth >= 1),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (borrower_id, source_loan_id)
);

CREATE TABLE IF NOT EXISTS payment_transaction (
  transaction_id TEXT PRIMARY KEY,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('REPAYMENT', 'LOAN_DISBURSEMENT', 'LOAN_CREATION', 'GUARANTOR_REPAYMENT', 'MISSED_INSTALLMENT')),
  loan_id BIGINT REFERENCES loan(loan_id),
  borrower_id BIGINT REFERENCES borrower(borrower_id),
  branch_id BIGINT REFERENCES branch(branch_id),
  amount NUMERIC(14,2) NOT NULL,
  payment_method TEXT NOT NULL,
  gateway_reference TEXT,
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'NETWORK_ABORTED', 'OVERDUE')),
  failure_reason TEXT,
  repayment_id BIGINT REFERENCES repayment(repayment_id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_borrower_center ON borrower(center_id);
CREATE INDEX idx_group_center ON jlg_group(center_id);
CREATE INDEX idx_loan_borrower ON loan(borrower_id);
CREATE INDEX idx_loan_group_status ON loan(group_id, status);
CREATE INDEX idx_installment_due ON installment(due_date, status);
CREATE INDEX idx_guarantee_loan ON guarantee(guaranteed_loan_id) WHERE active;
CREATE INDEX idx_exposure_borrower ON guarantee_exposure(borrower_id);
CREATE INDEX idx_ledger_loan_time ON ledger_entry(loan_id, posted_at);
CREATE INDEX idx_ledger_branch ON ledger_entry(branch_id);
CREATE INDEX idx_payment_transaction_branch ON payment_transaction(branch_id);
CREATE INDEX idx_payment_transaction_status ON payment_transaction(status);
