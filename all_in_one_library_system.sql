-- ============================================================================
-- ALL-IN-ONE SCRIPT: LIBRARY MANAGEMENT SYSTEM (ORACLE PL/SQL)
-- ============================================================================
-- Description: Complete mini-project containing:
--              1. Table & Sequence creation with integrity constraints
--              2. Realistic sample data seeding
--              3. Database trigger for book availability synchronization
--              4. PL/SQL Function for fine calculation
--              5. PL/SQL Procedures for issuing, returning, and history display
--              6. Comprehensive automated test scenarios with exception handling
-- ============================================================================

SET SERVEROUTPUT ON SIZE 1000000;
SET LINESIZE 200;
SET PAGESIZE 50;
SET FEEDBACK ON;

-- ============================================================================
-- STEP 1: CLEANUP PRE-EXISTING OBJECTS
-- ============================================================================
PROMPT ====================================================================
PROMPT Step 1: Cleaning up existing tables and sequences...
PROMPT ====================================================================

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

-- ============================================================================
-- STEP 2: SEQUENCES
-- ============================================================================
PROMPT ====================================================================
PROMPT Step 2: Creating Sequences...
PROMPT ====================================================================

CREATE SEQUENCE book_seq   START WITH 101  INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE member_seq START WITH 1    INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE loan_seq   START WITH 1001 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE fine_seq   START WITH 5001 INCREMENT BY 1 NOCACHE;

-- ============================================================================
-- STEP 3: TABLES AND CONSTRAINTS
-- ============================================================================
PROMPT ====================================================================
PROMPT Step 3: Creating Tables and Constraints...
PROMPT ====================================================================

CREATE TABLE books (
    book_id     NUMBER PRIMARY KEY,
    title       VARCHAR2(150) NOT NULL,
    author      VARCHAR2(100) NOT NULL,
    category    VARCHAR2(50)  NOT NULL,
    status      VARCHAR2(15)  DEFAULT 'AVAILABLE' NOT NULL,
    CONSTRAINT chk_book_status CHECK (status IN ('AVAILABLE', 'BORROWED'))
);

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

-- ============================================================================
-- STEP 4: SAMPLE DATA INSERTION
-- ============================================================================
PROMPT ====================================================================
PROMPT Step 4: Inserting Initial Sample Data...
PROMPT ====================================================================

-- Books
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

-- Members
INSERT INTO members (member_id, first_name, last_name, email, phone, join_date, status)
VALUES (member_seq.NEXTVAL, 'Alice', 'Johnson', 'alice.johnson@example.com', '555-0101', DATE '2024-01-15', 'ACTIVE');

INSERT INTO members (member_id, first_name, last_name, email, phone, join_date, status)
VALUES (member_seq.NEXTVAL, 'Bob', 'Smith', 'bob.smith@example.com', '555-0102', DATE '2024-02-20', 'ACTIVE');

INSERT INTO members (member_id, first_name, last_name, email, phone, join_date, status)
VALUES (member_seq.NEXTVAL, 'Charlie', 'Brown', 'charlie.brown@example.com', '555-0103', DATE '2024-03-10', 'ACTIVE');

INSERT INTO members (member_id, first_name, last_name, email, phone, join_date, status)
VALUES (member_seq.NEXTVAL, 'Diana', 'Prince', 'diana.prince@example.com', '555-0104', DATE '2024-04-05', 'SUSPENDED');

-- Loans
-- Loan 1001: Book 101 to Member 1, issued 20 days ago, due 6 days ago (OVERDUE for test)
INSERT INTO loans (loan_id, book_id, member_id, loan_date, due_date, return_date, status)
VALUES (loan_seq.NEXTVAL, 101, 1, TRUNC(SYSDATE) - 20, TRUNC(SYSDATE) - 6, NULL, 'ISSUED');

-- Loan 1002: Book 102 to Member 2, returned 2 days before due date (ON TIME)
INSERT INTO loans (loan_id, book_id, member_id, loan_date, due_date, return_date, status)
VALUES (loan_seq.NEXTVAL, 102, 2, TRUNC(SYSDATE) - 14, TRUNC(SYSDATE), TRUNC(SYSDATE) - 2, 'RETURNED');

COMMIT;

-- ============================================================================
-- STEP 5: DATABASE TRIGGER
-- ============================================================================
PROMPT ====================================================================
PROMPT Step 5: Creating Trigger trg_sync_book_availability...
PROMPT ====================================================================

CREATE OR REPLACE TRIGGER trg_sync_book_availability
AFTER INSERT OR UPDATE OF status ON loans
FOR EACH ROW
BEGIN
    -- Case 1: Loan issued -> Mark book as BORROWED
    IF INSERTING THEN
        IF :NEW.status = 'ISSUED' THEN
            UPDATE books
            SET status = 'BORROWED'
            WHERE book_id = :NEW.book_id;
        END IF;

    -- Case 2: Loan returned -> Mark book back as AVAILABLE
    ELSIF UPDATING THEN
        IF :NEW.status = 'RETURNED' AND :OLD.status = 'ISSUED' THEN
            UPDATE books
            SET status = 'AVAILABLE'
            WHERE book_id = :NEW.book_id;
        END IF;
    END IF;
END trg_sync_book_availability;
/
SHOW ERRORS TRIGGER trg_sync_book_availability;

-- ============================================================================
-- STEP 6: STORED FUNCTION AND PROCEDURES
-- ============================================================================
PROMPT ====================================================================
PROMPT Step 6: Creating Function and Procedures...
PROMPT ====================================================================

-- 1. Function: calculate_fine
CREATE OR REPLACE FUNCTION calculate_fine (
    p_loan_id     IN NUMBER,
    p_return_date IN DATE DEFAULT NULL
) RETURN NUMBER
IS
    c_fine_per_day   CONSTANT NUMBER(5, 2) := 2.00; -- $2.00 per overdue day
    v_due_date       loans.due_date%TYPE;
    v_loan_date      loans.loan_date%TYPE;
    v_actual_return  loans.return_date%TYPE;
    v_effective_date DATE;
    v_overdue_days   NUMBER := 0;
    v_fine_amount    NUMBER(8, 2) := 0.00;
BEGIN
    SELECT due_date, loan_date, return_date
    INTO v_due_date, v_loan_date, v_actual_return
    FROM loans
    WHERE loan_id = p_loan_id;

    v_effective_date := NVL(p_return_date, NVL(v_actual_return, TRUNC(SYSDATE)));

    IF TRUNC(v_effective_date) < TRUNC(v_loan_date) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Return date cannot be earlier than loan date (' || TO_CHAR(v_loan_date, 'YYYY-MM-DD') || ').');
    END IF;

    IF TRUNC(v_effective_date) > TRUNC(v_due_date) THEN
        v_overdue_days := TRUNC(v_effective_date) - TRUNC(v_due_date);
        v_fine_amount  := v_overdue_days * c_fine_per_day;
    ELSE
        v_fine_amount  := 0.00;
    END IF;

    RETURN v_fine_amount;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Loan ID ' || p_loan_id || ' does not exist.');
    WHEN OTHERS THEN
        RAISE;
END calculate_fine;
/
SHOW ERRORS FUNCTION calculate_fine;

-- 2. Procedure: issue_book
CREATE OR REPLACE PROCEDURE issue_book (
    p_book_id   IN NUMBER,
    p_member_id IN NUMBER,
    p_loan_days IN NUMBER DEFAULT 14
)
IS
    v_book_title    books.title%TYPE;
    v_book_status   books.status%TYPE;
    v_member_name   VARCHAR2(101);
    v_member_status members.status%TYPE;
    v_new_loan_id   loans.loan_id%TYPE;

    ex_invalid_member   EXCEPTION;
    ex_member_suspended EXCEPTION;
    ex_invalid_book     EXCEPTION;
    ex_book_unavailable EXCEPTION;
BEGIN
    -- Validate Member
    BEGIN
        SELECT first_name || ' ' || last_name, status
        INTO v_member_name, v_member_status
        FROM members
        WHERE member_id = p_member_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE ex_invalid_member;
    END;

    IF v_member_status = 'SUSPENDED' THEN
        RAISE ex_member_suspended;
    END IF;

    -- Validate Book
    BEGIN
        SELECT title, status
        INTO v_book_title, v_book_status
        FROM books
        WHERE book_id = p_book_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE ex_invalid_book;
    END;

    IF v_book_status != 'AVAILABLE' THEN
        RAISE ex_book_unavailable;
    END IF;

    -- Create Loan
    v_new_loan_id := loan_seq.NEXTVAL;
    INSERT INTO loans (loan_id, book_id, member_id, loan_date, due_date, return_date, status)
    VALUES (v_new_loan_id, p_book_id, p_member_id, TRUNC(SYSDATE), TRUNC(SYSDATE) + p_loan_days, NULL, 'ISSUED');

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Book issued successfully!');
    DBMS_OUTPUT.PUT_LINE('Loan ID     : ' || v_new_loan_id);
    DBMS_OUTPUT.PUT_LINE('Book Title  : ' || v_book_title || ' (ID: ' || p_book_id || ')');
    DBMS_OUTPUT.PUT_LINE('Member      : ' || v_member_name || ' (ID: ' || p_member_id || ')');
    DBMS_OUTPUT.PUT_LINE('Issue Date  : ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('Due Date    : ' || TO_CHAR(SYSDATE + p_loan_days, 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('Book Status : Changed to BORROWED by Trigger');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');

EXCEPTION
    WHEN ex_invalid_member THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Member ID ' || p_member_id || ' does not exist.');
    WHEN ex_member_suspended THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Member "' || v_member_name || '" (ID: ' || p_member_id || ') is SUSPENDED. Cannot issue books.');
    WHEN ex_invalid_book THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Book ID ' || p_book_id || ' does not exist.');
    WHEN ex_book_unavailable THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Book "' || v_book_title || '" (ID: ' || p_book_id || ') is already BORROWED and unavailable.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED ERROR: ' || SQLERRM);
END issue_book;
/
SHOW ERRORS PROCEDURE issue_book;

-- 3. Procedure: return_book
CREATE OR REPLACE PROCEDURE return_book (
    p_loan_id     IN NUMBER,
    p_return_date IN DATE DEFAULT SYSDATE
)
IS
    v_book_id       loans.book_id%TYPE;
    v_member_id     loans.member_id%TYPE;
    v_loan_date     loans.loan_date%TYPE;
    v_due_date      loans.due_date%TYPE;
    v_loan_status   loans.status%TYPE;
    v_book_title    books.title%TYPE;
    v_member_name   VARCHAR2(101);
    v_fine_amount   NUMBER(8, 2) := 0.00;
    v_overdue_days  NUMBER := 0;
    v_new_fine_id   fines.fine_id%TYPE;

    ex_loan_not_found   EXCEPTION;
    ex_already_returned EXCEPTION;
    ex_invalid_date     EXCEPTION;
BEGIN
    -- Validate Loan
    BEGIN
        SELECT book_id, member_id, loan_date, due_date, status
        INTO v_book_id, v_member_id, v_loan_date, v_due_date, v_loan_status
        FROM loans
        WHERE loan_id = p_loan_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE ex_loan_not_found;
    END;

    IF v_loan_status = 'RETURNED' THEN
        RAISE ex_already_returned;
    END IF;

    IF TRUNC(p_return_date) < TRUNC(v_loan_date) THEN
        RAISE ex_invalid_date;
    END IF;

    SELECT title INTO v_book_title FROM books WHERE book_id = v_book_id;
    SELECT first_name || ' ' || last_name INTO v_member_name FROM members WHERE member_id = v_member_id;

    -- Update loan record
    UPDATE loans
    SET return_date = TRUNC(p_return_date),
        status      = 'RETURNED'
    WHERE loan_id = p_loan_id;

    -- Calculate Fine
    v_fine_amount := calculate_fine(p_loan_id, p_return_date);

    IF TRUNC(p_return_date) > TRUNC(v_due_date) THEN
        v_overdue_days := TRUNC(p_return_date) - TRUNC(v_due_date);
    END IF;

    -- Record Fine if overdue
    IF v_fine_amount > 0 THEN
        v_new_fine_id := fine_seq.NEXTVAL;
        INSERT INTO fines (fine_id, loan_id, fine_amount, fine_date, payment_status)
        VALUES (v_new_fine_id, p_loan_id, v_fine_amount, TRUNC(SYSDATE), 'PENDING');
    END IF;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Book returned successfully!');
    DBMS_OUTPUT.PUT_LINE('Loan ID      : ' || p_loan_id);
    DBMS_OUTPUT.PUT_LINE('Book Title   : ' || v_book_title || ' (ID: ' || v_book_id || ')');
    DBMS_OUTPUT.PUT_LINE('Member       : ' || v_member_name || ' (ID: ' || v_member_id || ')');
    DBMS_OUTPUT.PUT_LINE('Due Date     : ' || TO_CHAR(v_due_date, 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('Return Date  : ' || TO_CHAR(p_return_date, 'YYYY-MM-DD'));
    IF v_overdue_days > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Overdue Days : ' || v_overdue_days || ' day(s)');
        DBMS_OUTPUT.PUT_LINE('Fine Imposed : $' || TO_CHAR(v_fine_amount, 'FM9990.00') || ' (Fine ID: ' || v_new_fine_id || ', Status: PENDING)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Overdue Days : 0 (Returned On Time)');
        DBMS_OUTPUT.PUT_LINE('Fine Imposed : $0.00');
    END IF;
    DBMS_OUTPUT.PUT_LINE('Book Status  : Changed to AVAILABLE by Trigger');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');

EXCEPTION
    WHEN ex_loan_not_found THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Loan ID ' || p_loan_id || ' does not exist.');
    WHEN ex_already_returned THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Loan ID ' || p_loan_id || ' has already been returned.');
    WHEN ex_invalid_date THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Return date cannot be earlier than loan issue date (' || TO_CHAR(v_loan_date, 'YYYY-MM-DD') || ').');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED ERROR: ' || SQLERRM);
END return_book;
/
SHOW ERRORS PROCEDURE return_book;

-- 4. Procedure: display_member_history
CREATE OR REPLACE PROCEDURE display_member_history (
    p_member_id IN NUMBER
)
IS
    v_member_name   VARCHAR2(101);
    v_email         members.email%TYPE;
    v_member_status members.status%TYPE;
    v_record_count  NUMBER := 0;

    ex_member_not_found EXCEPTION;

    CURSOR c_history IS
        SELECT l.loan_id,
               b.title,
               l.loan_date,
               l.due_date,
               l.return_date,
               l.status AS loan_status,
               NVL(f.fine_amount, 0) AS fine_amount,
               NVL(f.payment_status, 'NONE') AS fine_status
        FROM loans l
        JOIN books b ON l.book_id = b.book_id
        LEFT JOIN fines f ON l.loan_id = f.loan_id
        WHERE l.member_id = p_member_id
        ORDER BY l.loan_date DESC, l.loan_id DESC;
BEGIN
    BEGIN
        SELECT first_name || ' ' || last_name, email, status
        INTO v_member_name, v_email, v_member_status
        FROM members
        WHERE member_id = p_member_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE ex_member_not_found;
    END;

    DBMS_OUTPUT.PUT_LINE('========================================================================================');
    DBMS_OUTPUT.PUT_LINE('BORROWING HISTORY FOR MEMBER: ' || UPPER(v_member_name) || ' (ID: ' || p_member_id || ')');
    DBMS_OUTPUT.PUT_LINE('Email: ' || v_email || ' | Status: ' || v_member_status);
    DBMS_OUTPUT.PUT_LINE('========================================================================================');
    DBMS_OUTPUT.PUT_LINE(
        RPAD('Loan ID', 9) ||
        RPAD('Book Title', 30) ||
        RPAD('Issue Date', 13) ||
        RPAD('Due Date', 13) ||
        RPAD('Return Date', 13) ||
        RPAD('Status', 10) ||
        RPAD('Fine ($)', 10) ||
        RPAD('Payment', 8)
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 106, '-'));

    FOR r IN c_history LOOP
        v_record_count := v_record_count + 1;
        DBMS_OUTPUT.PUT_LINE(
            RPAD(TO_CHAR(r.loan_id), 9) ||
            RPAD(SUBSTR(r.title, 1, 28), 30) ||
            RPAD(TO_CHAR(r.loan_date, 'YYYY-MM-DD'), 13) ||
            RPAD(TO_CHAR(r.due_date, 'YYYY-MM-DD'), 13) ||
            RPAD(NVL(TO_CHAR(r.return_date, 'YYYY-MM-DD'), 'N/A'), 13) ||
            RPAD(r.loan_status, 10) ||
            RPAD(TO_CHAR(r.fine_amount, 'FM990.00'), 10) ||
            RPAD(r.fine_status, 8)
        );
    END LOOP;

    IF v_record_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No borrowing records found for this member.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('========================================================================================');
    DBMS_OUTPUT.PUT_LINE('Total Loans Found: ' || v_record_count);
    DBMS_OUTPUT.PUT_LINE('========================================================================================');

EXCEPTION
    WHEN ex_member_not_found THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Member ID ' || p_member_id || ' does not exist.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED ERROR: ' || SQLERRM);
END display_member_history;
/
SHOW ERRORS PROCEDURE display_member_history;

-- ============================================================================
-- STEP 7: TEST EXECUTION
-- ============================================================================
PROMPT ====================================================================
PROMPT Step 7: Running Test Scenarios...
PROMPT ====================================================================

PROMPT [TEST 1] Successful Issue of Book 103 to Member 1
BEGIN
    issue_book(103, 1);
END;
/

PROMPT [TEST 2] Exception: Try to issue unavailable Book 101
BEGIN
    issue_book(101, 2);
END;
/

PROMPT [TEST 3] Exception: Try to issue to invalid Member 999
BEGIN
    issue_book(104, 999);
END;
/

PROMPT [TEST 4] Exception: Try to issue to suspended Member 4
BEGIN
    issue_book(104, 4);
END;
/

PROMPT [TEST 5] Return Overdue Book (Loan 1001)
BEGIN
    return_book(1001);
END;
/

PROMPT [TEST 6] Exception: Try to return already returned Loan 1001
BEGIN
    return_book(1001);
END;
/

PROMPT [TEST 7] Exception: Try to return non-existent Loan 9999
BEGIN
    return_book(9999);
END;
/

PROMPT [TEST 8] Display History for Member 1
BEGIN
    display_member_history(1);
END;
/

PROMPT
PROMPT ====================================================================
PROMPT ALL SCRIPT OPERATIONS AND TESTS EXECUTED SUCCESSFULLY!
PROMPT ====================================================================

