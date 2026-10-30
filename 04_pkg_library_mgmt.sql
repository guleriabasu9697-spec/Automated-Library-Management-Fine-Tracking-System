-- =============================================================================
-- 04_pkg_library_mgmt.sql
-- Enterprise package: pkg_library_mgmt  (spec + body)
-- plus thin standalone wrappers issue_book / return_book / get_member_fine_balance
--
-- Transaction policy : procedures NEVER COMMIT. The caller owns the
--                      transaction. On failure each procedure rolls back to its
--                      own savepoint, so a failed call leaves no partial work.
-- Error-code map     : see the PRAGMA EXCEPTION_INIT list in the specification.
-- =============================================================================
SET DEFINE OFF

-- =============================================================================
-- PACKAGE SPECIFICATION  (public API)
-- =============================================================================
CREATE OR REPLACE PACKAGE pkg_library_mgmt AS

  ---------------------------------------------------------------------------
  -- Business constants
  ---------------------------------------------------------------------------
  c_loan_period_days  CONSTANT NUMBER := 14;   -- standard loan length
  c_fine_per_day      CONSTANT NUMBER := 5;    -- fine per overdue day
  c_max_fine_per_loan CONSTANT NUMBER := 500;  -- cap per loan

  ---------------------------------------------------------------------------
  -- Custom exceptions (callers can catch them by name).
  -- Codes must be literals in EXCEPTION_INIT; range -20001 .. -20999.
  ---------------------------------------------------------------------------
  ex_book_unavailable   EXCEPTION; PRAGMA EXCEPTION_INIT(ex_book_unavailable,   -20001);
  ex_outstanding_fines  EXCEPTION; PRAGMA EXCEPTION_INIT(ex_outstanding_fines,  -20002);
  ex_max_loans_reached  EXCEPTION; PRAGMA EXCEPTION_INIT(ex_max_loans_reached,  -20003);
  ex_member_inactive    EXCEPTION; PRAGMA EXCEPTION_INIT(ex_member_inactive,    -20004);
  ex_member_not_found   EXCEPTION; PRAGMA EXCEPTION_INIT(ex_member_not_found,   -20005);
  ex_book_not_found     EXCEPTION; PRAGMA EXCEPTION_INIT(ex_book_not_found,     -20006);
  ex_loan_not_found     EXCEPTION; PRAGMA EXCEPTION_INIT(ex_loan_not_found,     -20007);
  ex_loan_already_closed EXCEPTION; PRAGMA EXCEPTION_INIT(ex_loan_already_closed, -20008);
  ex_invalid_payment    EXCEPTION; PRAGMA EXCEPTION_INIT(ex_invalid_payment,    -20009);
  ex_negative_stock     EXCEPTION; PRAGMA EXCEPTION_INIT(ex_negative_stock,     -20010); -- raised by trigger
  ex_stock_exceeds_total EXCEPTION; PRAGMA EXCEPTION_INIT(ex_stock_exceeds_total, -20011); -- raised by trigger
  ex_duplicate_loan     EXCEPTION; PRAGMA EXCEPTION_INIT(ex_duplicate_loan,     -20012);
  ex_data_integrity     EXCEPTION; PRAGMA EXCEPTION_INIT(ex_data_integrity,     -20013);
  ex_payment_not_found  EXCEPTION; PRAGMA EXCEPTION_INIT(ex_payment_not_found,  -20014);
  ex_unexpected_error   EXCEPTION; PRAGMA EXCEPTION_INIT(ex_unexpected_error,   -20999);

  ---------------------------------------------------------------------------
  -- Public API
  ---------------------------------------------------------------------------
  -- Issue a book; returns the new loan id.
  PROCEDURE issue_book (p_member_id IN  NUMBER,
                        p_book_id   IN  NUMBER,
                        p_loan_id   OUT NUMBER);

  -- Overload for callers that do not need the loan id.
  PROCEDURE issue_book (p_member_id IN NUMBER,
                        p_book_id   IN NUMBER);

  -- Return a book; closes the loan, restores stock, raises a fine if late.
  PROCEDURE return_book (p_loan_id IN NUMBER);

  -- Total outstanding (UNPAID + PARTIAL) fines for a member.
  FUNCTION get_member_fine_balance (p_member_id IN NUMBER) RETURN NUMBER;

  -- Settle (fully or partially) a fine record.
  PROCEDURE pay_fine (p_payment_id IN NUMBER,
                      p_amount     IN NUMBER,
                      p_method     IN VARCHAR2 DEFAULT 'CASH');

  -- Batch job: flag ISSUED loans past their due date as OVERDUE.
  PROCEDURE mark_overdue_loans (p_updated OUT NUMBER);

END pkg_library_mgmt;
/
SHOW ERRORS PACKAGE pkg_library_mgmt

-- =============================================================================
-- PACKAGE BODY
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY pkg_library_mgmt AS

  ---------------------------------------------------------------------------
  -- PRIVATE HELPERS (not visible outside the package)
  -- Defined before first use, so no forward declarations are required.
  ---------------------------------------------------------------------------

  -- Raise -20005 unless the member exists (no lock taken).
  PROCEDURE assert_member_exists (p_member_id IN NUMBER) IS
    v_id members.member_id%TYPE;
  BEGIN
    SELECT member_id INTO v_id FROM members WHERE member_id = p_member_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20005, 'Member ' || p_member_id || ' not found.');
  END assert_member_exists;

  -- Fetch AND lock the member row (serialises concurrent checkouts per member).
  FUNCTION lock_member (p_member_id IN NUMBER) RETURN members%ROWTYPE IS
    v_row members%ROWTYPE;
  BEGIN
    SELECT * INTO v_row FROM members WHERE member_id = p_member_id FOR UPDATE;
    RETURN v_row;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20005, 'Member ' || p_member_id || ' not found.');
  END lock_member;

  -- Fetch AND lock the book row (prevents two sessions taking the last copy).
  FUNCTION lock_book (p_book_id IN NUMBER) RETURN books%ROWTYPE IS
    v_row books%ROWTYPE;
  BEGIN
    SELECT * INTO v_row FROM books WHERE book_id = p_book_id FOR UPDATE;
    RETURN v_row;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20006, 'Book ' || p_book_id || ' not found.');
  END lock_book;

  FUNCTION count_active_loans (p_member_id IN NUMBER) RETURN NUMBER IS
    v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt
      FROM book_loans
     WHERE member_id = p_member_id
       AND status IN ('ISSUED','OVERDUE');
    RETURN v_cnt;
  END count_active_loans;

  -- Returns the id of the member's active loan for a book, or NULL if none.
  FUNCTION find_active_loan (p_member_id IN NUMBER,
                             p_book_id   IN NUMBER) RETURN NUMBER IS
    v_loan_id book_loans.loan_id%TYPE;
  BEGIN
    SELECT loan_id INTO v_loan_id
      FROM book_loans
     WHERE member_id = p_member_id
       AND book_id   = p_book_id
       AND status IN ('ISSUED','OVERDUE');
    RETURN v_loan_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;                               -- expected: no active loan
    WHEN TOO_MANY_ROWS THEN                      -- should be impossible (unique index)
      RAISE_APPLICATION_ERROR(-20013,
        'Data integrity error: member ' || p_member_id
        || ' has multiple active loans for book ' || p_book_id || '.');
  END find_active_loan;

  -- Fine = overdue days * daily rate, capped per loan. Pure calculation.
  FUNCTION calc_fine (p_due_date    IN DATE,
                      p_return_date IN DATE) RETURN NUMBER IS
    v_days_late NUMBER;
  BEGIN
    v_days_late := GREATEST(TRUNC(p_return_date) - TRUNC(p_due_date), 0);
    RETURN LEAST(v_days_late * c_fine_per_day, c_max_fine_per_loan);
  END calc_fine;

  -- Append an audit row from inside the package (used for payments).
  PROCEDURE write_audit (p_table   IN VARCHAR2,
                         p_record  IN NUMBER,
                         p_action  IN VARCHAR2,
                         p_old     IN VARCHAR2,
                         p_new     IN VARCHAR2,
                         p_details IN VARCHAR2) IS
  BEGIN
    INSERT INTO audit_logs
      (audit_id, table_name, record_id, action_type, old_value, new_value, details)
    VALUES
      (seq_audit_id.NEXTVAL, p_table, p_record, p_action, p_old, p_new, p_details);
  END write_audit;

  ---------------------------------------------------------------------------
  -- get_member_fine_balance
  ---------------------------------------------------------------------------
  FUNCTION get_member_fine_balance (p_member_id IN NUMBER) RETURN NUMBER IS
    v_balance NUMBER;
  BEGIN
    assert_member_exists(p_member_id);

    SELECT NVL(SUM(fine_amount - amount_paid), 0)
      INTO v_balance
      FROM fine_payments
     WHERE member_id = p_member_id
       AND payment_status IN ('UNPAID','PARTIAL');

    RETURN v_balance;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE BETWEEN -20999 AND -20001 THEN
        RAISE;                                   -- keep our business errors intact
      END IF;
      RAISE_APPLICATION_ERROR(-20999,
        'get_member_fine_balance failed for member ' || p_member_id || ': ' || SQLERRM);
  END get_member_fine_balance;

  ---------------------------------------------------------------------------
  -- issue_book
  -- Validation order (cheap/static checks first, inventory last):
  --   member exists -> member active -> no unpaid fines -> under loan limit
  --   -> book exists -> not already borrowed -> copy available
  ---------------------------------------------------------------------------
  PROCEDURE issue_book (p_member_id IN  NUMBER,
                        p_book_id   IN  NUMBER,
                        p_loan_id   OUT NUMBER) IS
    v_member  members%ROWTYPE;
    v_book    books%ROWTYPE;
    v_balance NUMBER;
    v_active  NUMBER;
    v_code    PLS_INTEGER;
    v_msg     VARCHAR2(4000);
  BEGIN
    SAVEPOINT sp_issue_book;
    p_loan_id := NULL;

    -- Lock order is always MEMBER then BOOK to avoid deadlocks.
    v_member := lock_member(p_member_id);

    IF v_member.status <> 'ACTIVE' OR v_member.expiry_date < TRUNC(SYSDATE) THEN
      RAISE_APPLICATION_ERROR(-20004,
        'Member ' || p_member_id || ' is not eligible to borrow (status='
        || v_member.status || ', expiry=' || TO_CHAR(v_member.expiry_date, 'YYYY-MM-DD') || ').');
    END IF;

    v_balance := get_member_fine_balance(p_member_id);
    IF v_balance > 0 THEN
      RAISE_APPLICATION_ERROR(-20002,
        'Member ' || p_member_id || ' has outstanding fines of '
        || TO_CHAR(v_balance, 'FM999990.00') || '. Clear dues before borrowing.');
    END IF;

    v_active := count_active_loans(p_member_id);
    IF v_active >= v_member.max_loans THEN
      RAISE_APPLICATION_ERROR(-20003,
        'Member ' || p_member_id || ' already holds ' || v_active
        || ' of ' || v_member.max_loans || ' permitted loans.');
    END IF;

    v_book := lock_book(p_book_id);

    IF find_active_loan(p_member_id, p_book_id) IS NOT NULL THEN
      RAISE_APPLICATION_ERROR(-20012,
        'Member ' || p_member_id || ' already has book ' || p_book_id || ' on loan.');
    END IF;

    IF v_book.available_copies < 1 THEN
      RAISE_APPLICATION_ERROR(-20001,
        'No copies of "' || v_book.title || '" (book ' || p_book_id || ') are available.');
    END IF;

    INSERT INTO book_loans (loan_id, member_id, book_id, issue_date, due_date, status)
    VALUES (seq_loan_id.NEXTVAL, p_member_id, p_book_id,
            TRUNC(SYSDATE), TRUNC(SYSDATE) + c_loan_period_days, 'ISSUED')
    RETURNING loan_id INTO p_loan_id;

    -- Row is already locked; the BEFORE trigger re-validates the new count.
    UPDATE books
       SET available_copies = available_copies - 1
     WHERE book_id = p_book_id;

  EXCEPTION
    WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
      v_msg := SQLERRM;
      ROLLBACK TO SAVEPOINT sp_issue_book;
      p_loan_id := NULL;
      RAISE_APPLICATION_ERROR(-20013,
        'Data integrity error while issuing book ' || p_book_id
        || ' to member ' || p_member_id || ': ' || v_msg);
    WHEN OTHERS THEN
      v_code := SQLCODE;                         -- capture before any other statement
      v_msg  := SQLERRM;
      ROLLBACK TO SAVEPOINT sp_issue_book;
      p_loan_id := NULL;
      IF v_code BETWEEN -20999 AND -20001 THEN
        RAISE;                                   -- business/trigger error: pass through
      END IF;
      RAISE_APPLICATION_ERROR(-20999, 'issue_book failed: ' || v_msg);
  END issue_book;

  -- Overload without OUT parameter (matches the simple 2-argument contract).
  PROCEDURE issue_book (p_member_id IN NUMBER,
                        p_book_id   IN NUMBER) IS
    v_loan_id NUMBER;
  BEGIN
    issue_book(p_member_id, p_book_id, v_loan_id);
  END issue_book;

  ---------------------------------------------------------------------------
  -- return_book
  ---------------------------------------------------------------------------
  PROCEDURE return_book (p_loan_id IN NUMBER) IS
    v_loan book_loans%ROWTYPE;
    v_fine NUMBER;
    v_code PLS_INTEGER;
    v_msg  VARCHAR2(4000);
  BEGIN
    SAVEPOINT sp_return_book;

    -- The only SELECT INTO in this block: NO_DATA_FOUND here means "no such loan".
    SELECT * INTO v_loan FROM book_loans WHERE loan_id = p_loan_id FOR UPDATE;

    IF v_loan.status NOT IN ('ISSUED','OVERDUE') THEN
      RAISE_APPLICATION_ERROR(-20008,
        'Loan ' || p_loan_id || ' cannot be returned (current status: ' || v_loan.status || ').');
    END IF;

    v_fine := calc_fine(v_loan.due_date, SYSDATE);

    -- Status change fires trg_loans_status_audit.
    UPDATE book_loans
       SET return_date = SYSDATE,
           status      = 'RETURNED',
           fine_amount = v_fine
     WHERE loan_id = p_loan_id;

    -- Restore inventory (trigger blocks anything above total_copies).
    UPDATE books
       SET available_copies = available_copies + 1
     WHERE book_id = v_loan.book_id;

    IF v_fine > 0 THEN
      INSERT INTO fine_payments
        (payment_id, loan_id, member_id, fine_amount, amount_paid, payment_status)
      VALUES
        (seq_payment_id.NEXTVAL, p_loan_id, v_loan.member_id, v_fine, 0, 'UNPAID');
    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ROLLBACK TO SAVEPOINT sp_return_book;
      RAISE_APPLICATION_ERROR(-20007, 'Loan ' || p_loan_id || ' not found.');
    WHEN TOO_MANY_ROWS THEN
      ROLLBACK TO SAVEPOINT sp_return_book;
      RAISE_APPLICATION_ERROR(-20013,
        'Data integrity error: multiple rows for loan ' || p_loan_id || '.');
    WHEN OTHERS THEN
      v_code := SQLCODE;
      v_msg  := SQLERRM;
      ROLLBACK TO SAVEPOINT sp_return_book;
      IF v_code BETWEEN -20999 AND -20001 THEN
        RAISE;
      END IF;
      RAISE_APPLICATION_ERROR(-20999, 'return_book failed: ' || v_msg);
  END return_book;

  ---------------------------------------------------------------------------
  -- pay_fine
  ---------------------------------------------------------------------------
  PROCEDURE pay_fine (p_payment_id IN NUMBER,
                      p_amount     IN NUMBER,
                      p_method     IN VARCHAR2 DEFAULT 'CASH') IS
    v_fp          fine_payments%ROWTYPE;
    v_outstanding NUMBER;
    v_new_paid    NUMBER;
    v_new_status  fine_payments.payment_status%TYPE;
    v_code        PLS_INTEGER;
    v_msg         VARCHAR2(4000);
  BEGIN
    SAVEPOINT sp_pay_fine;

    IF p_amount IS NULL OR p_amount <= 0 THEN
      RAISE_APPLICATION_ERROR(-20009, 'Payment amount must be greater than zero.');
    END IF;

    SELECT * INTO v_fp FROM fine_payments WHERE payment_id = p_payment_id FOR UPDATE;

    IF v_fp.payment_status NOT IN ('UNPAID','PARTIAL') THEN
      RAISE_APPLICATION_ERROR(-20009,
        'Fine record ' || p_payment_id || ' is already settled (status: '
        || v_fp.payment_status || ').');
    END IF;

    v_outstanding := v_fp.fine_amount - v_fp.amount_paid;
    IF p_amount > v_outstanding THEN
      RAISE_APPLICATION_ERROR(-20009,
        'Payment ' || TO_CHAR(p_amount, 'FM999990.00') || ' exceeds outstanding balance '
        || TO_CHAR(v_outstanding, 'FM999990.00') || ' on fine record ' || p_payment_id || '.');
    END IF;

    v_new_paid   := v_fp.amount_paid + p_amount;
    v_new_status := CASE WHEN v_new_paid = v_fp.fine_amount THEN 'PAID' ELSE 'PARTIAL' END;

    UPDATE fine_payments
       SET amount_paid    = v_new_paid,
           payment_status = v_new_status,
           payment_method = UPPER(p_method),
           payment_date   = SYSDATE
     WHERE payment_id = p_payment_id;

    write_audit('FINE_PAYMENTS', p_payment_id, 'PAYMENT',
                v_fp.payment_status, v_new_status,
                'paid=' || TO_CHAR(p_amount, 'FM999990.00') || ' via ' || UPPER(p_method)
                || ', remaining=' || TO_CHAR(v_fp.fine_amount - v_new_paid, 'FM999990.00'));

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ROLLBACK TO SAVEPOINT sp_pay_fine;
      RAISE_APPLICATION_ERROR(-20014, 'Fine record ' || p_payment_id || ' not found.');
    WHEN TOO_MANY_ROWS THEN
      ROLLBACK TO SAVEPOINT sp_pay_fine;
      RAISE_APPLICATION_ERROR(-20013,
        'Data integrity error: multiple rows for fine record ' || p_payment_id || '.');
    WHEN OTHERS THEN
      v_code := SQLCODE;
      v_msg  := SQLERRM;
      ROLLBACK TO SAVEPOINT sp_pay_fine;
      IF v_code BETWEEN -20999 AND -20001 THEN
        RAISE;
      END IF;
      RAISE_APPLICATION_ERROR(-20999, 'pay_fine failed: ' || v_msg);
  END pay_fine;

  ---------------------------------------------------------------------------
  -- mark_overdue_loans  (each changed row is audited by the trigger)
  ---------------------------------------------------------------------------
  PROCEDURE mark_overdue_loans (p_updated OUT NUMBER) IS
    v_code PLS_INTEGER;
    v_msg  VARCHAR2(4000);
  BEGIN
    SAVEPOINT sp_mark_overdue;

    UPDATE book_loans
       SET status = 'OVERDUE'
     WHERE status = 'ISSUED'
       AND due_date < TRUNC(SYSDATE);

    p_updated := SQL%ROWCOUNT;
  EXCEPTION
    WHEN OTHERS THEN
      v_code := SQLCODE;
      v_msg  := SQLERRM;
      ROLLBACK TO SAVEPOINT sp_mark_overdue;
      p_updated := 0;
      IF v_code BETWEEN -20999 AND -20001 THEN
        RAISE;
      END IF;
      RAISE_APPLICATION_ERROR(-20999, 'mark_overdue_loans failed: ' || v_msg);
  END mark_overdue_loans;

END pkg_library_mgmt;
/
SHOW ERRORS PACKAGE BODY pkg_library_mgmt

-- =============================================================================
-- STANDALONE WRAPPERS
-- Thin stored subprograms with the exact signatures from the specification.
-- They delegate to the package, so there is one source of truth for the logic.
-- =============================================================================
CREATE OR REPLACE PROCEDURE issue_book (p_member_id IN NUMBER,
                                        p_book_id   IN NUMBER) AS
BEGIN
  pkg_library_mgmt.issue_book(p_member_id, p_book_id);
END issue_book;
/
SHOW ERRORS PROCEDURE issue_book

CREATE OR REPLACE PROCEDURE return_book (p_loan_id IN NUMBER) AS
BEGIN
  pkg_library_mgmt.return_book(p_loan_id);
END return_book;
/
SHOW ERRORS PROCEDURE return_book

CREATE OR REPLACE FUNCTION get_member_fine_balance (p_member_id IN NUMBER)
  RETURN NUMBER AS
BEGIN
  RETURN pkg_library_mgmt.get_member_fine_balance(p_member_id);
END get_member_fine_balance;
/
SHOW ERRORS FUNCTION get_member_fine_balance

PROMPT Package and wrappers created.
