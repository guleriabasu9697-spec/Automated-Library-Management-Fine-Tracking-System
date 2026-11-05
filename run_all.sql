-- ============================================================================
-- MASTER RUNNER SCRIPT: run_all.sql
-- Project: Library Management System
-- Purpose: Executes modular SQL scripts in sequential order.
-- Usage  : In Oracle SQL Developer or SQL*Plus, run:
--          @run_all.sql
-- ============================================================================

SET ECHO OFF;
SET FEEDBACK ON;
SET SERVEROUTPUT ON SIZE 1000000;

PROMPT ========================================================================
PROMPT EXECUTING 01_schema_and_data.sql...
PROMPT ========================================================================
@01_schema_and_data.sql

PROMPT ========================================================================
PROMPT EXECUTING 02_triggers.sql...
PROMPT ========================================================================
@02_triggers.sql

PROMPT ========================================================================
PROMPT EXECUTING 03_procedures_and_functions.sql...
PROMPT ========================================================================
@03_procedures_and_functions.sql

PROMPT ========================================================================
PROMPT EXECUTING 04_test_cases.sql...
PROMPT ========================================================================
@04_test_cases.sql

PROMPT ========================================================================
PROMPT MASTER RUN COMPLETE!
PROMPT ========================================================================
========================================================================
EXECUTING 01_schema_and_data.sql...
========================================================================
1. Cleaning up any pre-existing tables and sequences...
   PL/SQL procedure successfully completed. (Tables and sequences reset)

2. Creating Sequences for Primary Keys...
   Sequence book_seq created (Starts at 101).
   Sequence member_seq created (Starts at 1).
   Sequence loan_seq created (Starts at 1001).
   Sequence fine_seq created (Starts at 5001).

3. Creating Tables with Constraints...
   Table BOOKS created (PK: book_id, CHECK: status IN ('AVAILABLE', 'BORROWED')).
   Table MEMBERS created (PK: member_id, UNIQUE: email, CHECK: status IN ('ACTIVE', 'SUSPENDED')).
   Table LOANS created (PK: loan_id, FKs: book_id, member_id, CHECK: status IN ('ISSUED', 'RETURNED')).
   Table FINES created (PK: fine_id, FK: loan_id UNIQUE, CHECK: payment_status IN ('PENDING', 'PAID')).

4. Populating Sample Data...
   5 books, 4 members, and 2 seed loans inserted and committed.

========================================================================
EXECUTING 02_triggers.sql...
========================================================================
Trigger TRG_SYNC_BOOK_AVAILABILITY created with No errors.

========================================================================
EXECUTING 03_procedures_and_functions.sql...
========================================================================
Function  CALCULATE_FINE           created with No errors.
Procedure ISSUE_BOOK               created with No errors.
Procedure RETURN_BOOK              created with No errors.
Procedure DISPLAY_MEMBER_HISTORY   created with No errors.

========================================================================
EXECUTING 04_test_cases.sql...
========================================================================
[TEST 1] Issue Book 103 ('Introduction to Algorithms') to Member 1 ('Alice Johnson')
----------------------------------------------------
SUCCESS: Book issued successfully!
Loan ID     : 1003
Book Title  : Introduction to Algorithms (ID: 103)
Member      : Alice Johnson (ID: 1)
Issue Date  : 2026-11-03
Due Date    : 2026-11-17
Book Status : Changed to BORROWED by Trigger
----------------------------------------------------
Verification Query: Book 103 status is now BORROWED.

[TEST 2] Exception Test: Attempt to issue already borrowed Book 101
ERROR: Book "Database System Concepts" (ID: 101) is already BORROWED and unavailable.

[TEST 3] Exception Test: Attempt to issue to non-existent Member 999
ERROR: Member ID 999 does not exist.

[TEST 4] Exception Test: Attempt to issue to suspended Member 4 ('Diana Prince')
ERROR: Member "Diana Prince" (ID: 4) is SUSPENDED. Cannot issue books.

[TEST 5] SQL Function Test: Calculate Overdue Fine on Loan 1001 (Due 6 days ago)
   LOAN_ID    BOOK_ID  MEMBER_ID  DUE_DATE     DAYS_OVERDUE  CALCULATED_FINE_AMOUNT
---------- ---------- ---------- ------------ ------------  ----------------------
      1001        101          1  28-OCT-2026            6                   $12.00

[TEST 6] Return Overdue Book (Loan 1001)
----------------------------------------------------
SUCCESS: Book returned successfully!
Loan ID      : 1001
Book Title   : Database System Concepts (ID: 101)
Member       : Alice Johnson (ID: 1)
Due Date     : 2026-10-28
Return Date  : 2026-11-03
Overdue Days : 6 day(s)
Fine Imposed : $12.00 (Fine ID: 5001, Status: PENDING)
Book Status  : Changed to AVAILABLE by Trigger
----------------------------------------------------
Verification Query: Book 101 status is now AVAILABLE.
Verification Query: Record in FINES table created for Loan 1001 with fine $12.00.

[TEST 7] Exception Test: Attempt to return already returned Loan 1001
ERROR: Loan ID 1001 has already been returned.

[TEST 8] Exception Test: Attempt to return non-existent Loan 9999
ERROR: Loan ID 9999 does not exist.

[TEST 9] Procedure Test: Display History for Member 1 ('Alice Johnson')
========================================================================================
BORROWING HISTORY FOR MEMBER: ALICE JOHNSON (ID: 1)
Email: alice.johnson@example.com | Status: ACTIVE
========================================================================================
Loan ID  Book Title                    Issue Date   Due Date     Return Date  Status    Fine ($)  Payment 
----------------------------------------------------------------------------------------------------------
1003     Introduction to Algorithms    2026-11-03   2026-11-17   N/A          ISSUED    0.00      NONE    
1001     Database System Concepts      2026-10-14   2026-10-28   2026-11-03   RETURNED  12.00     PENDING 
========================================================================================
Total Loans Found: 2
========================================================================================

[TEST 10] Procedure Test: Display History for Member 3 (No Loans)
========================================================================================
BORROWING HISTORY FOR MEMBER: CHARLIE BROWN (ID: 3)
Email: charlie.brown@example.com | Status: ACTIVE
========================================================================================
No borrowing records found for this member.
Total Loans Found: 0
========================================================================================

[TEST 11] Exception Test: Display History for invalid Member 999
ERROR: Member ID 999 does not exist.

========================================================================
MASTER RUN COMPLETE!
========================================================================

