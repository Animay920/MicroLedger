-- R2: reducing-balance weekly repayment schedule.
CREATE OR REPLACE FUNCTION generate_repayment_schedule(p_loan_id BIGINT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  v_principal NUMERIC(14,2);
  v_rate NUMERIC;
  v_weeks INTEGER;
  v_date DATE;
  v_balance NUMERIC(14,2);
  v_interest NUMERIC(14,2);
  v_payment NUMERIC(14,2);
  v_principal_part NUMERIC(14,2);
  i INTEGER;
BEGIN
  SELECT principal, annual_rate / 100.0 / 52.0, tenure_weeks, disbursed_on
  INTO v_principal, v_rate, v_weeks, v_date
  FROM loan WHERE loan_id=p_loan_id FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'Loan % not found', p_loan_id; END IF;
  DELETE FROM installment WHERE loan_id=p_loan_id;
  v_balance := v_principal;

  IF v_rate = 0 THEN
    v_payment := round(v_principal / v_weeks, 2);
  ELSE
    v_payment := round(v_principal * v_rate / (1 - power(1 + v_rate, -v_weeks)), 2);
  END IF;

  FOR i IN 1..v_weeks LOOP
    v_interest := round(v_balance * v_rate, 2);
    IF i = v_weeks THEN
      v_principal_part := v_balance;
    ELSE
      v_principal_part := LEAST(v_balance, v_payment - v_interest);
    END IF;

    INSERT INTO installment(
      loan_id, seq_no, due_date, current_interest_due, principal_due
    ) VALUES (
      p_loan_id, i, v_date + (i * 7), v_interest, v_principal_part
    );

    v_balance := GREATEST(0, v_balance - v_principal_part);
  END LOOP;
END;
$$;

-- R13: block disbursement if current group guarantee exposure exceeds its cap or if RBI 50% FOIR limit is exceeded.
CREATE OR REPLACE FUNCTION assert_group_eligible(p_group_id BIGINT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  v_exposure NUMERIC(14,2);
  v_limit NUMERIC(14,2);
  v_status TEXT;
  v_member RECORD;
  v_monthly_debt NUMERIC(14,2);
  v_foir_limit NUMERIC(14,2);
BEGIN
  SELECT status, max_exposure INTO v_status, v_limit
  FROM jlg_group WHERE group_id=p_group_id FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'Group not found'; END IF;
  IF v_status <> 'ACTIVE' THEN RAISE EXCEPTION 'Group is not active'; END IF;

  SELECT COALESCE(SUM(ge.exposure_amount),0)
  INTO v_exposure
  FROM guarantee_exposure ge
  JOIN group_member gm ON gm.borrower_id=ge.borrower_id
  WHERE gm.group_id=p_group_id AND gm.left_on IS NULL;

  IF v_exposure > v_limit THEN
    RAISE EXCEPTION 'Disbursement blocked: group exposure % exceeds limit %', v_exposure, v_limit;
  END IF;

  -- RBI Household FOIR Validation:
  -- Total monthly debt obligations must not exceed 50% of monthly household income
  FOR v_member IN
    SELECT b.borrower_id, b.full_name, b.monthly_household_income
    FROM group_member gm
    JOIN borrower b ON b.borrower_id = gm.borrower_id
    WHERE gm.group_id = p_group_id AND gm.left_on IS NULL
  LOOP
    SELECT COALESCE(SUM(
      CASE
        WHEN l.annual_rate = 0 THEN (l.principal / l.tenure_weeks) * (52.0 / 12.0)
        ELSE (
          l.principal * (l.annual_rate / 100.0 / 52.0) /
          (1 - power(1 + (l.annual_rate / 100.0 / 52.0), -l.tenure_weeks))
        ) * (52.0 / 12.0)
      END
    ), 0)
    INTO v_monthly_debt
    FROM loan l
    WHERE l.borrower_id = v_member.borrower_id
      AND l.status IN ('PENDING', 'ACTIVE', 'DELINQUENT');

    v_foir_limit := round(v_member.monthly_household_income * 0.50, 2);

    IF v_monthly_debt > v_foir_limit THEN
      RAISE EXCEPTION 'Disbursement blocked: Borrower % (%) monthly debt obligations % exceed 50%% of monthly household income % (FOIR limit %)',
        v_member.borrower_id, v_member.full_name, v_monthly_debt, v_member.monthly_household_income, v_foir_limit;
    END IF;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION disburse_loan(p_loan_id BIGINT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE v_group BIGINT;
BEGIN
  SELECT group_id INTO v_group FROM loan WHERE loan_id=p_loan_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Loan not found'; END IF;

  PERFORM assert_group_eligible(v_group);

  UPDATE loan
  SET status='ACTIVE', outstanding_principal=principal, version=version+1
  WHERE loan_id=p_loan_id AND status='PENDING';

  IF NOT FOUND THEN RAISE EXCEPTION 'Only pending loans can be disbursed'; END IF;
  PERFORM generate_repayment_schedule(p_loan_id);
END;
$$;

-- R9: propagate default exposure through guarantee edges.
-- Each hop applies the next guarantor's guarantee percentage. Path prevents cycles.
CREATE OR REPLACE FUNCTION propagate_guarantee_exposure(p_default_loan_id BIGINT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
  v_default_amount NUMERIC(14,2);
  v_status TEXT;
  v_group_id BIGINT;
BEGIN
  SELECT status, (fees_due + overdue_interest_due + current_interest_due + outstanding_principal), group_id
  INTO v_status, v_default_amount, v_group_id
  FROM loan WHERE loan_id=p_default_loan_id;

  IF NOT FOUND THEN RAISE EXCEPTION 'Default loan not found'; END IF;

  IF v_status NOT IN ('DELINQUENT', 'DEFAULTED') OR v_default_amount = 0 THEN
    UPDATE guarantee_exposure
    SET exposure_amount = 0, updated_at = now()
    WHERE source_loan_id = p_default_loan_id;
    RETURN;
  END IF;

  WITH RECURSIVE liability(borrower_id, amount, depth, path) AS (
    SELECT g.guarantor_id,
           round(v_default_amount * g.share_pct / 100.0, 2),
           1,
           ARRAY[g.guarantor_id]::BIGINT[]
    FROM guarantee g
    WHERE g.guaranteed_loan_id=p_default_loan_id AND g.active

    UNION ALL

    SELECT g2.guarantor_id,
           round(l.amount * g2.share_pct / 100.0, 2),
           l.depth + 1,
           l.path || g2.guarantor_id
    FROM liability l
    JOIN loan other_loan ON other_loan.borrower_id=l.borrower_id
    JOIN guarantee g2 ON g2.guaranteed_loan_id=other_loan.loan_id AND g2.active
    WHERE l.depth < 8
      AND NOT g2.guarantor_id = ANY(l.path)
      -- Confine guarantee propagation strictly to the same JLG group as the defaulting loan
      AND other_loan.group_id = v_group_id
  )
  INSERT INTO guarantee_exposure(borrower_id, source_loan_id, exposure_amount, depth, updated_at)
  SELECT borrower_id, p_default_loan_id, SUM(amount), MIN(depth), now()
  FROM liability
  GROUP BY borrower_id
  ON CONFLICT (borrower_id, source_loan_id)
  DO UPDATE SET exposure_amount=EXCLUDED.exposure_amount,
                depth=EXCLUDED.depth, updated_at=now();
END;
$$;

-- R8/R11/R12: one atomic repayment with waterfall allocation and ledger posting.
-- Call inside a DB transaction. Unique idempotency_key is the final duplicate guard.
CREATE OR REPLACE FUNCTION post_repayment(
  p_loan_id BIGINT,
  p_collected_by BIGINT,
  p_amount NUMERIC(14,2),
  p_idempotency_key TEXT,
  p_channel TEXT,
  p_expected_version BIGINT,
  p_paid_by_name TEXT DEFAULT NULL,
  p_payer_relation TEXT DEFAULT 'SELF'
)
RETURNS TABLE(repayment_id BIGINT, fees_paid NUMERIC, overdue_interest_paid NUMERIC,
              current_interest_paid NUMERIC, principal_paid NUMERIC, new_version BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
  v_loan loan%ROWTYPE;
  v_repayment_id BIGINT;
  v_remaining NUMERIC(14,2);
  v_fees NUMERIC(14,2);
  v_overdue NUMERIC(14,2);
  v_current NUMERIC(14,2);
  v_principal NUMERIC(14,2);
  v_branch_id BIGINT;
  v_prev_hash TEXT;
  v_hash TEXT;
  v_head TEXT;
  v_amt NUMERIC(14,2);
  v_ts TIMESTAMPTZ;
  v_alloc_remaining NUMERIC(14,2);
  v_inst RECORD;
  v_inst_due NUMERIC(14,2);
  v_inst_pay NUMERIC(14,2);
BEGIN
  IF p_amount <= 0 THEN RAISE EXCEPTION 'Repayment amount must be positive'; END IF;

  -- Optimistic attempt. The row version protects against lost updates.
  UPDATE loan
  SET version=version+1
  WHERE loan_id=p_loan_id AND version=p_expected_version
  RETURNING * INTO v_loan;

  IF NOT FOUND THEN
    -- Pessimistic fallback: acquire row lock, then reject stale client state.
    SELECT * INTO v_loan FROM loan WHERE loan_id=p_loan_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Loan not found'; END IF;
    RAISE EXCEPTION 'VERSION_CONFLICT: expected %, current %', p_expected_version, v_loan.version
      USING ERRCODE='40001';
  END IF;

  IF v_loan.status NOT IN ('ACTIVE','DELINQUENT','DEFAULTED') THEN
    RAISE EXCEPTION 'Loan is not open for repayment';
  END IF;

  -- Determine branch_id for branch-scoped locking and ledger entry
  SELECT c.branch_id INTO v_branch_id
  FROM borrower b
  JOIN center c ON c.center_id = b.center_id
  WHERE b.borrower_id = v_loan.borrower_id;

  INSERT INTO repayment(loan_id,collected_by,amount,idempotency_key,channel,paid_by_name,payer_relation)
  VALUES(p_loan_id,p_collected_by,p_amount,p_idempotency_key,p_channel,p_paid_by_name,COALESCE(p_payer_relation, 'SELF'))
  RETURNING repayment.repayment_id INTO v_repayment_id;

  v_remaining := p_amount;
  v_fees := LEAST(v_remaining, v_loan.fees_due);
  v_remaining := v_remaining - v_fees;

  v_overdue := LEAST(v_remaining, v_loan.overdue_interest_due);
  v_remaining := v_remaining - v_overdue;

  v_current := LEAST(v_remaining, v_loan.current_interest_due);
  v_remaining := v_remaining - v_current;

  v_principal := LEAST(v_remaining, v_loan.outstanding_principal);
  v_remaining := v_remaining - v_principal;

  IF v_remaining > 0 THEN
    RAISE EXCEPTION 'Repayment exceeds total outstanding dues by %', v_remaining;
  END IF;

  UPDATE loan SET
    fees_due=fees_due-v_fees,
    overdue_interest_due=overdue_interest_due-v_overdue,
    current_interest_due=current_interest_due-v_current,
    outstanding_principal=outstanding_principal-v_principal,
    status=CASE WHEN (outstanding_principal-v_principal=0)
                     AND (fees_due-v_fees=0)
                     AND (overdue_interest_due-v_overdue=0)
                     AND (current_interest_due-v_current=0)
                THEN 'CLOSED'
                WHEN status IN ('DELINQUENT', 'DEFAULTED')
                     AND (fees_due-v_fees=0)
                     AND (overdue_interest_due-v_overdue=0)
                THEN 'ACTIVE'
                ELSE status END
  WHERE loan_id=p_loan_id;

  IF v_fees > 0 THEN INSERT INTO payment_allocation VALUES(DEFAULT,v_repayment_id,'FEES',v_fees); END IF;
  IF v_overdue > 0 THEN INSERT INTO payment_allocation VALUES(DEFAULT,v_repayment_id,'OVERDUE_INTEREST',v_overdue); END IF;
  IF v_current > 0 THEN INSERT INTO payment_allocation VALUES(DEFAULT,v_repayment_id,'CURRENT_INTEREST',v_current); END IF;
  IF v_principal > 0 THEN INSERT INTO payment_allocation VALUES(DEFAULT,v_repayment_id,'PRINCIPAL',v_principal); END IF;

  -- Synchronize installment rows chronologically
  v_alloc_remaining := p_amount;
  FOR v_inst IN
    SELECT installment_id, fee_due, arrears_interest_due, current_interest_due, principal_due, paid_total
    FROM installment
    WHERE loan_id = p_loan_id AND status IN ('DUE', 'PARTIAL', 'OVERDUE')
    ORDER BY seq_no
    FOR UPDATE
  LOOP
    EXIT WHEN v_alloc_remaining <= 0;
    v_inst_due := (v_inst.fee_due + v_inst.arrears_interest_due + v_inst.current_interest_due + v_inst.principal_due) - v_inst.paid_total;
    IF v_inst_due > 0 THEN
      v_inst_pay := LEAST(v_alloc_remaining, v_inst_due);
      UPDATE installment
      SET paid_total = paid_total + v_inst_pay,
          status = CASE WHEN (paid_total + v_inst_pay) >= (fee_due + arrears_interest_due + current_interest_due + principal_due)
                        THEN 'PAID' ELSE 'PARTIAL' END
      WHERE installment_id = v_inst.installment_id;
      v_alloc_remaining := v_alloc_remaining - v_inst_pay;
    END IF;
  END LOOP;

  -- Branch-scoped advisory lock prevents global serialization
  PERFORM pg_advisory_xact_lock(v_branch_id);
  SELECT entry_hash INTO v_prev_hash
  FROM ledger_entry
  WHERE branch_id = v_branch_id
  ORDER BY entry_id DESC LIMIT 1;

  -- Debit cash once, then credit each receivable account head.
  -- Deterministic v_ts ensures verify_ledger_hash_chain can perfectly recompute hashes.
  FOR v_head, v_amt IN
    SELECT 'CASH', p_amount
    UNION ALL SELECT 'FEES_RECEIVABLE', v_fees WHERE v_fees>0
    UNION ALL SELECT 'OVERDUE_INTEREST_RECEIVABLE', v_overdue WHERE v_overdue>0
    UNION ALL SELECT 'CURRENT_INTEREST_RECEIVABLE', v_current WHERE v_current>0
    UNION ALL SELECT 'PRINCIPAL_RECEIVABLE', v_principal WHERE v_principal>0
  LOOP
    v_ts := clock_timestamp();
    IF v_head='CASH' THEN
      v_hash := encode(digest(concat_ws('|',v_prev_hash,v_repayment_id,p_loan_id,v_head,v_amt,0::NUMERIC(14,2),v_ts),'sha256'),'hex');
      INSERT INTO ledger_entry(branch_id,repayment_id,loan_id,account_head,debit,credit,posted_at,prev_hash,entry_hash)
      VALUES(v_branch_id,v_repayment_id,p_loan_id,v_head,v_amt,0,v_ts,v_prev_hash,v_hash);
    ELSE
      v_hash := encode(digest(concat_ws('|',v_prev_hash,v_repayment_id,p_loan_id,v_head,0::NUMERIC(14,2),v_amt,v_ts),'sha256'),'hex');
      INSERT INTO ledger_entry(branch_id,repayment_id,loan_id,account_head,debit,credit,posted_at,prev_hash,entry_hash)
      VALUES(v_branch_id,v_repayment_id,p_loan_id,v_head,0,v_amt,v_ts,v_prev_hash,v_hash);
    END IF;
    v_prev_hash := v_hash;
  END LOOP;

  RETURN QUERY SELECT v_repayment_id,v_fees,v_overdue,v_current,v_principal,v_loan.version;
END;
$$;

-- Reversing-Entry Correction Procedure
CREATE OR REPLACE FUNCTION reverse_repayment(
  p_repayment_id BIGINT,
  p_user_id BIGINT
)
RETURNS TABLE(repayment_id BIGINT, loan_id BIGINT, reversed_amount NUMERIC, new_version BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
  v_rep repayment%ROWTYPE;
  v_loan loan%ROWTYPE;
  v_branch_id BIGINT;
  v_fees NUMERIC(14,2) := 0;
  v_overdue NUMERIC(14,2) := 0;
  v_current NUMERIC(14,2) := 0;
  v_principal NUMERIC(14,2) := 0;
  v_prev_hash TEXT;
  v_hash TEXT;
  v_ts TIMESTAMPTZ;
  v_head TEXT;
  v_amt NUMERIC(14,2);
  v_alloc_unwind NUMERIC(14,2);
  v_inst RECORD;
  v_inst_unwind NUMERIC(14,2);
  v_already_reversed BOOLEAN;
BEGIN
  SELECT * INTO v_rep FROM repayment WHERE repayment.repayment_id = p_repayment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Repayment % not found', p_repayment_id;
  END IF;

  -- Guard against duplicate reversal
  SELECT EXISTS (
    SELECT 1 FROM ledger_entry le
    WHERE le.repayment_id = p_repayment_id AND le.account_head = 'REVERSAL_CASH'
  ) INTO v_already_reversed;

  IF v_already_reversed THEN
    RAISE EXCEPTION 'Repayment % has already been reversed', p_repayment_id;
  END IF;

  SELECT * INTO v_loan FROM loan WHERE loan.loan_id = v_rep.loan_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Loan % not found', v_rep.loan_id;
  END IF;

  SELECT c.branch_id INTO v_branch_id
  FROM borrower b
  JOIN center c ON c.center_id = b.center_id
  WHERE b.borrower_id = v_loan.borrower_id;

  -- Branch-scoped lock
  PERFORM pg_advisory_xact_lock(v_branch_id);

  -- Retrieve original allocations
  SELECT COALESCE(SUM(pa.amount) FILTER (WHERE pa.account_head = 'FEES'), 0),
         COALESCE(SUM(pa.amount) FILTER (WHERE pa.account_head = 'OVERDUE_INTEREST'), 0),
         COALESCE(SUM(pa.amount) FILTER (WHERE pa.account_head = 'CURRENT_INTEREST'), 0),
         COALESCE(SUM(pa.amount) FILTER (WHERE pa.account_head = 'PRINCIPAL'), 0)
  INTO v_fees, v_overdue, v_current, v_principal
  FROM payment_allocation pa
  WHERE pa.repayment_id = p_repayment_id;

  -- Restore loan dues and status
  UPDATE loan SET
    fees_due = fees_due + v_fees,
    overdue_interest_due = overdue_interest_due + v_overdue,
    current_interest_due = current_interest_due + v_current,
    outstanding_principal = outstanding_principal + v_principal,
    status = CASE WHEN status = 'CLOSED' THEN 'ACTIVE' ELSE status END,
    version = version + 1
  WHERE loan.loan_id = v_rep.loan_id
  RETURNING * INTO v_loan;

  -- Unwind installment rows chronologically in reverse
  v_alloc_unwind := v_rep.amount;
  FOR v_inst IN
    SELECT installment_id, fee_due, arrears_interest_due, current_interest_due, principal_due, paid_total, due_date
    FROM installment
    WHERE installment.loan_id = v_rep.loan_id AND paid_total > 0
    ORDER BY seq_no DESC
    FOR UPDATE
  LOOP
    EXIT WHEN v_alloc_unwind <= 0;
    v_inst_unwind := LEAST(v_alloc_unwind, v_inst.paid_total);
    UPDATE installment
    SET paid_total = paid_total - v_inst_unwind,
        status = CASE WHEN (paid_total - v_inst_unwind) = 0 THEN
                        CASE WHEN due_date < CURRENT_DATE THEN 'OVERDUE' ELSE 'DUE' END
                      ELSE 'PARTIAL' END
    WHERE installment_id = v_inst.installment_id;
    v_alloc_unwind := v_alloc_unwind - v_inst_unwind;
  END LOOP;

  -- Fetch latest branch hash
  SELECT entry_hash INTO v_prev_hash
  FROM ledger_entry
  WHERE branch_id = v_branch_id
  ORDER BY entry_id DESC LIMIT 1;

  -- Mirror debit to receivables
  FOR v_head, v_amt IN
    SELECT 'FEES_RECEIVABLE', v_fees WHERE v_fees > 0
    UNION ALL SELECT 'OVERDUE_INTEREST_RECEIVABLE', v_overdue WHERE v_overdue > 0
    UNION ALL SELECT 'CURRENT_INTEREST_RECEIVABLE', v_current WHERE v_current > 0
    UNION ALL SELECT 'PRINCIPAL_RECEIVABLE', v_principal WHERE v_principal > 0
  LOOP
    v_ts := clock_timestamp();
    v_hash := encode(digest(concat_ws('|', v_prev_hash, p_repayment_id, v_rep.loan_id, v_head, v_amt, 0::NUMERIC(14,2), v_ts), 'sha256'), 'hex');
    INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
    VALUES(v_branch_id, p_repayment_id, v_rep.loan_id, v_head, v_amt, 0, v_ts, v_prev_hash, v_hash);
    v_prev_hash := v_hash;
  END LOOP;

  -- Mirror credit to cash
  v_ts := clock_timestamp();
  v_hash := encode(digest(concat_ws('|', v_prev_hash, p_repayment_id, v_rep.loan_id, 'REVERSAL_CASH', 0::NUMERIC(14,2), v_rep.amount, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES(v_branch_id, p_repayment_id, v_rep.loan_id, 'REVERSAL_CASH', 0, v_rep.amount, v_ts, v_prev_hash, v_hash);

  -- If loan is in delinquent/defaulted state, update guarantee exposure
  IF v_loan.status IN ('DELINQUENT', 'DEFAULTED') THEN
    PERFORM propagate_guarantee_exposure(v_rep.loan_id);
  END IF;

  RETURN QUERY SELECT p_repayment_id, v_rep.loan_id, v_rep.amount, v_loan.version;
END;
$$;

-- End-of-Day (EOD) Delinquency & Accrual Engine
CREATE OR REPLACE FUNCTION run_eod_accrual(p_as_of_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
  processed_loans INTEGER,
  overdue_installments INTEGER,
  delinquent_loans INTEGER,
  defaulted_loans INTEGER
) LANGUAGE plpgsql AS $$
DECLARE
  v_overdue_count INTEGER := 0;
  v_delinquent_count INTEGER := 0;
  v_defaulted_count INTEGER := 0;
  v_processed_loans INTEGER := 0;
  v_loan RECORD;
  v_old_status TEXT;
  v_new_status TEXT;
  v_max_dpd INTEGER;
  v_late_fee NUMERIC(14,2) := 50.00;
BEGIN
  -- 1. Mark past-due installments as OVERDUE
  WITH updated_inst AS (
    UPDATE installment
    SET status = 'OVERDUE'
    WHERE due_date < p_as_of_date
      AND status IN ('DUE', 'PARTIAL')
    RETURNING loan_id, seq_no
  )
  SELECT COUNT(*) INTO v_overdue_count FROM updated_inst;

  -- 2. Process all open loans
  FOR v_loan IN
    SELECT l.loan_id, l.status, l.current_interest_due, l.overdue_interest_due, l.fees_due
    FROM loan l
    WHERE l.status IN ('ACTIVE', 'DELINQUENT')
    FOR UPDATE
  LOOP
    v_processed_loans := v_processed_loans + 1;
    v_old_status := v_loan.status;

    -- Calculate maximum Days Past Due (DPD)
    SELECT COALESCE(MAX(p_as_of_date - i.due_date), 0)
    INTO v_max_dpd
    FROM installment i
    WHERE i.loan_id = v_loan.loan_id
      AND i.status = 'OVERDUE'
      AND (i.fee_due + i.arrears_interest_due + i.current_interest_due + i.principal_due > i.paid_total);

    IF v_max_dpd > 0 THEN
      IF v_max_dpd > 90 THEN
        v_new_status := 'DEFAULTED';
        v_defaulted_count := v_defaulted_count + 1;
      ELSE
        v_new_status := 'DELINQUENT';
        v_delinquent_count := v_delinquent_count + 1;
      END IF;

      -- Shift unpaid interest to overdue_interest_due, apply late fee, and update status
      UPDATE loan
      SET status = v_new_status,
          overdue_interest_due = overdue_interest_due + current_interest_due,
          current_interest_due = 0,
          fees_due = fees_due + (CASE WHEN v_old_status = 'ACTIVE' THEN v_late_fee ELSE 0 END),
          version = version + 1
      WHERE loan_id = v_loan.loan_id;

      -- Propagate exposure
      PERFORM propagate_guarantee_exposure(v_loan.loan_id);
    END IF;
  END LOOP;

  RETURN QUERY SELECT v_processed_loans, v_overdue_count, v_delinquent_count, v_defaulted_count;
END;
$$;