-- ============================================================================
-- SCRIPT 04: COMPREHENSIVE TEST SUITE
-- Project   : Library Management System (Oracle PL/SQL Mini Project)
-- Purpose   : Demonstrates and verifies all procedures, functions, triggers,
--             and exception handling scenarios.
-- ============================================================================

SET SERVEROUTPUT ON SIZE 1000000;
SET LINESIZE 200;
SET PAGESIZE 50;

PROMPT ================================================================================
PROMPT TEST 1: ISSUE A BOOK TO AN ACTIVE MEMBER (SUCCESS PATH)
PROMPT Issuing Book 103 ('Introduction to Algorithms') to Member 1 ('Alice Johnson')
PROMPT ================================================================================
BEGIN
    issue_book(p_book_id => 103, p_member_id => 1, p_loan_days => 14);
END;
/

PROMPT
PROMPT Verify that the trigger updated Book 103 status to BORROWED:
SELECT book_id, title, status FROM books WHERE book_id = 103;

PROMPT
PROMPT ================================================================================
PROMPT TEST 2: ATTEMPT TO ISSUE AN ALREADY BORROWED BOOK (EXCEPTION HANDLING)
PROMPT Attempting to issue Book 101 (already borrowed) to Member 2 ('Bob Smith')
PROMPT ================================================================================
BEGIN
    issue_book(p_book_id => 101, p_member_id => 2);
END;
/

PROMPT
PROMPT ================================================================================
PROMPT TEST 3: ATTEMPT TO ISSUE TO A NON-EXISTENT MEMBER (EXCEPTION HANDLING)
PROMPT Attempting to issue Book 104 to Member ID 999
PROMPT ================================================================================
BEGIN
    issue_book(p_book_id => 104, p_member_id => 999);
END;
/

PROMPT
PROMPT ================================================================================
PROMPT TEST 4: ATTEMPT TO ISSUE TO A SUSPENDED MEMBER (EXCEPTION HANDLING)
PROMPT Attempting to issue Book 104 to Member 4 ('Diana Prince', status = 'SUSPENDED')
PROMPT ================================================================================
BEGIN
    issue_book(p_book_id => 104, p_member_id => 4);
END;
/

PROMPT
PROMPT ================================================================================
PROMPT TEST 5: CALCULATE OVERDUE FINE VIA SQL FUNCTION
PROMPT Loan 1001 was due 6 days ago. Fine rate is $2.00/day. Expected fine: $12.00
PROMPT ================================================================================
SELECT loan_id,
       book_id,
       member_id,
       loan_date,
       due_date,
       TRUNC(SYSDATE) - due_date AS days_overdue,
       calculate_fine(loan_id)   AS calculated_fine_amount
FROM loans
WHERE loan_id = 1001;

PROMPT
PROMPT ================================================================================
PROMPT TEST 6: RETURN AN OVERDUE BOOK AND GENERATE FINE RECORD (SUCCESS PATH)
PROMPT Returning Loan 1001 (Book 101). Expected: Book status AVAILABLE, Fine recorded.
PROMPT ================================================================================
BEGIN
    return_book(p_loan_id => 1001, p_return_date => SYSDATE);
END;
/

PROMPT
PROMPT Verify that the trigger reset Book 101 status back to AVAILABLE:
SELECT book_id, title, status FROM books WHERE book_id = 101;

PROMPT
PROMPT Verify fine generated in the FINES table:
SELECT * FROM fines WHERE loan_id = 1001;

PROMPT
PROMPT ================================================================================
PROMPT TEST 7: ATTEMPT TO RETURN AN ALREADY RETURNED LOAN (EXCEPTION HANDLING)
PROMPT Calling return_book again on Loan 1001
PROMPT ================================================================================
BEGIN
    return_book(p_loan_id => 1001);
END;
/

PROMPT
PROMPT ================================================================================
PROMPT TEST 8: ATTEMPT TO RETURN A NON-EXISTENT LOAN (EXCEPTION HANDLING)
PROMPT Calling return_book with invalid Loan ID 9999
PROMPT ================================================================================
BEGIN
    return_book(p_loan_id => 9999);
END;
/

PROMPT
PROMPT ================================================================================
PROMPT TEST 9: DISPLAY BORROWING HISTORY FOR MEMBER 1 (ALICE JOHNSON)
PROMPT Should display 2 records: Loan 1001 (Returned with fine) and Loan 1003 (Issued)
PROMPT ================================================================================
BEGIN
    display_member_history(p_member_id => 1);
END;
/

PROMPT
PROMPT ================================================================================
PROMPT TEST 10: DISPLAY BORROWING HISTORY FOR MEMBER 3 (CHARLIE BROWN - NO LOANS)
PROMPT ================================================================================
BEGIN
    display_member_history(p_member_id => 3);
END;
/

PROMPT
PROMPT ================================================================================
PROMPT TEST 11: DISPLAY BORROWING HISTORY FOR INVALID MEMBER ID (EXCEPTION HANDLING)
PROMPT ================================================================================
BEGIN
    display_member_history(p_member_id => 999);
END;
/

PROMPT
PROMPT All tests completed!

