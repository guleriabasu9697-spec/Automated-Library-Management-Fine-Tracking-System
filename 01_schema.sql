-- =============================================================================
-- 01_schema.sql
-- Automated Library Management & Fine Tracking System
-- Sequences, tables, integrity constraints and indexes
-- Target: Oracle Database 12c or later (SQL*Plus / SQL Developer / SQLcl)
-- WARNING: the cleanup block below DROPS the project tables and sequences.
-- =============================================================================
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED

-- -----------------------------------------------------------------------------
-- 0. Idempotent cleanup (safe to re-run)
-- -----------------------------------------------------------------------------
BEGIN
  FOR r IN (SELECT table_name
              FROM user_tables
             WHERE table_name IN ('AUDIT_LOGS','FINE_PAYMENTS','BOOK_LOANS','MEMBERS','BOOKS'))
  LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || r.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;

  FOR r IN (SELECT sequence_name
              FROM user_sequences
             WHERE sequence_name IN ('SEQ_BOOK_ID','SEQ_MEMBER_ID','SEQ_LOAN_ID',
                                     'SEQ_PAYMENT_ID','SEQ_AUDIT_ID'))
  LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || r.sequence_name;
  END LOOP;
END;
/

-- -----------------------------------------------------------------------------
-- 1. Sequences
--    START WITH 1000 so that application-generated IDs never collide with the
--    explicit IDs (1..99) used by the seed data in 02_seed_data.sql.
-- -----------------------------------------------------------------------------
CREATE SEQUENCE seq_book_id    START WITH 1000 INCREMENT BY 1 CACHE 20 NOCYCLE;
CREATE SEQUENCE seq_member_id  START WITH 1000 INCREMENT BY 1 CACHE 20 NOCYCLE;
CREATE SEQUENCE seq_loan_id    START WITH 1000 INCREMENT BY 1 CACHE 20 NOCYCLE;
CREATE SEQUENCE seq_payment_id START WITH 1000 INCREMENT BY 1 CACHE 20 NOCYCLE;
CREATE SEQUENCE seq_audit_id   START WITH 1000 INCREMENT BY 1 CACHE 20 NOCYCLE;

-- -----------------------------------------------------------------------------
-- 2. BOOKS  (catalogue + inventory counters)
-- -----------------------------------------------------------------------------
CREATE TABLE books (
  book_id          NUMBER(10)     CONSTRAINT pk_books PRIMARY KEY,
  isbn             VARCHAR2(20)   NOT NULL
                                  CONSTRAINT uq_books_isbn UNIQUE,
  title            VARCHAR2(200)  NOT NULL,
  author           VARCHAR2(120)  NOT NULL,
  category         VARCHAR2(50)   DEFAULT 'GENERAL' NOT NULL,
  publisher        VARCHAR2(100),
  publication_year NUMBER(4)      CONSTRAINT ck_books_year
                                  CHECK (publication_year BETWEEN 1400 AND 2100),
  total_copies     NUMBER(4)      DEFAULT 1 NOT NULL
                                  CONSTRAINT ck_books_total CHECK (total_copies >= 0),
  available_copies NUMBER(4)      DEFAULT 1 NOT NULL,
  created_at       DATE           DEFAULT SYSDATE NOT NULL,
  updated_at       DATE           DEFAULT SYSDATE NOT NULL,
  CONSTRAINT ck_books_stock
    CHECK (available_copies >= 0 AND available_copies <= total_copies)
);

-- -----------------------------------------------------------------------------
-- 3. MEMBERS
-- -----------------------------------------------------------------------------
CREATE TABLE members (
  member_id       NUMBER(10)    CONSTRAINT pk_members PRIMARY KEY,
  first_name      VARCHAR2(60)  NOT NULL,
  last_name       VARCHAR2(60)  NOT NULL,
  email           VARCHAR2(120) NOT NULL
                                CONSTRAINT uq_members_email UNIQUE
                                CONSTRAINT ck_members_email CHECK (INSTR(email, '@') > 1),
  phone           VARCHAR2(20),
  membership_type VARCHAR2(10)  DEFAULT 'STANDARD' NOT NULL
                                CONSTRAINT ck_members_type
                                CHECK (membership_type IN ('STANDARD','PREMIUM','STUDENT')),
  status          VARCHAR2(10)  DEFAULT 'ACTIVE' NOT NULL
                                CONSTRAINT ck_members_status
                                CHECK (status IN ('ACTIVE','SUSPENDED','EXPIRED')),
  max_loans       NUMBER(2)     DEFAULT 3 NOT NULL
                                CONSTRAINT ck_members_maxloans CHECK (max_loans BETWEEN 1 AND 10),
  join_date       DATE          DEFAULT SYSDATE NOT NULL,
  expiry_date     DATE          NOT NULL,
  created_at      DATE          DEFAULT SYSDATE NOT NULL,
  CONSTRAINT ck_members_dates CHECK (expiry_date > join_date)
);

-- -----------------------------------------------------------------------------
-- 4. BOOK_LOANS
-- -----------------------------------------------------------------------------
CREATE TABLE book_loans (
  loan_id     NUMBER(10)   CONSTRAINT pk_book_loans PRIMARY KEY,
  member_id   NUMBER(10)   NOT NULL
                           CONSTRAINT fk_loans_member REFERENCES members (member_id),
  book_id     NUMBER(10)   NOT NULL
                           CONSTRAINT fk_loans_book REFERENCES books (book_id),
  issue_date  DATE         DEFAULT SYSDATE NOT NULL,
  due_date    DATE         NOT NULL,
  return_date DATE,
  status      VARCHAR2(10) DEFAULT 'ISSUED' NOT NULL
                           CONSTRAINT ck_loans_status
                           CHECK (status IN ('ISSUED','RETURNED','OVERDUE','LOST')),
  fine_amount NUMBER(8,2)  DEFAULT 0 NOT NULL
                           CONSTRAINT ck_loans_fine CHECK (fine_amount >= 0),
  CONSTRAINT ck_loans_due_date    CHECK (due_date >= issue_date),
  CONSTRAINT ck_loans_return_date CHECK (return_date IS NULL OR return_date >= issue_date),
  -- A loan has a return_date if and only if it is RETURNED
  CONSTRAINT ck_loans_return_consistency
    CHECK ((status = 'RETURNED' AND return_date IS NOT NULL)
        OR (status <> 'RETURNED' AND return_date IS NULL))
);

-- -----------------------------------------------------------------------------
-- 5. FINE_PAYMENTS  (one fine record per loan; supports partial payments)
-- -----------------------------------------------------------------------------
CREATE TABLE fine_payments (
  payment_id     NUMBER(10)   CONSTRAINT pk_fine_payments PRIMARY KEY,
  loan_id        NUMBER(10)   NOT NULL
                              CONSTRAINT uq_fines_loan UNIQUE
                              CONSTRAINT fk_fines_loan REFERENCES book_loans (loan_id),
  member_id      NUMBER(10)   NOT NULL
                              CONSTRAINT fk_fines_member REFERENCES members (member_id),
  fine_amount    NUMBER(8,2)  NOT NULL
                              CONSTRAINT ck_fines_amount CHECK (fine_amount > 0),
  amount_paid    NUMBER(8,2)  DEFAULT 0 NOT NULL
                              CONSTRAINT ck_fines_paid CHECK (amount_paid >= 0),
  payment_status VARCHAR2(10) DEFAULT 'UNPAID' NOT NULL
                              CONSTRAINT ck_fines_status
                              CHECK (payment_status IN ('UNPAID','PARTIAL','PAID','WAIVED')),
  payment_method VARCHAR2(10) CONSTRAINT ck_fines_method
                              CHECK (payment_method IN ('CASH','CARD','UPI','ONLINE')),
  payment_date   DATE,
  created_at     DATE         DEFAULT SYSDATE NOT NULL,
  CONSTRAINT ck_fines_paid_le_due CHECK (amount_paid <= fine_amount)
);

-- -----------------------------------------------------------------------------
-- 6. AUDIT_LOGS  (append-only trail written by triggers / package)
-- -----------------------------------------------------------------------------
CREATE TABLE audit_logs (
  audit_id    NUMBER(12)    CONSTRAINT pk_audit_logs PRIMARY KEY,
  table_name  VARCHAR2(30)  NOT NULL,
  record_id   NUMBER(10)    NOT NULL,
  action_type VARCHAR2(15)  NOT NULL
                            CONSTRAINT ck_audit_action
                            CHECK (action_type IN ('INSERT','UPDATE','DELETE','STATUS_CHANGE','PAYMENT')),
  old_value   VARCHAR2(100),
  new_value   VARCHAR2(100),
  changed_by  VARCHAR2(60)  DEFAULT USER NOT NULL,
  changed_at  TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
  details     VARCHAR2(500)
);

-- -----------------------------------------------------------------------------
-- 7. Indexes (FK columns, hot predicates, search columns)
--    PK / UNIQUE constraints already create their own indexes.
-- -----------------------------------------------------------------------------
-- "How many active loans does this member have?"  (also covers the member FK)
CREATE INDEX idx_loans_member_status ON book_loans (member_id, status);
-- Book FK + "who has this book?"
CREATE INDEX idx_loans_book          ON book_loans (book_id);
-- Nightly overdue sweep: WHERE status = 'ISSUED' AND due_date < TRUNC(SYSDATE)
CREATE INDEX idx_loans_status_due    ON book_loans (status, due_date);
-- Business rule enforced by the database: a member cannot hold two active
-- loans of the same book. Rows with non-active status map to (NULL, NULL) and
-- are therefore not indexed at all, so history is unaffected.
CREATE UNIQUE INDEX uq_loans_one_active_per_book
  ON book_loans (CASE WHEN status IN ('ISSUED','OVERDUE') THEN member_id END,
                 CASE WHEN status IN ('ISSUED','OVERDUE') THEN book_id   END);

-- Fine balance lookup (also covers the member FK)
CREATE INDEX idx_fines_member_status ON fine_payments (member_id, payment_status);

-- Case-insensitive catalogue search
CREATE INDEX idx_books_title_upper   ON books (UPPER(title));
CREATE INDEX idx_books_author_upper  ON books (UPPER(author));
CREATE INDEX idx_members_name        ON members (last_name, first_name);

-- Audit trail look-ups
CREATE INDEX idx_audit_table_record  ON audit_logs (table_name, record_id);
CREATE INDEX idx_audit_changed_at    ON audit_logs (changed_at);

PROMPT Schema created successfully.
