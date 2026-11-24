-- R14:
CREATE OR REPLACE FUNCTION check_repayment_allocations()
RETURNS TABLE(repayment_id BIGINT, repayment_amount NUMERIC, allocated_amount NUMERIC)
LANGUAGE sql AS $$
  SELECT r.repayment_id, r.amount, COALESCE(SUM(pa.amount),0)
  FROM repayment r
  LEFT JOIN payment_allocation pa ON pa.repayment_id=r.repayment_id
  GROUP BY r.repayment_id,r.amount
  HAVING r.amount <> COALESCE(SUM(pa.amount),0)
$$;

-- R14: 
CREATE OR REPLACE FUNCTION check_ledger_balance()
RETURNS TABLE(repayment_id BIGINT, total_debit NUMERIC, total_credit NUMERIC)
LANGUAGE sql AS $$
  SELECT repayment_id, SUM(debit), SUM(credit)
  FROM ledger_entry
  WHERE repayment_id IS NOT NULL
  GROUP BY repayment_id
  HAVING SUM(debit) <> SUM(credit)
$$;

-- R10/R14:
-- Verifies cryptographic hash chain linkage and deterministic tamper evidence per branch.
CREATE OR REPLACE FUNCTION verify_ledger_hash_chain()
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
  v_branch RECORD;
  rec RECORD;
  expected_prev TEXT;
  expected_hash TEXT;
BEGIN
  FOR v_branch IN SELECT DISTINCT branch_id FROM ledger_entry LOOP
    expected_prev := NULL;
    FOR rec IN
      SELECT * FROM ledger_entry
      WHERE branch_id = v_branch.branch_id
      ORDER BY entry_id
    LOOP
      IF rec.prev_hash IS DISTINCT FROM expected_prev THEN
        RETURN FALSE;
      END IF;

      expected_hash := encode(
        digest(concat_ws('|', rec.prev_hash, rec.repayment_id, rec.loan_id,
                         rec.account_head, rec.debit, rec.credit, rec.posted_at), 'sha256'),
        'hex'
      );

      IF rec.entry_hash <> expected_hash THEN
        RETURN FALSE;
      END IF;

      expected_prev := rec.entry_hash;
    END LOOP;
  END LOOP;
  RETURN TRUE;
END;
$$;