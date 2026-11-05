-- ============================================================================
-- SCRIPT 03: PL/SQL PROCEDURES AND FUNCTIONS
-- Project   : Library Management System (Oracle PL/SQL Mini Project)
-- Purpose   : Core business logic:
--             1. FUNCTION  calculate_fine
--             2. PROCEDURE issue_book
--             3. PROCEDURE return_book
--             4. PROCEDURE display_member_history
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. FUNCTION: calculate_fine
-- Description: Computes fine based on due date and return date.
-- Assumptions: Fine rate is $2.00 per day overdue.
--              If returned on or before due date, fine is $0.00.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_fine (
    p_loan_id     IN NUMBER,
    p_return_date IN DATE DEFAULT NULL
) RETURN NUMBER
IS
    -- Business constant: Fine charged per day overdue
    c_fine_per_day   CONSTANT NUMBER(5, 2) := 2.00;
    
    v_due_date       loans.due_date%TYPE;
    v_loan_date      loans.loan_date%TYPE;
    v_actual_return  loans.return_date%TYPE;
    v_effective_date DATE;
    v_overdue_days   NUMBER := 0;
    v_fine_amount    NUMBER(8, 2) := 0.00;
BEGIN
    -- Retrieve loan details
    SELECT due_date, loan_date, return_date
    INTO v_due_date, v_loan_date, v_actual_return
    FROM loans
    WHERE loan_id = p_loan_id;

    -- If no return date was supplied as argument, use the stored return_date, or SYSDATE
    v_effective_date := NVL(p_return_date, NVL(v_actual_return, TRUNC(SYSDATE)));

    -- Date sanity check
    IF TRUNC(v_effective_date) < TRUNC(v_loan_date) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Return date cannot be earlier than loan date (' || TO_CHAR(v_loan_date, 'YYYY-MM-DD') || ').');
    END IF;

    -- Overdue calculation
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


-- ----------------------------------------------------------------------------
-- 2. PROCEDURE: issue_book
-- Description: Issues an available book to an active member.
--              The trigger trg_sync_book_availability will automatically
--              update the book status to 'BORROWED'.
-- ----------------------------------------------------------------------------
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

    -- User-defined exceptions
    ex_invalid_member   EXCEPTION;
    ex_member_suspended EXCEPTION;
    ex_invalid_book     EXCEPTION;
    ex_book_unavailable EXCEPTION;
BEGIN
    -- 1. Validate Member
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

    -- 2. Validate Book
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

    -- 3. Insert Loan Record
    -- Note: trg_sync_book_availability automatically updates books.status = 'BORROWED'
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


-- ----------------------------------------------------------------------------
-- 3. PROCEDURE: return_book
-- Description: Records a book return, changes loan status to RETURNED.
--              The trigger trg_sync_book_availability will automatically
--              update the book status back to 'AVAILABLE'.
--              If returned after the due date, an overdue fine is calculated
--              and automatically inserted into the FINES table.
-- ----------------------------------------------------------------------------
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

    -- User-defined exceptions
    ex_loan_not_found   EXCEPTION;
    ex_already_returned EXCEPTION;
    ex_invalid_date     EXCEPTION;
BEGIN
    -- 1. Validate Loan
    BEGIN
        SELECT book_id, member_id, loan_date, due_date, status
        INTO v_book_id, v_member_id, v_loan_date, v_due_date, v_loan_status
        FROM loans
        WHERE loan_id = p_loan_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE ex_loan_not_found;
    END;

    -- Ensure loan is not already closed
    IF v_loan_status = 'RETURNED' THEN
        RAISE ex_already_returned;
    END IF;

    -- Validate return date
    IF TRUNC(p_return_date) < TRUNC(v_loan_date) THEN
        RAISE ex_invalid_date;
    END IF;

    -- Fetch book and member names for the receipt output
    SELECT title INTO v_book_title FROM books WHERE book_id = v_book_id;
    SELECT first_name || ' ' || last_name INTO v_member_name FROM members WHERE member_id = v_member_id;

    -- 2. Update Loan Status
    -- Note: trg_sync_book_availability automatically updates books.status = 'AVAILABLE'
    UPDATE loans
    SET return_date = TRUNC(p_return_date),
        status      = 'RETURNED'
    WHERE loan_id = p_loan_id;

    -- 3. Calculate Fine using the calculate_fine function
    v_fine_amount := calculate_fine(p_loan_id, p_return_date);

    IF TRUNC(p_return_date) > TRUNC(v_due_date) THEN
        v_overdue_days := TRUNC(p_return_date) - TRUNC(v_due_date);
    END IF;

    -- 4. If fine applies, record it in FINES table
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


-- ----------------------------------------------------------------------------
-- 4. PROCEDURE: display_member_history
-- Description: Queries and displays a formatted borrowing history of all
--              books loaned by a member, including loan dates, return status,
--              and fines.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE display_member_history (
    p_member_id IN NUMBER
)
IS
    v_member_name   VARCHAR2(101);
    v_email         members.email%TYPE;
    v_member_status members.status%TYPE;
    v_record_count  NUMBER := 0;

    -- User-defined exception
    ex_member_not_found EXCEPTION;

    -- Cursor to retrieve member's loan history along with fines
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
    -- 1. Validate Member
    BEGIN
        SELECT first_name || ' ' || last_name, email, status
        INTO v_member_name, v_email, v_member_status
        FROM members
        WHERE member_id = p_member_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE ex_member_not_found;
    END;

    -- 2. Print Header
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

    -- 3. Loop through loan records
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

    -- Handle case where member has no borrowing history
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

PROMPT All procedures and functions compiled successfully!

