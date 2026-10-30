-- =============================================================================
-- 03_triggers.sql
-- 1) trg_books_validate_stock : BEFORE INSERT OR UPDATE on BOOKS
-- 2) trg_loans_status_audit   : AFTER UPDATE on BOOK_LOANS -> AUDIT_LOGS
-- =============================================================================
SET DEFINE OFF

-- -----------------------------------------------------------------------------
-- 1. Inventory guard
--    Fires BEFORE the CHECK constraint is evaluated, so callers get a clear,
--    business-level message (ORA-20010 / ORA-20011) instead of a generic
--    ORA-02290. The constraint remains as a second line of defence.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_books_validate_stock
BEFORE INSERT OR UPDATE ON books
FOR EACH ROW
BEGIN
  IF :NEW.available_copies < 0 THEN
    RAISE_APPLICATION_ERROR(-20010,
      'Inventory error: available_copies cannot be negative (book_id='
      || :NEW.book_id || ', attempted value=' || :NEW.available_copies || ').');
  END IF;

  IF :NEW.available_copies > :NEW.total_copies THEN
    RAISE_APPLICATION_ERROR(-20011,
      'Inventory error: available_copies (' || :NEW.available_copies
      || ') cannot exceed total_copies (' || :NEW.total_copies
      || ') for book_id=' || :NEW.book_id || '.');
  END IF;

  :NEW.updated_at := SYSDATE;
END trg_books_validate_stock;
/
SHOW ERRORS TRIGGER trg_books_validate_stock

-- -----------------------------------------------------------------------------
-- 2. Loan status audit
--    "UPDATE OF status" + WHEN clause means the trigger body only runs when the
--    status value really changes (ISSUED->OVERDUE, OVERDUE->RETURNED, ...).
--    changed_by / changed_at come from the AUDIT_LOGS column defaults.
--    No COMMIT here: the audit row lives or dies with the business transaction.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_loans_status_audit
AFTER UPDATE OF status ON book_loans
FOR EACH ROW
WHEN (OLD.status <> NEW.status)
BEGIN
  INSERT INTO audit_logs
    (audit_id, table_name, record_id, action_type, old_value, new_value, details)
  VALUES
    (seq_audit_id.NEXTVAL, 'BOOK_LOANS', :NEW.loan_id, 'STATUS_CHANGE',
     :OLD.status, :NEW.status,
     'member_id=' || :NEW.member_id || ', book_id=' || :NEW.book_id
       || ', due=' || TO_CHAR(:NEW.due_date, 'YYYY-MM-DD')
       || ', fine=' || TO_CHAR(:NEW.fine_amount, 'FM999990.00'));
END trg_loans_status_audit;
/
SHOW ERRORS TRIGGER trg_loans_status_audit

PROMPT Triggers created.
