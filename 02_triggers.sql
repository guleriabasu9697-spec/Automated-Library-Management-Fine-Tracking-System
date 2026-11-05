-- ============================================================================
-- SCRIPT 02: DATABASE TRIGGERS
-- Project   : Library Management System (Oracle PL/SQL Mini Project)
-- Purpose   : Automatically synchronizes the book availability status in the
--             BOOKS table whenever a loan record is created (status = 'ISSUED')
--             or updated (status = 'RETURNED').
-- ============================================================================

CREATE OR REPLACE TRIGGER trg_sync_book_availability
AFTER INSERT OR UPDATE OF status ON loans
FOR EACH ROW
BEGIN
    -- Case 1: A new loan is recorded with status 'ISSUED' -> mark book as BORROWED
    IF INSERTING THEN
        IF :NEW.status = 'ISSUED' THEN
            UPDATE books
            SET status = 'BORROWED'
            WHERE book_id = :NEW.book_id;
        END IF;

    -- Case 2: An existing loan is marked as 'RETURNED' -> mark book back as AVAILABLE
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

PROMPT Trigger trg_sync_book_availability compiled successfully!

