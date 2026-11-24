-- R6/R10:
CREATE OR REPLACE FUNCTION reject_ledger_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'ledger_entry is append-only; post a reversing entry instead';
END;
$$;

CREATE TRIGGER ledger_no_update
BEFORE UPDATE ON ledger_entry
FOR EACH ROW EXECUTE FUNCTION reject_ledger_mutation();

CREATE TRIGGER ledger_no_delete
BEFORE DELETE ON ledger_entry
FOR EACH ROW EXECUTE FUNCTION reject_ledger_mutation();

-- Hash values are created by the posting function. Prevent callers from
-- inserting ledger rows directly unless they provide a hash chain.
CREATE OR REPLACE FUNCTION validate_ledger_insert()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.entry_hash IS NULL OR NEW.entry_hash = '' THEN
    RAISE EXCEPTION 'entry_hash is required';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER ledger_validate_insert
BEFORE INSERT ON ledger_entry
FOR EACH ROW EXECUTE FUNCTION validate_ledger_insert();

-- Generic branch/centre lookup helpers for RLS.
CREATE OR REPLACE FUNCTION current_branch_id()
RETURNS BIGINT LANGUAGE sql STABLE AS $$
  SELECT NULLIF(current_setting('app.branch_id', true), '')::BIGINT
$$;

CREATE OR REPLACE FUNCTION current_app_role()
RETURNS TEXT LANGUAGE sql STABLE AS $$
  SELECT COALESCE(NULLIF(current_setting('app.role', true), ''), 'NONE')
$$;

ALTER TABLE center ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE borrower ENABLE ROW LEVEL SECURITY;
ALTER TABLE jlg_group ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_member ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan ENABLE ROW LEVEL SECURITY;
ALTER TABLE installment ENABLE ROW LEVEL SECURITY;
ALTER TABLE guarantee ENABLE ROW LEVEL SECURITY;
ALTER TABLE repayment ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_allocation ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledger_entry ENABLE ROW LEVEL SECURITY;
ALTER TABLE guarantee_exposure ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transaction ENABLE ROW LEVEL SECURITY;

ALTER TABLE center FORCE ROW LEVEL SECURITY;
ALTER TABLE app_user FORCE ROW LEVEL SECURITY;
ALTER TABLE borrower FORCE ROW LEVEL SECURITY;
ALTER TABLE jlg_group FORCE ROW LEVEL SECURITY;
ALTER TABLE group_member FORCE ROW LEVEL SECURITY;
ALTER TABLE loan FORCE ROW LEVEL SECURITY;
ALTER TABLE installment FORCE ROW LEVEL SECURITY;
ALTER TABLE guarantee FORCE ROW LEVEL SECURITY;
ALTER TABLE repayment FORCE ROW LEVEL SECURITY;
ALTER TABLE payment_allocation FORCE ROW LEVEL SECURITY;
ALTER TABLE ledger_entry FORCE ROW LEVEL SECURITY;
ALTER TABLE guarantee_exposure FORCE ROW LEVEL SECURITY;
ALTER TABLE payment_transaction FORCE ROW LEVEL SECURITY;

-- SECURITY DEFINER lookup for unauthenticated login requests
CREATE OR REPLACE FUNCTION public.login_lookup(p_email TEXT)
RETURNS TABLE (
  user_id BIGINT,
  branch_id BIGINT,
  full_name TEXT,
  email TEXT,
  role TEXT,
  password_hash TEXT,
  active BOOLEAN,
  created_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT user_id, branch_id, full_name, email, role, password_hash, active, created_at
  FROM app_user
  WHERE email = p_email;
$$;

REVOKE ALL ON FUNCTION public.login_lookup(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.login_lookup(TEXT) TO PUBLIC;

-- Trigger ensuring guarantee share_pct per loan does not exceed 100%
CREATE OR REPLACE FUNCTION check_guarantee_share_limit()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_total NUMERIC(5,2);
BEGIN
  IF NOT NEW.active THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(SUM(share_pct), 0)
  INTO v_total
  FROM guarantee
  WHERE guaranteed_loan_id = NEW.guaranteed_loan_id
    AND active = TRUE
    AND guarantee_id IS DISTINCT FROM NEW.guarantee_id;

  IF (v_total + NEW.share_pct) > 100.00 THEN
    RAISE EXCEPTION 'Total guarantee share_pct for loan % cannot exceed 100%% (current: %, attempted: %)',
      NEW.guaranteed_loan_id, v_total, NEW.share_pct;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS guarantee_share_limit_trigger ON guarantee;
CREATE TRIGGER guarantee_share_limit_trigger
BEFORE INSERT OR UPDATE ON guarantee
FOR EACH ROW
EXECUTE FUNCTION check_guarantee_share_limit();

-- Auto-trigger peer-liability propagation on loan delinquency/default
CREATE OR REPLACE FUNCTION trg_loan_propagate_exposure()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status IN ('DELINQUENT', 'DEFAULTED') THEN
    PERFORM propagate_guarantee_exposure(NEW.loan_id);
  ELSIF OLD.status IN ('DELINQUENT', 'DEFAULTED') AND NEW.status NOT IN ('DELINQUENT', 'DEFAULTED') THEN
    PERFORM propagate_guarantee_exposure(NEW.loan_id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS loan_after_update_exposure ON loan;
CREATE TRIGGER loan_after_update_exposure
AFTER UPDATE ON loan
FOR EACH ROW
EXECUTE FUNCTION trg_loan_propagate_exposure();

CREATE POLICY center_branch_policy ON center
USING (branch_id = current_branch_id() OR current_app_role() = 'ADMIN')
WITH CHECK (branch_id = current_branch_id() OR current_app_role() = 'ADMIN');

CREATE POLICY user_branch_policy ON app_user
USING (branch_id = current_branch_id() OR current_app_role() = 'ADMIN')
WITH CHECK (branch_id = current_branch_id() OR current_app_role() = 'ADMIN');

CREATE POLICY borrower_branch_policy ON borrower
USING (EXISTS (SELECT 1 FROM center c WHERE c.center_id = borrower.center_id))
WITH CHECK (EXISTS (SELECT 1 FROM center c WHERE c.center_id = borrower.center_id));

CREATE POLICY group_branch_policy ON jlg_group
USING (EXISTS (SELECT 1 FROM center c WHERE c.center_id = jlg_group.center_id))
WITH CHECK (EXISTS (SELECT 1 FROM center c WHERE c.center_id = jlg_group.center_id));

CREATE POLICY member_branch_policy ON group_member
USING (
  EXISTS (SELECT 1 FROM borrower b JOIN center c ON c.center_id=b.center_id
          WHERE b.borrower_id=group_member.borrower_id)
)
WITH CHECK (
  EXISTS (SELECT 1 FROM borrower b JOIN center c ON c.center_id=b.center_id
          WHERE b.borrower_id=group_member.borrower_id)
);

CREATE POLICY loan_branch_policy ON loan
USING (EXISTS (SELECT 1 FROM borrower b JOIN center c ON c.center_id=b.center_id
               WHERE b.borrower_id=loan.borrower_id))
WITH CHECK (EXISTS (SELECT 1 FROM borrower b JOIN center c ON c.center_id=b.center_id
                    WHERE b.borrower_id=loan.borrower_id));

CREATE POLICY installment_branch_policy ON installment
USING (EXISTS (SELECT 1 FROM loan l JOIN borrower b ON b.borrower_id=l.borrower_id
               JOIN center c ON c.center_id=b.center_id WHERE l.loan_id=installment.loan_id))
WITH CHECK (EXISTS (SELECT 1 FROM loan l JOIN borrower b ON b.borrower_id=l.borrower_id
                    JOIN center c ON c.center_id=b.center_id WHERE l.loan_id=installment.loan_id));

CREATE POLICY guarantee_branch_policy ON guarantee
USING (EXISTS (SELECT 1 FROM borrower b JOIN center c ON c.center_id=b.center_id
               WHERE b.borrower_id=guarantee.guarantor_id))
WITH CHECK (EXISTS (SELECT 1 FROM borrower b JOIN center c ON c.center_id=b.center_id
                    WHERE b.borrower_id=guarantee.guarantor_id));

CREATE POLICY repayment_branch_policy ON repayment
USING (EXISTS (SELECT 1 FROM loan l JOIN borrower b ON b.borrower_id=l.borrower_id
               JOIN center c ON c.center_id=b.center_id WHERE l.loan_id=repayment.loan_id))
WITH CHECK (EXISTS (SELECT 1 FROM loan l JOIN borrower b ON b.borrower_id=l.borrower_id
                    JOIN center c ON c.center_id=b.center_id WHERE l.loan_id=repayment.loan_id));

CREATE POLICY allocation_branch_policy ON payment_allocation
USING (EXISTS (SELECT 1 FROM repayment r JOIN loan l ON l.loan_id=r.loan_id
               JOIN borrower b ON b.borrower_id=l.borrower_id JOIN center c ON c.center_id=b.center_id
               WHERE r.repayment_id=payment_allocation.repayment_id))
WITH CHECK (EXISTS (SELECT 1 FROM repayment r JOIN loan l ON l.loan_id=r.loan_id
                    JOIN borrower b ON b.borrower_id=l.borrower_id JOIN center c ON c.center_id=b.center_id
                    WHERE r.repayment_id=payment_allocation.repayment_id));

CREATE POLICY ledger_branch_policy ON ledger_entry
USING (branch_id = current_branch_id() OR current_app_role() = 'ADMIN')
WITH CHECK (branch_id = current_branch_id() OR current_app_role() = 'ADMIN');

CREATE POLICY exposure_branch_policy ON guarantee_exposure
USING (EXISTS (SELECT 1 FROM borrower b JOIN center c ON c.center_id=b.center_id
               WHERE b.borrower_id=guarantee_exposure.borrower_id))
WITH CHECK (EXISTS (SELECT 1 FROM borrower b JOIN center c ON c.center_id=b.center_id
                    WHERE b.borrower_id=guarantee_exposure.borrower_id));

CREATE POLICY txn_branch_policy ON payment_transaction
USING (branch_id = current_branch_id() OR current_app_role() = 'ADMIN')
WITH CHECK (branch_id = current_branch_id() OR current_app_role() = 'ADMIN');
