-- =============================================================================
-- 05_test_cases.sql
-- Execution scripts / demonstration blocks.
-- Run AFTER 01..04, on freshly seeded data (re-run 01 + 02 to reset).
-- Tests are meant to be run in order; later tests rely on earlier ones.
-- =============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 220
SET PAGESIZE 100
SET DEFINE OFF
COLUMN title        FORMAT A36
COLUMN details      FORMAT A70
COLUMN changed_by   FORMAT A12
COLUMN table_name   FORMAT A14
COLUMN first_name   FORMAT A10

PROMPT
PROMPT ===== BASELINE ==========================================================
SELECT book_id, title, total_copies, available_copies FROM books ORDER BY book_id;
SELECT member_id, first_name, status, max_loans,
       pkg_library_mgmt.get_member_fine_balance(member_id) AS fine_balance
  FROM members ORDER BY member_id;

-- =============================================================================
-- TEST 1 (a) : Successful checkout and on-time return
--   Priya (member 2) borrows "Wings of Fire" (book 5, 3 copies).
--   EXPECT: available 3 -> 2 -> 3, loan RETURNED, fine 0
-- =============================================================================
PROMPT
PROMPT ===== TEST 1: successful checkout and return ===========================
DECLARE
  v_loan_id NUMBER;
  v_status  book_loans.status%TYPE;
  v_fine    book_loans.fine_amount%TYPE;

  FUNCTION avail (p_book_id IN NUMBER) RETURN NUMBER IS
    v NUMBER;
  BEGIN
    SELECT available_copies INTO v FROM books WHERE book_id = p_book_id;
    RETURN v;
  END avail;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Available copies before issue : ' || avail(5));

  pkg_library_mgmt.issue_book(2, 5, v_loan_id);
  DBMS_OUTPUT.PUT_LINE('Issued loan_id=' || v_loan_id
                       || ' | available copies now   : ' || avail(5));

  pkg_library_mgmt.return_book(v_loan_id);
  SELECT status, fine_amount INTO v_status, v_fine
    FROM book_loans WHERE loan_id = v_loan_id;
  DBMS_OUTPUT.PUT_LINE('Returned loan_id=' || v_loan_id || ' status=' || v_status
                       || ' fine=' || v_fine || ' | available copies now: ' || avail(5));
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('TEST 1 FAILED: ' || SQLERRM);
END;
/

-- =============================================================================
-- TEST 2 (a) : Overdue sweep + late return generates a fine
--   Loan 5 (Simran, book 4) is 16 days past due.
--   EXPECT: 1 loan flagged OVERDUE, then returned with fine = 16 * 5 = 80,
--           Simran's balance becomes 80.00
-- =============================================================================
PROMPT
PROMPT ===== TEST 2: overdue sweep and late return with fine =================
DECLARE
  v_updated NUMBER;
  v_balance NUMBER;
BEGIN
  pkg_library_mgmt.mark_overdue_loans(v_updated);
  DBMS_OUTPUT.PUT_LINE('Loans flagged OVERDUE        : ' || v_updated);

  pkg_library_mgmt.return_book(5);
  v_balance := pkg_library_mgmt.get_member_fine_balance(4);
  DBMS_OUTPUT.PUT_LINE('Simran fine balance after late return: ' || TO_CHAR(v_balance, 'FM999990.00'));
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('TEST 2 FAILED: ' || SQLERRM);
END;
/

-- =============================================================================
-- TEST 3 (b) : Business-rule failure - borrowing while fines are unpaid
--   Rohan (member 3) owes 50.
--   EXPECT: ORA-20002 caught as pkg_library_mgmt.ex_outstanding_fines
-- =============================================================================
PROMPT
PROMPT ===== TEST 3: borrow blocked by outstanding fines ======================
BEGIN
  pkg_library_mgmt.issue_book(3, 7);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: issue succeeded despite unpaid fines!');
  ROLLBACK;
EXCEPTION
  WHEN pkg_library_mgmt.ex_outstanding_fines THEN
    DBMS_OUTPUT.PUT_LINE('PASS - ex_outstanding_fines caught');
    DBMS_OUTPUT.PUT_LINE('  SQLCODE = ' || SQLCODE);
    DBMS_OUTPUT.PUT_LINE('  ' || SQLERRM);
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('TEST 3 FAILED with unexpected error: ' || SQLERRM);
END;
/

-- =============================================================================
-- TEST 4 : Remaining business rules and validation errors
-- =============================================================================
PROMPT
PROMPT ===== TEST 4: other business rules =====================================
DECLARE
  v_loan NUMBER;
  v_dup  NUMBER;

  -- Local helper: try to issue and report which named exception fired.
  FUNCTION attempt (p_label  IN VARCHAR2,
                    p_member IN NUMBER,
                    p_book   IN NUMBER) RETURN NUMBER IS
    v_loan_id NUMBER := NULL;
  BEGIN
    BEGIN
      pkg_library_mgmt.issue_book(p_member, p_book, v_loan_id);
      DBMS_OUTPUT.PUT_LINE('[ OK     ] ' || p_label || ' -> loan_id=' || v_loan_id);
    EXCEPTION
      WHEN pkg_library_mgmt.ex_max_loans_reached THEN
        DBMS_OUTPUT.PUT_LINE('[ RULE   ] ' || p_label || ' -> ex_max_loans_reached  | ' || SQLERRM);
      WHEN pkg_library_mgmt.ex_book_unavailable THEN
        DBMS_OUTPUT.PUT_LINE('[ RULE   ] ' || p_label || ' -> ex_book_unavailable   | ' || SQLERRM);
      WHEN pkg_library_mgmt.ex_member_inactive THEN
        DBMS_OUTPUT.PUT_LINE('[ RULE   ] ' || p_label || ' -> ex_member_inactive    | ' || SQLERRM);
      WHEN pkg_library_mgmt.ex_duplicate_loan THEN
        DBMS_OUTPUT.PUT_LINE('[ RULE   ] ' || p_label || ' -> ex_duplicate_loan     | ' || SQLERRM);
      WHEN pkg_library_mgmt.ex_member_not_found THEN
        DBMS_OUTPUT.PUT_LINE('[ LOOKUP ] ' || p_label || ' -> ex_member_not_found   | ' || SQLERRM);
      WHEN pkg_library_mgmt.ex_book_not_found THEN
        DBMS_OUTPUT.PUT_LINE('[ LOOKUP ] ' || p_label || ' -> ex_book_not_found     | ' || SQLERRM);
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[ ERROR  ] ' || p_label || ' -> ' || SQLERRM);
    END;
    RETURN v_loan_id;                -- NULL when the attempt was rejected
  END attempt;
BEGIN
  v_loan := attempt('Aarav already at 3/3 loans, wants book 8   ', 1, 8);   -- -20003
  v_loan := attempt('Priya wants Clean Code (0 copies left)      ', 2, 3);   -- -20001
  v_loan := attempt('Karan is SUSPENDED, wants book 8            ', 5, 8);   -- -20004
  v_loan := attempt('Unknown member 999                          ', 999, 8); -- -20005
  v_loan := attempt('Unknown book 999                            ', 2, 999); -- -20006

  -- Duplicate-loan rule: borrow, try again, then clean up
  v_loan := attempt('Priya borrows Effective Java (first time)   ', 2, 9);   -- OK
  v_dup  := attempt('Priya borrows Effective Java (second time)  ', 2, 9);   -- -20012
  IF v_loan IS NOT NULL THEN
    pkg_library_mgmt.return_book(v_loan);
  END IF;

  -- Returning an already-returned / non-existent loan
  BEGIN
    pkg_library_mgmt.return_book(7);
  EXCEPTION
    WHEN pkg_library_mgmt.ex_loan_already_closed THEN
      DBMS_OUTPUT.PUT_LINE('[ RULE   ] Return loan 7 again           -> ex_loan_already_closed | ' || SQLERRM);
  END;
  BEGIN
    pkg_library_mgmt.return_book(99999);
  EXCEPTION
    WHEN pkg_library_mgmt.ex_loan_not_found THEN
      DBMS_OUTPUT.PUT_LINE('[ LOOKUP ] Return loan 99999             -> ex_loan_not_found      | ' || SQLERRM);
  END;
  COMMIT;
END;
/

-- =============================================================================
-- TEST 5 : Fine settlement unlocks borrowing
--   Rohan pays 50 in two instalments (20 + 30), then can borrow again.
--   EXPECT: still blocked after the partial payment, allowed after the final one
-- =============================================================================
PROMPT
PROMPT ===== TEST 5: pay fine, then borrow again ==============================
DECLARE
  v_loan NUMBER;
BEGIN
  pkg_library_mgmt.pay_fine(1, 20, 'CASH');
  DBMS_OUTPUT.PUT_LINE('After partial payment, balance = '
    || TO_CHAR(pkg_library_mgmt.get_member_fine_balance(3), 'FM999990.00'));

  BEGIN
    pkg_library_mgmt.issue_book(3, 7);
    DBMS_OUTPUT.PUT_LINE('UNEXPECTED: borrow allowed with a remaining balance');
    ROLLBACK;
  EXCEPTION
    WHEN pkg_library_mgmt.ex_outstanding_fines THEN
      DBMS_OUTPUT.PUT_LINE('Still blocked (PARTIAL fine): ' || SQLERRM);
  END;

  -- Over-payment must be rejected
  BEGIN
    pkg_library_mgmt.pay_fine(1, 1000, 'CASH');
  EXCEPTION
    WHEN pkg_library_mgmt.ex_invalid_payment THEN
      DBMS_OUTPUT.PUT_LINE('Over-payment rejected: ' || SQLERRM);
  END;

  pkg_library_mgmt.pay_fine(1, 30, 'UPI');
  DBMS_OUTPUT.PUT_LINE('After final payment, balance   = '
    || TO_CHAR(pkg_library_mgmt.get_member_fine_balance(3), 'FM999990.00'));

  pkg_library_mgmt.issue_book(3, 7, v_loan);
  DBMS_OUTPUT.PUT_LINE('Borrow now allowed -> loan_id=' || v_loan);
  pkg_library_mgmt.return_book(v_loan);
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('TEST 5 FAILED: ' || SQLERRM);
END;
/

-- =============================================================================
-- TEST 6 : Inventory trigger blocks invalid stock values
--   EXPECT: ORA-20010 (negative) and ORA-20011 (exceeds total)
-- =============================================================================
PROMPT
PROMPT ===== TEST 6: inventory validation trigger =============================
BEGIN
  BEGIN
    UPDATE books SET available_copies = -1 WHERE book_id = 1;
    DBMS_OUTPUT.PUT_LINE('UNEXPECTED: negative stock accepted');
  EXCEPTION
    WHEN pkg_library_mgmt.ex_negative_stock THEN
      DBMS_OUTPUT.PUT_LINE('PASS - negative stock blocked: ' || SQLERRM);
  END;

  BEGIN
    UPDATE books SET available_copies = total_copies + 5 WHERE book_id = 1;
    DBMS_OUTPUT.PUT_LINE('UNEXPECTED: stock above total accepted');
  EXCEPTION
    WHEN pkg_library_mgmt.ex_stock_exceeds_total THEN
      DBMS_OUTPUT.PUT_LINE('PASS - stock above total blocked: ' || SQLERRM);
  END;
  ROLLBACK;
END;
/

-- =============================================================================
-- TEST 7 (c) : Prove the AFTER UPDATE trigger wrote to AUDIT_LOGS
--   Rows with an audit_id >= 1000 were written at runtime by
--   trg_loans_status_audit (STATUS_CHANGE) or pkg_library_mgmt (PAYMENT).
--   EXPECT: ISSUED->OVERDUE and OVERDUE->RETURNED for loan 5, and
--           ISSUED->RETURNED for the loans created in tests 1, 4 and 5.
-- =============================================================================
PROMPT
PROMPT ===== TEST 7: audit trail written by the trigger =======================
SELECT audit_id, table_name, record_id, action_type, old_value, new_value,
       changed_by, TO_CHAR(changed_at, 'YYYY-MM-DD HH24:MI:SS') AS changed_at, details
  FROM audit_logs
 WHERE audit_id >= 1000
 ORDER BY audit_id;

PROMPT
PROMPT --- Full life-cycle of loan 5 (historic + live audit rows) -------------
SELECT audit_id, action_type, old_value, new_value, details
  FROM audit_logs
 WHERE table_name = 'BOOK_LOANS' AND record_id = 5
 ORDER BY audit_id;

-- =============================================================================
-- FINAL INTEGRITY CHECKS
-- =============================================================================
PROMPT
PROMPT ===== INTEGRITY CHECK: stock vs active loans (expect NO ROWS) ==========
SELECT b.book_id, b.title, b.total_copies, b.available_copies,
       NVL(a.active_loans, 0) AS active_loans
  FROM books b
  LEFT JOIN (SELECT book_id, COUNT(*) AS active_loans
               FROM book_loans
              WHERE status IN ('ISSUED','OVERDUE')
              GROUP BY book_id) a
    ON a.book_id = b.book_id
 WHERE b.available_copies <> b.total_copies - NVL(a.active_loans, 0);

PROMPT
PROMPT ===== FINAL MEMBER FINE BALANCES =======================================
SELECT member_id, first_name, last_name,
       pkg_library_mgmt.get_member_fine_balance(member_id) AS fine_balance
  FROM members ORDER BY member_id;
