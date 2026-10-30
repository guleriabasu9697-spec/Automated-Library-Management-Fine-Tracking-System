# Automated Library Management & Fine Tracking System (Oracle PL/SQL)

Target: Oracle Database 12c or later. No special privileges beyond `CREATE TABLE/SEQUENCE/PROCEDURE/TRIGGER`.

## Files (run in this order)

| File | Purpose |
|---|---|
| `00_install.sql` | Runs 01 to 05 in order (SQL*Plus / SQLcl) |
| `01_schema.sql` | Cleanup, 5 sequences, 5 tables, constraints, indexes |
| `02_seed_data.sql` | 10 books, 6 members, 7 loans, 2 fines, 4 audit rows |
| `03_triggers.sql` | Inventory guard + loan-status audit trigger |
| `04_pkg_library_mgmt.sql` | Package spec/body + standalone wrappers |
| `05_test_cases.sql` | Anonymous blocks: success, failure, audit proof |

## Entity model

```mermaid
erDiagram
    MEMBERS ||--o{ BOOK_LOANS : borrows
    BOOKS   ||--o{ BOOK_LOANS : "is lent as"
    BOOK_LOANS ||--o| FINE_PAYMENTS : "may incur"
    MEMBERS ||--o{ FINE_PAYMENTS : owes
    BOOK_LOANS ||..o{ AUDIT_LOGS : "status change logged"
```

## Business rules

* Loan period 14 days; fine = 5 per overdue day, capped at 500 per loan (constants in the package spec).
* A member may borrow only if: ACTIVE and not expired, fine balance = 0, active loans < `max_loans`, the book exists, a copy is available, and the member does not already hold that title.
* Active loan = status `ISSUED` or `OVERDUE`.
* Procedures never `COMMIT`; each rolls back to its own savepoint on failure.

## Error codes

| Code | Exception | Raised when |
|---|---|---|
| -20001 | `ex_book_unavailable` | No copies left |
| -20002 | `ex_outstanding_fines` | Member has unpaid/partial fines |
| -20003 | `ex_max_loans_reached` | Member at loan limit |
| -20004 | `ex_member_inactive` | Suspended / expired member |
| -20005 | `ex_member_not_found` | Unknown member (from `NO_DATA_FOUND`) |
| -20006 | `ex_book_not_found` | Unknown book (from `NO_DATA_FOUND`) |
| -20007 | `ex_loan_not_found` | Unknown loan |
| -20008 | `ex_loan_already_closed` | Loan not ISSUED/OVERDUE |
| -20009 | `ex_invalid_payment` | Bad / excessive / repeated payment |
| -20010 | `ex_negative_stock` | Trigger: available_copies < 0 |
| -20011 | `ex_stock_exceeds_total` | Trigger: available > total |
| -20012 | `ex_duplicate_loan` | Member already holds this book |
| -20013 | `ex_data_integrity` | `TOO_MANY_ROWS` / unexpected missing data |
| -20014 | `ex_payment_not_found` | Unknown fine record |
| -20999 | `ex_unexpected_error` | Any other Oracle error, wrapped with context |

## Design notes

* **Encapsulation**: `lock_member`, `lock_book`, `count_active_loans`, `find_active_loan`, `calc_fine`, `write_audit`, `assert_member_exists` are private to the package body.
* **Concurrency**: member then book rows are locked with `SELECT ... FOR UPDATE` (always in that order) so two sessions cannot take the last copy or exceed the loan limit.
* **Defence in depth**: stock rules exist as a trigger (friendly message) and a CHECK constraint; "one active loan per member per title" is enforced by a function-based unique index.
* **Error passthrough**: `WHEN OTHERS` handlers re-raise anything in -20999..-20001 untouched and wrap everything else as -20999, so business errors are never masked.
* **Overloading**: `issue_book` exists with and without the `OUT p_loan_id` parameter. Standalone `issue_book`, `return_book`, `get_member_fine_balance` delegate to the package.

## Expected test results (fresh seed)

1. Test 1: stock 3 -> 2 -> 3, fine 0.
2. Test 2: 1 loan flagged overdue; loan 5 returned with fine 80.
3. Test 3: `ex_outstanding_fines` (-20002) for Rohan.
4. Test 4: -20003, -20001, -20004, -20005, -20006, then OK + -20012, -20008, -20007.
5. Test 5: blocked after 20, over-payment rejected, allowed after the full 50 is paid.
6. Test 6: -20010 and -20011 from the trigger.
7. Test 7: audit rows with `audit_id >= 1000` show the runtime status changes; the integrity query returns no rows.

To reset the demo, re-run `01_schema.sql` and `02_seed_data.sql`.
