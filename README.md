# Library Management System - Web Frontend

A responsive web frontend for the **Oracle PL/SQL Automated Library Management System**.

## 🚀 How to Open and Run

There are **no build steps, node modules, or dependencies** required to run the frontend!

### Option 1: Double Click (Instant)
- On Windows: Double-click **`open_frontend.bat`** (or open **`frontend/index.html`** in Chrome, Edge, Brave, or Firefox).

### Option 2: PowerShell
```powershell
.\open_frontend.ps1
```

---

## 🌟 Key Features

### 1. 📊 Interactive Dashboard
- Live KPIs: Total Books, Available/Borrowed breakdown, Active Members, Suspended Members, Active Loans, Overdue Loans, and Total Fines.
- Recent transaction feed showing real-time updates.

### 2. 📚 Books Inventory (`BOOKS`)
- Full search and filtering by Category and Status (`AVAILABLE` vs `BORROWED`).
- **Add New Book** modal with automatic sequence generation (`book_seq.NEXTVAL`).
- One-click "Issue Book" quick action.

### 3. 👥 Members Directory (`MEMBERS`)
- Member table with status badges (`ACTIVE` vs `SUSPENDED`).
- Constraint check: Toggle member status to test `SUSPENDED` member exception handling.
- **Register Member** modal with automatic sequence generation (`member_seq.NEXTVAL`) and email uniqueness checks.

### 4. ✍️ Issue Book Procedure (`issue_book`)
- Form to execute the stored procedure `issue_book(p_book_id, p_member_id, p_loan_days)`.
- Validates that the member exists and is not `SUSPENDED`.
- Validates that the book exists and is `AVAILABLE`.
- Shows automatic trigger firing: `trg_sync_book_availability` updates book status to `BORROWED`.
- Prints formatted receipt matching the Oracle `DBMS_OUTPUT`.

### 5. 🔄 Return Book & Overdue Fines (`return_book` & `calculate_fine`)
- Select an active loan to return.
- Customizable return date picker with live fine calculation preview ($2.00/day overdue).
- Automatic execution of:
  - `calculate_fine` function.
  - Automatic `FINES` table entry creation if returned overdue.
  - Automatic trigger execution `trg_sync_book_availability` flipping book status back to `AVAILABLE`.
- Fines audit table with one-click **"Pay Fine"** action.

### 6. 📜 Member Borrowing History (`display_member_history`)
- Select any member to view their complete history.
- Displays both an interactive table AND an exact replica of the **SQL*Plus ASCII DBMS_OUTPUT terminal table** created by the PL/SQL cursor procedure.

### 7. 💻 Real-Time Oracle DBMS_OUTPUT Console
- Collapsible bottom console dock showing:
  - `[SQL]` Statements executed.
  - `[TRIGGER]` Real-time notifications when `trg_sync_book_availability` fires.
  - `[OUTPUT]` Procedure `DBMS_OUTPUT.PUT_LINE` logs.
  - `[ERROR]` PL/SQL user-defined and system exception messages.

### 8. 🗄️ Database Inspector & Reset
- Inspect the raw relational tables and sequence counters in real time.
- **"↺ Reset DB"** button to restore tables back to original seed data (`01_schema_and_data.sql`).

---

## 🔌 Optional Real Oracle DB Backend Integration

If you want to connect this frontend to a real Oracle Database 19c/21c/XE instance, check the `backend/` directory:

1. Install requirements:
   ```bash
   pip install flask flask-cors oracledb
   ```
2. Start the API:
   ```bash
   python backend/server.py
   ```
3. The server connects directly using Oracle's official `oracledb` Python driver and invokes the stored procedures `issue_book` and `return_book`.

