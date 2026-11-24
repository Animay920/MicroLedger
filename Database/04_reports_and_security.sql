-- R5
CREATE OR REPLACE VIEW v_collection_report AS
SELECT r.repayment_id, r.received_at, r.loan_id, l.borrower_id,
       b.full_name AS borrower_name, r.amount, r.channel, r.collected_by
FROM repayment r
JOIN loan l ON l.loan_id=r.loan_id
JOIN borrower b ON b.borrower_id=l.borrower_id;

CREATE OR REPLACE VIEW v_arrears_report AS
SELECT l.loan_id, l.borrower_id, b.full_name,
       l.group_id, l.outstanding_principal,
       l.fees_due, l.overdue_interest_due, l.current_interest_due,
       (l.fees_due+l.overdue_interest_due+l.current_interest_due) AS total_arrears
FROM loan l JOIN borrower b ON b.borrower_id=l.borrower_id
WHERE l.status IN ('ACTIVE','DELINQUENT','DEFAULTED')
  AND (l.fees_due+l.overdue_interest_due+l.current_interest_due)>0;

CREATE OR REPLACE VIEW v_portfolio_at_risk AS
SELECT group_id,
       COUNT(*) FILTER (WHERE status IN ('DELINQUENT','DEFAULTED')) AS at_risk_loans,
       COUNT(*) AS total_open_loans,
       SUM(outstanding_principal) FILTER (WHERE status IN ('DELINQUENT','DEFAULTED')) AS at_risk_amount,
       SUM(outstanding_principal) AS total_outstanding
FROM loan
WHERE status IN ('ACTIVE','DELINQUENT','DEFAULTED')
GROUP BY group_id;

CREATE OR REPLACE VIEW v_group_exposure AS
SELECT gm.group_id, SUM(ge.exposure_amount) AS total_guarantee_exposure
FROM group_member gm
JOIN guarantee_exposure ge ON ge.borrower_id=gm.borrower_id
WHERE gm.left_on IS NULL
GROUP BY gm.group_id;

-- Apply a branch/role context within a transaction from the trusted API.
-- Example: SELECT set_config('app.branch_id','1',true);
-- Example: SELECT set_config('app.role','MANAGER',true);
