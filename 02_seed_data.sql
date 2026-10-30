-- =============================================================================
-- 02_seed_data.sql
-- Realistic mock data. Inventory counters are consistent with active loans:
--   available_copies = total_copies - (loans in ISSUED/OVERDUE status)
-- All dates are relative to SYSDATE, so the demo works whenever you run it.
-- Explicit IDs (1..99) are used so test scripts can reference known rows;
-- sequences start at 1000 and never collide with them.
-- =============================================================================
SET DEFINE OFF

-- -----------------------------------------------------------------------------
-- BOOKS (10)
-- -----------------------------------------------------------------------------
INSERT INTO books (book_id, isbn, title, author, category, publisher, publication_year, total_copies, available_copies)
VALUES (1, '978-1-000-00001-1', 'Oracle PL/SQL Programming', 'Steven Feuerstein', 'TECHNOLOGY', 'O''Reilly Media', 2014, 3, 2);
INSERT INTO books (book_id, isbn, title, author, category, publisher, publication_year, total_copies, available_copies)
VALUES (2, '978-1-000-00002-8', 'Database System Concepts', 'Abraham Silberschatz', 'TECHNOLOGY', 'McGraw-Hill', 2019, 2, 1);
INSERT INTO books (book_id, isbn, title, author, category, publisher, publication_year, total_copies, available_copies)
VALUES (3, '978-1-000-00003-5', 'Clean Code', 'Robert C. Martin', 'TECHNOLOGY', 'Prentice Hall', 2008, 1, 0);
INSERT INTO books (book_id, isbn, title, author, category, publisher, publication_year, total_copies, available_copies)
VALUES (4, '978-1-000-00004-2', 'The Pragmatic Programmer', 'Andrew Hunt', 'TECHNOLOGY', 'Addison-Wesley', 2019, 2, 1);
INSERT INTO books (book_id, isbn, title, author, category, publisher, publication_year, total_copies, available_copies)
VALUES (5, '978-1-000-00005-9', 'Wings of Fire', 'A. P. J. Abdul Kalam', 'BIOGRAPHY', 'Universities Press', 1999, 3, 3);
INSERT INTO books (book_id, isbn, title, author, category, publisher, publication_year, total_copies, available_copies)
VALUES (6, '978-1-000-00006-6', 'Sapiens: A Brief History of Humankind', 'Yuval Noah Harari', 'HISTORY', 'Harper', 2015, 2, 2);
INSERT INTO books (book_id, isbn, title, author, category, publisher, publication_year, total_copies, available_copies)
VALUES (7, '978-1-000-00007-3', 'Train to Pakistan', 'Khushwant Singh', 'FICTION', 'Penguin India', 1956, 2, 2);
INSERT INTO books (book_id, isbn, title, author, category, publisher, publication_year, total_copies, available_copies)
VALUES (8, '978-1-000-00008-0', 'Godan', 'Munshi Premchand', 'FICTION', 'Rajpal & Sons', 1936, 1, 1);
INSERT INTO books (book_id, isbn, title, author, category, publisher, publication_year, total_copies, available_copies)
VALUES (9, '978-1-000-00009-7', 'Effective Java', 'Joshua Bloch', 'TECHNOLOGY', 'Addison-Wesley', 2018, 2, 2);
INSERT INTO books (book_id, isbn, title, author, category, publisher, publication_year, total_copies, available_copies)
VALUES (10, '978-1-000-00010-3', 'The Alchemist', 'Paulo Coelho', 'FICTION', 'HarperCollins', 1988, 3, 3);

-- -----------------------------------------------------------------------------
-- MEMBERS (6)
--   1 Aarav  : at max loans (3/3)               -> tests ex_max_loans_reached
--   2 Priya  : PREMIUM, clean record            -> happy-path borrower
--   3 Rohan  : has an UNPAID fine of 50         -> tests ex_outstanding_fines
--   4 Simran : holds an overdue loan (id 5)     -> tests fine calculation
--   5 Karan  : SUSPENDED                        -> tests ex_member_inactive
--   6 Neha   : fine fully paid in the past
-- -----------------------------------------------------------------------------
INSERT INTO members (member_id, first_name, last_name, email, phone, membership_type, status, max_loans, join_date, expiry_date)
VALUES (1, 'Aarav',  'Sharma', 'aarav.sharma@example.com', '+91-98140-10001', 'STANDARD', 'ACTIVE',    3, ADD_MONTHS(TRUNC(SYSDATE), -18), ADD_MONTHS(TRUNC(SYSDATE), 6));
INSERT INTO members (member_id, first_name, last_name, email, phone, membership_type, status, max_loans, join_date, expiry_date)
VALUES (2, 'Priya',  'Kaur',   'priya.kaur@example.com',   '+91-98140-10002', 'PREMIUM',  'ACTIVE',    5, ADD_MONTHS(TRUNC(SYSDATE), -24), ADD_MONTHS(TRUNC(SYSDATE), 12));
INSERT INTO members (member_id, first_name, last_name, email, phone, membership_type, status, max_loans, join_date, expiry_date)
VALUES (3, 'Rohan',  'Singh',  'rohan.singh@example.com',  '+91-98140-10003', 'STUDENT',  'ACTIVE',    2, ADD_MONTHS(TRUNC(SYSDATE), -10), ADD_MONTHS(TRUNC(SYSDATE), 2));
INSERT INTO members (member_id, first_name, last_name, email, phone, membership_type, status, max_loans, join_date, expiry_date)
VALUES (4, 'Simran', 'Gill',   'simran.gill@example.com',  '+91-98140-10004', 'STANDARD', 'ACTIVE',    3, ADD_MONTHS(TRUNC(SYSDATE), -12), ADD_MONTHS(TRUNC(SYSDATE), 4));
INSERT INTO members (member_id, first_name, last_name, email, phone, membership_type, status, max_loans, join_date, expiry_date)
VALUES (5, 'Karan',  'Mehta',  'karan.mehta@example.com',  '+91-98140-10005', 'STANDARD', 'SUSPENDED', 3, ADD_MONTHS(TRUNC(SYSDATE), -30), ADD_MONTHS(TRUNC(SYSDATE), 3));
INSERT INTO members (member_id, first_name, last_name, email, phone, membership_type, status, max_loans, join_date, expiry_date)
VALUES (6, 'Neha',   'Verma',  'neha.verma@example.com',   '+91-98140-10006', 'STUDENT',  'ACTIVE',    2, ADD_MONTHS(TRUNC(SYSDATE), -8),  ADD_MONTHS(TRUNC(SYSDATE), 4));

-- -----------------------------------------------------------------------------
-- BOOK_LOANS (7)   Loan period = 14 days
--   1-3  active loans of Aarav (books 1,2,3)
--   4    Rohan: returned 10 days late  -> fine 50 (UNPAID)
--   5    Simran: ISSUED, 16 days past due (not yet returned)
--   6    Neha: returned 4 days late    -> fine 20 (PAID)
--   7    Priya: returned on time
-- -----------------------------------------------------------------------------
INSERT INTO book_loans (loan_id, member_id, book_id, issue_date, due_date, return_date, status, fine_amount)
VALUES (1, 1, 1, TRUNC(SYSDATE) - 5,  TRUNC(SYSDATE) + 9,  NULL, 'ISSUED', 0);
INSERT INTO book_loans (loan_id, member_id, book_id, issue_date, due_date, return_date, status, fine_amount)
VALUES (2, 1, 2, TRUNC(SYSDATE) - 3,  TRUNC(SYSDATE) + 11, NULL, 'ISSUED', 0);
INSERT INTO book_loans (loan_id, member_id, book_id, issue_date, due_date, return_date, status, fine_amount)
VALUES (3, 1, 3, TRUNC(SYSDATE) - 2,  TRUNC(SYSDATE) + 12, NULL, 'ISSUED', 0);
INSERT INTO book_loans (loan_id, member_id, book_id, issue_date, due_date, return_date, status, fine_amount)
VALUES (4, 3, 5, TRUNC(SYSDATE) - 30, TRUNC(SYSDATE) - 16, TRUNC(SYSDATE) - 6,  'RETURNED', 50);
INSERT INTO book_loans (loan_id, member_id, book_id, issue_date, due_date, return_date, status, fine_amount)
VALUES (5, 4, 4, TRUNC(SYSDATE) - 30, TRUNC(SYSDATE) - 16, NULL, 'ISSUED', 0);
INSERT INTO book_loans (loan_id, member_id, book_id, issue_date, due_date, return_date, status, fine_amount)
VALUES (6, 6, 6, TRUNC(SYSDATE) - 40, TRUNC(SYSDATE) - 26, TRUNC(SYSDATE) - 22, 'RETURNED', 20);
INSERT INTO book_loans (loan_id, member_id, book_id, issue_date, due_date, return_date, status, fine_amount)
VALUES (7, 2, 7, TRUNC(SYSDATE) - 20, TRUNC(SYSDATE) - 6,  TRUNC(SYSDATE) - 8,  'RETURNED', 0);

-- -----------------------------------------------------------------------------
-- FINE_PAYMENTS (2)
-- -----------------------------------------------------------------------------
INSERT INTO fine_payments (payment_id, loan_id, member_id, fine_amount, amount_paid, payment_status, payment_method, payment_date)
VALUES (1, 4, 3, 50, 0,  'UNPAID', NULL,  NULL);
INSERT INTO fine_payments (payment_id, loan_id, member_id, fine_amount, amount_paid, payment_status, payment_method, payment_date)
VALUES (2, 6, 6, 20, 20, 'PAID',   'UPI', TRUNC(SYSDATE) - 21);

-- -----------------------------------------------------------------------------
-- AUDIT_LOGS (4 historic entries; triggers add new ones at runtime)
-- -----------------------------------------------------------------------------
INSERT INTO audit_logs (audit_id, table_name, record_id, action_type, old_value, new_value, changed_by, changed_at, details)
VALUES (seq_audit_id.NEXTVAL, 'BOOK_LOANS', 4, 'STATUS_CHANGE', 'ISSUED',  'OVERDUE',  'BATCH_JOB', SYSTIMESTAMP - INTERVAL '15' DAY, 'Historic: loan 4 flagged overdue by nightly job');
INSERT INTO audit_logs (audit_id, table_name, record_id, action_type, old_value, new_value, changed_by, changed_at, details)
VALUES (seq_audit_id.NEXTVAL, 'BOOK_LOANS', 4, 'STATUS_CHANGE', 'OVERDUE', 'RETURNED', 'LIBRARIAN1', SYSTIMESTAMP - INTERVAL '6' DAY,  'Historic: loan 4 returned, fine 50 raised');
INSERT INTO audit_logs (audit_id, table_name, record_id, action_type, old_value, new_value, changed_by, changed_at, details)
VALUES (seq_audit_id.NEXTVAL, 'BOOK_LOANS', 6, 'STATUS_CHANGE', 'ISSUED',  'RETURNED', 'LIBRARIAN2', SYSTIMESTAMP - INTERVAL '22' DAY, 'Historic: loan 6 returned, fine 20 raised');
INSERT INTO audit_logs (audit_id, table_name, record_id, action_type, old_value, new_value, changed_by, changed_at, details)
VALUES (seq_audit_id.NEXTVAL, 'FINE_PAYMENTS', 2, 'PAYMENT', 'UNPAID', 'PAID', 'LIBRARIAN2', SYSTIMESTAMP - INTERVAL '21' DAY, 'Historic: paid 20 via UPI');

COMMIT;

PROMPT Seed data loaded.
SELECT 'BOOKS' AS tbl, COUNT(*) AS row_count FROM books
UNION ALL SELECT 'MEMBERS',       COUNT(*) FROM members
UNION ALL SELECT 'BOOK_LOANS',    COUNT(*) FROM book_loans
UNION ALL SELECT 'FINE_PAYMENTS', COUNT(*) FROM fine_payments
UNION ALL SELECT 'AUDIT_LOGS',    COUNT(*) FROM audit_logs;
