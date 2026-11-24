-- ============================================================================
-- MicroLedger - 10 JLG Groups & Real-World Historical Transactions Seed
-- File: Database/06_seed_kiva_nrlm.sql
-- ============================================================================
-- Description:
-- Clean purge of existing data and seed of 28 borrowers across 10 JLGs in Kamrup
-- District (Chaygaon, Boko, Rangia branches), 5 village centers, and 193 historical
-- transaction events (disbursements, reducing-balance weekly repayments, missed
-- payments with late fees, arrears catch-up, and peer-guarantor bailouts).
-- ============================================================================

BEGIN;

-- Temporarily bypass RLS checks during administrative seed
SET LOCAL app.role = 'ADMIN';
SET LOCAL app.branch_id = '1';

-- Update check constraints on payment_transaction to accommodate seed transactions
ALTER TABLE payment_transaction DROP CONSTRAINT IF EXISTS payment_transaction_transaction_type_check;
ALTER TABLE payment_transaction ADD CONSTRAINT payment_transaction_transaction_type_check 
  CHECK (transaction_type = ANY (ARRAY['REPAYMENT'::text, 'LOAN_DISBURSEMENT'::text, 'LOAN_CREATION'::text, 'GUARANTOR_REPAYMENT'::text, 'MISSED_INSTALLMENT'::text]));

ALTER TABLE payment_transaction DROP CONSTRAINT IF EXISTS payment_transaction_status_check;
ALTER TABLE payment_transaction ADD CONSTRAINT payment_transaction_status_check 
  CHECK (status = ANY (ARRAY['PENDING'::text, 'SUCCESS'::text, 'FAILED'::text, 'NETWORK_ABORTED'::text, 'OVERDUE'::text]));

-- ----------------------------------------------------------------------------
-- 1. PURGE ALL EXISTING DATA (RESTART IDENTITY)
-- ----------------------------------------------------------------------------
TRUNCATE TABLE
  payment_transaction,
  guarantee_exposure,
  ledger_entry,
  payment_allocation,
  repayment,
  guarantee,
  installment,
  loan,
  group_member,
  jlg_group,
  borrower,
  center,
  app_user,
  branch
RESTART IDENTITY CASCADE;

-- ----------------------------------------------------------------------------
-- 2. BRANCHES (Kamrup District)
-- ----------------------------------------------------------------------------
INSERT INTO branch(branch_id, name, region) OVERRIDING SYSTEM VALUE VALUES (1, 'Kamrup Rural - Chaygaon Branch', 'Chaygaon Block');
INSERT INTO branch(branch_id, name, region) OVERRIDING SYSTEM VALUE VALUES (2, 'Kamrup Rural - Boko Branch', 'Boko Block');
INSERT INTO branch(branch_id, name, region) OVERRIDING SYSTEM VALUE VALUES (3, 'Kamrup Rural - Rangia Branch', 'Rangia Block');

-- ----------------------------------------------------------------------------
-- 3. ADMINISTRATIVE & OPERATIONAL USERS
-- Password for all seeded users: Admin@12345
-- ----------------------------------------------------------------------------
INSERT INTO app_user(branch_id, full_name, email, role, password_hash, active) VALUES
(1, 'MicroLedger System Administrator', 'admin@microledger.com', 'ADMIN', '$2b$10$54PikYqVWK3avI8tph5aWupyUakpKDWP4eQUOg/tDSlsQaSL0/Y2m', TRUE),
(1, 'Kamrup District Area Manager', 'manager@microledger.com', 'MANAGER', '$2b$10$54PikYqVWK3avI8tph5aWupyUakpKDWP4eQUOg/tDSlsQaSL0/Y2m', TRUE),
(1, 'Chaygaon Block Field Officer', 'fo.chaygaon@microledger.com', 'FIELD_OFFICER', '$2b$10$54PikYqVWK3avI8tph5aWupyUakpKDWP4eQUOg/tDSlsQaSL0/Y2m', TRUE),
(2, 'Boko Block Field Officer', 'fo.boko@microledger.com', 'FIELD_OFFICER', '$2b$10$54PikYqVWK3avI8tph5aWupyUakpKDWP4eQUOg/tDSlsQaSL0/Y2m', TRUE),
(3, 'Rangia Block Field Officer', 'fo.rangia@microledger.com', 'FIELD_OFFICER', '$2b$10$54PikYqVWK3avI8tph5aWupyUakpKDWP4eQUOg/tDSlsQaSL0/Y2m', TRUE),
(1, 'Kamrup Head Cashier', 'cashier@microledger.com', 'CASHIER', '$2b$10$54PikYqVWK3avI8tph5aWupyUakpKDWP4eQUOg/tDSlsQaSL0/Y2m', TRUE),
(1, 'Compliance & Internal Auditor', 'auditor@microledger.com', 'AUDITOR', '$2b$10$54PikYqVWK3avI8tph5aWupyUakpKDWP4eQUOg/tDSlsQaSL0/Y2m', TRUE);

-- ----------------------------------------------------------------------------
-- 4. VILLAGE MEETING CENTERS
-- ----------------------------------------------------------------------------
INSERT INTO center(center_id, branch_id, name, meeting_day, frequency) OVERRIDING SYSTEM VALUE VALUES (1, 1, 'Goroimari Char Center', 5, 'WEEKLY');
INSERT INTO center(center_id, branch_id, name, meeting_day, frequency) OVERRIDING SYSTEM VALUE VALUES (2, 1, 'Chaygaon Central GP Center', 1, 'WEEKLY');
INSERT INTO center(center_id, branch_id, name, meeting_day, frequency) OVERRIDING SYSTEM VALUE VALUES (3, 2, 'Hahim Village Center', 4, 'WEEKLY');
INSERT INTO center(center_id, branch_id, name, meeting_day, frequency) OVERRIDING SYSTEM VALUE VALUES (4, 2, 'Boko Gram Panchayat Center', 2, 'WEEKLY');
INSERT INTO center(center_id, branch_id, name, meeting_day, frequency) OVERRIDING SYSTEM VALUE VALUES (5, 3, 'Rangia Town GP Center', 3, 'WEEKLY');

-- ----------------------------------------------------------------------------
-- 5. JOINT LIABILITY GROUPS
-- ----------------------------------------------------------------------------
INSERT INTO jlg_group(group_id, center_id, name, formed_on, status, max_exposure) OVERRIDING SYSTEM VALUE VALUES (1, 1, 'Naba Jyoti Mahila SHG (JLG-2026-01)', '2025-06-12', 'ACTIVE', 250000.00);
INSERT INTO jlg_group(group_id, center_id, name, formed_on, status, max_exposure) OVERRIDING SYSTEM VALUE VALUES (2, 2, 'Arundhati Rural SHG (JLG-2026-02)', '2025-01-28', 'ACTIVE', 300000.00);
INSERT INTO jlg_group(group_id, center_id, name, formed_on, status, max_exposure) OVERRIDING SYSTEM VALUE VALUES (3, 1, 'Lakhimi Pragati SHG (JLG-2026-03)', '2024-11-19', 'ACTIVE', 200000.00);
INSERT INTO jlg_group(group_id, center_id, name, formed_on, status, max_exposure) OVERRIDING SYSTEM VALUE VALUES (4, 3, 'Kopou Phul JLG (JLG-2026-04)', '2025-09-15', 'ACTIVE', 250000.00);
INSERT INTO jlg_group(group_id, center_id, name, formed_on, status, max_exposure) OVERRIDING SYSTEM VALUE VALUES (5, 3, 'Brahmaputra Ekata SHG (JLG-2026-05)', '2025-07-22', 'ACTIVE', 150000.00);
INSERT INTO jlg_group(group_id, center_id, name, formed_on, status, max_exposure) OVERRIDING SYSTEM VALUE VALUES (6, 4, 'Sewali Mahila JLG (JLG-2026-06)', '2025-08-30', 'ACTIVE', 300000.00);
INSERT INTO jlg_group(group_id, center_id, name, formed_on, status, max_exposure) OVERRIDING SYSTEM VALUE VALUES (7, 4, 'Jonaki Unnati SHG (JLG-2026-07)', '2025-09-04', 'ACTIVE', 250000.00);
INSERT INTO jlg_group(group_id, center_id, name, formed_on, status, max_exposure) OVERRIDING SYSTEM VALUE VALUES (8, 5, 'Bordoisila Shakti JLG (JLG-2026-08)', '2025-01-14', 'ACTIVE', 200000.00);
INSERT INTO jlg_group(group_id, center_id, name, formed_on, status, max_exposure) OVERRIDING SYSTEM VALUE VALUES (9, 1, 'Parijat Srishti SHG (JLG-2026-09)', '2025-08-18', 'ACTIVE', 350000.00);
INSERT INTO jlg_group(group_id, center_id, name, formed_on, status, max_exposure) OVERRIDING SYSTEM VALUE VALUES (10, 5, 'Rupali Maitree JLG (JLG-2026-10)', '2025-01-25', 'ACTIVE', 200000.00);

-- ----------------------------------------------------------------------------
-- 6. BORROWERS (28 Members with Household Income & NID Hashes)
-- ----------------------------------------------------------------------------
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (1, 1, 'Junali Deka', 'feaf16d5df90d7c65568e20edeb42c8fda60c986f2c13054c888e09fb49f38d2', '9864055094', 25600.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (2, 1, 'Kalyani Bora', 'ddf19391e1822ecf0f1a4f78ffb02286ba6f494a40f3d58e75c6a815563ddc6c', '9864080906', 36300.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (3, 1, 'Sabita Saikia', 'fd23c0d3c94288603d8e9b83c13cf04b5198bb00e46435e21c68fd12ab5cdb35', '9435014768', 29700.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (4, 2, 'Nizara Das', '81a55e20fd62a7259e58d9d06127ee0c89475254bbd164900b32dbd47cf879b4', '8638038083', 24700.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (5, 2, 'Nizara Rabha', 'f27a74e26caf87dd648031b1f22cb63d700513c3ada3b22b38d7f5311e897ac1', '7002037994', 21000.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (6, 2, 'Ranjita Choudhury', '33c2f7bea8ce981b9e36eb4a8fb3e5842f4475e0bd9244afd7f6e5b0a6d811d1', '8638055891', 38600.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (7, 2, 'Purnima Nath', '94d0b622a5bc38b9d21090ed98c3d798219930126ad08b19a0dd731df8a984af', '7002064589', 41200.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (8, 1, 'Bornali Talukdar', '433cef12a8ef36ec992cc57371d1f7be0d471e4893d9d212b05d1d982b9e5f36', '7002086545', 36200.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (9, 1, 'Mamoni Talukdar', '40a26f79dc4cea6fba47f62122754c0e3149e84c667a1e3c2a9bb308b5fbafd8', '8638082929', 32300.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (10, 3, 'Sabita Boro', '602c8fb38db55c351921a1394ef42ecc16271400c751da91656610a9de0f911d', '8638078196', 36000.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (11, 3, 'Barnali Deka', '5fbabba00fc92296c20d9af9109c97ca2f2826817cd259f7765944ce443d8ce6', '8638058808', 22900.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (12, 3, 'Rumi Saikia', 'ea8f86c474e7fb5e44fa9aeef617a6219de9cdb6f6de9400181e2dce35465067', '7002013846', 46200.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (13, 3, 'Ranjita Gogoi', '1cb8d999596549e87927416326554ff6f8b4ced4c8e88ab871072cfc1a37b353', '9435089436', 31500.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (14, 4, 'Bornali Deka', '5b0d56ff798fa6ff32753b9fd23222ed9cf45ca42cc748553730bb35bcd59e8f', '9435075706', 25300.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (15, 4, 'Rumi Choudhury', 'a87282306ba0202884ddd8464486f7762d6b9c1522d06f1defd41e47d7732c84', '8638062655', 39000.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (16, 4, 'Sunita Sarma', 'fd82b8cb0e5c28f38d5cd61feb222c280141fa30c45cb57fda343b3ae07dbfe1', '9435060202', 35700.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (17, 4, 'Bina Sarma', '230f8ec87d2ed250bddb39171808d955d2ebdbb5df3e4fe07024e8b06aac0588', '8638094844', 37600.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (18, 4, 'Runjun Deka', '900653334909c67a9ebf8760eb87f5871520a6d672f3394cd6e5632fff33a586', '8638039577', 19200.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (19, 4, 'Sunita Bora', 'acc08f20f9c5abe4498dd24989379defaea9026f799abae9e3e1e2b05223924a', '8638018337', 51800.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (20, 4, 'Papori Medhi', 'e391724a5b8934c741da68cc658fba3d646e847ad5f71b6fa6d48c7974b5f302', '9864081841', 41100.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (21, 5, 'Papori Gogoi', '7f3742886cb49d57717c3862aadd88af57cadfd36f32879a64cfc477f7b7a60f', '9864094642', 32000.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (22, 5, 'Monika Talukdar', '1e19d27f50a20bfa1bcb6b4d90cf80dc94b9fe2bc3db34337c28805b7f0910d1', '9864095579', 28400.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (23, 1, 'Mousumi Gogoi', 'fa737740b4941a2b4f47a742086baac3398eeef1a61b5cc46988b2a0560350f9', '7002097831', 56400.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (24, 1, 'Sunita Gogoi', '0ea4dda5911baf1d3fc32e9deb6fff7b2d6957d9a8530de30e4343dd87d25899', '9864097701', 29900.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (25, 1, 'Ranjita Sarma', '2adedc80d18c57a192027a7fddf588e2502bfc53638104aac6c7b40ce7d26fcc', '8638058604', 27500.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (26, 1, 'Bina Choudhury', 'd991ca2454401c18b9584b1d8251ab7ce29b01ee293c31121536e9c585a94854', '9864033753', 48000.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (27, 5, 'Bornali Barman', 'a831d080b3832d4d387a7464f695653b7ee2ec42ff6ba1eb156c68e6d6b3b9e5', '8638026173', 25300.00, 'ACTIVE');
INSERT INTO borrower(borrower_id, center_id, full_name, national_id_hash, phone, monthly_household_income, status) OVERRIDING SYSTEM VALUE VALUES (28, 5, 'Papori Saikia', '615d08da34775ab6ed6214ac8d2cb2b00c1cd1e0fd300db19a6dc8cfdd7ff3b2', '9864015458', 40100.00, 'ACTIVE');

-- ----------------------------------------------------------------------------
-- 7. GROUP MEMBERSHIP JUNCTION
-- ----------------------------------------------------------------------------
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (1, 1, '2025-06-12', 'PRESIDENT');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (1, 2, '2025-06-15', 'SECRETARY');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (1, 3, '2025-06-23', 'MEMBER');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (2, 4, '2025-01-28', 'PRESIDENT');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (2, 5, '2025-02-02', 'SECRETARY');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (2, 6, '2025-02-03', 'MEMBER');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (2, 7, '2025-02-05', 'MEMBER');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (3, 8, '2024-11-19', 'PRESIDENT');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (3, 9, '2024-11-21', 'SECRETARY');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (4, 10, '2025-09-15', 'PRESIDENT');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (4, 11, '2025-09-19', 'SECRETARY');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (4, 12, '2025-09-25', 'MEMBER');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (5, 13, '2025-07-22', 'PRESIDENT');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (6, 14, '2025-08-30', 'PRESIDENT');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (6, 15, '2025-09-01', 'SECRETARY');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (6, 16, '2025-09-05', 'MEMBER');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (6, 17, '2025-09-06', 'MEMBER');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (7, 18, '2025-09-04', 'PRESIDENT');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (7, 19, '2025-09-06', 'SECRETARY');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (7, 20, '2025-09-20', 'MEMBER');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (8, 21, '2025-01-14', 'PRESIDENT');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (8, 22, '2025-01-18', 'SECRETARY');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (9, 23, '2025-08-18', 'PRESIDENT');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (9, 24, '2025-08-22', 'SECRETARY');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (9, 25, '2025-08-30', 'MEMBER');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (9, 26, '2025-09-01', 'MEMBER');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (10, 27, '2025-01-25', 'PRESIDENT');
INSERT INTO group_member(group_id, borrower_id, joined_on, member_role) VALUES (10, 28, '2025-01-28', 'SECRETARY');

-- ----------------------------------------------------------------------------
-- 8. LOANS (28 Originated Loans with Reducing Balance Schedules)
-- ----------------------------------------------------------------------------
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (1, 1, 1, 1, 24500.00, 19.5000, 36, '2026-09-28', 24500.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (2, 2, 1, 1, 20500.00, 19.5000, 48, '2026-03-13', 20500.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (3, 3, 1, 1, 19000.00, 14.5000, 36, '2026-08-11', 19000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (4, 4, 2, 1, 45000.00, 19.5000, 25, '2026-04-09', 45000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (5, 5, 2, 1, 50000.00, 12.0000, 48, '2026-05-19', 50000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (6, 6, 2, 1, 30000.00, 18.5000, 52, '2025-12-27', 30000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (7, 7, 2, 1, 50000.00, 19.5000, 24, '2026-01-01', 50000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (8, 8, 3, 1, 22500.00, 19.5000, 24, '2026-10-14', 22500.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (9, 9, 3, 1, 22500.00, 12.0000, 25, '2026-02-26', 22500.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (10, 10, 4, 1, 22500.00, 22.0000, 52, '2026-04-28', 22500.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (11, 11, 4, 1, 12000.00, 19.5000, 36, '2026-09-25', 12000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (12, 12, 4, 1, 22500.00, 18.5000, 36, '2026-06-04', 22500.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (13, 13, 5, 1, 17000.00, 12.0000, 24, '2026-07-27', 17000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (14, 14, 6, 1, 15000.00, 20.5000, 36, '2026-03-21', 15000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (15, 15, 6, 1, 50000.00, 22.0000, 52, '2026-01-31', 50000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (16, 16, 6, 1, 12000.00, 20.5000, 24, '2026-07-31', 12000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (17, 17, 6, 1, 34000.00, 18.5000, 25, '2026-05-14', 34000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (18, 18, 7, 1, 15000.00, 20.5000, 48, '2026-10-17', 15000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (19, 19, 7, 1, 12000.00, 18.5000, 36, '2026-09-15', 12000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (20, 20, 7, 1, 13000.00, 19.5000, 24, '2026-07-09', 13000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (21, 21, 8, 1, 24500.00, 18.5000, 36, '2026-07-01', 24500.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (22, 22, 8, 1, 35500.00, 13.5000, 25, '2026-06-11', 35500.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (23, 23, 9, 1, 35500.00, 13.5000, 24, '2026-03-13', 35500.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (24, 24, 9, 1, 19000.00, 19.5000, 36, '2026-11-08', 19000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (25, 25, 9, 1, 28000.00, 22.0000, 52, '2026-10-03', 28000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (26, 26, 9, 1, 24500.00, 20.5000, 24, '2026-04-27', 24500.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (27, 27, 10, 1, 50000.00, 19.5000, 48, '2026-07-05', 50000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);
INSERT INTO loan(loan_id, borrower_id, group_id, cycle_no, principal, annual_rate, tenure_weeks, disbursed_on, outstanding_principal, fees_due, overdue_interest_due, current_interest_due, status, version) OVERRIDING SYSTEM VALUE VALUES (28, 28, 10, 1, 30000.00, 18.5000, 25, '2026-09-16', 30000.00, 0.00, 0.00, 0.00, 'ACTIVE', 0);

-- ----------------------------------------------------------------------------
-- 9. REPAYMENT SCHEDULE GENERATION
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT loan_id FROM loan ORDER BY loan_id LOOP
    PERFORM generate_repayment_schedule(r.loan_id);
  END LOOP;
END;
$$;

-- ----------------------------------------------------------------------------
-- 10. JLG PEER CROSS-GUARANTEES
-- ----------------------------------------------------------------------------
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (2, 1, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (3, 1, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (1, 2, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (3, 2, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (1, 3, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (2, 3, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (5, 4, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (6, 4, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (7, 4, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (4, 5, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (6, 5, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (7, 5, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (4, 6, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (5, 6, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (7, 6, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (4, 7, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (5, 7, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (6, 7, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (9, 8, 100.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (8, 9, 100.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (11, 10, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (12, 10, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (10, 11, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (12, 11, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (10, 12, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (11, 12, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (15, 14, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (16, 14, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (17, 14, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (14, 15, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (16, 15, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (17, 15, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (14, 16, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (15, 16, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (17, 16, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (14, 17, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (15, 17, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (16, 17, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (19, 18, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (20, 18, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (18, 19, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (20, 19, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (18, 20, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (19, 20, 50.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (22, 21, 100.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (21, 22, 100.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (24, 23, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (25, 23, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (26, 23, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (23, 24, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (25, 24, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (26, 24, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (23, 25, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (24, 25, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (26, 25, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (23, 26, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (24, 26, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (25, 26, 33.33, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (28, 27, 100.00, TRUE);
INSERT INTO guarantee(guarantor_id, guaranteed_loan_id, share_pct, active) VALUES (27, 28, 100.00, TRUE);

-- ----------------------------------------------------------------------------
-- 11. PROCESS 193 HISTORICAL TRANSACTIONS & CRYPTOGRAPHIC LEDGER CHAIN
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  v_repayment_id BIGINT;
  v_user_id BIGINT;
  v_branch_id BIGINT;
  v_prev_hash TEXT;
  v_hash TEXT;
  v_ts TIMESTAMPTZ;
  v_fees_alloc NUMERIC(14,2);
  v_interest_alloc NUMERIC(14,2);
  v_principal_alloc NUMERIC(14,2);
  v_rem_amt NUMERIC(14,2);
BEGIN
  SELECT user_id INTO v_user_id FROM app_user WHERE role = 'FIELD_OFFICER' AND branch_id = 1 LIMIT 1;

  -- Transaction TX-0001 (DISBURSEMENT - Loan #1 Junali Deka - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0001', 'LOAN_DISBURSEMENT', 1, 1, 1, 24500.00, 'BANK_TRANSFER', 'GW-TX-0001', 'SUCCESS', '2026-09-28 18:29:04+05:30', '2026-09-28 18:29:04+05:30');

  -- Transaction TX-0002 (REPAYMENT - Loan #1 Junali Deka - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (1, v_user_id, 728.80, '2026-10-06 03:29:04+05:30', '15acea59-f665-4d84-bfd3-92d0a064a8e9', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 1 AND seq_no = 1;
  v_rem_amt := 728.80;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 1) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 1));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 1;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 1) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 1));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 1;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 1 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-06 03:29:04+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 1, 'CASH', 728.80, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 1, 'CASH', 728.80, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 1, 'LOAN_PORTFOLIO', 0.00, 728.80, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 1, 'LOAN_PORTFOLIO', 0.00, 728.80, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0002', 'REPAYMENT', 1, 1, 1, 728.80, 'CASH', 'GW-TX-0002', 'SUCCESS', v_repayment_id, '2026-10-06 03:29:04+05:30', '2026-10-06 03:29:04+05:30');

  -- Transaction TX-0003 (REPAYMENT - Loan #1 Junali Deka - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (1, v_user_id, 728.80, '2026-10-13 10:29:04+05:30', '64556cca-06da-4937-8c21-2b5a969ef622', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 1 AND seq_no = 2;
  v_rem_amt := 728.80;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 1) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 1));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 1;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 1) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 1));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 1;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 1 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-13 10:29:04+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 1, 'CASH', 728.80, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 1, 'CASH', 728.80, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 1, 'LOAN_PORTFOLIO', 0.00, 728.80, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 1, 'LOAN_PORTFOLIO', 0.00, 728.80, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0003', 'REPAYMENT', 1, 1, 1, 728.80, 'CASH', 'GW-TX-0003', 'SUCCESS', v_repayment_id, '2026-10-13 10:29:04+05:30', '2026-10-13 10:29:04+05:30');

  -- Transaction TX-0004 (REPAYMENT - Loan #1 Junali Deka - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (1, v_user_id, 728.80, '2026-10-20 09:29:04+05:30', '23b7993e-3370-4059-a742-18408f757ac7', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 1 AND seq_no = 3;
  v_rem_amt := 728.80;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 1) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 1));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 1;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 1) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 1));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 1;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 1 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-20 09:29:04+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 1, 'CASH', 728.80, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 1, 'CASH', 728.80, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 1, 'LOAN_PORTFOLIO', 0.00, 728.80, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 1, 'LOAN_PORTFOLIO', 0.00, 728.80, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0004', 'REPAYMENT', 1, 1, 1, 728.80, 'CASH', 'GW-TX-0004', 'SUCCESS', v_repayment_id, '2026-10-20 09:29:04+05:30', '2026-10-20 09:29:04+05:30');

  -- Transaction TX-0005 (REPAYMENT - Loan #1 Junali Deka - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (1, v_user_id, 728.80, '2026-10-27 08:29:04+05:30', '8227f794-ad27-4163-bfc7-368998f4acef', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 1 AND seq_no = 4;
  v_rem_amt := 728.80;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 1) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 1));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 1;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 1) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 1));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 1;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 1 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-27 08:29:04+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 1, 'CASH', 728.80, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 1, 'CASH', 728.80, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 1, 'LOAN_PORTFOLIO', 0.00, 728.80, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 1, 'LOAN_PORTFOLIO', 0.00, 728.80, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0005', 'REPAYMENT', 1, 1, 1, 728.80, 'CASH', 'GW-TX-0005', 'SUCCESS', v_repayment_id, '2026-10-27 08:29:04+05:30', '2026-10-27 08:29:04+05:30');

  -- Transaction TX-0006 (REPAYMENT - Loan #1 Junali Deka - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (1, v_user_id, 728.80, '2026-11-03 10:29:04+05:30', '173c388f-898b-492a-b5fb-994dab4be71d', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 1 AND seq_no = 5;
  v_rem_amt := 728.80;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 1) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 1));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 1;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 1) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 1));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 1;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 1 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-11-03 10:29:04+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 1, 'CASH', 728.80, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 1, 'CASH', 728.80, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 1, 'LOAN_PORTFOLIO', 0.00, 728.80, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 1, 'LOAN_PORTFOLIO', 0.00, 728.80, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0006', 'REPAYMENT', 1, 1, 1, 728.80, 'CASH', 'GW-TX-0006', 'SUCCESS', v_repayment_id, '2026-11-03 10:29:04+05:30', '2026-11-03 10:29:04+05:30');

  -- Transaction TX-0007 (REPAYMENT - Loan #1 Junali Deka - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (1, v_user_id, 728.80, '2026-11-10 08:29:04+05:30', '728070a3-7ef0-4c46-8583-402cec34af5f', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 1 AND seq_no = 6;
  v_rem_amt := 728.80;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 1) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 1));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 1;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 1) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 1));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 1;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 1 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-11-10 08:29:04+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 1, 'CASH', 728.80, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 1, 'CASH', 728.80, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 1, 'LOAN_PORTFOLIO', 0.00, 728.80, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 1, 'LOAN_PORTFOLIO', 0.00, 728.80, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0007', 'REPAYMENT', 1, 1, 1, 728.80, 'CASH', 'GW-TX-0007', 'SUCCESS', v_repayment_id, '2026-11-10 08:29:04+05:30', '2026-11-10 08:29:04+05:30');

  -- Transaction TX-0008 (DISBURSEMENT - Loan #2 Kalyani Bora - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0008', 'LOAN_DISBURSEMENT', 2, 2, 1, 20500.00, 'BANK_TRANSFER', 'GW-TX-0008', 'SUCCESS', '2026-03-13 20:01:01+05:30', '2026-03-13 20:01:01+05:30');

  -- Transaction TX-0009 (REPAYMENT - Loan #2 Kalyani Bora - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (2, v_user_id, 467.47, '2026-03-21 10:01:01+05:30', '5c7ca4e8-8806-4d89-ac18-ab9ecf6edf2e', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 2 AND seq_no = 1;
  v_rem_amt := 467.47;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 2) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 2));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 2;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 2) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 2));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 2;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 2 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-03-21 10:01:01+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 2, 'CASH', 467.47, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 2, 'CASH', 467.47, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 2, 'LOAN_PORTFOLIO', 0.00, 467.47, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 2, 'LOAN_PORTFOLIO', 0.00, 467.47, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0009', 'REPAYMENT', 2, 2, 1, 467.47, 'CASH', 'GW-TX-0009', 'SUCCESS', v_repayment_id, '2026-03-21 10:01:01+05:30', '2026-03-21 10:01:01+05:30');

  -- Transaction TX-0010 (REPAYMENT - Loan #2 Kalyani Bora - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (2, v_user_id, 467.47, '2026-03-28 05:01:01+05:30', 'b3a3b36a-e05f-45d1-9ece-a6aa539e8081', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 2 AND seq_no = 2;
  v_rem_amt := 467.47;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 2) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 2));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 2;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 2) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 2));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 2;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 2 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-03-28 05:01:01+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 2, 'CASH', 467.47, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 2, 'CASH', 467.47, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 2, 'LOAN_PORTFOLIO', 0.00, 467.47, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 2, 'LOAN_PORTFOLIO', 0.00, 467.47, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0010', 'REPAYMENT', 2, 2, 1, 467.47, 'CASH', 'GW-TX-0010', 'SUCCESS', v_repayment_id, '2026-03-28 05:01:01+05:30', '2026-03-28 05:01:01+05:30');

  -- Transaction TX-0011 (REPAYMENT - Loan #2 Kalyani Bora - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (2, v_user_id, 467.47, '2026-04-04 12:01:01+05:30', '78e78a3d-0a53-42ca-a8c0-46423d4efa8e', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 2 AND seq_no = 3;
  v_rem_amt := 467.47;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 2) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 2));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 2;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 2) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 2));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 2;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 2 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-04-04 12:01:01+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 2, 'CASH', 467.47, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 2, 'CASH', 467.47, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 2, 'LOAN_PORTFOLIO', 0.00, 467.47, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 2, 'LOAN_PORTFOLIO', 0.00, 467.47, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0011', 'REPAYMENT', 2, 2, 1, 467.47, 'ONLINE_UPI', 'GW-TX-0011', 'SUCCESS', v_repayment_id, '2026-04-04 12:01:01+05:30', '2026-04-04 12:01:01+05:30');

  -- Transaction TX-0012 (REPAYMENT - Loan #2 Kalyani Bora - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (2, v_user_id, 467.47, '2026-04-11 08:01:01+05:30', '0e2ec619-7277-49cc-a354-3d83f973e474', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 2 AND seq_no = 4;
  v_rem_amt := 467.47;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 2) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 2));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 2;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 2) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 2));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 2;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 2 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-04-11 08:01:01+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 2, 'CASH', 467.47, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 2, 'CASH', 467.47, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 2, 'LOAN_PORTFOLIO', 0.00, 467.47, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 2, 'LOAN_PORTFOLIO', 0.00, 467.47, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0012', 'REPAYMENT', 2, 2, 1, 467.47, 'CASH', 'GW-TX-0012', 'SUCCESS', v_repayment_id, '2026-04-11 08:01:01+05:30', '2026-04-11 08:01:01+05:30');

  -- Transaction TX-0013 (REPAYMENT - Loan #2 Kalyani Bora - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (2, v_user_id, 467.47, '2026-04-18 07:01:01+05:30', 'df412e43-d197-42f4-a5c2-39967072f570', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 2 AND seq_no = 5;
  v_rem_amt := 467.47;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 2) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 2));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 2;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 2) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 2));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 2;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 2 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-04-18 07:01:01+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 2, 'CASH', 467.47, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 2, 'CASH', 467.47, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 2, 'LOAN_PORTFOLIO', 0.00, 467.47, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 2, 'LOAN_PORTFOLIO', 0.00, 467.47, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0013', 'REPAYMENT', 2, 2, 1, 467.47, 'CASH', 'GW-TX-0013', 'SUCCESS', v_repayment_id, '2026-04-18 07:01:01+05:30', '2026-04-18 07:01:01+05:30');

  -- Transaction TX-0014 (REPAYMENT - Loan #2 Kalyani Bora - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (2, v_user_id, 467.47, '2026-04-25 07:01:01+05:30', '524129e6-e051-4c8c-991d-5003b263b6c2', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 2 AND seq_no = 6;
  v_rem_amt := 467.47;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 2) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 2));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 2;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 2) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 2));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 2;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 2 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-04-25 07:01:01+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 2, 'CASH', 467.47, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 2, 'CASH', 467.47, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 2, 'LOAN_PORTFOLIO', 0.00, 467.47, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 2, 'LOAN_PORTFOLIO', 0.00, 467.47, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0014', 'REPAYMENT', 2, 2, 1, 467.47, 'CASH', 'GW-TX-0014', 'SUCCESS', v_repayment_id, '2026-04-25 07:01:01+05:30', '2026-04-25 07:01:01+05:30');

  -- Transaction TX-0015 (DISBURSEMENT - Loan #3 Sabita Saikia - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0015', 'LOAN_DISBURSEMENT', 3, 3, 1, 19000.00, 'BANK_TRANSFER', 'GW-TX-0015', 'SUCCESS', '2026-08-11 03:25:32+05:30', '2026-08-11 03:25:32+05:30');

  -- Transaction TX-0016 (REPAYMENT - Loan #3 Sabita Saikia - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (3, v_user_id, 555.45, '2026-08-18 12:25:32+05:30', '58e22f09-5f16-4143-9bf3-3339ae60341a', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 3 AND seq_no = 1;
  v_rem_amt := 555.45;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 3) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 3));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 3;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 3) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 3));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 3;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 3 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-18 12:25:32+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 3, 'CASH', 555.45, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 3, 'CASH', 555.45, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 3, 'LOAN_PORTFOLIO', 0.00, 555.45, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 3, 'LOAN_PORTFOLIO', 0.00, 555.45, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0016', 'REPAYMENT', 3, 3, 1, 555.45, 'CASH', 'GW-TX-0016', 'SUCCESS', v_repayment_id, '2026-08-18 12:25:32+05:30', '2026-08-18 12:25:32+05:30');

  -- Transaction TX-0017 (REPAYMENT - Loan #3 Sabita Saikia - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (3, v_user_id, 555.45, '2026-08-25 17:25:32+05:30', 'a66848d9-3ce3-4e91-8edc-094987afa87a', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 3 AND seq_no = 2;
  v_rem_amt := 555.45;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 3) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 3));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 3;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 3) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 3));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 3;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 3 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-25 17:25:32+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 3, 'CASH', 555.45, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 3, 'CASH', 555.45, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 3, 'LOAN_PORTFOLIO', 0.00, 555.45, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 3, 'LOAN_PORTFOLIO', 0.00, 555.45, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0017', 'REPAYMENT', 3, 3, 1, 555.45, 'CASH', 'GW-TX-0017', 'SUCCESS', v_repayment_id, '2026-08-25 17:25:32+05:30', '2026-08-25 17:25:32+05:30');

  -- Transaction TX-0018 (REPAYMENT - Loan #3 Sabita Saikia - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (3, v_user_id, 555.45, '2026-09-01 18:25:32+05:30', '04f4f29d-cf20-4b44-9bd3-132c056715f2', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 3 AND seq_no = 3;
  v_rem_amt := 555.45;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 3) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 3));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 3;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 3) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 3));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 3;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 3 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-09-01 18:25:32+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 3, 'CASH', 555.45, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 3, 'CASH', 555.45, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 3, 'LOAN_PORTFOLIO', 0.00, 555.45, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 3, 'LOAN_PORTFOLIO', 0.00, 555.45, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0018', 'REPAYMENT', 3, 3, 1, 555.45, 'CASH', 'GW-TX-0018', 'SUCCESS', v_repayment_id, '2026-09-01 18:25:32+05:30', '2026-09-01 18:25:32+05:30');

  -- Transaction TX-0019 (REPAYMENT - Loan #3 Sabita Saikia - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (3, v_user_id, 555.45, '2026-09-08 19:25:32+05:30', 'd18abfea-ad18-4343-a31f-90ad2c250bc9', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 3 AND seq_no = 4;
  v_rem_amt := 555.45;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 3) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 3));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 3;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 3) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 3));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 3;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 3 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-09-08 19:25:32+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 3, 'CASH', 555.45, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 3, 'CASH', 555.45, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 3, 'LOAN_PORTFOLIO', 0.00, 555.45, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 3, 'LOAN_PORTFOLIO', 0.00, 555.45, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0019', 'REPAYMENT', 3, 3, 1, 555.45, 'ONLINE_UPI', 'GW-TX-0019', 'SUCCESS', v_repayment_id, '2026-09-08 19:25:32+05:30', '2026-09-08 19:25:32+05:30');

  -- Transaction TX-0020 (REPAYMENT - Loan #3 Sabita Saikia - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (3, v_user_id, 555.45, '2026-09-15 17:25:32+05:30', '9e9b5670-f340-4650-83c4-73191570abc5', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 3 AND seq_no = 5;
  v_rem_amt := 555.45;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 3) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 3));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 3;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 3) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 3));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 3;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 3 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-09-15 17:25:32+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 3, 'CASH', 555.45, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 3, 'CASH', 555.45, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 3, 'LOAN_PORTFOLIO', 0.00, 555.45, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 3, 'LOAN_PORTFOLIO', 0.00, 555.45, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0020', 'REPAYMENT', 3, 3, 1, 555.45, 'ONLINE_UPI', 'GW-TX-0020', 'SUCCESS', v_repayment_id, '2026-09-15 17:25:32+05:30', '2026-09-15 17:25:32+05:30');

  -- Transaction TX-0021 (REPAYMENT - Loan #3 Sabita Saikia - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (3, v_user_id, 555.45, '2026-09-22 19:25:32+05:30', 'c93283d1-7ae0-41ce-9287-6e2abca4c1cc', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 3 AND seq_no = 6;
  v_rem_amt := 555.45;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 3) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 3));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 3;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 3) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 3));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 3;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 3 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-09-22 19:25:32+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 3, 'CASH', 555.45, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 3, 'CASH', 555.45, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 3, 'LOAN_PORTFOLIO', 0.00, 555.45, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 3, 'LOAN_PORTFOLIO', 0.00, 555.45, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0021', 'REPAYMENT', 3, 3, 1, 555.45, 'CASH', 'GW-TX-0021', 'SUCCESS', v_repayment_id, '2026-09-22 19:25:32+05:30', '2026-09-22 19:25:32+05:30');

  -- Transaction TX-0022 (DISBURSEMENT - Loan #4 Nizara Das - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0022', 'LOAN_DISBURSEMENT', 4, 4, 1, 45000.00, 'BANK_TRANSFER', 'GW-TX-0022', 'SUCCESS', '2026-04-09 00:44:48+05:30', '2026-04-09 00:44:48+05:30');

  -- Transaction TX-0023 (REPAYMENT - Loan #4 Nizara Das - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (4, v_user_id, 1889.06, '2026-04-16 16:44:48+05:30', 'cd97523b-ec6d-4a99-86ce-fee57a0d3173', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 4 AND seq_no = 1;
  v_rem_amt := 1889.06;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 4) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 4));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 4;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 4) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 4));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 4;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 4 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-04-16 16:44:48+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 4, 'CASH', 1889.06, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 4, 'CASH', 1889.06, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 4, 'LOAN_PORTFOLIO', 0.00, 1889.06, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 4, 'LOAN_PORTFOLIO', 0.00, 1889.06, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0023', 'REPAYMENT', 4, 4, 1, 1889.06, 'CASH', 'GW-TX-0023', 'SUCCESS', v_repayment_id, '2026-04-16 16:44:48+05:30', '2026-04-16 16:44:48+05:30');

  -- Transaction TX-0024 (REPAYMENT - Loan #4 Nizara Das - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (4, v_user_id, 1889.06, '2026-04-23 15:44:48+05:30', '063b426b-830c-4162-8db0-1eb109472b62', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 4 AND seq_no = 2;
  v_rem_amt := 1889.06;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 4) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 4));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 4;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 4) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 4));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 4;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 4 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-04-23 15:44:48+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 4, 'CASH', 1889.06, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 4, 'CASH', 1889.06, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 4, 'LOAN_PORTFOLIO', 0.00, 1889.06, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 4, 'LOAN_PORTFOLIO', 0.00, 1889.06, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0024', 'REPAYMENT', 4, 4, 1, 1889.06, 'CASH', 'GW-TX-0024', 'SUCCESS', v_repayment_id, '2026-04-23 15:44:48+05:30', '2026-04-23 15:44:48+05:30');

  -- Transaction TX-0025 (REPAYMENT - Loan #4 Nizara Das - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (4, v_user_id, 1889.06, '2026-04-30 16:44:48+05:30', '0dd4ce71-7d84-42c4-8a30-d42442cc66f0', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 4 AND seq_no = 3;
  v_rem_amt := 1889.06;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 4) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 4));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 4;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 4) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 4));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 4;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 4 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-04-30 16:44:48+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 4, 'CASH', 1889.06, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 4, 'CASH', 1889.06, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 4, 'LOAN_PORTFOLIO', 0.00, 1889.06, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 4, 'LOAN_PORTFOLIO', 0.00, 1889.06, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0025', 'REPAYMENT', 4, 4, 1, 1889.06, 'CASH', 'GW-TX-0025', 'SUCCESS', v_repayment_id, '2026-04-30 16:44:48+05:30', '2026-04-30 16:44:48+05:30');

  -- Transaction TX-0026 (REPAYMENT - Loan #4 Nizara Das - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (4, v_user_id, 1889.06, '2026-05-07 10:44:48+05:30', '4f415f58-86f1-48c8-85a7-94f730e2e447', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 4 AND seq_no = 4;
  v_rem_amt := 1889.06;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 4) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 4));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 4;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 4) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 4));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 4;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 4 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-05-07 10:44:48+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 4, 'CASH', 1889.06, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 4, 'CASH', 1889.06, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 4, 'LOAN_PORTFOLIO', 0.00, 1889.06, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 4, 'LOAN_PORTFOLIO', 0.00, 1889.06, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0026', 'REPAYMENT', 4, 4, 1, 1889.06, 'ONLINE_UPI', 'GW-TX-0026', 'SUCCESS', v_repayment_id, '2026-05-07 10:44:48+05:30', '2026-05-07 10:44:48+05:30');

  -- Transaction TX-0027 (REPAYMENT - Loan #4 Nizara Das - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (4, v_user_id, 1889.06, '2026-05-14 12:44:48+05:30', '78d033d2-282d-4a64-8704-56f861ec09f6', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 4 AND seq_no = 5;
  v_rem_amt := 1889.06;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 4) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 4));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 4;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 4) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 4));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 4;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 4 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-05-14 12:44:48+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 4, 'CASH', 1889.06, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 4, 'CASH', 1889.06, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 4, 'LOAN_PORTFOLIO', 0.00, 1889.06, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 4, 'LOAN_PORTFOLIO', 0.00, 1889.06, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0027', 'REPAYMENT', 4, 4, 1, 1889.06, 'CASH', 'GW-TX-0027', 'SUCCESS', v_repayment_id, '2026-05-14 12:44:48+05:30', '2026-05-14 12:44:48+05:30');

  -- Transaction TX-0028 (REPAYMENT - Loan #4 Nizara Das - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (4, v_user_id, 1889.06, '2026-05-21 15:44:48+05:30', 'c4431d74-4a51-465a-8c3e-f43e06e00c55', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 4 AND seq_no = 6;
  v_rem_amt := 1889.06;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 4) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 4));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 4;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 4) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 4));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 4;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 4 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-05-21 15:44:48+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 4, 'CASH', 1889.06, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 4, 'CASH', 1889.06, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 4, 'LOAN_PORTFOLIO', 0.00, 1889.06, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 4, 'LOAN_PORTFOLIO', 0.00, 1889.06, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0028', 'REPAYMENT', 4, 4, 1, 1889.06, 'ONLINE_UPI', 'GW-TX-0028', 'SUCCESS', v_repayment_id, '2026-05-21 15:44:48+05:30', '2026-05-21 15:44:48+05:30');

  -- Transaction TX-0029 (DISBURSEMENT - Loan #5 Nizara Rabha - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0029', 'LOAN_DISBURSEMENT', 5, 5, 1, 50000.00, 'BANK_TRANSFER', 'GW-TX-0029', 'SUCCESS', '2026-05-19 18:59:37+05:30', '2026-05-19 18:59:37+05:30');

  -- Transaction TX-0030 (REPAYMENT - Loan #5 Nizara Rabha - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (5, v_user_id, 1101.62, '2026-05-27 04:59:37+05:30', 'd3fe0782-d5fe-4aa7-b25d-7df4b9bdb247', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 5 AND seq_no = 1;
  v_rem_amt := 1101.62;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 5) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 5));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 5;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 5) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 5));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 5;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 5 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-05-27 04:59:37+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 5, 'CASH', 1101.62, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 5, 'CASH', 1101.62, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 5, 'LOAN_PORTFOLIO', 0.00, 1101.62, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 5, 'LOAN_PORTFOLIO', 0.00, 1101.62, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0030', 'REPAYMENT', 5, 5, 1, 1101.62, 'CASH', 'GW-TX-0030', 'SUCCESS', v_repayment_id, '2026-05-27 04:59:37+05:30', '2026-05-27 04:59:37+05:30');

  -- Transaction TX-0031 (MISSED_PAYMENT - Loan #5 Nizara Rabha - Seq 2)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 5 AND seq_no = 2;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 5 AND seq_no = 2), status = CASE WHEN 2 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 5;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0031', 'MISSED_INSTALLMENT', 5, 5, 1, 1101.62, 'FIELD', 'GW-TX-0031', 'OVERDUE', 'Borrower absent at center meeting; late fee ₹50 accrued', '2026-06-03 14:59:37+05:30', '2026-06-03 14:59:37+05:30');

  -- Transaction TX-0032 (REPAYMENT - Loan #5 Nizara Rabha - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (5, v_user_id, 2253.24, '2026-06-10 05:59:37+05:30', 'f6b06c52-3ec7-43b7-bb89-edca81091df9', 'BRANCH')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 5 AND seq_no = 3;
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 5 AND seq_no = 2;
  v_rem_amt := 2253.24;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 5) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 5));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 5;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 5) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 5));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 5;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 5 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-10 05:59:37+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 5, 'CASH', 2253.24, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 5, 'CASH', 2253.24, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 5, 'LOAN_PORTFOLIO', 0.00, 2253.24, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 5, 'LOAN_PORTFOLIO', 0.00, 2253.24, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0032', 'REPAYMENT', 5, 5, 1, 2253.24, 'CASH', 'GW-TX-0032', 'SUCCESS', v_repayment_id, '2026-06-10 05:59:37+05:30', '2026-06-10 05:59:37+05:30');

  -- Transaction TX-0033 (REPAYMENT - Loan #5 Nizara Rabha - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (5, v_user_id, 1101.62, '2026-06-17 04:59:37+05:30', '88681758-713a-4dc7-a8cd-b2a175c0a1cd', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 5 AND seq_no = 4;
  v_rem_amt := 1101.62;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 5) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 5));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 5;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 5) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 5));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 5;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 5 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-17 04:59:37+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 5, 'CASH', 1101.62, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 5, 'CASH', 1101.62, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 5, 'LOAN_PORTFOLIO', 0.00, 1101.62, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 5, 'LOAN_PORTFOLIO', 0.00, 1101.62, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0033', 'REPAYMENT', 5, 5, 1, 1101.62, 'CASH', 'GW-TX-0033', 'SUCCESS', v_repayment_id, '2026-06-17 04:59:37+05:30', '2026-06-17 04:59:37+05:30');

  -- Transaction TX-0034 (REPAYMENT - Loan #5 Nizara Rabha - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (5, v_user_id, 1101.62, '2026-06-24 04:59:37+05:30', '39c31af0-dddd-4a86-9ec6-343fc0a1db44', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 5 AND seq_no = 5;
  v_rem_amt := 1101.62;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 5) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 5));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 5;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 5) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 5));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 5;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 5 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-24 04:59:37+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 5, 'CASH', 1101.62, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 5, 'CASH', 1101.62, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 5, 'LOAN_PORTFOLIO', 0.00, 1101.62, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 5, 'LOAN_PORTFOLIO', 0.00, 1101.62, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0034', 'REPAYMENT', 5, 5, 1, 1101.62, 'CASH', 'GW-TX-0034', 'SUCCESS', v_repayment_id, '2026-06-24 04:59:37+05:30', '2026-06-24 04:59:37+05:30');

  -- Transaction TX-0035 (REPAYMENT - Loan #5 Nizara Rabha - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (5, v_user_id, 1101.62, '2026-07-01 04:59:37+05:30', 'c790c860-21d2-4481-bc16-7f0a401b068b', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 5 AND seq_no = 6;
  v_rem_amt := 1101.62;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 5) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 5));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 5;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 5) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 5));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 5;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 5 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-01 04:59:37+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 5, 'CASH', 1101.62, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 5, 'CASH', 1101.62, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 5, 'LOAN_PORTFOLIO', 0.00, 1101.62, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 5, 'LOAN_PORTFOLIO', 0.00, 1101.62, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0035', 'REPAYMENT', 5, 5, 1, 1101.62, 'CASH', 'GW-TX-0035', 'SUCCESS', v_repayment_id, '2026-07-01 04:59:37+05:30', '2026-07-01 04:59:37+05:30');

  -- Transaction TX-0036 (DISBURSEMENT - Loan #6 Ranjita Choudhury - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0036', 'LOAN_DISBURSEMENT', 6, 6, 1, 30000.00, 'BANK_TRANSFER', 'GW-TX-0036', 'SUCCESS', '2025-12-27 06:26:31+05:30', '2025-12-27 06:26:31+05:30');

  -- Transaction TX-0037 (REPAYMENT - Loan #6 Ranjita Choudhury - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (6, v_user_id, 632.96, '2026-01-03 16:26:31+05:30', '30dd8458-de3f-4dd8-b004-44139b2c122c', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 6 AND seq_no = 1;
  v_rem_amt := 632.96;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 6) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 6));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 6;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 6) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 6));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 6;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 6 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-01-03 16:26:31+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 6, 'CASH', 632.96, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 6, 'CASH', 632.96, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 6, 'LOAN_PORTFOLIO', 0.00, 632.96, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 6, 'LOAN_PORTFOLIO', 0.00, 632.96, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0037', 'REPAYMENT', 6, 6, 1, 632.96, 'CASH', 'GW-TX-0037', 'SUCCESS', v_repayment_id, '2026-01-03 16:26:31+05:30', '2026-01-03 16:26:31+05:30');

  -- Transaction TX-0038 (MISSED_PAYMENT - Loan #6 Ranjita Choudhury - Seq 2)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 6 AND seq_no = 2;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 6 AND seq_no = 2), status = CASE WHEN 2 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 6;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0038', 'MISSED_INSTALLMENT', 6, 6, 1, 632.96, 'FIELD', 'GW-TX-0038', 'OVERDUE', 'Borrower absent at center meeting; late fee ₹50 accrued', '2026-01-11 02:26:31+05:30', '2026-01-11 02:26:31+05:30');

  -- Transaction TX-0039 (REPAYMENT - Loan #6 Ranjita Choudhury - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (6, v_user_id, 1315.92, '2026-01-17 17:26:31+05:30', '1ec217fd-cf25-44ac-b678-9ed0d4a71942', 'BRANCH')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 6 AND seq_no = 3;
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 6 AND seq_no = 2;
  v_rem_amt := 1315.92;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 6) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 6));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 6;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 6) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 6));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 6;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 6 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-01-17 17:26:31+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 6, 'CASH', 1315.92, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 6, 'CASH', 1315.92, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 6, 'LOAN_PORTFOLIO', 0.00, 1315.92, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 6, 'LOAN_PORTFOLIO', 0.00, 1315.92, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0039', 'REPAYMENT', 6, 6, 1, 1315.92, 'CASH', 'GW-TX-0039', 'SUCCESS', v_repayment_id, '2026-01-17 17:26:31+05:30', '2026-01-17 17:26:31+05:30');

  -- Transaction TX-0040 (REPAYMENT - Loan #6 Ranjita Choudhury - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (6, v_user_id, 632.96, '2026-01-24 16:26:31+05:30', 'd2c03e2c-be75-461b-a3c5-a747e375a378', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 6 AND seq_no = 4;
  v_rem_amt := 632.96;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 6) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 6));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 6;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 6) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 6));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 6;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 6 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-01-24 16:26:31+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 6, 'CASH', 632.96, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 6, 'CASH', 632.96, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 6, 'LOAN_PORTFOLIO', 0.00, 632.96, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 6, 'LOAN_PORTFOLIO', 0.00, 632.96, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0040', 'REPAYMENT', 6, 6, 1, 632.96, 'CASH', 'GW-TX-0040', 'SUCCESS', v_repayment_id, '2026-01-24 16:26:31+05:30', '2026-01-24 16:26:31+05:30');

  -- Transaction TX-0041 (REPAYMENT - Loan #6 Ranjita Choudhury - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (6, v_user_id, 632.96, '2026-01-31 16:26:31+05:30', '2355dde3-e72c-4293-ba7e-b13d856d8f8a', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 6 AND seq_no = 5;
  v_rem_amt := 632.96;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 6) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 6));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 6;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 6) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 6));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 6;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 6 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-01-31 16:26:31+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 6, 'CASH', 632.96, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 6, 'CASH', 632.96, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 6, 'LOAN_PORTFOLIO', 0.00, 632.96, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 6, 'LOAN_PORTFOLIO', 0.00, 632.96, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0041', 'REPAYMENT', 6, 6, 1, 632.96, 'CASH', 'GW-TX-0041', 'SUCCESS', v_repayment_id, '2026-01-31 16:26:31+05:30', '2026-01-31 16:26:31+05:30');

  -- Transaction TX-0042 (REPAYMENT - Loan #6 Ranjita Choudhury - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (6, v_user_id, 632.96, '2026-02-07 16:26:31+05:30', '5ced5b16-70a5-4aee-8273-f2ba80f2767b', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 6 AND seq_no = 6;
  v_rem_amt := 632.96;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 6) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 6));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 6;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 6) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 6));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 6;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 6 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-02-07 16:26:31+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 6, 'CASH', 632.96, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 6, 'CASH', 632.96, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 6, 'LOAN_PORTFOLIO', 0.00, 632.96, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 6, 'LOAN_PORTFOLIO', 0.00, 632.96, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0042', 'REPAYMENT', 6, 6, 1, 632.96, 'CASH', 'GW-TX-0042', 'SUCCESS', v_repayment_id, '2026-02-07 16:26:31+05:30', '2026-02-07 16:26:31+05:30');

  -- Transaction TX-0043 (DISBURSEMENT - Loan #7 Purnima Nath - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0043', 'LOAN_DISBURSEMENT', 7, 7, 1, 50000.00, 'BANK_TRANSFER', 'GW-TX-0043', 'SUCCESS', '2026-01-01 03:35:13+05:30', '2026-01-01 03:35:13+05:30');

  -- Transaction TX-0044 (REPAYMENT - Loan #7 Purnima Nath - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (7, v_user_id, 2182.39, '2026-01-08 13:35:13+05:30', 'b92eb8c4-9201-48e7-a218-5a82bad6cbf8', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 7 AND seq_no = 1;
  v_rem_amt := 2182.39;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 7) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 7));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 7;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 7) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 7));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 7;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 7 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-01-08 13:35:13+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 7, 'CASH', 2182.39, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 7, 'CASH', 2182.39, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 7, 'LOAN_PORTFOLIO', 0.00, 2182.39, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 7, 'LOAN_PORTFOLIO', 0.00, 2182.39, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0044', 'REPAYMENT', 7, 7, 1, 2182.39, 'CASH', 'GW-TX-0044', 'SUCCESS', v_repayment_id, '2026-01-08 13:35:13+05:30', '2026-01-08 13:35:13+05:30');

  -- Transaction TX-0045 (MISSED_PAYMENT - Loan #7 Purnima Nath - Seq 2)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 7 AND seq_no = 2;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 7 AND seq_no = 2), status = CASE WHEN 2 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 7;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0045', 'MISSED_INSTALLMENT', 7, 7, 1, 2182.39, 'FIELD', 'GW-TX-0045', 'OVERDUE', 'Borrower absent at center meeting; late fee ₹50 accrued', '2026-01-15 23:35:13+05:30', '2026-01-15 23:35:13+05:30');

  -- Transaction TX-0046 (REPAYMENT - Loan #7 Purnima Nath - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (7, v_user_id, 4414.78, '2026-01-22 14:35:13+05:30', '393a86d0-1887-4d63-b8d9-789721e42497', 'BRANCH')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 7 AND seq_no = 3;
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 7 AND seq_no = 2;
  v_rem_amt := 4414.78;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 7) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 7));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 7;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 7) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 7));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 7;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 7 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-01-22 14:35:13+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 7, 'CASH', 4414.78, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 7, 'CASH', 4414.78, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 7, 'LOAN_PORTFOLIO', 0.00, 4414.78, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 7, 'LOAN_PORTFOLIO', 0.00, 4414.78, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0046', 'REPAYMENT', 7, 7, 1, 4414.78, 'CASH', 'GW-TX-0046', 'SUCCESS', v_repayment_id, '2026-01-22 14:35:13+05:30', '2026-01-22 14:35:13+05:30');

  -- Transaction TX-0047 (REPAYMENT - Loan #7 Purnima Nath - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (7, v_user_id, 2182.39, '2026-01-29 13:35:13+05:30', 'c939e11d-5ebe-4251-b92d-1f8905f4a57b', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 7 AND seq_no = 4;
  v_rem_amt := 2182.39;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 7) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 7));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 7;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 7) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 7));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 7;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 7 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-01-29 13:35:13+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 7, 'CASH', 2182.39, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 7, 'CASH', 2182.39, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 7, 'LOAN_PORTFOLIO', 0.00, 2182.39, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 7, 'LOAN_PORTFOLIO', 0.00, 2182.39, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0047', 'REPAYMENT', 7, 7, 1, 2182.39, 'CASH', 'GW-TX-0047', 'SUCCESS', v_repayment_id, '2026-01-29 13:35:13+05:30', '2026-01-29 13:35:13+05:30');

  -- Transaction TX-0048 (REPAYMENT - Loan #7 Purnima Nath - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (7, v_user_id, 2182.39, '2026-02-05 13:35:13+05:30', '2508aecb-6da4-48fb-acee-da51bc7a6004', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 7 AND seq_no = 5;
  v_rem_amt := 2182.39;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 7) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 7));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 7;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 7) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 7));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 7;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 7 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-02-05 13:35:13+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 7, 'CASH', 2182.39, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 7, 'CASH', 2182.39, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 7, 'LOAN_PORTFOLIO', 0.00, 2182.39, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 7, 'LOAN_PORTFOLIO', 0.00, 2182.39, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0048', 'REPAYMENT', 7, 7, 1, 2182.39, 'CASH', 'GW-TX-0048', 'SUCCESS', v_repayment_id, '2026-02-05 13:35:13+05:30', '2026-02-05 13:35:13+05:30');

  -- Transaction TX-0049 (REPAYMENT - Loan #7 Purnima Nath - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (7, v_user_id, 2182.39, '2026-02-12 13:35:13+05:30', '5b8b07f1-ca19-45f0-8dd8-501166947189', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 7 AND seq_no = 6;
  v_rem_amt := 2182.39;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 7) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 7));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 7;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 7) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 7));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 7;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 7 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-02-12 13:35:13+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 7, 'CASH', 2182.39, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 7, 'CASH', 2182.39, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 7, 'LOAN_PORTFOLIO', 0.00, 2182.39, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 7, 'LOAN_PORTFOLIO', 0.00, 2182.39, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0049', 'REPAYMENT', 7, 7, 1, 2182.39, 'CASH', 'GW-TX-0049', 'SUCCESS', v_repayment_id, '2026-02-12 13:35:13+05:30', '2026-02-12 13:35:13+05:30');

  -- Transaction TX-0050 (DISBURSEMENT - Loan #8 Bornali Talukdar - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0050', 'LOAN_DISBURSEMENT', 8, 8, 1, 22500.00, 'BANK_TRANSFER', 'GW-TX-0050', 'SUCCESS', '2026-10-14 06:48:39+05:30', '2026-10-14 06:48:39+05:30');

  -- Transaction TX-0051 (REPAYMENT - Loan #8 Bornali Talukdar - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (8, v_user_id, 982.08, '2026-10-21 15:48:39+05:30', '630b19b7-709c-4cac-802e-c5bb85f86ba7', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 8 AND seq_no = 1;
  v_rem_amt := 982.08;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 8) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 8));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 8;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 8) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 8));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 8;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 8 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-21 15:48:39+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 8, 'CASH', 982.08, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 8, 'CASH', 982.08, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 8, 'LOAN_PORTFOLIO', 0.00, 982.08, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 8, 'LOAN_PORTFOLIO', 0.00, 982.08, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0051', 'REPAYMENT', 8, 8, 1, 982.08, 'ONLINE_UPI', 'GW-TX-0051', 'SUCCESS', v_repayment_id, '2026-10-21 15:48:39+05:30', '2026-10-21 15:48:39+05:30');

  -- Transaction TX-0052 (REPAYMENT - Loan #8 Bornali Talukdar - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (8, v_user_id, 982.08, '2026-10-28 21:48:39+05:30', '0ca6fc88-d549-43e6-9b9c-1e657272b9f3', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 8 AND seq_no = 2;
  v_rem_amt := 982.08;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 8) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 8));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 8;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 8) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 8));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 8;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 8 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-28 21:48:39+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 8, 'CASH', 982.08, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 8, 'CASH', 982.08, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 8, 'LOAN_PORTFOLIO', 0.00, 982.08, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 8, 'LOAN_PORTFOLIO', 0.00, 982.08, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0052', 'REPAYMENT', 8, 8, 1, 982.08, 'CASH', 'GW-TX-0052', 'SUCCESS', v_repayment_id, '2026-10-28 21:48:39+05:30', '2026-10-28 21:48:39+05:30');

  -- Transaction TX-0053 (REPAYMENT - Loan #8 Bornali Talukdar - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (8, v_user_id, 982.08, '2026-11-04 18:48:39+05:30', '36e8e1a3-c7f5-4e7d-a7d0-dfd63d0a10d1', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 8 AND seq_no = 3;
  v_rem_amt := 982.08;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 8) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 8));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 8;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 8) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 8));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 8;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 8 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-11-04 18:48:39+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 8, 'CASH', 982.08, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 8, 'CASH', 982.08, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 8, 'LOAN_PORTFOLIO', 0.00, 982.08, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 8, 'LOAN_PORTFOLIO', 0.00, 982.08, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0053', 'REPAYMENT', 8, 8, 1, 982.08, 'ONLINE_UPI', 'GW-TX-0053', 'SUCCESS', v_repayment_id, '2026-11-04 18:48:39+05:30', '2026-11-04 18:48:39+05:30');

  -- Transaction TX-0054 (REPAYMENT - Loan #8 Bornali Talukdar - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (8, v_user_id, 982.08, '2026-11-11 15:48:39+05:30', 'cf3f5f45-474a-4fb6-b6b5-d589017cbad5', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 8 AND seq_no = 4;
  v_rem_amt := 982.08;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 8) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 8));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 8;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 8) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 8));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 8;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 8 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-11-11 15:48:39+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 8, 'CASH', 982.08, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 8, 'CASH', 982.08, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 8, 'LOAN_PORTFOLIO', 0.00, 982.08, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 8, 'LOAN_PORTFOLIO', 0.00, 982.08, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0054', 'REPAYMENT', 8, 8, 1, 982.08, 'ONLINE_UPI', 'GW-TX-0054', 'SUCCESS', v_repayment_id, '2026-11-11 15:48:39+05:30', '2026-11-11 15:48:39+05:30');

  -- Transaction TX-0055 (REPAYMENT - Loan #8 Bornali Talukdar - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (8, v_user_id, 982.08, '2026-11-18 22:48:39+05:30', '72106ff4-3109-421d-b0d3-5b01ff39831e', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 8 AND seq_no = 5;
  v_rem_amt := 982.08;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 8) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 8));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 8;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 8) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 8));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 8;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 8 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-11-18 22:48:39+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 8, 'CASH', 982.08, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 8, 'CASH', 982.08, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 8, 'LOAN_PORTFOLIO', 0.00, 982.08, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 8, 'LOAN_PORTFOLIO', 0.00, 982.08, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0055', 'REPAYMENT', 8, 8, 1, 982.08, 'CASH', 'GW-TX-0055', 'SUCCESS', v_repayment_id, '2026-11-18 22:48:39+05:30', '2026-11-18 22:48:39+05:30');

  -- Transaction TX-0056 (DISBURSEMENT - Loan #9 Mamoni Talukdar - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0056', 'LOAN_DISBURSEMENT', 9, 9, 1, 22500.00, 'BANK_TRANSFER', 'GW-TX-0056', 'SUCCESS', '2026-02-26 02:21:06+05:30', '2026-02-26 02:21:06+05:30');

  -- Transaction TX-0057 (REPAYMENT - Loan #9 Mamoni Talukdar - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (9, v_user_id, 927.25, '2026-03-05 11:21:06+05:30', 'bdf51b89-9aa4-452d-9c8a-01c9ab1cb6b5', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 9 AND seq_no = 1;
  v_rem_amt := 927.25;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 9) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 9));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 9;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 9) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 9));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 9;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 9 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-03-05 11:21:06+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 9, 'CASH', 927.25, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 9, 'CASH', 927.25, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 9, 'LOAN_PORTFOLIO', 0.00, 927.25, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 9, 'LOAN_PORTFOLIO', 0.00, 927.25, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0057', 'REPAYMENT', 9, 9, 1, 927.25, 'CASH', 'GW-TX-0057', 'SUCCESS', v_repayment_id, '2026-03-05 11:21:06+05:30', '2026-03-05 11:21:06+05:30');

  -- Transaction TX-0058 (REPAYMENT - Loan #9 Mamoni Talukdar - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (9, v_user_id, 927.25, '2026-03-12 17:21:06+05:30', 'fa7be30a-7d7c-4af1-8393-aa5f659d7984', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 9 AND seq_no = 2;
  v_rem_amt := 927.25;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 9) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 9));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 9;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 9) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 9));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 9;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 9 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-03-12 17:21:06+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 9, 'CASH', 927.25, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 9, 'CASH', 927.25, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 9, 'LOAN_PORTFOLIO', 0.00, 927.25, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 9, 'LOAN_PORTFOLIO', 0.00, 927.25, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0058', 'REPAYMENT', 9, 9, 1, 927.25, 'ONLINE_UPI', 'GW-TX-0058', 'SUCCESS', v_repayment_id, '2026-03-12 17:21:06+05:30', '2026-03-12 17:21:06+05:30');

  -- Transaction TX-0059 (REPAYMENT - Loan #9 Mamoni Talukdar - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (9, v_user_id, 927.25, '2026-03-19 17:21:06+05:30', 'a2a0ee75-d93d-4c1a-be81-8ba4066c7902', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 9 AND seq_no = 3;
  v_rem_amt := 927.25;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 9) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 9));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 9;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 9) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 9));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 9;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 9 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-03-19 17:21:06+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 9, 'CASH', 927.25, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 9, 'CASH', 927.25, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 9, 'LOAN_PORTFOLIO', 0.00, 927.25, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 9, 'LOAN_PORTFOLIO', 0.00, 927.25, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0059', 'REPAYMENT', 9, 9, 1, 927.25, 'ONLINE_UPI', 'GW-TX-0059', 'SUCCESS', v_repayment_id, '2026-03-19 17:21:06+05:30', '2026-03-19 17:21:06+05:30');

  -- Transaction TX-0060 (REPAYMENT - Loan #9 Mamoni Talukdar - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (9, v_user_id, 927.25, '2026-03-26 15:21:06+05:30', '3f2bb1dc-5b80-4766-8e35-c043c11ac824', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 9 AND seq_no = 4;
  v_rem_amt := 927.25;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 9) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 9));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 9;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 9) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 9));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 9;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 9 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-03-26 15:21:06+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 9, 'CASH', 927.25, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 9, 'CASH', 927.25, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 9, 'LOAN_PORTFOLIO', 0.00, 927.25, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 9, 'LOAN_PORTFOLIO', 0.00, 927.25, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0060', 'REPAYMENT', 9, 9, 1, 927.25, 'CASH', 'GW-TX-0060', 'SUCCESS', v_repayment_id, '2026-03-26 15:21:06+05:30', '2026-03-26 15:21:06+05:30');

  -- Transaction TX-0061 (REPAYMENT - Loan #9 Mamoni Talukdar - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (9, v_user_id, 927.25, '2026-04-02 13:21:06+05:30', '6d3f0297-4c00-4f6b-a204-1485847c1273', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 9 AND seq_no = 5;
  v_rem_amt := 927.25;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 9) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 9));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 9;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 9) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 9));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 9;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 9 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-04-02 13:21:06+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 9, 'CASH', 927.25, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 9, 'CASH', 927.25, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 9, 'LOAN_PORTFOLIO', 0.00, 927.25, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 9, 'LOAN_PORTFOLIO', 0.00, 927.25, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0061', 'REPAYMENT', 9, 9, 1, 927.25, 'CASH', 'GW-TX-0061', 'SUCCESS', v_repayment_id, '2026-04-02 13:21:06+05:30', '2026-04-02 13:21:06+05:30');

  -- Transaction TX-0062 (REPAYMENT - Loan #9 Mamoni Talukdar - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (9, v_user_id, 927.25, '2026-04-09 13:21:06+05:30', 'a4db4176-380a-4c70-b0ce-de522c185787', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 9 AND seq_no = 6;
  v_rem_amt := 927.25;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 9) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 9));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 9;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 9) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 9));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 9;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 9 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-04-09 13:21:06+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 9, 'CASH', 927.25, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 9, 'CASH', 927.25, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 9, 'LOAN_PORTFOLIO', 0.00, 927.25, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 9, 'LOAN_PORTFOLIO', 0.00, 927.25, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0062', 'REPAYMENT', 9, 9, 1, 927.25, 'ONLINE_UPI', 'GW-TX-0062', 'SUCCESS', v_repayment_id, '2026-04-09 13:21:06+05:30', '2026-04-09 13:21:06+05:30');

  -- Transaction TX-0063 (DISBURSEMENT - Loan #10 Sabita Boro - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0063', 'LOAN_DISBURSEMENT', 10, 10, 2, 22500.00, 'BANK_TRANSFER', 'GW-TX-0063', 'SUCCESS', '2026-04-28 10:27:48+05:30', '2026-04-28 10:27:48+05:30');

  -- Transaction TX-0064 (REPAYMENT - Loan #10 Sabita Boro - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (10, v_user_id, 482.94, '2026-05-05 20:27:48+05:30', '3c1105d6-2cf8-4df9-92e7-724d60f15c1b', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 10 AND seq_no = 1;
  v_rem_amt := 482.94;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 10) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 10));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 10;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 10) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 10));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 10;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 10 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-05-05 20:27:48+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 10, 'CASH', 482.94, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 10, 'CASH', 482.94, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 10, 'LOAN_PORTFOLIO', 0.00, 482.94, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 10, 'LOAN_PORTFOLIO', 0.00, 482.94, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0064', 'REPAYMENT', 10, 10, 2, 482.94, 'CASH', 'GW-TX-0064', 'SUCCESS', v_repayment_id, '2026-05-05 20:27:48+05:30', '2026-05-05 20:27:48+05:30');

  -- Transaction TX-0065 (MISSED_PAYMENT - Loan #10 Sabita Boro - Seq 2)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 10 AND seq_no = 2;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 10 AND seq_no = 2), status = CASE WHEN 2 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 10;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0065', 'MISSED_INSTALLMENT', 10, 10, 2, 482.94, 'FIELD', 'GW-TX-0065', 'OVERDUE', 'Unpaid default; propagates 50.0% liability to co-guarantors', '2026-05-13 04:27:48+05:30', '2026-05-13 04:27:48+05:30');

  -- Transaction TX-0066 (MISSED_PAYMENT - Loan #10 Sabita Boro - Seq 3)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 10 AND seq_no = 3;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 10 AND seq_no = 3), status = CASE WHEN 3 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 10;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0066', 'MISSED_INSTALLMENT', 10, 10, 2, 482.94, 'FIELD', 'GW-TX-0066', 'OVERDUE', 'Unpaid default; propagates 50.0% liability to co-guarantors', '2026-05-20 04:27:48+05:30', '2026-05-20 04:27:48+05:30');

  -- Transaction TX-0067 (MISSED_PAYMENT - Loan #10 Sabita Boro - Seq 4)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 10 AND seq_no = 4;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 10 AND seq_no = 4), status = CASE WHEN 4 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 10;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0067', 'MISSED_INSTALLMENT', 10, 10, 2, 482.94, 'FIELD', 'GW-TX-0067', 'OVERDUE', 'Unpaid default; propagates 50.0% liability to co-guarantors', '2026-05-27 04:27:48+05:30', '2026-05-27 04:27:48+05:30');

  -- Transaction TX-0068 (MISSED_PAYMENT - Loan #10 Sabita Boro - Seq 5)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 10 AND seq_no = 5;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 10 AND seq_no = 5), status = CASE WHEN 5 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 10;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0068', 'MISSED_INSTALLMENT', 10, 10, 2, 482.94, 'FIELD', 'GW-TX-0068', 'OVERDUE', 'Unpaid default; propagates 50.0% liability to co-guarantors', '2026-06-03 04:27:48+05:30', '2026-06-03 04:27:48+05:30');

  -- Transaction TX-0069 (MISSED_PAYMENT - Loan #10 Sabita Boro - Seq 6)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 10 AND seq_no = 6;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 10 AND seq_no = 6), status = CASE WHEN 6 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 10;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0069', 'MISSED_INSTALLMENT', 10, 10, 2, 482.94, 'FIELD', 'GW-TX-0069', 'OVERDUE', 'Unpaid default; propagates 50.0% liability to co-guarantors', '2026-06-10 04:27:48+05:30', '2026-06-10 04:27:48+05:30');

  -- Transaction TX-0070 (DISBURSEMENT - Loan #11 Barnali Deka - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0070', 'LOAN_DISBURSEMENT', 11, 11, 2, 12000.00, 'BANK_TRANSFER', 'GW-TX-0070', 'SUCCESS', '2026-09-25 14:25:56+05:30', '2026-09-25 14:25:56+05:30');

  -- Transaction TX-0071 (REPAYMENT - Loan #11 Barnali Deka - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (11, v_user_id, 356.96, '2026-10-03 05:25:56+05:30', '8c6e2cb6-dfab-4f98-b7a0-e7fc0a05b675', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 11 AND seq_no = 1;
  v_rem_amt := 356.96;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 11) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 11));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 11;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 11) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 11));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 11;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 11 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-03 05:25:56+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 11, 'CASH', 356.96, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 11, 'CASH', 356.96, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 11, 'LOAN_PORTFOLIO', 0.00, 356.96, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 11, 'LOAN_PORTFOLIO', 0.00, 356.96, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0071', 'REPAYMENT', 11, 11, 2, 356.96, 'ONLINE_UPI', 'GW-TX-0071', 'SUCCESS', v_repayment_id, '2026-10-03 05:25:56+05:30', '2026-10-03 05:25:56+05:30');

  -- Transaction TX-0072 (REPAYMENT - Loan #11 Barnali Deka - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (11, v_user_id, 356.96, '2026-10-09 23:25:56+05:30', 'f106a616-fb85-4575-b2a1-b4a9facf688b', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 11 AND seq_no = 2;
  v_rem_amt := 356.96;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 11) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 11));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 11;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 11) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 11));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 11;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 11 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-09 23:25:56+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 11, 'CASH', 356.96, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 11, 'CASH', 356.96, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 11, 'LOAN_PORTFOLIO', 0.00, 356.96, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 11, 'LOAN_PORTFOLIO', 0.00, 356.96, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0072', 'REPAYMENT', 11, 11, 2, 356.96, 'CASH', 'GW-TX-0072', 'SUCCESS', v_repayment_id, '2026-10-09 23:25:56+05:30', '2026-10-09 23:25:56+05:30');

  -- Transaction TX-0073 (REPAYMENT - Loan #11 Barnali Deka - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (11, v_user_id, 356.96, '2026-10-17 06:25:56+05:30', '314305c1-19da-43bc-809a-8572f648f4b3', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 11 AND seq_no = 3;
  v_rem_amt := 356.96;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 11) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 11));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 11;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 11) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 11));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 11;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 11 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-17 06:25:56+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 11, 'CASH', 356.96, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 11, 'CASH', 356.96, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 11, 'LOAN_PORTFOLIO', 0.00, 356.96, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 11, 'LOAN_PORTFOLIO', 0.00, 356.96, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0073', 'REPAYMENT', 11, 11, 2, 356.96, 'CASH', 'GW-TX-0073', 'SUCCESS', v_repayment_id, '2026-10-17 06:25:56+05:30', '2026-10-17 06:25:56+05:30');

  -- Transaction TX-0074 (REPAYMENT - Loan #11 Barnali Deka - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (11, v_user_id, 356.96, '2026-10-24 05:25:56+05:30', 'c9df8040-3d61-4b87-bd75-7e4fb3ac5ad7', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 11 AND seq_no = 4;
  v_rem_amt := 356.96;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 11) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 11));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 11;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 11) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 11));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 11;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 11 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-24 05:25:56+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 11, 'CASH', 356.96, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 11, 'CASH', 356.96, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 11, 'LOAN_PORTFOLIO', 0.00, 356.96, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 11, 'LOAN_PORTFOLIO', 0.00, 356.96, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0074', 'REPAYMENT', 11, 11, 2, 356.96, 'ONLINE_UPI', 'GW-TX-0074', 'SUCCESS', v_repayment_id, '2026-10-24 05:25:56+05:30', '2026-10-24 05:25:56+05:30');

  -- Transaction TX-0075 (REPAYMENT - Loan #11 Barnali Deka - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (11, v_user_id, 356.96, '2026-10-31 05:25:56+05:30', 'abf0018c-63a2-4945-8482-1af0b9c9580a', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 11 AND seq_no = 5;
  v_rem_amt := 356.96;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 11) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 11));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 11;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 11) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 11));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 11;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 11 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-31 05:25:56+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 11, 'CASH', 356.96, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 11, 'CASH', 356.96, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 11, 'LOAN_PORTFOLIO', 0.00, 356.96, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 11, 'LOAN_PORTFOLIO', 0.00, 356.96, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0075', 'REPAYMENT', 11, 11, 2, 356.96, 'CASH', 'GW-TX-0075', 'SUCCESS', v_repayment_id, '2026-10-31 05:25:56+05:30', '2026-10-31 05:25:56+05:30');

  -- Transaction TX-0076 (REPAYMENT - Loan #11 Barnali Deka - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (11, v_user_id, 356.96, '2026-11-07 06:25:56+05:30', '2e1999f7-894d-442c-bd32-84c790842a5a', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 11 AND seq_no = 6;
  v_rem_amt := 356.96;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 11) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 11));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 11;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 11) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 11));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 11;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 11 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-11-07 06:25:56+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 11, 'CASH', 356.96, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 11, 'CASH', 356.96, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 11, 'LOAN_PORTFOLIO', 0.00, 356.96, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 11, 'LOAN_PORTFOLIO', 0.00, 356.96, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0076', 'REPAYMENT', 11, 11, 2, 356.96, 'ONLINE_UPI', 'GW-TX-0076', 'SUCCESS', v_repayment_id, '2026-11-07 06:25:56+05:30', '2026-11-07 06:25:56+05:30');

  -- Transaction TX-0077 (DISBURSEMENT - Loan #12 Rumi Saikia - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0077', 'LOAN_DISBURSEMENT', 12, 12, 2, 22500.00, 'BANK_TRANSFER', 'GW-TX-0077', 'SUCCESS', '2026-06-04 21:21:23+05:30', '2026-06-04 21:21:23+05:30');

  -- Transaction TX-0078 (REPAYMENT - Loan #12 Rumi Saikia - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (12, v_user_id, 666.99, '2026-06-12 06:21:23+05:30', 'eead7766-3596-4cbf-91fe-9a777b339e67', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 12 AND seq_no = 1;
  v_rem_amt := 666.99;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 12) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 12));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 12;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 12) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 12));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 12;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 12 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-12 06:21:23+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 12, 'CASH', 666.99, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 12, 'CASH', 666.99, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 12, 'LOAN_PORTFOLIO', 0.00, 666.99, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 12, 'LOAN_PORTFOLIO', 0.00, 666.99, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0078', 'REPAYMENT', 12, 12, 2, 666.99, 'ONLINE_UPI', 'GW-TX-0078', 'SUCCESS', v_repayment_id, '2026-06-12 06:21:23+05:30', '2026-06-12 06:21:23+05:30');

  -- Transaction TX-0079 (REPAYMENT - Loan #12 Rumi Saikia - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (12, v_user_id, 666.99, '2026-06-19 11:21:23+05:30', '315eca4a-15c9-4876-a663-08e79063157e', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 12 AND seq_no = 2;
  v_rem_amt := 666.99;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 12) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 12));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 12;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 12) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 12));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 12;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 12 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-19 11:21:23+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 12, 'CASH', 666.99, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 12, 'CASH', 666.99, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 12, 'LOAN_PORTFOLIO', 0.00, 666.99, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 12, 'LOAN_PORTFOLIO', 0.00, 666.99, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0079', 'REPAYMENT', 12, 12, 2, 666.99, 'ONLINE_UPI', 'GW-TX-0079', 'SUCCESS', v_repayment_id, '2026-06-19 11:21:23+05:30', '2026-06-19 11:21:23+05:30');

  -- Transaction TX-0080 (REPAYMENT - Loan #12 Rumi Saikia - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (12, v_user_id, 666.99, '2026-06-26 07:21:23+05:30', 'ebdec9fc-7753-4e11-a326-522685fd9bfa', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 12 AND seq_no = 3;
  v_rem_amt := 666.99;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 12) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 12));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 12;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 12) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 12));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 12;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 12 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-26 07:21:23+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 12, 'CASH', 666.99, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 12, 'CASH', 666.99, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 12, 'LOAN_PORTFOLIO', 0.00, 666.99, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 12, 'LOAN_PORTFOLIO', 0.00, 666.99, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0080', 'REPAYMENT', 12, 12, 2, 666.99, 'CASH', 'GW-TX-0080', 'SUCCESS', v_repayment_id, '2026-06-26 07:21:23+05:30', '2026-06-26 07:21:23+05:30');

  -- Transaction TX-0081 (REPAYMENT - Loan #12 Rumi Saikia - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (12, v_user_id, 666.99, '2026-07-03 06:21:23+05:30', '99723979-ec65-40eb-8f22-12157a556094', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 12 AND seq_no = 4;
  v_rem_amt := 666.99;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 12) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 12));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 12;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 12) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 12));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 12;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 12 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-03 06:21:23+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 12, 'CASH', 666.99, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 12, 'CASH', 666.99, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 12, 'LOAN_PORTFOLIO', 0.00, 666.99, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 12, 'LOAN_PORTFOLIO', 0.00, 666.99, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0081', 'REPAYMENT', 12, 12, 2, 666.99, 'CASH', 'GW-TX-0081', 'SUCCESS', v_repayment_id, '2026-07-03 06:21:23+05:30', '2026-07-03 06:21:23+05:30');

  -- Transaction TX-0082 (REPAYMENT - Loan #12 Rumi Saikia - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (12, v_user_id, 666.99, '2026-07-10 06:21:23+05:30', '23c8ab73-79c2-4c79-85f2-bf158ed8dc72', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 12 AND seq_no = 5;
  v_rem_amt := 666.99;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 12) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 12));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 12;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 12) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 12));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 12;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 12 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-10 06:21:23+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 12, 'CASH', 666.99, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 12, 'CASH', 666.99, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 12, 'LOAN_PORTFOLIO', 0.00, 666.99, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 12, 'LOAN_PORTFOLIO', 0.00, 666.99, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0082', 'REPAYMENT', 12, 12, 2, 666.99, 'CASH', 'GW-TX-0082', 'SUCCESS', v_repayment_id, '2026-07-10 06:21:23+05:30', '2026-07-10 06:21:23+05:30');

  -- Transaction TX-0083 (REPAYMENT - Loan #12 Rumi Saikia - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (12, v_user_id, 666.99, '2026-07-17 11:21:23+05:30', 'c659ce8e-9bac-493d-9c70-cdc7e032d594', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 12 AND seq_no = 6;
  v_rem_amt := 666.99;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 12) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 12));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 12;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 12) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 12));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 12;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 12 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-17 11:21:23+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 12, 'CASH', 666.99, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 12, 'CASH', 666.99, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 12, 'LOAN_PORTFOLIO', 0.00, 666.99, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 12, 'LOAN_PORTFOLIO', 0.00, 666.99, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0083', 'REPAYMENT', 12, 12, 2, 666.99, 'ONLINE_UPI', 'GW-TX-0083', 'SUCCESS', v_repayment_id, '2026-07-17 11:21:23+05:30', '2026-07-17 11:21:23+05:30');

  -- Transaction TX-0084 (DISBURSEMENT - Loan #13 Ranjita Gogoi - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0084', 'LOAN_DISBURSEMENT', 13, 13, 2, 17000.00, 'BANK_TRANSFER', 'GW-TX-0084', 'SUCCESS', '2026-07-27 14:17:36+05:30', '2026-07-27 14:17:36+05:30');

  -- Transaction TX-0085 (REPAYMENT - Loan #13 Ranjita Gogoi - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (13, v_user_id, 728.95, '2026-08-04 03:17:36+05:30', '62dd9b28-754f-4070-a2d2-7aab0acf7319', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 13 AND seq_no = 1;
  v_rem_amt := 728.95;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 13) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 13));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 13;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 13) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 13));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 13;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 13 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-04 03:17:36+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 13, 'CASH', 728.95, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 13, 'CASH', 728.95, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 13, 'LOAN_PORTFOLIO', 0.00, 728.95, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 13, 'LOAN_PORTFOLIO', 0.00, 728.95, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0085', 'REPAYMENT', 13, 13, 2, 728.95, 'ONLINE_UPI', 'GW-TX-0085', 'SUCCESS', v_repayment_id, '2026-08-04 03:17:36+05:30', '2026-08-04 03:17:36+05:30');

  -- Transaction TX-0086 (REPAYMENT - Loan #13 Ranjita Gogoi - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (13, v_user_id, 728.95, '2026-08-11 03:17:36+05:30', '8227d9b1-11ec-4088-b3bd-2c28472d4d0a', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 13 AND seq_no = 2;
  v_rem_amt := 728.95;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 13) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 13));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 13;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 13) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 13));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 13;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 13 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-11 03:17:36+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 13, 'CASH', 728.95, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 13, 'CASH', 728.95, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 13, 'LOAN_PORTFOLIO', 0.00, 728.95, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 13, 'LOAN_PORTFOLIO', 0.00, 728.95, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0086', 'REPAYMENT', 13, 13, 2, 728.95, 'ONLINE_UPI', 'GW-TX-0086', 'SUCCESS', v_repayment_id, '2026-08-11 03:17:36+05:30', '2026-08-11 03:17:36+05:30');

  -- Transaction TX-0087 (REPAYMENT - Loan #13 Ranjita Gogoi - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (13, v_user_id, 728.95, '2026-08-18 01:17:36+05:30', 'f1709d0c-f0ba-49c3-af07-7aabd871dd37', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 13 AND seq_no = 3;
  v_rem_amt := 728.95;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 13) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 13));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 13;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 13) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 13));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 13;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 13 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-18 01:17:36+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 13, 'CASH', 728.95, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 13, 'CASH', 728.95, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 13, 'LOAN_PORTFOLIO', 0.00, 728.95, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 13, 'LOAN_PORTFOLIO', 0.00, 728.95, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0087', 'REPAYMENT', 13, 13, 2, 728.95, 'CASH', 'GW-TX-0087', 'SUCCESS', v_repayment_id, '2026-08-18 01:17:36+05:30', '2026-08-18 01:17:36+05:30');

  -- Transaction TX-0088 (REPAYMENT - Loan #13 Ranjita Gogoi - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (13, v_user_id, 728.95, '2026-08-24 23:17:36+05:30', 'c2c97133-b4b0-488c-88dd-2f673ef33199', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 13 AND seq_no = 4;
  v_rem_amt := 728.95;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 13) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 13));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 13;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 13) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 13));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 13;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 13 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-24 23:17:36+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 13, 'CASH', 728.95, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 13, 'CASH', 728.95, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 13, 'LOAN_PORTFOLIO', 0.00, 728.95, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 13, 'LOAN_PORTFOLIO', 0.00, 728.95, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0088', 'REPAYMENT', 13, 13, 2, 728.95, 'ONLINE_UPI', 'GW-TX-0088', 'SUCCESS', v_repayment_id, '2026-08-24 23:17:36+05:30', '2026-08-24 23:17:36+05:30');

  -- Transaction TX-0089 (REPAYMENT - Loan #13 Ranjita Gogoi - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (13, v_user_id, 728.95, '2026-09-01 06:17:36+05:30', '7dc39268-18c4-43bb-ac8a-f09fcc2c3034', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 13 AND seq_no = 5;
  v_rem_amt := 728.95;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 13) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 13));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 13;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 13) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 13));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 13;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 13 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-09-01 06:17:36+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 13, 'CASH', 728.95, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 13, 'CASH', 728.95, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 13, 'LOAN_PORTFOLIO', 0.00, 728.95, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 13, 'LOAN_PORTFOLIO', 0.00, 728.95, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0089', 'REPAYMENT', 13, 13, 2, 728.95, 'ONLINE_UPI', 'GW-TX-0089', 'SUCCESS', v_repayment_id, '2026-09-01 06:17:36+05:30', '2026-09-01 06:17:36+05:30');

  -- Transaction TX-0090 (REPAYMENT - Loan #13 Ranjita Gogoi - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (13, v_user_id, 728.95, '2026-09-08 06:17:36+05:30', 'c35b09b9-7f09-459c-a081-0cb644046a79', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 13 AND seq_no = 6;
  v_rem_amt := 728.95;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 13) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 13));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 13;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 13) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 13));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 13;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 13 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-09-08 06:17:36+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 13, 'CASH', 728.95, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 13, 'CASH', 728.95, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 13, 'LOAN_PORTFOLIO', 0.00, 728.95, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 13, 'LOAN_PORTFOLIO', 0.00, 728.95, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0090', 'REPAYMENT', 13, 13, 2, 728.95, 'CASH', 'GW-TX-0090', 'SUCCESS', v_repayment_id, '2026-09-08 06:17:36+05:30', '2026-09-08 06:17:36+05:30');

  -- Transaction TX-0091 (DISBURSEMENT - Loan #14 Bornali Deka - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0091', 'LOAN_DISBURSEMENT', 14, 14, 2, 15000.00, 'BANK_TRANSFER', 'GW-TX-0091', 'SUCCESS', '2026-03-21 14:35:54+05:30', '2026-03-21 14:35:54+05:30');

  -- Transaction TX-0092 (REPAYMENT - Loan #14 Bornali Deka - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (14, v_user_id, 447.75, '2026-03-29 00:35:54+05:30', '3f186405-7b39-4d5f-803d-ab32d8d7f664', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 14 AND seq_no = 1;
  v_rem_amt := 447.75;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 14) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 14));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 14;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 14) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 14));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 14;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 14 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-03-29 00:35:54+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 14, 'CASH', 447.75, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 14, 'CASH', 447.75, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 14, 'LOAN_PORTFOLIO', 0.00, 447.75, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 14, 'LOAN_PORTFOLIO', 0.00, 447.75, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0092', 'REPAYMENT', 14, 14, 2, 447.75, 'CASH', 'GW-TX-0092', 'SUCCESS', v_repayment_id, '2026-03-29 00:35:54+05:30', '2026-03-29 00:35:54+05:30');

  -- Transaction TX-0093 (MISSED_PAYMENT - Loan #14 Bornali Deka - Seq 2)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 14 AND seq_no = 2;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 14 AND seq_no = 2), status = CASE WHEN 2 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 14;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0093', 'MISSED_INSTALLMENT', 14, 14, 2, 447.75, 'FIELD', 'GW-TX-0093', 'OVERDUE', 'Unpaid default; propagates 33.33% liability to co-guarantors', '2026-04-05 08:35:54+05:30', '2026-04-05 08:35:54+05:30');

  -- Transaction TX-0094 (MISSED_PAYMENT - Loan #14 Bornali Deka - Seq 3)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 14 AND seq_no = 3;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 14 AND seq_no = 3), status = CASE WHEN 3 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 14;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0094', 'MISSED_INSTALLMENT', 14, 14, 2, 447.75, 'FIELD', 'GW-TX-0094', 'OVERDUE', 'Unpaid default; propagates 33.33% liability to co-guarantors', '2026-04-12 08:35:54+05:30', '2026-04-12 08:35:54+05:30');

  -- Transaction TX-0095 (MISSED_PAYMENT - Loan #14 Bornali Deka - Seq 4)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 14 AND seq_no = 4;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 14 AND seq_no = 4), status = CASE WHEN 4 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 14;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0095', 'MISSED_INSTALLMENT', 14, 14, 2, 447.75, 'FIELD', 'GW-TX-0095', 'OVERDUE', 'Unpaid default; propagates 33.33% liability to co-guarantors', '2026-04-19 08:35:54+05:30', '2026-04-19 08:35:54+05:30');

  -- Transaction TX-0096 (MISSED_PAYMENT - Loan #14 Bornali Deka - Seq 5)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 14 AND seq_no = 5;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 14 AND seq_no = 5), status = CASE WHEN 5 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 14;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0096', 'MISSED_INSTALLMENT', 14, 14, 2, 447.75, 'FIELD', 'GW-TX-0096', 'OVERDUE', 'Unpaid default; propagates 33.33% liability to co-guarantors', '2026-04-26 08:35:54+05:30', '2026-04-26 08:35:54+05:30');

  -- Transaction TX-0097 (MISSED_PAYMENT - Loan #14 Bornali Deka - Seq 6)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 14 AND seq_no = 6;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 14 AND seq_no = 6), status = CASE WHEN 6 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 14;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0097', 'MISSED_INSTALLMENT', 14, 14, 2, 447.75, 'FIELD', 'GW-TX-0097', 'OVERDUE', 'Unpaid default; propagates 33.33% liability to co-guarantors', '2026-05-03 08:35:54+05:30', '2026-05-03 08:35:54+05:30');

  -- Transaction TX-0098 (DISBURSEMENT - Loan #15 Rumi Choudhury - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0098', 'LOAN_DISBURSEMENT', 15, 15, 2, 50000.00, 'BANK_TRANSFER', 'GW-TX-0098', 'SUCCESS', '2026-01-31 22:31:59+05:30', '2026-01-31 22:31:59+05:30');

  -- Transaction TX-0099 (REPAYMENT - Loan #15 Rumi Choudhury - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (15, v_user_id, 1073.21, '2026-02-08 08:31:59+05:30', '71e2a3df-5ae4-4f32-bbb0-1c42f269a957', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 15 AND seq_no = 1;
  v_rem_amt := 1073.21;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 15) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 15));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 15;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 15) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 15));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 15;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 15 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-02-08 08:31:59+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 15, 'CASH', 1073.21, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 15, 'CASH', 1073.21, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 15, 'LOAN_PORTFOLIO', 0.00, 1073.21, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 15, 'LOAN_PORTFOLIO', 0.00, 1073.21, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0099', 'REPAYMENT', 15, 15, 2, 1073.21, 'CASH', 'GW-TX-0099', 'SUCCESS', v_repayment_id, '2026-02-08 08:31:59+05:30', '2026-02-08 08:31:59+05:30');

  -- Transaction TX-0100 (MISSED_PAYMENT - Loan #15 Rumi Choudhury - Seq 2)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 15 AND seq_no = 2;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 15 AND seq_no = 2), status = CASE WHEN 2 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 15;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0100', 'MISSED_INSTALLMENT', 15, 15, 2, 1073.21, 'FIELD', 'GW-TX-0100', 'OVERDUE', 'Borrower absent at center meeting; late fee ₹50 accrued', '2026-02-15 18:31:59+05:30', '2026-02-15 18:31:59+05:30');

  -- Transaction TX-0101 (REPAYMENT - Loan #15 Rumi Choudhury - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (15, v_user_id, 2196.42, '2026-02-22 09:31:59+05:30', 'ff3955a1-89c3-4ee8-9f4a-8724b616331a', 'BRANCH')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 15 AND seq_no = 3;
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 15 AND seq_no = 2;
  v_rem_amt := 2196.42;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 15) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 15));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 15;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 15) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 15));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 15;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 15 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-02-22 09:31:59+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 15, 'CASH', 2196.42, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 15, 'CASH', 2196.42, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 15, 'LOAN_PORTFOLIO', 0.00, 2196.42, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 15, 'LOAN_PORTFOLIO', 0.00, 2196.42, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0101', 'REPAYMENT', 15, 15, 2, 2196.42, 'CASH', 'GW-TX-0101', 'SUCCESS', v_repayment_id, '2026-02-22 09:31:59+05:30', '2026-02-22 09:31:59+05:30');

  -- Transaction TX-0102 (REPAYMENT - Loan #15 Rumi Choudhury - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (15, v_user_id, 1073.21, '2026-03-01 08:31:59+05:30', '62f65690-df6f-4db0-b5c4-ffd880082f3c', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 15 AND seq_no = 4;
  v_rem_amt := 1073.21;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 15) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 15));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 15;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 15) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 15));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 15;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 15 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-03-01 08:31:59+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 15, 'CASH', 1073.21, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 15, 'CASH', 1073.21, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 15, 'LOAN_PORTFOLIO', 0.00, 1073.21, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 15, 'LOAN_PORTFOLIO', 0.00, 1073.21, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0102', 'REPAYMENT', 15, 15, 2, 1073.21, 'CASH', 'GW-TX-0102', 'SUCCESS', v_repayment_id, '2026-03-01 08:31:59+05:30', '2026-03-01 08:31:59+05:30');

  -- Transaction TX-0103 (REPAYMENT - Loan #15 Rumi Choudhury - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (15, v_user_id, 1073.21, '2026-03-08 08:31:59+05:30', '38486189-6da5-40bc-a7ae-03cdf8c81f73', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 15 AND seq_no = 5;
  v_rem_amt := 1073.21;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 15) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 15));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 15;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 15) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 15));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 15;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 15 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-03-08 08:31:59+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 15, 'CASH', 1073.21, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 15, 'CASH', 1073.21, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 15, 'LOAN_PORTFOLIO', 0.00, 1073.21, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 15, 'LOAN_PORTFOLIO', 0.00, 1073.21, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0103', 'REPAYMENT', 15, 15, 2, 1073.21, 'CASH', 'GW-TX-0103', 'SUCCESS', v_repayment_id, '2026-03-08 08:31:59+05:30', '2026-03-08 08:31:59+05:30');

  -- Transaction TX-0104 (REPAYMENT - Loan #15 Rumi Choudhury - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (15, v_user_id, 1073.21, '2026-03-15 08:31:59+05:30', 'd18998a7-204d-4a7d-a8d8-8c99d25071f3', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 15 AND seq_no = 6;
  v_rem_amt := 1073.21;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 15) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 15));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 15;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 15) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 15));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 15;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 15 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-03-15 08:31:59+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 15, 'CASH', 1073.21, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 15, 'CASH', 1073.21, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 15, 'LOAN_PORTFOLIO', 0.00, 1073.21, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 15, 'LOAN_PORTFOLIO', 0.00, 1073.21, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0104', 'REPAYMENT', 15, 15, 2, 1073.21, 'CASH', 'GW-TX-0104', 'SUCCESS', v_repayment_id, '2026-03-15 08:31:59+05:30', '2026-03-15 08:31:59+05:30');

  -- Transaction TX-0105 (DISBURSEMENT - Loan #16 Sunita Sarma - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0105', 'LOAN_DISBURSEMENT', 16, 16, 2, 12000.00, 'BANK_TRANSFER', 'GW-TX-0105', 'SUCCESS', '2026-07-31 04:41:23+05:30', '2026-07-31 04:41:23+05:30');

  -- Transaction TX-0106 (REPAYMENT - Loan #16 Sunita Sarma - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (16, v_user_id, 525.01, '2026-08-07 19:41:23+05:30', '758f1ad6-0fac-47c8-a942-d3f64d8574a9', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 16 AND seq_no = 1;
  v_rem_amt := 525.01;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 16) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 16));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 16;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 16) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 16));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 16;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 16 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-07 19:41:23+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 16, 'CASH', 525.01, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 16, 'CASH', 525.01, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 16, 'LOAN_PORTFOLIO', 0.00, 525.01, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 16, 'LOAN_PORTFOLIO', 0.00, 525.01, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0106', 'REPAYMENT', 16, 16, 2, 525.01, 'CASH', 'GW-TX-0106', 'SUCCESS', v_repayment_id, '2026-08-07 19:41:23+05:30', '2026-08-07 19:41:23+05:30');

  -- Transaction TX-0107 (REPAYMENT - Loan #16 Sunita Sarma - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (16, v_user_id, 525.01, '2026-08-14 15:41:23+05:30', '80b56380-33f7-4110-97a4-4f4a31081f92', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 16 AND seq_no = 2;
  v_rem_amt := 525.01;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 16) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 16));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 16;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 16) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 16));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 16;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 16 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-14 15:41:23+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 16, 'CASH', 525.01, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 16, 'CASH', 525.01, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 16, 'LOAN_PORTFOLIO', 0.00, 525.01, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 16, 'LOAN_PORTFOLIO', 0.00, 525.01, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0107', 'REPAYMENT', 16, 16, 2, 525.01, 'CASH', 'GW-TX-0107', 'SUCCESS', v_repayment_id, '2026-08-14 15:41:23+05:30', '2026-08-14 15:41:23+05:30');

  -- Transaction TX-0108 (REPAYMENT - Loan #16 Sunita Sarma - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (16, v_user_id, 525.01, '2026-08-21 20:41:23+05:30', '645a534d-b66b-4a15-83a2-6abfefe813db', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 16 AND seq_no = 3;
  v_rem_amt := 525.01;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 16) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 16));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 16;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 16) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 16));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 16;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 16 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-21 20:41:23+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 16, 'CASH', 525.01, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 16, 'CASH', 525.01, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 16, 'LOAN_PORTFOLIO', 0.00, 525.01, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 16, 'LOAN_PORTFOLIO', 0.00, 525.01, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0108', 'REPAYMENT', 16, 16, 2, 525.01, 'CASH', 'GW-TX-0108', 'SUCCESS', v_repayment_id, '2026-08-21 20:41:23+05:30', '2026-08-21 20:41:23+05:30');

  -- Transaction TX-0109 (REPAYMENT - Loan #16 Sunita Sarma - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (16, v_user_id, 525.01, '2026-08-28 19:41:23+05:30', 'f62b6b99-3e8c-45bf-b3bf-21be96bd6730', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 16 AND seq_no = 4;
  v_rem_amt := 525.01;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 16) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 16));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 16;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 16) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 16));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 16;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 16 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-28 19:41:23+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 16, 'CASH', 525.01, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 16, 'CASH', 525.01, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 16, 'LOAN_PORTFOLIO', 0.00, 525.01, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 16, 'LOAN_PORTFOLIO', 0.00, 525.01, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0109', 'REPAYMENT', 16, 16, 2, 525.01, 'ONLINE_UPI', 'GW-TX-0109', 'SUCCESS', v_repayment_id, '2026-08-28 19:41:23+05:30', '2026-08-28 19:41:23+05:30');

  -- Transaction TX-0110 (REPAYMENT - Loan #16 Sunita Sarma - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (16, v_user_id, 525.01, '2026-09-04 18:41:23+05:30', '873b7949-8930-4ac9-ab62-793c958fcef5', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 16 AND seq_no = 5;
  v_rem_amt := 525.01;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 16) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 16));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 16;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 16) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 16));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 16;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 16 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-09-04 18:41:23+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 16, 'CASH', 525.01, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 16, 'CASH', 525.01, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 16, 'LOAN_PORTFOLIO', 0.00, 525.01, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 16, 'LOAN_PORTFOLIO', 0.00, 525.01, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0110', 'REPAYMENT', 16, 16, 2, 525.01, 'ONLINE_UPI', 'GW-TX-0110', 'SUCCESS', v_repayment_id, '2026-09-04 18:41:23+05:30', '2026-09-04 18:41:23+05:30');

  -- Transaction TX-0111 (REPAYMENT - Loan #16 Sunita Sarma - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (16, v_user_id, 525.01, '2026-09-11 15:41:23+05:30', '61aac92f-d298-4022-92f3-08df30ad7cf1', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 16 AND seq_no = 6;
  v_rem_amt := 525.01;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 16) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 16));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 16;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 16) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 16));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 16;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 16 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-09-11 15:41:23+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 16, 'CASH', 525.01, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 16, 'CASH', 525.01, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 16, 'LOAN_PORTFOLIO', 0.00, 525.01, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 16, 'LOAN_PORTFOLIO', 0.00, 525.01, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0111', 'REPAYMENT', 16, 16, 2, 525.01, 'ONLINE_UPI', 'GW-TX-0111', 'SUCCESS', v_repayment_id, '2026-09-11 15:41:23+05:30', '2026-09-11 15:41:23+05:30');

  -- Transaction TX-0112 (DISBURSEMENT - Loan #17 Bina Sarma - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0112', 'LOAN_DISBURSEMENT', 17, 17, 2, 34000.00, 'BANK_TRANSFER', 'GW-TX-0112', 'SUCCESS', '2026-05-14 16:28:19+05:30', '2026-05-14 16:28:19+05:30');

  -- Transaction TX-0113 (REPAYMENT - Loan #17 Bina Sarma - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (17, v_user_id, 1423.79, '2026-05-22 04:28:19+05:30', '7c4f1193-3e1e-40ac-9bfa-48ae206e18d9', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 17 AND seq_no = 1;
  v_rem_amt := 1423.79;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 17) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 17));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 17;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 17) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 17));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 17;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 17 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-05-22 04:28:19+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 17, 'CASH', 1423.79, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 17, 'CASH', 1423.79, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 17, 'LOAN_PORTFOLIO', 0.00, 1423.79, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 17, 'LOAN_PORTFOLIO', 0.00, 1423.79, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0113', 'REPAYMENT', 17, 17, 2, 1423.79, 'CASH', 'GW-TX-0113', 'SUCCESS', v_repayment_id, '2026-05-22 04:28:19+05:30', '2026-05-22 04:28:19+05:30');

  -- Transaction TX-0114 (REPAYMENT - Loan #17 Bina Sarma - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (17, v_user_id, 1423.79, '2026-05-29 02:28:19+05:30', '435d7b50-c339-40d8-8e67-fc837e9d456a', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 17 AND seq_no = 2;
  v_rem_amt := 1423.79;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 17) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 17));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 17;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 17) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 17));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 17;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 17 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-05-29 02:28:19+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 17, 'CASH', 1423.79, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 17, 'CASH', 1423.79, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 17, 'LOAN_PORTFOLIO', 0.00, 1423.79, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 17, 'LOAN_PORTFOLIO', 0.00, 1423.79, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0114', 'REPAYMENT', 17, 17, 2, 1423.79, 'ONLINE_UPI', 'GW-TX-0114', 'SUCCESS', v_repayment_id, '2026-05-29 02:28:19+05:30', '2026-05-29 02:28:19+05:30');

  -- Transaction TX-0115 (REPAYMENT - Loan #17 Bina Sarma - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (17, v_user_id, 1423.79, '2026-06-05 02:28:19+05:30', '678d9731-7e37-417a-961e-2e12926cf11c', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 17 AND seq_no = 3;
  v_rem_amt := 1423.79;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 17) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 17));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 17;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 17) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 17));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 17;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 17 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-05 02:28:19+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 17, 'CASH', 1423.79, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 17, 'CASH', 1423.79, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 17, 'LOAN_PORTFOLIO', 0.00, 1423.79, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 17, 'LOAN_PORTFOLIO', 0.00, 1423.79, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0115', 'REPAYMENT', 17, 17, 2, 1423.79, 'CASH', 'GW-TX-0115', 'SUCCESS', v_repayment_id, '2026-06-05 02:28:19+05:30', '2026-06-05 02:28:19+05:30');

  -- Transaction TX-0116 (REPAYMENT - Loan #17 Bina Sarma - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (17, v_user_id, 1423.79, '2026-06-12 05:28:19+05:30', 'b6e63fb3-2bee-411f-86b9-a69f99c582d6', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 17 AND seq_no = 4;
  v_rem_amt := 1423.79;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 17) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 17));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 17;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 17) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 17));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 17;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 17 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-12 05:28:19+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 17, 'CASH', 1423.79, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 17, 'CASH', 1423.79, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 17, 'LOAN_PORTFOLIO', 0.00, 1423.79, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 17, 'LOAN_PORTFOLIO', 0.00, 1423.79, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0116', 'REPAYMENT', 17, 17, 2, 1423.79, 'ONLINE_UPI', 'GW-TX-0116', 'SUCCESS', v_repayment_id, '2026-06-12 05:28:19+05:30', '2026-06-12 05:28:19+05:30');

  -- Transaction TX-0117 (REPAYMENT - Loan #17 Bina Sarma - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (17, v_user_id, 1423.79, '2026-06-19 04:28:19+05:30', '4cd0d0c8-0365-441e-bce2-273ae57786ba', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 17 AND seq_no = 5;
  v_rem_amt := 1423.79;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 17) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 17));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 17;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 17) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 17));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 17;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 17 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-19 04:28:19+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 17, 'CASH', 1423.79, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 17, 'CASH', 1423.79, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 17, 'LOAN_PORTFOLIO', 0.00, 1423.79, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 17, 'LOAN_PORTFOLIO', 0.00, 1423.79, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0117', 'REPAYMENT', 17, 17, 2, 1423.79, 'CASH', 'GW-TX-0117', 'SUCCESS', v_repayment_id, '2026-06-19 04:28:19+05:30', '2026-06-19 04:28:19+05:30');

  -- Transaction TX-0118 (REPAYMENT - Loan #17 Bina Sarma - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (17, v_user_id, 1423.79, '2026-06-26 06:28:19+05:30', 'b9383b14-4222-4042-8641-4db1353ac383', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 17 AND seq_no = 6;
  v_rem_amt := 1423.79;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 17) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 17));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 17;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 17) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 17));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 17;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 17 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-26 06:28:19+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 17, 'CASH', 1423.79, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 17, 'CASH', 1423.79, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 17, 'LOAN_PORTFOLIO', 0.00, 1423.79, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 17, 'LOAN_PORTFOLIO', 0.00, 1423.79, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0118', 'REPAYMENT', 17, 17, 2, 1423.79, 'ONLINE_UPI', 'GW-TX-0118', 'SUCCESS', v_repayment_id, '2026-06-26 06:28:19+05:30', '2026-06-26 06:28:19+05:30');

  -- Transaction TX-0119 (DISBURSEMENT - Loan #18 Runjun Deka - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0119', 'LOAN_DISBURSEMENT', 18, 18, 2, 15000.00, 'BANK_TRANSFER', 'GW-TX-0119', 'SUCCESS', '2026-10-17 03:20:21+05:30', '2026-10-17 03:20:21+05:30');

  -- Transaction TX-0120 (REPAYMENT - Loan #18 Runjun Deka - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (18, v_user_id, 343.61, '2026-10-24 17:20:21+05:30', '00b730a1-2e8d-4475-a188-a03a6eab53b7', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 18 AND seq_no = 1;
  v_rem_amt := 343.61;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 18) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 18));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 18;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 18) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 18));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 18;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 18 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-24 17:20:21+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 18, 'CASH', 343.61, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 18, 'CASH', 343.61, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 18, 'LOAN_PORTFOLIO', 0.00, 343.61, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 18, 'LOAN_PORTFOLIO', 0.00, 343.61, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0120', 'REPAYMENT', 18, 18, 2, 343.61, 'CASH', 'GW-TX-0120', 'SUCCESS', v_repayment_id, '2026-10-24 17:20:21+05:30', '2026-10-24 17:20:21+05:30');

  -- Transaction TX-0121 (REPAYMENT - Loan #18 Runjun Deka - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (18, v_user_id, 343.61, '2026-10-31 14:20:21+05:30', 'ccfdc492-abe2-4254-b112-7cb739890ee1', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 18 AND seq_no = 2;
  v_rem_amt := 343.61;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 18) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 18));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 18;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 18) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 18));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 18;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 18 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-31 14:20:21+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 18, 'CASH', 343.61, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 18, 'CASH', 343.61, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 18, 'LOAN_PORTFOLIO', 0.00, 343.61, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 18, 'LOAN_PORTFOLIO', 0.00, 343.61, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0121', 'REPAYMENT', 18, 18, 2, 343.61, 'ONLINE_UPI', 'GW-TX-0121', 'SUCCESS', v_repayment_id, '2026-10-31 14:20:21+05:30', '2026-10-31 14:20:21+05:30');

  -- Transaction TX-0122 (REPAYMENT - Loan #18 Runjun Deka - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (18, v_user_id, 343.61, '2026-11-07 17:20:21+05:30', 'bddde818-9266-48c0-a8b2-402e73c6b151', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 18 AND seq_no = 3;
  v_rem_amt := 343.61;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 18) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 18));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 18;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 18) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 18));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 18;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 18 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-11-07 17:20:21+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 18, 'CASH', 343.61, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 18, 'CASH', 343.61, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 18, 'LOAN_PORTFOLIO', 0.00, 343.61, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 18, 'LOAN_PORTFOLIO', 0.00, 343.61, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0122', 'REPAYMENT', 18, 18, 2, 343.61, 'CASH', 'GW-TX-0122', 'SUCCESS', v_repayment_id, '2026-11-07 17:20:21+05:30', '2026-11-07 17:20:21+05:30');

  -- Transaction TX-0123 (REPAYMENT - Loan #18 Runjun Deka - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (18, v_user_id, 343.61, '2026-11-14 16:20:21+05:30', '8621dc59-bafd-4f0f-a8a1-7f1e2e648d1d', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 18 AND seq_no = 4;
  v_rem_amt := 343.61;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 18) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 18));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 18;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 18) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 18));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 18;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 18 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-11-14 16:20:21+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 18, 'CASH', 343.61, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 18, 'CASH', 343.61, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 18, 'LOAN_PORTFOLIO', 0.00, 343.61, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 18, 'LOAN_PORTFOLIO', 0.00, 343.61, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0123', 'REPAYMENT', 18, 18, 2, 343.61, 'CASH', 'GW-TX-0123', 'SUCCESS', v_repayment_id, '2026-11-14 16:20:21+05:30', '2026-11-14 16:20:21+05:30');

  -- Transaction TX-0124 (REPAYMENT - Loan #18 Runjun Deka - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (18, v_user_id, 343.61, '2026-11-21 13:20:21+05:30', 'bc70625f-dbc9-4046-b34e-0b233ca9d230', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 18 AND seq_no = 5;
  v_rem_amt := 343.61;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 18) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 18));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 18;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 18) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 18));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 18;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 18 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-11-21 13:20:21+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 18, 'CASH', 343.61, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 18, 'CASH', 343.61, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 18, 'LOAN_PORTFOLIO', 0.00, 343.61, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 18, 'LOAN_PORTFOLIO', 0.00, 343.61, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0124', 'REPAYMENT', 18, 18, 2, 343.61, 'ONLINE_UPI', 'GW-TX-0124', 'SUCCESS', v_repayment_id, '2026-11-21 13:20:21+05:30', '2026-11-21 13:20:21+05:30');

  -- Transaction TX-0125 (DISBURSEMENT - Loan #19 Sunita Bora - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0125', 'LOAN_DISBURSEMENT', 19, 19, 2, 12000.00, 'BANK_TRANSFER', 'GW-TX-0125', 'SUCCESS', '2026-09-15 17:27:11+05:30', '2026-09-15 17:27:11+05:30');

  -- Transaction TX-0126 (REPAYMENT - Loan #19 Sunita Bora - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (19, v_user_id, 355.73, '2026-09-23 03:27:11+05:30', '4da6e0a1-d480-4c1b-bcb0-71b7e5494245', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 19 AND seq_no = 1;
  v_rem_amt := 355.73;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 19) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 19));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 19;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 19) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 19));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 19;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 19 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-09-23 03:27:11+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 19, 'CASH', 355.73, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 19, 'CASH', 355.73, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 19, 'LOAN_PORTFOLIO', 0.00, 355.73, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 19, 'LOAN_PORTFOLIO', 0.00, 355.73, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0126', 'REPAYMENT', 19, 19, 2, 355.73, 'CASH', 'GW-TX-0126', 'SUCCESS', v_repayment_id, '2026-09-23 03:27:11+05:30', '2026-09-23 03:27:11+05:30');

  -- Transaction TX-0127 (MISSED_PAYMENT - Loan #19 Sunita Bora - Seq 2)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 19 AND seq_no = 2;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 19 AND seq_no = 2), status = CASE WHEN 2 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 19;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0127', 'MISSED_INSTALLMENT', 19, 19, 2, 355.73, 'FIELD', 'GW-TX-0127', 'OVERDUE', 'Borrower absent at center meeting; late fee ₹50 accrued', '2026-09-30 13:27:11+05:30', '2026-09-30 13:27:11+05:30');

  -- Transaction TX-0128 (REPAYMENT - Loan #19 Sunita Bora - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (19, v_user_id, 761.46, '2026-10-07 04:27:11+05:30', 'b8d2fb40-de33-4bc7-a5de-9ae5b5132ec1', 'BRANCH')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 19 AND seq_no = 3;
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 19 AND seq_no = 2;
  v_rem_amt := 761.46;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 19) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 19));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 19;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 19) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 19));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 19;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 19 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-07 04:27:11+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 19, 'CASH', 761.46, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 19, 'CASH', 761.46, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 19, 'LOAN_PORTFOLIO', 0.00, 761.46, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 19, 'LOAN_PORTFOLIO', 0.00, 761.46, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0128', 'REPAYMENT', 19, 19, 2, 761.46, 'CASH', 'GW-TX-0128', 'SUCCESS', v_repayment_id, '2026-10-07 04:27:11+05:30', '2026-10-07 04:27:11+05:30');

  -- Transaction TX-0129 (REPAYMENT - Loan #19 Sunita Bora - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (19, v_user_id, 355.73, '2026-10-14 03:27:11+05:30', 'e9c0c8ba-c753-4fcf-b552-0bba32517560', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 19 AND seq_no = 4;
  v_rem_amt := 355.73;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 19) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 19));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 19;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 19) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 19));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 19;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 19 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-14 03:27:11+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 19, 'CASH', 355.73, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 19, 'CASH', 355.73, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 19, 'LOAN_PORTFOLIO', 0.00, 355.73, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 19, 'LOAN_PORTFOLIO', 0.00, 355.73, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0129', 'REPAYMENT', 19, 19, 2, 355.73, 'CASH', 'GW-TX-0129', 'SUCCESS', v_repayment_id, '2026-10-14 03:27:11+05:30', '2026-10-14 03:27:11+05:30');

  -- Transaction TX-0130 (REPAYMENT - Loan #19 Sunita Bora - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (19, v_user_id, 355.73, '2026-10-21 03:27:11+05:30', '3ef84b5a-0b2f-4845-a680-b94b21c78744', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 19 AND seq_no = 5;
  v_rem_amt := 355.73;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 19) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 19));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 19;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 19) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 19));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 19;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 19 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-21 03:27:11+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 19, 'CASH', 355.73, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 19, 'CASH', 355.73, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 19, 'LOAN_PORTFOLIO', 0.00, 355.73, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 19, 'LOAN_PORTFOLIO', 0.00, 355.73, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0130', 'REPAYMENT', 19, 19, 2, 355.73, 'CASH', 'GW-TX-0130', 'SUCCESS', v_repayment_id, '2026-10-21 03:27:11+05:30', '2026-10-21 03:27:11+05:30');

  -- Transaction TX-0131 (REPAYMENT - Loan #19 Sunita Bora - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (19, v_user_id, 355.73, '2026-10-28 03:27:11+05:30', '072aec5b-7c68-4862-a71f-a7d81d49fef7', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 19 AND seq_no = 6;
  v_rem_amt := 355.73;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 19) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 19));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 19;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 19) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 19));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 19;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 19 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-28 03:27:11+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 19, 'CASH', 355.73, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 19, 'CASH', 355.73, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 19, 'LOAN_PORTFOLIO', 0.00, 355.73, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 19, 'LOAN_PORTFOLIO', 0.00, 355.73, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0131', 'REPAYMENT', 19, 19, 2, 355.73, 'CASH', 'GW-TX-0131', 'SUCCESS', v_repayment_id, '2026-10-28 03:27:11+05:30', '2026-10-28 03:27:11+05:30');

  -- Transaction TX-0132 (DISBURSEMENT - Loan #20 Papori Medhi - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0132', 'LOAN_DISBURSEMENT', 20, 20, 2, 13000.00, 'BANK_TRANSFER', 'GW-TX-0132', 'SUCCESS', '2026-07-09 03:21:26+05:30', '2026-07-09 03:21:26+05:30');

  -- Transaction TX-0133 (REPAYMENT - Loan #20 Papori Medhi - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (20, v_user_id, 567.42, '2026-07-16 13:21:26+05:30', 'ea891b27-7049-4667-bbe4-52a7341b9a54', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 20 AND seq_no = 1;
  v_rem_amt := 567.42;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 20) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 20));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 20;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 20) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 20));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 20;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 20 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-16 13:21:26+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 20, 'CASH', 567.42, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 20, 'CASH', 567.42, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 20, 'LOAN_PORTFOLIO', 0.00, 567.42, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 20, 'LOAN_PORTFOLIO', 0.00, 567.42, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0133', 'REPAYMENT', 20, 20, 2, 567.42, 'CASH', 'GW-TX-0133', 'SUCCESS', v_repayment_id, '2026-07-16 13:21:26+05:30', '2026-07-16 13:21:26+05:30');

  -- Transaction TX-0134 (MISSED_PAYMENT - Loan #20 Papori Medhi - Seq 2)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 20 AND seq_no = 2;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 20 AND seq_no = 2), status = CASE WHEN 2 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 20;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0134', 'MISSED_INSTALLMENT', 20, 20, 2, 567.42, 'FIELD', 'GW-TX-0134', 'OVERDUE', 'Borrower absent at center meeting; late fee ₹50 accrued', '2026-07-23 23:21:26+05:30', '2026-07-23 23:21:26+05:30');

  -- Transaction TX-0135 (REPAYMENT - Loan #20 Papori Medhi - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (20, v_user_id, 1184.84, '2026-07-30 14:21:26+05:30', 'fa7f0392-a1e9-4ac0-86b3-9925848a0021', 'BRANCH')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 20 AND seq_no = 3;
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 20 AND seq_no = 2;
  v_rem_amt := 1184.84;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 20) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 20));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 20;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 20) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 20));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 20;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 20 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-30 14:21:26+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 20, 'CASH', 1184.84, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 20, 'CASH', 1184.84, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 20, 'LOAN_PORTFOLIO', 0.00, 1184.84, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 20, 'LOAN_PORTFOLIO', 0.00, 1184.84, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0135', 'REPAYMENT', 20, 20, 2, 1184.84, 'CASH', 'GW-TX-0135', 'SUCCESS', v_repayment_id, '2026-07-30 14:21:26+05:30', '2026-07-30 14:21:26+05:30');

  -- Transaction TX-0136 (REPAYMENT - Loan #20 Papori Medhi - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (20, v_user_id, 567.42, '2026-08-06 13:21:26+05:30', '2f17b59b-fe0d-48ad-bc51-32f4d89ac34c', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 20 AND seq_no = 4;
  v_rem_amt := 567.42;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 20) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 20));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 20;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 20) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 20));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 20;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 20 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-06 13:21:26+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 20, 'CASH', 567.42, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 20, 'CASH', 567.42, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 20, 'LOAN_PORTFOLIO', 0.00, 567.42, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 20, 'LOAN_PORTFOLIO', 0.00, 567.42, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0136', 'REPAYMENT', 20, 20, 2, 567.42, 'CASH', 'GW-TX-0136', 'SUCCESS', v_repayment_id, '2026-08-06 13:21:26+05:30', '2026-08-06 13:21:26+05:30');

  -- Transaction TX-0137 (REPAYMENT - Loan #20 Papori Medhi - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (20, v_user_id, 567.42, '2026-08-13 13:21:26+05:30', 'cb866cee-e155-4c25-8d44-f9506d8e5180', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 20 AND seq_no = 5;
  v_rem_amt := 567.42;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 20) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 20));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 20;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 20) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 20));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 20;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 20 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-13 13:21:26+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 20, 'CASH', 567.42, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 20, 'CASH', 567.42, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 20, 'LOAN_PORTFOLIO', 0.00, 567.42, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 20, 'LOAN_PORTFOLIO', 0.00, 567.42, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0137', 'REPAYMENT', 20, 20, 2, 567.42, 'CASH', 'GW-TX-0137', 'SUCCESS', v_repayment_id, '2026-08-13 13:21:26+05:30', '2026-08-13 13:21:26+05:30');

  -- Transaction TX-0138 (REPAYMENT - Loan #20 Papori Medhi - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 2 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (20, v_user_id, 567.42, '2026-08-20 13:21:26+05:30', '4e3a7c7e-6646-4f95-999b-751b1dd0ff60', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 20 AND seq_no = 6;
  v_rem_amt := 567.42;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 20) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 20));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 20;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 20) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 20));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 20;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 20 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 2 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-20 13:21:26+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 20, 'CASH', 567.42, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 20, 'CASH', 567.42, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 20, 'LOAN_PORTFOLIO', 0.00, 567.42, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (2, v_repayment_id, 20, 'LOAN_PORTFOLIO', 0.00, 567.42, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0138', 'REPAYMENT', 20, 20, 2, 567.42, 'CASH', 'GW-TX-0138', 'SUCCESS', v_repayment_id, '2026-08-20 13:21:26+05:30', '2026-08-20 13:21:26+05:30');

  -- Transaction TX-0139 (DISBURSEMENT - Loan #21 Papori Gogoi - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0139', 'LOAN_DISBURSEMENT', 21, 21, 3, 24500.00, 'BANK_TRANSFER', 'GW-TX-0139', 'SUCCESS', '2026-07-01 12:04:56+05:30', '2026-07-01 12:04:56+05:30');

  -- Transaction TX-0140 (REPAYMENT - Loan #21 Papori Gogoi - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (21, v_user_id, 726.28, '2026-07-09 02:04:56+05:30', '1f32bef2-17bc-4fa9-8e3f-4bd76f0c489c', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 21 AND seq_no = 1;
  v_rem_amt := 726.28;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 21) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 21));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 21;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 21) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 21));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 21;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 21 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-09 02:04:56+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 21, 'CASH', 726.28, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 21, 'CASH', 726.28, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 21, 'LOAN_PORTFOLIO', 0.00, 726.28, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 21, 'LOAN_PORTFOLIO', 0.00, 726.28, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0140', 'REPAYMENT', 21, 21, 3, 726.28, 'ONLINE_UPI', 'GW-TX-0140', 'SUCCESS', v_repayment_id, '2026-07-09 02:04:56+05:30', '2026-07-09 02:04:56+05:30');

  -- Transaction TX-0141 (REPAYMENT - Loan #21 Papori Gogoi - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (21, v_user_id, 726.28, '2026-07-16 04:04:56+05:30', '25bcc5b4-fc24-4400-beb4-0a4be4a5745f', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 21 AND seq_no = 2;
  v_rem_amt := 726.28;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 21) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 21));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 21;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 21) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 21));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 21;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 21 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-16 04:04:56+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 21, 'CASH', 726.28, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 21, 'CASH', 726.28, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 21, 'LOAN_PORTFOLIO', 0.00, 726.28, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 21, 'LOAN_PORTFOLIO', 0.00, 726.28, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0141', 'REPAYMENT', 21, 21, 3, 726.28, 'CASH', 'GW-TX-0141', 'SUCCESS', v_repayment_id, '2026-07-16 04:04:56+05:30', '2026-07-16 04:04:56+05:30');

  -- Transaction TX-0142 (REPAYMENT - Loan #21 Papori Gogoi - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (21, v_user_id, 726.28, '2026-07-22 22:04:56+05:30', '1a5f0e61-83d1-4984-926e-b198e5e9a211', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 21 AND seq_no = 3;
  v_rem_amt := 726.28;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 21) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 21));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 21;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 21) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 21));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 21;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 21 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-22 22:04:56+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 21, 'CASH', 726.28, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 21, 'CASH', 726.28, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 21, 'LOAN_PORTFOLIO', 0.00, 726.28, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 21, 'LOAN_PORTFOLIO', 0.00, 726.28, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0142', 'REPAYMENT', 21, 21, 3, 726.28, 'CASH', 'GW-TX-0142', 'SUCCESS', v_repayment_id, '2026-07-22 22:04:56+05:30', '2026-07-22 22:04:56+05:30');

  -- Transaction TX-0143 (REPAYMENT - Loan #21 Papori Gogoi - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (21, v_user_id, 726.28, '2026-07-30 00:04:56+05:30', 'a50333e7-6ca3-4f23-9be2-0f7b2147d364', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 21 AND seq_no = 4;
  v_rem_amt := 726.28;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 21) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 21));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 21;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 21) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 21));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 21;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 21 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-30 00:04:56+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 21, 'CASH', 726.28, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 21, 'CASH', 726.28, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 21, 'LOAN_PORTFOLIO', 0.00, 726.28, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 21, 'LOAN_PORTFOLIO', 0.00, 726.28, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0143', 'REPAYMENT', 21, 21, 3, 726.28, 'CASH', 'GW-TX-0143', 'SUCCESS', v_repayment_id, '2026-07-30 00:04:56+05:30', '2026-07-30 00:04:56+05:30');

  -- Transaction TX-0144 (REPAYMENT - Loan #21 Papori Gogoi - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (21, v_user_id, 726.28, '2026-08-05 21:04:56+05:30', 'a65c8c7a-583b-4914-a21a-8a95652c867c', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 21 AND seq_no = 5;
  v_rem_amt := 726.28;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 21) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 21));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 21;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 21) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 21));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 21;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 21 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-05 21:04:56+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 21, 'CASH', 726.28, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 21, 'CASH', 726.28, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 21, 'LOAN_PORTFOLIO', 0.00, 726.28, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 21, 'LOAN_PORTFOLIO', 0.00, 726.28, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0144', 'REPAYMENT', 21, 21, 3, 726.28, 'ONLINE_UPI', 'GW-TX-0144', 'SUCCESS', v_repayment_id, '2026-08-05 21:04:56+05:30', '2026-08-05 21:04:56+05:30');

  -- Transaction TX-0145 (REPAYMENT - Loan #21 Papori Gogoi - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (21, v_user_id, 726.28, '2026-08-13 03:04:56+05:30', 'f6719f0d-521e-4fa2-9b6d-6766a4fb4cae', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 21 AND seq_no = 6;
  v_rem_amt := 726.28;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 21) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 21));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 21;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 21) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 21));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 21;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 21 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-13 03:04:56+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 21, 'CASH', 726.28, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 21, 'CASH', 726.28, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 21, 'LOAN_PORTFOLIO', 0.00, 726.28, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 21, 'LOAN_PORTFOLIO', 0.00, 726.28, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0145', 'REPAYMENT', 21, 21, 3, 726.28, 'ONLINE_UPI', 'GW-TX-0145', 'SUCCESS', v_repayment_id, '2026-08-13 03:04:56+05:30', '2026-08-13 03:04:56+05:30');

  -- Transaction TX-0146 (DISBURSEMENT - Loan #22 Monika Talukdar - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0146', 'LOAN_DISBURSEMENT', 22, 22, 3, 35500.00, 'BANK_TRANSFER', 'GW-TX-0146', 'SUCCESS', '2026-06-11 13:20:35+05:30', '2026-06-11 13:20:35+05:30');

  -- Transaction TX-0147 (REPAYMENT - Loan #22 Monika Talukdar - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (22, v_user_id, 1468.42, '2026-06-18 23:20:35+05:30', '61a67cff-be1f-4381-8965-97cef5116f94', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 22 AND seq_no = 1;
  v_rem_amt := 1468.42;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 22) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 22));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 22;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 22) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 22));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 22;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 22 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-18 23:20:35+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 22, 'CASH', 1468.42, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 22, 'CASH', 1468.42, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 22, 'LOAN_PORTFOLIO', 0.00, 1468.42, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 22, 'LOAN_PORTFOLIO', 0.00, 1468.42, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0147', 'REPAYMENT', 22, 22, 3, 1468.42, 'CASH', 'GW-TX-0147', 'SUCCESS', v_repayment_id, '2026-06-18 23:20:35+05:30', '2026-06-18 23:20:35+05:30');

  -- Transaction TX-0148 (REPAYMENT - Loan #22 Monika Talukdar - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (22, v_user_id, 1468.42, '2026-06-25 23:20:35+05:30', 'decb987e-80e4-420f-812f-4c0edf1e2c80', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 22 AND seq_no = 2;
  v_rem_amt := 1468.42;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 22) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 22));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 22;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 22) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 22));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 22;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 22 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-25 23:20:35+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 22, 'CASH', 1468.42, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 22, 'CASH', 1468.42, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 22, 'LOAN_PORTFOLIO', 0.00, 1468.42, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 22, 'LOAN_PORTFOLIO', 0.00, 1468.42, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0148', 'REPAYMENT', 22, 22, 3, 1468.42, 'CASH', 'GW-TX-0148', 'SUCCESS', v_repayment_id, '2026-06-25 23:20:35+05:30', '2026-06-25 23:20:35+05:30');

  -- Transaction TX-0149 (REPAYMENT - Loan #22 Monika Talukdar - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (22, v_user_id, 1468.42, '2026-07-02 23:20:35+05:30', 'dd19922a-afdf-41a2-b8f7-b6f262a4d75f', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 22 AND seq_no = 3;
  v_rem_amt := 1468.42;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 22) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 22));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 22;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 22) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 22));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 22;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 22 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-02 23:20:35+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 22, 'CASH', 1468.42, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 22, 'CASH', 1468.42, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 22, 'LOAN_PORTFOLIO', 0.00, 1468.42, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 22, 'LOAN_PORTFOLIO', 0.00, 1468.42, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0149', 'REPAYMENT', 22, 22, 3, 1468.42, 'CASH', 'GW-TX-0149', 'SUCCESS', v_repayment_id, '2026-07-02 23:20:35+05:30', '2026-07-02 23:20:35+05:30');

  -- Transaction TX-0150 (REPAYMENT - Loan #22 Monika Talukdar - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (22, v_user_id, 1468.42, '2026-07-09 23:20:35+05:30', '78de619d-8f32-4cc6-a840-59e033a4ce94', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 22 AND seq_no = 4;
  v_rem_amt := 1468.42;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 22) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 22));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 22;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 22) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 22));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 22;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 22 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-09 23:20:35+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 22, 'CASH', 1468.42, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 22, 'CASH', 1468.42, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 22, 'LOAN_PORTFOLIO', 0.00, 1468.42, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 22, 'LOAN_PORTFOLIO', 0.00, 1468.42, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0150', 'REPAYMENT', 22, 22, 3, 1468.42, 'CASH', 'GW-TX-0150', 'SUCCESS', v_repayment_id, '2026-07-09 23:20:35+05:30', '2026-07-09 23:20:35+05:30');

  -- Transaction TX-0151 (REPAYMENT - Loan #22 Monika Talukdar - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (22, v_user_id, 1468.42, '2026-07-16 23:20:35+05:30', '9197e577-493a-40e8-8a51-685367b8638c', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 22 AND seq_no = 5;
  v_rem_amt := 1468.42;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 22) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 22));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 22;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 22) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 22));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 22;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 22 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-16 23:20:35+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 22, 'CASH', 1468.42, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 22, 'CASH', 1468.42, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 22, 'LOAN_PORTFOLIO', 0.00, 1468.42, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 22, 'LOAN_PORTFOLIO', 0.00, 1468.42, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0151', 'REPAYMENT', 22, 22, 3, 1468.42, 'CASH', 'GW-TX-0151', 'SUCCESS', v_repayment_id, '2026-07-16 23:20:35+05:30', '2026-07-16 23:20:35+05:30');

  -- Transaction TX-0152 (MISSED_PAYMENT - Loan #22 Monika Talukdar - Seq 6)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 22 AND seq_no = 6;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 22 AND seq_no = 6), status = CASE WHEN 6 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 22;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0152', 'MISSED_INSTALLMENT', 22, 22, 3, 1468.42, 'FIELD', 'GW-TX-0152', 'OVERDUE', 'Borrower unable to pay; JLG peer-liability triggered', '2026-07-24 01:20:35+05:30', '2026-07-24 01:20:35+05:30');

  -- Transaction TX-0153 (GUARANTOR_REPAYMENT - Loan #22 Monika Talukdar - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (22, v_user_id, 1468.42, '2026-07-24 04:20:35+05:30', '8e1fe495-d631-4c32-9ff4-da46ec878735', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 22 AND seq_no = 6;
  v_rem_amt := 1468.42;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 22) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 22));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 22;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 22) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 22));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 22;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 22 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-24 04:20:35+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 22, 'CASH', 1468.42, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 22, 'CASH', 1468.42, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 22, 'LOAN_PORTFOLIO', 0.00, 1468.42, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 22, 'LOAN_PORTFOLIO', 0.00, 1468.42, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0153', 'GUARANTOR_REPAYMENT', 22, 21, 3, 1468.42, 'CASH', 'GW-TX-0153', 'SUCCESS', v_repayment_id, '2026-07-24 04:20:35+05:30', '2026-07-24 04:20:35+05:30');

  -- Transaction TX-0154 (DISBURSEMENT - Loan #23 Mousumi Gogoi - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0154', 'LOAN_DISBURSEMENT', 23, 23, 1, 35500.00, 'BANK_TRANSFER', 'GW-TX-0154', 'SUCCESS', '2026-03-13 00:28:04+05:30', '2026-03-13 00:28:04+05:30');

  -- Transaction TX-0155 (REPAYMENT - Loan #23 Mousumi Gogoi - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (23, v_user_id, 1527.65, '2026-03-20 10:28:04+05:30', 'fa018353-39ec-481e-b441-dcd082fbdac4', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 23 AND seq_no = 1;
  v_rem_amt := 1527.65;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 23) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 23));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 23;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 23) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 23));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 23;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 23 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-03-20 10:28:04+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 23, 'CASH', 1527.65, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 23, 'CASH', 1527.65, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 23, 'LOAN_PORTFOLIO', 0.00, 1527.65, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 23, 'LOAN_PORTFOLIO', 0.00, 1527.65, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0155', 'REPAYMENT', 23, 23, 1, 1527.65, 'CASH', 'GW-TX-0155', 'SUCCESS', v_repayment_id, '2026-03-20 10:28:04+05:30', '2026-03-20 10:28:04+05:30');

  -- Transaction TX-0156 (REPAYMENT - Loan #23 Mousumi Gogoi - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (23, v_user_id, 1527.65, '2026-03-27 10:28:04+05:30', '9e66c0e6-226e-4e5c-86ea-89bae5e0d44c', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 23 AND seq_no = 2;
  v_rem_amt := 1527.65;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 23) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 23));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 23;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 23) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 23));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 23;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 23 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-03-27 10:28:04+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 23, 'CASH', 1527.65, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 23, 'CASH', 1527.65, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 23, 'LOAN_PORTFOLIO', 0.00, 1527.65, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 23, 'LOAN_PORTFOLIO', 0.00, 1527.65, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0156', 'REPAYMENT', 23, 23, 1, 1527.65, 'CASH', 'GW-TX-0156', 'SUCCESS', v_repayment_id, '2026-03-27 10:28:04+05:30', '2026-03-27 10:28:04+05:30');

  -- Transaction TX-0157 (REPAYMENT - Loan #23 Mousumi Gogoi - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (23, v_user_id, 1527.65, '2026-04-03 10:28:04+05:30', 'c97e27a8-30cd-448f-b1f5-2b4fd419ac7c', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 23 AND seq_no = 3;
  v_rem_amt := 1527.65;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 23) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 23));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 23;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 23) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 23));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 23;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 23 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-04-03 10:28:04+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 23, 'CASH', 1527.65, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 23, 'CASH', 1527.65, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 23, 'LOAN_PORTFOLIO', 0.00, 1527.65, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 23, 'LOAN_PORTFOLIO', 0.00, 1527.65, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0157', 'REPAYMENT', 23, 23, 1, 1527.65, 'CASH', 'GW-TX-0157', 'SUCCESS', v_repayment_id, '2026-04-03 10:28:04+05:30', '2026-04-03 10:28:04+05:30');

  -- Transaction TX-0158 (REPAYMENT - Loan #23 Mousumi Gogoi - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (23, v_user_id, 1527.65, '2026-04-10 10:28:04+05:30', '099b927c-55cb-49ba-9139-9ee5ae4c0e37', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 23 AND seq_no = 4;
  v_rem_amt := 1527.65;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 23) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 23));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 23;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 23) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 23));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 23;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 23 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-04-10 10:28:04+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 23, 'CASH', 1527.65, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 23, 'CASH', 1527.65, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 23, 'LOAN_PORTFOLIO', 0.00, 1527.65, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 23, 'LOAN_PORTFOLIO', 0.00, 1527.65, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0158', 'REPAYMENT', 23, 23, 1, 1527.65, 'CASH', 'GW-TX-0158', 'SUCCESS', v_repayment_id, '2026-04-10 10:28:04+05:30', '2026-04-10 10:28:04+05:30');

  -- Transaction TX-0159 (REPAYMENT - Loan #23 Mousumi Gogoi - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (23, v_user_id, 1527.65, '2026-04-17 10:28:04+05:30', '88ee6a49-3f29-40a4-89d3-e0e071f4daa8', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 23 AND seq_no = 5;
  v_rem_amt := 1527.65;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 23) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 23));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 23;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 23) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 23));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 23;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 23 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-04-17 10:28:04+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 23, 'CASH', 1527.65, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 23, 'CASH', 1527.65, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 23, 'LOAN_PORTFOLIO', 0.00, 1527.65, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 23, 'LOAN_PORTFOLIO', 0.00, 1527.65, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0159', 'REPAYMENT', 23, 23, 1, 1527.65, 'CASH', 'GW-TX-0159', 'SUCCESS', v_repayment_id, '2026-04-17 10:28:04+05:30', '2026-04-17 10:28:04+05:30');

  -- Transaction TX-0160 (MISSED_PAYMENT - Loan #23 Mousumi Gogoi - Seq 6)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 23 AND seq_no = 6;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 23 AND seq_no = 6), status = CASE WHEN 6 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 23;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0160', 'MISSED_INSTALLMENT', 23, 23, 1, 1527.65, 'FIELD', 'GW-TX-0160', 'OVERDUE', 'Borrower unable to pay; JLG peer-liability triggered', '2026-04-24 12:28:04+05:30', '2026-04-24 12:28:04+05:30');

  -- Transaction TX-0161 (GUARANTOR_REPAYMENT - Loan #23 Mousumi Gogoi - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (23, v_user_id, 1527.65, '2026-04-24 15:28:04+05:30', '053a141a-55dd-42bc-967c-b5f520a9292c', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 23 AND seq_no = 6;
  v_rem_amt := 1527.65;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 23) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 23));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 23;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 23) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 23));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 23;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 23 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-04-24 15:28:04+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 23, 'CASH', 1527.65, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 23, 'CASH', 1527.65, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 23, 'LOAN_PORTFOLIO', 0.00, 1527.65, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 23, 'LOAN_PORTFOLIO', 0.00, 1527.65, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0161', 'GUARANTOR_REPAYMENT', 23, 25, 1, 1527.65, 'CASH', 'GW-TX-0161', 'SUCCESS', v_repayment_id, '2026-04-24 15:28:04+05:30', '2026-04-24 15:28:04+05:30');

  -- Transaction TX-0162 (DISBURSEMENT - Loan #24 Sunita Gogoi - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0162', 'LOAN_DISBURSEMENT', 24, 24, 1, 19000.00, 'BANK_TRANSFER', 'GW-TX-0162', 'SUCCESS', '2026-11-08 05:04:35+05:30', '2026-11-08 05:04:35+05:30');

  -- Transaction TX-0163 (REPAYMENT - Loan #24 Sunita Gogoi - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (24, v_user_id, 565.19, '2026-11-15 15:04:35+05:30', 'f5fb1cff-5acd-45b4-9380-d6be6b5c4793', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 24 AND seq_no = 1;
  v_rem_amt := 565.19;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 24) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 24));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 24;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 24) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 24));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 24;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 24 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-11-15 15:04:35+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 24, 'CASH', 565.19, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 24, 'CASH', 565.19, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 24, 'LOAN_PORTFOLIO', 0.00, 565.19, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 24, 'LOAN_PORTFOLIO', 0.00, 565.19, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0163', 'REPAYMENT', 24, 24, 1, 565.19, 'CASH', 'GW-TX-0163', 'SUCCESS', v_repayment_id, '2026-11-15 15:04:35+05:30', '2026-11-15 15:04:35+05:30');

  -- Transaction TX-0164 (MISSED_PAYMENT - Loan #24 Sunita Gogoi - Seq 2)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 24 AND seq_no = 2;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 24 AND seq_no = 2), status = CASE WHEN 2 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 24;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0164', 'MISSED_INSTALLMENT', 24, 24, 1, 565.19, 'FIELD', 'GW-TX-0164', 'OVERDUE', 'Borrower unable to pay; JLG peer-liability triggered', '2026-11-22 17:04:35+05:30', '2026-11-22 17:04:35+05:30');

  -- Transaction TX-0165 (GUARANTOR_REPAYMENT - Loan #24 Sunita Gogoi - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (24, v_user_id, 565.19, '2026-11-22 20:04:35+05:30', 'd267df01-a46f-412d-8ead-b3f32c918e7a', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 24 AND seq_no = 2;
  v_rem_amt := 565.19;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 24) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 24));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 24;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 24) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 24));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 24;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 24 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-11-22 20:04:35+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 24, 'CASH', 565.19, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 24, 'CASH', 565.19, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 24, 'LOAN_PORTFOLIO', 0.00, 565.19, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 24, 'LOAN_PORTFOLIO', 0.00, 565.19, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0165', 'GUARANTOR_REPAYMENT', 24, 23, 1, 565.19, 'CASH', 'GW-TX-0165', 'SUCCESS', v_repayment_id, '2026-11-22 20:04:35+05:30', '2026-11-22 20:04:35+05:30');

  -- Transaction TX-0166 (DISBURSEMENT - Loan #25 Ranjita Sarma - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0166', 'LOAN_DISBURSEMENT', 25, 25, 1, 28000.00, 'BANK_TRANSFER', 'GW-TX-0166', 'SUCCESS', '2026-10-03 10:13:53+05:30', '2026-10-03 10:13:53+05:30');

  -- Transaction TX-0167 (REPAYMENT - Loan #25 Ranjita Sarma - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (25, v_user_id, 601.00, '2026-10-10 20:13:53+05:30', 'c905ee49-0276-4539-803d-8661049f4892', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 25 AND seq_no = 1;
  v_rem_amt := 601.00;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 25) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 25));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 25;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 25) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 25));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 25;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 25 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-10 20:13:53+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 25, 'CASH', 601.00, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 25, 'CASH', 601.00, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 25, 'LOAN_PORTFOLIO', 0.00, 601.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 25, 'LOAN_PORTFOLIO', 0.00, 601.00, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0167', 'REPAYMENT', 25, 25, 1, 601.00, 'CASH', 'GW-TX-0167', 'SUCCESS', v_repayment_id, '2026-10-10 20:13:53+05:30', '2026-10-10 20:13:53+05:30');

  -- Transaction TX-0168 (MISSED_PAYMENT - Loan #25 Ranjita Sarma - Seq 2)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 25 AND seq_no = 2;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 25 AND seq_no = 2), status = CASE WHEN 2 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 25;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0168', 'MISSED_INSTALLMENT', 25, 25, 1, 601.00, 'FIELD', 'GW-TX-0168', 'OVERDUE', 'Unpaid default; propagates 33.33% liability to co-guarantors', '2026-10-18 04:13:53+05:30', '2026-10-18 04:13:53+05:30');

  -- Transaction TX-0169 (MISSED_PAYMENT - Loan #25 Ranjita Sarma - Seq 3)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 25 AND seq_no = 3;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 25 AND seq_no = 3), status = CASE WHEN 3 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 25;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0169', 'MISSED_INSTALLMENT', 25, 25, 1, 601.00, 'FIELD', 'GW-TX-0169', 'OVERDUE', 'Unpaid default; propagates 33.33% liability to co-guarantors', '2026-10-25 04:13:53+05:30', '2026-10-25 04:13:53+05:30');

  -- Transaction TX-0170 (MISSED_PAYMENT - Loan #25 Ranjita Sarma - Seq 4)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 25 AND seq_no = 4;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 25 AND seq_no = 4), status = CASE WHEN 4 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 25;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0170', 'MISSED_INSTALLMENT', 25, 25, 1, 601.00, 'FIELD', 'GW-TX-0170', 'OVERDUE', 'Unpaid default; propagates 33.33% liability to co-guarantors', '2026-11-01 04:13:53+05:30', '2026-11-01 04:13:53+05:30');

  -- Transaction TX-0171 (MISSED_PAYMENT - Loan #25 Ranjita Sarma - Seq 5)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 25 AND seq_no = 5;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 25 AND seq_no = 5), status = CASE WHEN 5 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 25;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0171', 'MISSED_INSTALLMENT', 25, 25, 1, 601.00, 'FIELD', 'GW-TX-0171', 'OVERDUE', 'Unpaid default; propagates 33.33% liability to co-guarantors', '2026-11-08 04:13:53+05:30', '2026-11-08 04:13:53+05:30');

  -- Transaction TX-0172 (MISSED_PAYMENT - Loan #25 Ranjita Sarma - Seq 6)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 25 AND seq_no = 6;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 25 AND seq_no = 6), status = CASE WHEN 6 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 25;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0172', 'MISSED_INSTALLMENT', 25, 25, 1, 601.00, 'FIELD', 'GW-TX-0172', 'OVERDUE', 'Unpaid default; propagates 33.33% liability to co-guarantors', '2026-11-15 04:13:53+05:30', '2026-11-15 04:13:53+05:30');

  -- Transaction TX-0173 (DISBURSEMENT - Loan #26 Bina Choudhury - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0173', 'LOAN_DISBURSEMENT', 26, 26, 1, 24500.00, 'BANK_TRANSFER', 'GW-TX-0173', 'SUCCESS', '2026-04-27 21:25:41+05:30', '2026-04-27 21:25:41+05:30');

  -- Transaction TX-0174 (REPAYMENT - Loan #26 Bina Choudhury - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (26, v_user_id, 1071.90, '2026-05-05 10:25:41+05:30', '6a370b2d-394b-475f-82de-c790a9f73607', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 26 AND seq_no = 1;
  v_rem_amt := 1071.90;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 26) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 26));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 26;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 26) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 26));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 26;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 26 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-05-05 10:25:41+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 26, 'CASH', 1071.90, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 26, 'CASH', 1071.90, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 26, 'LOAN_PORTFOLIO', 0.00, 1071.90, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 26, 'LOAN_PORTFOLIO', 0.00, 1071.90, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0174', 'REPAYMENT', 26, 26, 1, 1071.90, 'ONLINE_UPI', 'GW-TX-0174', 'SUCCESS', v_repayment_id, '2026-05-05 10:25:41+05:30', '2026-05-05 10:25:41+05:30');

  -- Transaction TX-0175 (REPAYMENT - Loan #26 Bina Choudhury - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (26, v_user_id, 1071.90, '2026-05-12 11:25:41+05:30', '9d849f0f-9910-4481-a3da-37d6145949f1', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 26 AND seq_no = 2;
  v_rem_amt := 1071.90;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 26) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 26));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 26;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 26) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 26));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 26;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 26 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-05-12 11:25:41+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 26, 'CASH', 1071.90, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 26, 'CASH', 1071.90, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 26, 'LOAN_PORTFOLIO', 0.00, 1071.90, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 26, 'LOAN_PORTFOLIO', 0.00, 1071.90, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0175', 'REPAYMENT', 26, 26, 1, 1071.90, 'ONLINE_UPI', 'GW-TX-0175', 'SUCCESS', v_repayment_id, '2026-05-12 11:25:41+05:30', '2026-05-12 11:25:41+05:30');

  -- Transaction TX-0176 (REPAYMENT - Loan #26 Bina Choudhury - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (26, v_user_id, 1071.90, '2026-05-19 11:25:41+05:30', 'cf508e93-b1c3-4f78-9e7b-2e294e349002', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 26 AND seq_no = 3;
  v_rem_amt := 1071.90;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 26) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 26));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 26;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 26) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 26));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 26;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 26 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-05-19 11:25:41+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 26, 'CASH', 1071.90, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 26, 'CASH', 1071.90, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 26, 'LOAN_PORTFOLIO', 0.00, 1071.90, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 26, 'LOAN_PORTFOLIO', 0.00, 1071.90, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0176', 'REPAYMENT', 26, 26, 1, 1071.90, 'ONLINE_UPI', 'GW-TX-0176', 'SUCCESS', v_repayment_id, '2026-05-19 11:25:41+05:30', '2026-05-19 11:25:41+05:30');

  -- Transaction TX-0177 (REPAYMENT - Loan #26 Bina Choudhury - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (26, v_user_id, 1071.90, '2026-05-26 07:25:41+05:30', 'e33f8654-f26b-40c1-9890-c0dcbaa98e9f', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 26 AND seq_no = 4;
  v_rem_amt := 1071.90;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 26) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 26));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 26;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 26) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 26));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 26;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 26 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-05-26 07:25:41+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 26, 'CASH', 1071.90, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 26, 'CASH', 1071.90, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 26, 'LOAN_PORTFOLIO', 0.00, 1071.90, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 26, 'LOAN_PORTFOLIO', 0.00, 1071.90, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0177', 'REPAYMENT', 26, 26, 1, 1071.90, 'ONLINE_UPI', 'GW-TX-0177', 'SUCCESS', v_repayment_id, '2026-05-26 07:25:41+05:30', '2026-05-26 07:25:41+05:30');

  -- Transaction TX-0178 (REPAYMENT - Loan #26 Bina Choudhury - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (26, v_user_id, 1071.90, '2026-06-02 11:25:41+05:30', 'e40f4922-d638-49bd-8bb6-1c1bc09a4430', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 26 AND seq_no = 5;
  v_rem_amt := 1071.90;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 26) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 26));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 26;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 26) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 26));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 26;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 26 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-02 11:25:41+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 26, 'CASH', 1071.90, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 26, 'CASH', 1071.90, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 26, 'LOAN_PORTFOLIO', 0.00, 1071.90, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 26, 'LOAN_PORTFOLIO', 0.00, 1071.90, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0178', 'REPAYMENT', 26, 26, 1, 1071.90, 'ONLINE_UPI', 'GW-TX-0178', 'SUCCESS', v_repayment_id, '2026-06-02 11:25:41+05:30', '2026-06-02 11:25:41+05:30');

  -- Transaction TX-0179 (REPAYMENT - Loan #26 Bina Choudhury - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 1 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (26, v_user_id, 1071.90, '2026-06-09 13:25:41+05:30', 'ef17b4c3-94ae-40ed-8664-85198b9df91c', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 26 AND seq_no = 6;
  v_rem_amt := 1071.90;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 26) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 26));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 26;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 26) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 26));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 26;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 26 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 1 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-06-09 13:25:41+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 26, 'CASH', 1071.90, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 26, 'CASH', 1071.90, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 26, 'LOAN_PORTFOLIO', 0.00, 1071.90, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (1, v_repayment_id, 26, 'LOAN_PORTFOLIO', 0.00, 1071.90, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0179', 'REPAYMENT', 26, 26, 1, 1071.90, 'CASH', 'GW-TX-0179', 'SUCCESS', v_repayment_id, '2026-06-09 13:25:41+05:30', '2026-06-09 13:25:41+05:30');

  -- Transaction TX-0180 (DISBURSEMENT - Loan #27 Bornali Barman - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0180', 'LOAN_DISBURSEMENT', 27, 27, 3, 50000.00, 'BANK_TRANSFER', 'GW-TX-0180', 'SUCCESS', '2026-07-05 07:34:25+05:30', '2026-07-05 07:34:25+05:30');

  -- Transaction TX-0181 (REPAYMENT - Loan #27 Bornali Barman - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (27, v_user_id, 1140.17, '2026-07-12 17:34:25+05:30', '7a534686-952a-4745-9ed4-61dd85dbf506', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 27 AND seq_no = 1;
  v_rem_amt := 1140.17;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 27) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 27));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 27;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 27) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 27));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 27;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 27 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-12 17:34:25+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 27, 'CASH', 1140.17, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 27, 'CASH', 1140.17, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 27, 'LOAN_PORTFOLIO', 0.00, 1140.17, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 27, 'LOAN_PORTFOLIO', 0.00, 1140.17, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0181', 'REPAYMENT', 27, 27, 3, 1140.17, 'CASH', 'GW-TX-0181', 'SUCCESS', v_repayment_id, '2026-07-12 17:34:25+05:30', '2026-07-12 17:34:25+05:30');

  -- Transaction TX-0182 (MISSED_PAYMENT - Loan #27 Bornali Barman - Seq 2)
  UPDATE installment SET status = 'OVERDUE', fee_due = 50.00, arrears_interest_due = current_interest_due, current_interest_due = 0.00
  WHERE loan_id = 27 AND seq_no = 2;
  UPDATE loan SET fees_due = fees_due + 50.00, overdue_interest_due = overdue_interest_due + (SELECT arrears_interest_due FROM installment WHERE loan_id = 27 AND seq_no = 2), status = CASE WHEN 2 >= 3 THEN 'DELINQUENT' ELSE status END
  WHERE loan_id = 27;
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, failure_reason, created_at, updated_at)
  VALUES ('TX-0182', 'MISSED_INSTALLMENT', 27, 27, 3, 1140.17, 'FIELD', 'GW-TX-0182', 'OVERDUE', 'Borrower absent at center meeting; late fee ₹50 accrued', '2026-07-20 03:34:25+05:30', '2026-07-20 03:34:25+05:30');

  -- Transaction TX-0183 (REPAYMENT - Loan #27 Bornali Barman - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (27, v_user_id, 2330.34, '2026-07-26 18:34:25+05:30', '07b436ff-0cbc-4609-878f-1f40bba05e3f', 'BRANCH')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 27 AND seq_no = 3;
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 27 AND seq_no = 2;
  v_rem_amt := 2330.34;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 27) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 27));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 27;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 27) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 27));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 27;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 27 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-07-26 18:34:25+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 27, 'CASH', 2330.34, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 27, 'CASH', 2330.34, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 27, 'LOAN_PORTFOLIO', 0.00, 2330.34, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 27, 'LOAN_PORTFOLIO', 0.00, 2330.34, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0183', 'REPAYMENT', 27, 27, 3, 2330.34, 'CASH', 'GW-TX-0183', 'SUCCESS', v_repayment_id, '2026-07-26 18:34:25+05:30', '2026-07-26 18:34:25+05:30');

  -- Transaction TX-0184 (REPAYMENT - Loan #27 Bornali Barman - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (27, v_user_id, 1140.17, '2026-08-02 17:34:25+05:30', '6d5f1edd-9e7d-4ab8-8812-5d718a8db8f5', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 27 AND seq_no = 4;
  v_rem_amt := 1140.17;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 27) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 27));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 27;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 27) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 27));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 27;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 27 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-02 17:34:25+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 27, 'CASH', 1140.17, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 27, 'CASH', 1140.17, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 27, 'LOAN_PORTFOLIO', 0.00, 1140.17, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 27, 'LOAN_PORTFOLIO', 0.00, 1140.17, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0184', 'REPAYMENT', 27, 27, 3, 1140.17, 'CASH', 'GW-TX-0184', 'SUCCESS', v_repayment_id, '2026-08-02 17:34:25+05:30', '2026-08-02 17:34:25+05:30');

  -- Transaction TX-0185 (REPAYMENT - Loan #27 Bornali Barman - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (27, v_user_id, 1140.17, '2026-08-09 17:34:25+05:30', 'd4129f7c-d5a2-4582-b6f5-bef4edb606ae', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 27 AND seq_no = 5;
  v_rem_amt := 1140.17;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 27) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 27));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 27;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 27) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 27));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 27;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 27 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-09 17:34:25+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 27, 'CASH', 1140.17, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 27, 'CASH', 1140.17, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 27, 'LOAN_PORTFOLIO', 0.00, 1140.17, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 27, 'LOAN_PORTFOLIO', 0.00, 1140.17, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0185', 'REPAYMENT', 27, 27, 3, 1140.17, 'CASH', 'GW-TX-0185', 'SUCCESS', v_repayment_id, '2026-08-09 17:34:25+05:30', '2026-08-09 17:34:25+05:30');

  -- Transaction TX-0186 (REPAYMENT - Loan #27 Bornali Barman - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (27, v_user_id, 1140.17, '2026-08-16 17:34:25+05:30', '2f74d0b8-2013-4dc1-adc2-e33af92d8831', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 27 AND seq_no = 6;
  v_rem_amt := 1140.17;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 27) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 27));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 27;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 27) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 27));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 27;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 27 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-08-16 17:34:25+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 27, 'CASH', 1140.17, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 27, 'CASH', 1140.17, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 27, 'LOAN_PORTFOLIO', 0.00, 1140.17, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 27, 'LOAN_PORTFOLIO', 0.00, 1140.17, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0186', 'REPAYMENT', 27, 27, 3, 1140.17, 'CASH', 'GW-TX-0186', 'SUCCESS', v_repayment_id, '2026-08-16 17:34:25+05:30', '2026-08-16 17:34:25+05:30');

  -- Transaction TX-0187 (DISBURSEMENT - Loan #28 Papori Saikia - Seq 0)
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, created_at, updated_at)
  VALUES ('TX-0187', 'LOAN_DISBURSEMENT', 28, 28, 3, 30000.00, 'BANK_TRANSFER', 'GW-TX-0187', 'SUCCESS', '2026-09-16 10:13:06+05:30', '2026-09-16 10:13:06+05:30');

  -- Transaction TX-0188 (REPAYMENT - Loan #28 Papori Saikia - Seq 1)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (28, v_user_id, 1256.29, '2026-09-24 02:13:06+05:30', 'c649ed7b-114d-43b4-8b1f-c3b8dc5cf3e6', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 28 AND seq_no = 1;
  v_rem_amt := 1256.29;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 28) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 28));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 28;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 28) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 28));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 28;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 28 AND seq_no = 1;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-09-24 02:13:06+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 28, 'CASH', 1256.29, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 28, 'CASH', 1256.29, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 28, 'LOAN_PORTFOLIO', 0.00, 1256.29, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 28, 'LOAN_PORTFOLIO', 0.00, 1256.29, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0188', 'REPAYMENT', 28, 28, 3, 1256.29, 'CASH', 'GW-TX-0188', 'SUCCESS', v_repayment_id, '2026-09-24 02:13:06+05:30', '2026-09-24 02:13:06+05:30');

  -- Transaction TX-0189 (REPAYMENT - Loan #28 Papori Saikia - Seq 2)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (28, v_user_id, 1256.29, '2026-09-30 21:13:06+05:30', '248b12fe-a725-4dd8-9cab-05a6572fa25a', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 28 AND seq_no = 2;
  v_rem_amt := 1256.29;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 28) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 28));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 28;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 28) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 28));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 28;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 28 AND seq_no = 2;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-09-30 21:13:06+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 28, 'CASH', 1256.29, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 28, 'CASH', 1256.29, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 28, 'LOAN_PORTFOLIO', 0.00, 1256.29, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 28, 'LOAN_PORTFOLIO', 0.00, 1256.29, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0189', 'REPAYMENT', 28, 28, 3, 1256.29, 'ONLINE_UPI', 'GW-TX-0189', 'SUCCESS', v_repayment_id, '2026-09-30 21:13:06+05:30', '2026-09-30 21:13:06+05:30');

  -- Transaction TX-0190 (REPAYMENT - Loan #28 Papori Saikia - Seq 3)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (28, v_user_id, 1256.29, '2026-10-07 20:13:06+05:30', 'fe84e52f-43b4-40fd-96cb-be608f547068', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 28 AND seq_no = 3;
  v_rem_amt := 1256.29;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 28) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 28));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 28;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 28) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 28));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 28;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 28 AND seq_no = 3;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-07 20:13:06+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 28, 'CASH', 1256.29, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 28, 'CASH', 1256.29, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 28, 'LOAN_PORTFOLIO', 0.00, 1256.29, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 28, 'LOAN_PORTFOLIO', 0.00, 1256.29, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0190', 'REPAYMENT', 28, 28, 3, 1256.29, 'CASH', 'GW-TX-0190', 'SUCCESS', v_repayment_id, '2026-10-07 20:13:06+05:30', '2026-10-07 20:13:06+05:30');

  -- Transaction TX-0191 (REPAYMENT - Loan #28 Papori Saikia - Seq 4)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (28, v_user_id, 1256.29, '2026-10-14 20:13:06+05:30', '9bd05042-4415-4c03-8338-ab923a19bc9a', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 28 AND seq_no = 4;
  v_rem_amt := 1256.29;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 28) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 28));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 28;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 28) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 28));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 28;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 28 AND seq_no = 4;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-14 20:13:06+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 28, 'CASH', 1256.29, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 28, 'CASH', 1256.29, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 28, 'LOAN_PORTFOLIO', 0.00, 1256.29, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 28, 'LOAN_PORTFOLIO', 0.00, 1256.29, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0191', 'REPAYMENT', 28, 28, 3, 1256.29, 'ONLINE_UPI', 'GW-TX-0191', 'SUCCESS', v_repayment_id, '2026-10-14 20:13:06+05:30', '2026-10-14 20:13:06+05:30');

  -- Transaction TX-0192 (REPAYMENT - Loan #28 Papori Saikia - Seq 5)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (28, v_user_id, 1256.29, '2026-10-21 23:13:06+05:30', '8fc55004-513d-4aec-acc0-17254851013e', 'ONLINE')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 28 AND seq_no = 5;
  v_rem_amt := 1256.29;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 28) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 28));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 28;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 28) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 28));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 28;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 28 AND seq_no = 5;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-21 23:13:06+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 28, 'CASH', 1256.29, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 28, 'CASH', 1256.29, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 28, 'LOAN_PORTFOLIO', 0.00, 1256.29, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 28, 'LOAN_PORTFOLIO', 0.00, 1256.29, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0192', 'REPAYMENT', 28, 28, 3, 1256.29, 'ONLINE_UPI', 'GW-TX-0192', 'SUCCESS', v_repayment_id, '2026-10-21 23:13:06+05:30', '2026-10-21 23:13:06+05:30');

  -- Transaction TX-0193 (REPAYMENT - Loan #28 Papori Saikia - Seq 6)
  -- Process Repayment
  SELECT user_id INTO v_user_id FROM app_user WHERE branch_id = 3 AND role = 'FIELD_OFFICER' LIMIT 1;
  IF v_user_id IS NULL THEN SELECT user_id INTO v_user_id FROM app_user WHERE role = 'ADMIN' LIMIT 1; END IF;

  INSERT INTO repayment(loan_id, collected_by, amount, received_at, idempotency_key, channel)
  VALUES (28, v_user_id, 1256.29, '2026-10-28 19:13:06+05:30', '59af5309-a434-4043-aa8c-f63e048f3fcc', 'FIELD')
  RETURNING repayment_id INTO v_repayment_id;

  -- Clear paid installment(s)
  UPDATE installment SET status = 'PAID', paid_total = principal_due + arrears_interest_due + current_interest_due + fee_due, fee_due = 0.00
  WHERE loan_id = 28 AND seq_no = 6;
  v_rem_amt := 1256.29;

  -- 1. Fees allocation
  IF (SELECT fees_due FROM loan WHERE loan_id = 28) > 0 THEN
    v_fees_alloc := LEAST(v_rem_amt, (SELECT fees_due FROM loan WHERE loan_id = 28));
    v_rem_amt := v_rem_amt - v_fees_alloc;
    UPDATE loan SET fees_due = fees_due - v_fees_alloc WHERE loan_id = 28;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'FEES', v_fees_alloc);
  END IF;

  -- 2. Overdue Interest allocation
  IF v_rem_amt > 0 AND (SELECT overdue_interest_due FROM loan WHERE loan_id = 28) > 0 THEN
    v_interest_alloc := LEAST(v_rem_amt, (SELECT overdue_interest_due FROM loan WHERE loan_id = 28));
    v_rem_amt := v_rem_amt - v_interest_alloc;
    UPDATE loan SET overdue_interest_due = overdue_interest_due - v_interest_alloc WHERE loan_id = 28;
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'OVERDUE_INTEREST', v_interest_alloc);
  END IF;

  -- 3. Current Interest allocation
  IF v_rem_amt > 0 THEN
    SELECT LEAST(v_rem_amt, current_interest_due) INTO v_interest_alloc FROM installment WHERE loan_id = 28 AND seq_no = 6;
    IF v_interest_alloc > 0 THEN
      v_rem_amt := v_rem_amt - v_interest_alloc;
      INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'CURRENT_INTEREST', v_interest_alloc);
    END IF;
  END IF;

  -- 4. Principal allocation (remaining balance)
  IF v_rem_amt > 0 THEN
    INSERT INTO payment_allocation(repayment_id, account_head, amount) VALUES (v_repayment_id, 'PRINCIPAL', v_rem_amt);
  END IF;

  -- Post Branch Cryptographic Double-Entry Ledger Chain
  SELECT entry_hash INTO v_prev_hash FROM ledger_entry WHERE branch_id = 3 ORDER BY entry_id DESC LIMIT 1;

  -- Debit: CASH
  v_ts := '2026-10-28 19:13:06+05:30';
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 28, 'CASH', 1256.29, 0.00, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 28, 'CASH', 1256.29, 0.00, v_ts, v_prev_hash, v_hash);
  v_prev_hash := v_hash;

  -- Credit: LOAN_PORTFOLIO
  v_hash := encode(digest(concat_ws('|', v_prev_hash, v_repayment_id, 28, 'LOAN_PORTFOLIO', 0.00, 1256.29, v_ts), 'sha256'), 'hex');
  INSERT INTO ledger_entry(branch_id, repayment_id, loan_id, account_head, debit, credit, posted_at, prev_hash, entry_hash)
  VALUES (3, v_repayment_id, 28, 'LOAN_PORTFOLIO', 0.00, 1256.29, v_ts, v_prev_hash, v_hash);

  -- Record audit in payment_transaction
  INSERT INTO payment_transaction(transaction_id, transaction_type, loan_id, borrower_id, branch_id, amount, payment_method, gateway_reference, status, repayment_id, created_at, updated_at)
  VALUES ('TX-0193', 'REPAYMENT', 28, 28, 3, 1256.29, 'CASH', 'GW-TX-0193', 'SUCCESS', v_repayment_id, '2026-10-28 19:13:06+05:30', '2026-10-28 19:13:06+05:30');

END;
$$;

-- ----------------------------------------------------------------------------
-- 12. SYNC LOAN OUTSTANDING BALANCES & DELINQUENCY STATUSES
-- ----------------------------------------------------------------------------
UPDATE loan l SET
  outstanding_principal = COALESCE((SELECT SUM(principal_due) FROM installment WHERE loan_id = l.loan_id AND status IN ('DUE', 'OVERDUE', 'PARTIAL')), 0.00),
  fees_due = COALESCE((SELECT SUM(fee_due) FROM installment WHERE loan_id = l.loan_id AND status = 'OVERDUE'), 0.00),
  overdue_interest_due = COALESCE((SELECT SUM(arrears_interest_due) FROM installment WHERE loan_id = l.loan_id AND status = 'OVERDUE'), 0.00),
  status = CASE
    WHEN (SELECT COUNT(*) FROM installment WHERE loan_id = l.loan_id AND status = 'OVERDUE') >= 3 THEN 'DELINQUENT'
    WHEN (SELECT COUNT(*) FROM installment WHERE loan_id = l.loan_id AND status = 'OVERDUE') > 0 THEN 'ACTIVE'
    ELSE 'ACTIVE'
  END;

-- ----------------------------------------------------------------------------
-- 13. PROPAGATE GUARANTEE EXPOSURES FOR DELINQUENT LOANS
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT loan_id FROM loan WHERE status IN ('DELINQUENT', 'DEFAULTED') ORDER BY loan_id LOOP
    PERFORM propagate_guarantee_exposure(r.loan_id);
  END LOOP;
END;
$$;

-- ----------------------------------------------------------------------------
-- 14. RESET SYSTEM ID SEQUENCES
-- ----------------------------------------------------------------------------
SELECT setval('branch_branch_id_seq', (SELECT MAX(branch_id) FROM branch));
SELECT setval('center_center_id_seq', (SELECT MAX(center_id) FROM center));
SELECT setval('app_user_user_id_seq', (SELECT MAX(user_id) FROM app_user));
SELECT setval('jlg_group_group_id_seq', (SELECT MAX(group_id) FROM jlg_group));
SELECT setval('borrower_borrower_id_seq', (SELECT MAX(borrower_id) FROM borrower));
SELECT setval('loan_loan_id_seq', (SELECT MAX(loan_id) FROM loan));
SELECT setval('installment_installment_id_seq', (SELECT MAX(installment_id) FROM installment));
SELECT setval('guarantee_guarantee_id_seq', (SELECT MAX(guarantee_id) FROM guarantee));
SELECT setval('repayment_repayment_id_seq', COALESCE((SELECT MAX(repayment_id) FROM repayment), 1));
SELECT setval('payment_allocation_allocation_id_seq', COALESCE((SELECT MAX(allocation_id) FROM payment_allocation), 1));
SELECT setval('ledger_entry_entry_id_seq', COALESCE((SELECT MAX(entry_id) FROM ledger_entry), 1));
SELECT setval('guarantee_exposure_exposure_id_seq', COALESCE((SELECT MAX(exposure_id) FROM guarantee_exposure), 1));

COMMIT;

-- Integrity Verification Queries
SELECT 'Ledger Hash Chain Valid' AS test_name, verify_ledger_hash_chain() AS result;
SELECT 'Repayment Allocations Discrepancies' AS test_name, COUNT(*) AS discrepancies FROM check_repayment_allocations();
SELECT 'Ledger Balance Discrepancies' AS test_name, COUNT(*) AS discrepancies FROM check_ledger_balance();
