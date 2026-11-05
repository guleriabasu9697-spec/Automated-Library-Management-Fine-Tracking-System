-- ============================================================================
-- SCRIPT 01: SCHEMA AND SAMPLE DATA
-- Project   : Library Management System (Oracle PL/SQL Mini Project)
-- Purpose   : Drops old objects safely, creates sequences and tables with
--             integrity constraints, and populates initial sample data.
-- ============================================================================

SET SERVEROUTPUT ON;

PROMPT ====================================================================
PROMPT 1. Cleaning up any pre-existing tables and sequences...
PROMPT ====================================================================

-- Safe table drops (suppresses errors if running for the first time)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE fines CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE loans CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE books CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE members CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Safe sequence drops
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE book_seq';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE member_seq';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE loan_seq';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE fine_seq';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

PROMPT ====================================================================
PROMPT 2. Creating Sequences for Primary Keys...
PROMPT ====================================================================

CREATE SEQUENCE book_seq   START WITH 101  INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE member_seq START WITH 1    INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE loan_seq   START WITH 1001 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE fine_seq   START WITH 5001 INCREMENT BY 1 NOCACHE;

PROMPT ====================================================================
PROMPT 3. Creating Tables with Constraints...
PROMPT ====================================================================

-- 1. BOOKS TABLE
CREATE TABLE books (
    book_id     NUMBER PRIMARY KEY,
    title       VARCHAR2(150) NOT NULL,
    author      VARCHAR2(100) NOT NULL,
    category    VARCHAR2(50)  NOT NULL,
    status      VARCHAR2(15)  DEFAULT 'AVAILABLE' NOT NULL,
    CONSTRAINT chk_book_status CHECK (status IN ('AVAILABLE', 'BORROWED'))
);

-- 2. MEMBERS TABLE
CREATE TABLE members (
    member_id   NUMBER PRIMARY KEY,
    first_name  VARCHAR2(50)  NOT NULL,
    last_name   VARCHAR2(50)  NOT NULL,
    email       VARCHAR2(100) NOT NULL,
    phone       VARCHAR2(20),
    join_date   DATE DEFAULT SYSDATE NOT NULL,
    status      VARCHAR2(15)  DEFAULT 'ACTIVE' NOT NULL,
    CONSTRAINT uq_member_email UNIQUE (email),
    CONSTRAINT chk_member_status CHECK (status IN ('ACTIVE', 'SUSPENDED'))
);

-- 3. LOANS TABLE
CREATE TABLE loans (
    loan_id     NUMBER PRIMARY KEY,
    book_id     NUMBER NOT NULL,
    member_id   NUMBER NOT NULL,
    loan_date   DATE DEFAULT TRUNC(SYSDATE) NOT NULL,
    due_date    DATE NOT NULL,
    return_date DATE,
    status      VARCHAR2(15) DEFAULT 'ISSUED' NOT NULL,
    CONSTRAINT fk_loans_book   FOREIGN KEY (book_id)   REFERENCES books(book_id),
    CONSTRAINT fk_loans_member FOREIGN KEY (member_id) REFERENCES members(member_id),
    CONSTRAINT chk_loan_status CHECK (status IN ('ISSUED', 'RETURNED')),
    CONSTRAINT chk_loan_dates  CHECK (due_date >= loan_date)
);

-- 4. FINES TABLE
CREATE TABLE fines (
    fine_id        NUMBER PRIMARY KEY,
    loan_id        NUMBER NOT NULL,
    fine_amount    NUMBER(8, 2) NOT NULL,
    fine_date      DATE DEFAULT TRUNC(SYSDATE) NOT NULL,
    payment_status VARCHAR2(15) DEFAULT 'PENDING' NOT NULL,
    CONSTRAINT fk_fines_loan   FOREIGN KEY (loan_id) REFERENCES loans(loan_id),
    CONSTRAINT uq_fines_loan   UNIQUE (loan_id),
    CONSTRAINT chk_fine_amount CHECK (fine_amount >= 0),
    CONSTRAINT chk_fine_status CHECK (payment_status IN ('PENDING', 'PAID'))
);

PROMPT ====================================================================
PROMPT 4. Populating Sample Data...
PROMPT ====================================================================

-- Insert Sample Books
INSERT INTO books (book_id, title, author, category, status)
VALUES (book_seq.NEXTVAL, 'Database System Concepts', 'Abraham Silberschatz', 'Computer Science', 'BORROWED');

INSERT INTO books (book_id, title, author, category, status)
VALUES (book_seq.NEXTVAL, 'Clean Code: Handbook of Agile Software', 'Robert C. Martin', 'Software Engineering', 'AVAILABLE');

INSERT INTO books (book_id, title, author, category, status)
VALUES (book_seq.NEXTVAL, 'Introduction to Algorithms', 'Thomas H. Cormen', 'Computer Science', 'AVAILABLE');

INSERT INTO books (book_id, title, author, category, status)
VALUES (book_seq.NEXTVAL, 'Design Patterns: Elements of Reusable Code', 'Erich Gamma', 'Software Engineering', 'AVAILABLE');

INSERT INTO books (book_id, title, author, category, status)
VALUES (book_seq.NEXTVAL, 'Artificial Intelligence: A Modern Approach', 'Stuart Russell', 'Artificial Intelligence', 'AVAILABLE');

-- Insert Sample Members
INSERT INTO members (member_id, first_name, last_name, email, phone, join_date, status)
VALUES (member_seq.NEXTVAL, 'Alice', 'Johnson', 'alice.johnson@example.com', '555-0101', DATE '2024-01-15', 'ACTIVE');

INSERT INTO members (member_id, first_name, last_name, email, phone, join_date, status)
VALUES (member_seq.NEXTVAL, 'Bob', 'Smith', 'bob.smith@example.com', '555-0102', DATE '2024-02-20', 'ACTIVE');

INSERT INTO members (member_id, first_name, last_name, email, phone, join_date, status)
VALUES (member_seq.NEXTVAL, 'Charlie', 'Brown', 'charlie.brown@example.com', '555-0103', DATE '2024-03-10', 'ACTIVE');

INSERT INTO members (member_id, first_name, last_name, email, phone, join_date, status)
VALUES (member_seq.NEXTVAL, 'Diana', 'Prince', 'diana.prince@example.com', '555-0104', DATE '2024-04-05', 'SUSPENDED');

-- Insert Sample Loans:
-- Loan 1001: Book 101 to Member 1, issued 20 days ago, due 6 days ago (OVERDUE for testing)
INSERT INTO loans (loan_id, book_id, member_id, loan_date, due_date, return_date, status)
VALUES (loan_seq.NEXTVAL, 101, 1, TRUNC(SYSDATE) - 20, TRUNC(SYSDATE) - 6, NULL, 'ISSUED');

-- Loan 1002: Book 102 to Member 2, returned 2 days before due date (ON TIME)
INSERT INTO loans (loan_id, book_id, member_id, loan_date, due_date, return_date, status)
VALUES (loan_seq.NEXTVAL, 102, 2, TRUNC(SYSDATE) - 14, TRUNC(SYSDATE), TRUNC(SYSDATE) - 2, 'RETURNED');

COMMIT;

PROMPT Schema and sample data initialized successfully!

