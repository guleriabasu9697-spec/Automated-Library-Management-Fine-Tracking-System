/**
 * Library Management System - Frontend PL/SQL Engine & Application Controller
 * Matches Oracle PL/SQL mini-project business rules, triggers, and procedures.
 */

// ============================================================================
// 1. INITIAL SEED DATA (from 01_schema_and_data.sql)
// ============================================================================

const SEED_DATA = {
  books: [
    { book_id: 101, title: 'Database System Concepts', author: 'Abraham Silberschatz', category: 'Computer Science', status: 'BORROWED' },
    { book_id: 102, title: 'Clean Code: Handbook of Agile Software', author: 'Robert C. Martin', category: 'Software Engineering', status: 'AVAILABLE' },
    { book_id: 103, title: 'Introduction to Algorithms', author: 'Thomas H. Cormen', category: 'Computer Science', status: 'AVAILABLE' },
    { book_id: 104, title: 'Design Patterns: Elements of Reusable Code', author: 'Erich Gamma', category: 'Software Engineering', status: 'AVAILABLE' },
    { book_id: 105, title: 'Artificial Intelligence: A Modern Approach', author: 'Stuart Russell', category: 'Artificial Intelligence', status: 'AVAILABLE' }
  ],
  members: [
    { member_id: 1, first_name: 'Alice', last_name: 'Johnson', email: 'alice.johnson@example.com', phone: '555-0101', join_date: '2024-01-15', status: 'ACTIVE' },
    { member_id: 2, first_name: 'Bob', last_name: 'Smith', email: 'bob.smith@example.com', phone: '555-0102', join_date: '2024-02-20', status: 'ACTIVE' },
    { member_id: 3, first_name: 'Charlie', last_name: 'Brown', email: 'charlie.brown@example.com', phone: '555-0103', join_date: '2024-03-10', status: 'ACTIVE' },
    { member_id: 4, first_name: 'Diana', last_name: 'Prince', email: 'diana.prince@example.com', phone: '555-0104', join_date: '2024-04-05', status: 'SUSPENDED' }
  ],
  loans: [
    // Loan 1001: Book 101 to Member 1, issued 20 days ago, due 6 days ago (OVERDUE)
    {
      loan_id: 1001,
      book_id: 101,
      member_id: 1,
      loan_date: offsetDate(-20),
      due_date: offsetDate(-6),
      return_date: null,
      status: 'ISSUED'
    },
    // Loan 1002: Book 102 to Member 2, returned 2 days before due date (ON TIME)
    {
      loan_id: 1002,
      book_id: 102,
      member_id: 2,
      loan_date: offsetDate(-14),
      due_date: offsetDate(0),
      return_date: offsetDate(-2),
      status: 'RETURNED'
    }
  ],
  fines: [],
  sequences: {
    book_seq: 106,
    member_seq: 5,
    loan_seq: 1003,
    fine_seq: 5001
  }
};

// Date helper: returns ISO date YYYY-MM-DD
function offsetDate(daysOffset) {
  const d = new Date();
  d.setDate(d.getDate() + daysOffset);
  return d.toISOString().split('T')[0];
}

function getToday() {
  return new Date().toISOString().split('T')[0];
}

function daysBetween(date1Str, date2Str) {
  const d1 = new Date(date1Str);
  const d2 = new Date(date2Str);
  const diffTime = d2.getTime() - d1.getTime();
  return Math.round(diffTime / (1000 * 3600 * 24));
}

// ============================================================================
// 2. PL/SQL DATABASE ENGINE SIMULATOR
// ============================================================================

class OraclePLEngine {
  constructor() {
    this.storageKey = 'oracle_library_db_v1';
    this.loadState();
  }

  loadState() {
    const saved = localStorage.getItem(this.storageKey);
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        this.books = parsed.books || [];
        this.members = parsed.members || [];
        this.loans = parsed.loans || [];
        this.fines = parsed.fines || [];
        this.sequences = parsed.sequences || { book_seq: 106, member_seq: 5, loan_seq: 1003, fine_seq: 5001 };
        return;
      } catch (e) {
        console.error('Error parsing stored DB state, resetting to seed data.', e);
      }
    }
    this.resetToSeed();
  }

  saveState() {
    localStorage.setItem(this.storageKey, JSON.stringify({
      books: this.books,
      members: this.members,
      loans: this.loans,
      fines: this.fines,
      sequences: this.sequences
    }));
  }

  resetToSeed() {
    this.books = JSON.parse(JSON.stringify(SEED_DATA.books));
    this.members = JSON.parse(JSON.stringify(SEED_DATA.members));
    this.loans = JSON.parse(JSON.stringify(SEED_DATA.loans));
    this.fines = JSON.parse(JSON.stringify(SEED_DATA.fines));
    this.sequences = JSON.parse(JSON.stringify(SEED_DATA.sequences));
    this.saveState();
    logConsole('SYSTEM', 'Oracle database wiped and re-seeded successfully from 01_schema_and_data.sql');
  }

  // --- Sequences ---
  nextVal(seqName) {
    const val = this.sequences[seqName];
    this.sequences[seqName] += 1;
    this.saveState();
    return val;
  }

  // --- Triggers ---
  /**
   * TRIGGER trg_sync_book_availability
   * AFTER INSERT OR UPDATE OF status ON loans FOR EACH ROW
   */
  triggerSyncBookAvailability(action, loanRecord) {
    const book = this.books.find(b => b.book_id === loanRecord.book_id);
    if (!book) return;

    if (action === 'INSERT' && loanRecord.status === 'ISSUED') {
      book.status = 'BORROWED';
      logConsole('TRIGGER', `trg_sync_book_availability FIRED: [AFTER INSERT ON loans] Book ID ${book.book_id} ('${book.title}') status -> 'BORROWED'`);
    } else if (action === 'UPDATE' && loanRecord.status === 'RETURNED') {
      book.status = 'AVAILABLE';
      logConsole('TRIGGER', `trg_sync_book_availability FIRED: [AFTER UPDATE ON loans] Book ID ${book.book_id} ('${book.title}') status -> 'AVAILABLE'`);
    }
    this.saveState();
  }

  // --- Functions ---
  /**
   * FUNCTION calculate_fine(p_loan_id NUMBER, p_return_date DATE) RETURN NUMBER
   * Rate: $2.00 per day overdue
   */
  calculateFine(loanId, returnDate) {
    const loan = this.loans.find(l => l.loan_id === Number(loanId));
    if (!loan) {
      throw new Error(`ORA-20002: Loan ID ${loanId} does not exist.`);
    }

    const effectiveDate = returnDate || loan.return_date || getToday();

    // Check return date >= loan date
    if (new Date(effectiveDate) < new Date(loan.loan_date)) {
      throw new Error(`ORA-20001: Return date cannot be earlier than loan date (${loan.loan_date}).`);
    }

    const fineRate = 2.00;
    const diff = daysBetween(loan.due_date, effectiveDate);

    if (diff > 0) {
      return { overdueDays: diff, fineAmount: Number((diff * fineRate).toFixed(2)) };
    }
    return { overdueDays: 0, fineAmount: 0.00 };
  }

  // --- Procedures ---
  /**
   * PROCEDURE issue_book(p_book_id NUMBER, p_member_id NUMBER, p_loan_days NUMBER DEFAULT 14)
   */
  issueBook(bookId, memberId, loanDays = 14) {
    bookId = Number(bookId);
    memberId = Number(memberId);
    loanDays = Number(loanDays);

    logConsole('SQL', `EXEC issue_book(p_book_id => ${bookId}, p_member_id => ${memberId}, p_loan_days => ${loanDays});`);

    // 1. Validate Member
    const member = this.members.find(m => m.member_id === memberId);
    if (!member) {
      const err = `ERROR: Member ID ${memberId} does not exist.`;
      logConsole('ERROR', err);
      throw new Error(err);
    }

    if (member.status === 'SUSPENDED') {
      const err = `ERROR: Member "${member.first_name} ${member.last_name}" (ID: ${memberId}) is SUSPENDED. Cannot issue books.`;
      logConsole('ERROR', err);
      throw new Error(err);
    }

    // 2. Validate Book
    const book = this.books.find(b => b.book_id === bookId);
    if (!book) {
      const err = `ERROR: Book ID ${bookId} does not exist.`;
      logConsole('ERROR', err);
      throw new Error(err);
    }

    if (book.status !== 'AVAILABLE') {
      const err = `ERROR: Book "${book.title}" (ID: ${bookId}) is already BORROWED and unavailable.`;
      logConsole('ERROR', err);
      throw new Error(err);
    }

    // 3. Insert Loan Record
    const newLoanId = this.nextVal('loan_seq');
    const loanDate = getToday();
    const dueDate = offsetDate(loanDays);

    const newLoan = {
      loan_id: newLoanId,
      book_id: bookId,
      member_id: memberId,
      loan_date: loanDate,
      due_date: dueDate,
      return_date: null,
      status: 'ISSUED'
    };

    this.loans.push(newLoan);
    this.saveState();

    // Trigger fires on INSERT
    this.triggerSyncBookAvailability('INSERT', newLoan);

    // DBMS_OUTPUT formatting
    const output = [
      '----------------------------------------------------',
      'SUCCESS: Book issued successfully!',
      `Loan ID     : ${newLoanId}`,
      `Book Title  : ${book.title} (ID: ${bookId})`,
      `Member      : ${member.first_name} ${member.last_name} (ID: ${memberId})`,
      `Issue Date  : ${loanDate}`,
      `Due Date    : ${dueDate}`,
      `Book Status : Changed to BORROWED by Trigger`,
      '----------------------------------------------------'
    ];

    output.forEach(line => logConsole('OUTPUT', line));
    return { loan: newLoan, book, member, output: output.join('\n') };
  }

  /**
   * PROCEDURE return_book(p_loan_id NUMBER, p_return_date DATE DEFAULT SYSDATE)
   */
  returnBook(loanId, returnDate) {
    loanId = Number(loanId);
    returnDate = returnDate || getToday();

    logConsole('SQL', `EXEC return_book(p_loan_id => ${loanId}, p_return_date => TO_DATE('${returnDate}', 'YYYY-MM-DD'));`);

    // 1. Validate Loan
    const loan = this.loans.find(l => l.loan_id === loanId);
    if (!loan) {
      const err = `ERROR: Loan ID ${loanId} does not exist.`;
      logConsole('ERROR', err);
      throw new Error(err);
    }

    if (loan.status === 'RETURNED') {
      const err = `ERROR: Loan ID ${loanId} has already been returned.`;
      logConsole('ERROR', err);
      throw new Error(err);
    }

    // Check return date >= loan date
    if (new Date(returnDate) < new Date(loan.loan_date)) {
      const err = `ERROR: Return date cannot be earlier than loan issue date (${loan.loan_date}).`;
      logConsole('ERROR', err);
      throw new Error(err);
    }

    const book = this.books.find(b => b.book_id === loan.book_id);
    const member = this.members.find(m => m.member_id === loan.member_id);

    // 2. Update Loan Status
    loan.return_date = returnDate;
    loan.status = 'RETURNED';
    this.saveState();

    // Trigger fires on status update to RETURNED
    this.triggerSyncBookAvailability('UPDATE', loan);

    // 3. Calculate fine using function
    const { overdueDays, fineAmount } = this.calculateFine(loanId, returnDate);
    let newFine = null;

    if (fineAmount > 0) {
      const fineId = this.nextVal('fine_seq');
      newFine = {
        fine_id: fineId,
        loan_id: loanId,
        fine_amount: fineAmount,
        fine_date: getToday(),
        payment_status: 'PENDING'
      };
      this.fines.push(newFine);
      this.saveState();
      logConsole('SQL', `INSERT INTO fines VALUES (${fineId}, ${loanId}, ${fineAmount}, SYSDATE, 'PENDING');`);
    }

    // DBMS_OUTPUT formatting
    const output = [
      '----------------------------------------------------',
      'SUCCESS: Book returned successfully!',
      `Loan ID      : ${loanId}`,
      `Book Title   : ${book ? book.title : 'N/A'} (ID: ${loan.book_id})`,
      `Member       : ${member ? `${member.first_name} ${member.last_name}` : 'N/A'} (ID: ${loan.member_id})`,
      `Due Date     : ${loan.due_date}`,
      `Return Date  : ${returnDate}`,
      overdueDays > 0
        ? `Overdue Days : ${overdueDays} day(s)\nFine Imposed : $${fineAmount.toFixed(2)} (Fine ID: ${newFine.fine_id}, Status: PENDING)`
        : `Overdue Days : 0 (Returned On Time)\nFine Imposed : $0.00`,
      `Book Status  : Changed to AVAILABLE by Trigger`,
      '----------------------------------------------------'
    ];

    output.forEach(line => logConsole('OUTPUT', line));
    return { loan, book, member, overdueDays, fineAmount, fine: newFine, output: output.join('\n') };
  }

  /**
   * PROCEDURE display_member_history(p_member_id NUMBER)
   */
  displayMemberHistory(memberId) {
    memberId = Number(memberId);
    logConsole('SQL', `EXEC display_member_history(p_member_id => ${memberId});`);

    const member = this.members.find(m => m.member_id === memberId);
    if (!member) {
      const err = `ERROR: Member ID ${memberId} does not exist.`;
      logConsole('ERROR', err);
      throw new Error(err);
    }

    const memberLoans = this.loans.filter(l => l.member_id === memberId)
      .sort((a, b) => new Date(b.loan_date) - new Date(a.loan_date) || b.loan_id - a.loan_id);

    const historyRows = memberLoans.map(l => {
      const book = this.books.find(b => b.book_id === l.book_id);
      const fine = this.fines.find(f => f.loan_id === l.loan_id);
      return {
        loan_id: l.loan_id,
        title: book ? book.title : 'Unknown Book',
        loan_date: l.loan_date,
        due_date: l.due_date,
        return_date: l.return_date || 'N/A',
        loan_status: l.status,
        fine_amount: fine ? fine.fine_amount : 0.00,
        fine_status: fine ? fine.payment_status : 'NONE'
      };
    });

    // Generate ASCII table replica
    const divider = '='.repeat(88);
    const subDivider = '-'.repeat(88);
    let ascii = '';
    ascii += `${divider}\n`;
    ascii += `BORROWING HISTORY FOR MEMBER: ${(member.first_name + ' ' + member.last_name).toUpperCase()} (ID: ${memberId})\n`;
    ascii += `Email: ${member.email} | Status: ${member.status}\n`;
    ascii += `${divider}\n`;
    ascii += `${'Loan ID'.padEnd(9)}${'Book Title'.padEnd(28)}${'Issue Date'.padEnd(13)}${'Due Date'.padEnd(13)}${'Return Date'.padEnd(13)}${'Status'.padEnd(10)}${'Fine ($)'.padEnd(9)}${'Payment'}\n`;
    ascii += `${subDivider}\n`;

    if (historyRows.length === 0) {
      ascii += `No borrowing records found for this member.\n`;
    } else {
      historyRows.forEach(r => {
        const shortTitle = r.title.length > 25 ? r.title.substring(0, 24) + '…' : r.title;
        ascii += `${String(r.loan_id).padEnd(9)}${shortTitle.padEnd(28)}${r.loan_date.padEnd(13)}${r.due_date.padEnd(13)}${r.return_date.padEnd(13)}${r.loan_status.padEnd(10)}${('$' + r.fine_amount.toFixed(2)).padEnd(9)}${r.fine_status}\n`;
      });
    }

    ascii += `${divider}\n`;
    ascii += `Total Loans Found: ${historyRows.length}\n`;
    ascii += `${divider}\n`;

    logConsole('OUTPUT', ascii);
    return { member, history: historyRows, ascii };
  }

  // --- Fine Settlement ---
  payFine(fineId) {
    fineId = Number(fineId);
    const fine = this.fines.find(f => f.fine_id === fineId);
    if (!fine) {
      throw new Error(`Fine ID ${fineId} not found.`);
    }
    fine.payment_status = 'PAID';
    this.saveState();
    logConsole('SQL', `UPDATE fines SET payment_status = 'PAID' WHERE fine_id = ${fineId}; COMMIT;`);
    logConsole('OUTPUT', `SUCCESS: Fine ID ${fineId} of $${fine.fine_amount.toFixed(2)} marked as PAID.`);
    return fine;
  }

  // --- Management Operations ---
  addBook(title, author, category) {
    if (!title || !author || !category) {
      throw new Error('Title, Author, and Category are required.');
    }
    const newId = this.nextVal('book_seq');
    const book = {
      book_id: newId,
      title: title.trim(),
      author: author.trim(),
      category: category.trim(),
      status: 'AVAILABLE'
    };
    this.books.push(book);
    this.saveState();
    logConsole('SQL', `INSERT INTO books VALUES (${newId}, '${book.title}', '${book.author}', '${book.category}', 'AVAILABLE'); COMMIT;`);
    return book;
  }

  addMember(firstName, lastName, email, phone) {
    if (!firstName || !lastName || !email) {
      throw new Error('First name, last name, and email are required.');
    }
    if (this.members.some(m => m.email.toLowerCase() === email.toLowerCase().trim())) {
      throw new Error(`ORA-00001: Unique constraint (uq_member_email) violated for email '${email}'.`);
    }
    const newId = this.nextVal('member_seq');
    const member = {
      member_id: newId,
      first_name: firstName.trim(),
      last_name: lastName.trim(),
      email: email.trim().toLowerCase(),
      phone: phone ? phone.trim() : '',
      join_date: getToday(),
      status: 'ACTIVE'
    };
    this.members.push(member);
    this.saveState();
    logConsole('SQL', `INSERT INTO members VALUES (${newId}, '${member.first_name}', '${member.last_name}', '${member.email}', '${member.phone}', SYSDATE, 'ACTIVE'); COMMIT;`);
    return member;
  }

  toggleMemberStatus(memberId) {
    const member = this.members.find(m => m.member_id === Number(memberId));
    if (!member) throw new Error(`Member ${memberId} not found.`);
    member.status = member.status === 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';
    this.saveState();
    logConsole('SQL', `UPDATE members SET status = '${member.status}' WHERE member_id = ${memberId}; COMMIT;`);
    return member;
  }
}

// Instantiate Global DB Engine
const db = new OraclePLEngine();

// ============================================================================
// 3. CONSOLE & AUDIT LOGGER (DBMS_OUTPUT EMULATOR)
// ============================================================================

const consoleLogs = [];

function logConsole(type, message) {
  const time = new Date().toLocaleTimeString();
  const entry = { type, message, time };
  consoleLogs.push(entry);

  const container = document.getElementById('consoleLogBody');
  if (container) {
    const el = document.createElement('div');
    el.className = 'log-entry';

    let typeClass = 'log-sql';
    if (type === 'TRIGGER') typeClass = 'log-trigger';
    else if (type === 'OUTPUT') typeClass = 'log-output';
    else if (type === 'ERROR') typeClass = 'log-error';

    el.innerHTML = `
      <span class="log-time">[${time}]</span>
      <span class="log-type-tag ${typeClass}">[${type}]</span>
      <span style="white-space: pre-wrap;">${escapeHtml(message)}</span>
    `;
    container.appendChild(el);
    container.scrollTop = container.scrollHeight;
  }
}

function clearConsoleLogs() {
  consoleLogs.length = 0;
  const container = document.getElementById('consoleLogBody');
  if (container) container.innerHTML = '';
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// ============================================================================
// 4. TOAST NOTIFICATION CONTROLLER
// ============================================================================

function showToast(title, message, type = 'info') {
  const container = document.getElementById('toastContainer');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;

  const iconSvg = {
    success: `<svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>`,
    error: `<svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>`,
    warning: `<svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>`,
    info: `<svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>`
  }[type] || '';

  toast.innerHTML = `
    <div style="flex-shrink:0; color: currentColor;">${iconSvg}</div>
    <div class="toast-content" style="flex:1;">
      <h4>${escapeHtml(title)}</h4>
      <p>${escapeHtml(message)}</p>
    </div>
  `;

  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 4200);
}

// ============================================================================
// 5. UI VIEW RENDERING & CONTROLLER
// ============================================================================

document.addEventListener('DOMContentLoaded', () => {
  setupNavigation();
  setupConsoleDock();
  setupModals();
  setupEventListeners();

  // Initial render
  refreshAllViews();

  logConsole('SYSTEM', 'Oracle PL/SQL Mini Project Environment Initialized.');
  logConsole('OUTPUT', 'SET SERVEROUTPUT ON; Connected to ORCL Database.');
});

// Navigation Handling
function setupNavigation() {
  const links = document.querySelectorAll('.nav-link[data-tab]');
  links.forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      const tabId = link.getAttribute('data-tab');
      switchTab(tabId);
    });
  });

  // Mobile menu toggle
  const mobileToggle = document.getElementById('mobileMenuToggle');
  const sidebar = document.getElementById('sidebar');
  if (mobileToggle && sidebar) {
    mobileToggle.addEventListener('click', () => {
      sidebar.classList.toggle('open');
    });
  }
}

function switchTab(tabId) {
  // Update sidebar active state
  document.querySelectorAll('.nav-link[data-tab]').forEach(el => {
    el.classList.toggle('active', el.getAttribute('data-tab') === tabId);
  });

  // Update pane active state
  document.querySelectorAll('.tab-pane').forEach(pane => {
    pane.classList.remove('active');
  });
  const targetPane = document.getElementById(tabId);
  if (targetPane) {
    targetPane.classList.add('active');
  }

  // Update page header title
  const titleMap = {
    'tabDashboard': { title: 'Dashboard Overview', sub: 'Real-time library statistics, recent transactions, and system health.' },
    'tabBooks': { title: 'Books Inventory', sub: 'Manage books catalog, categories, and synchronized availability status.' },
    'tabMembers': { title: 'Members Directory', sub: 'Manage registered borrowers and status constraints.' },
    'tabIssue': { title: 'Issue Book (Loan)', sub: 'Execute PL/SQL procedure issue_book with automatic trigger sync.' },
    'tabReturn': { title: 'Return Book & Fines', sub: 'Execute return_book procedure with automated fine assessment ($2/day).' },
    'tabHistory': { title: 'Borrowing History', sub: 'Run PL/SQL cursor-based procedure display_member_history.' },
    'tabDatabase': { title: 'Oracle DB Inspector', sub: 'Inspect raw tables (BOOKS, MEMBERS, LOANS, FINES) and sequences.' }
  };

  const info = titleMap[tabId] || { title: 'Library Management', sub: '' };
  const h1 = document.getElementById('pageHeaderTitle');
  const p = document.getElementById('pageHeaderSub');
  if (h1) h1.textContent = info.title;
  if (p) p.textContent = info.sub;

  // Refresh tab content
  refreshAllViews();

  // Close mobile sidebar if open
  const sidebar = document.getElementById('sidebar');
  if (sidebar) sidebar.classList.remove('open');
}

// Console dock toggle
function setupConsoleDock() {
  const header = document.getElementById('consoleDockHeader');
  const dock = document.getElementById('consoleDock');
  const toggleIcon = document.getElementById('consoleToggleIcon');
  const clearBtn = document.getElementById('btnClearConsole');

  if (header && dock) {
    header.addEventListener('click', (e) => {
      if (e.target.closest('.console-btn')) return;
      dock.classList.toggle('collapsed');
      if (toggleIcon) {
        toggleIcon.textContent = dock.classList.contains('collapsed') ? '▲ Expand' : '▼ Minimize';
      }
    });
  }

  if (clearBtn) {
    clearBtn.addEventListener('click', () => {
      clearConsoleLogs();
      showToast('Console Cleared', 'DBMS_OUTPUT buffer has been emptied.', 'info');
    });
  }
}

// Modal handling
function setupModals() {
  document.querySelectorAll('[data-modal-open]').forEach(btn => {
    btn.addEventListener('click', () => {
      const modalId = btn.getAttribute('data-modal-open');
      openModal(modalId);
    });
  });

  document.querySelectorAll('[data-modal-close]').forEach(btn => {
    btn.addEventListener('click', () => {
      const modal = btn.closest('.modal-backdrop');
      if (modal) closeModal(modal.id);
    });
  });

  window.addEventListener('click', (e) => {
    if (e.target.classList.contains('modal-backdrop')) {
      closeModal(e.target.id);
    }
  });
}

function openModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) {
    modal.classList.add('show');
    // Pre-populate dropdowns if relevant
    if (modalId === 'modalAddBook') {
      document.getElementById('addBookForm')?.reset();
    } else if (modalId === 'modalAddMember') {
      document.getElementById('addMemberForm')?.reset();
    }
  }
}

function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) modal.classList.remove('show');
}

// Event Listeners for Forms & Filters
function setupEventListeners() {
  // Theme toggle
  const themeToggle = document.getElementById('themeToggleBtn');
  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const current = document.documentElement.getAttribute('data-theme');
      const next = current === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      themeToggle.textContent = next === 'dark' ? '☀️ Light' : '🌙 Dark';
    });
  }

  // Database Reset
  const resetBtn = document.getElementById('btnResetDatabase');
  if (resetBtn) {
    resetBtn.addEventListener('click', () => {
      if (confirm('Are you sure you want to re-initialize the Oracle database with original seed data? All custom records will be reset.')) {
        db.resetToSeed();
        refreshAllViews();
        showToast('Database Reset', 'Initialized tables with 01_schema_and_data.sql seeds.', 'success');
      }
    });
  }

  // Add Book Form
  const addBookForm = document.getElementById('addBookForm');
  if (addBookForm) {
    addBookForm.addEventListener('submit', (e) => {
      e.preventDefault();
      try {
        const title = document.getElementById('newBookTitle').value;
        const author = document.getElementById('newBookAuthor').value;
        const category = document.getElementById('newBookCategory').value;
        const book = db.addBook(title, author, category);
        closeModal('modalAddBook');
        refreshAllViews();
        showToast('Book Added', `"${book.title}" added with ID ${book.book_id}.`, 'success');
      } catch (err) {
        showToast('Error', err.message, 'error');
      }
    });
  }

  // Add Member Form
  const addMemberForm = document.getElementById('addMemberForm');
  if (addMemberForm) {
    addMemberForm.addEventListener('submit', (e) => {
      e.preventDefault();
      try {
        const fname = document.getElementById('newMemberFirst').value;
        const lname = document.getElementById('newMemberLast').value;
        const email = document.getElementById('newMemberEmail').value;
        const phone = document.getElementById('newMemberPhone').value;
        const member = db.addMember(fname, lname, email, phone);
        closeModal('modalAddMember');
        refreshAllViews();
        showToast('Member Enrolled', `${member.first_name} ${member.last_name} registered with ID ${member.member_id}.`, 'success');
      } catch (err) {
        showToast('Error', err.message, 'error');
      }
    });
  }

  // Issue Book Form (Dedicated tab)
  const issueForm = document.getElementById('issueBookForm');
  if (issueForm) {
    issueForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const bookId = document.getElementById('issueBookSelect').value;
      const memberId = document.getElementById('issueMemberSelect').value;
      const days = document.getElementById('issueLoanDays').value || 14;

      try {
        const res = db.issueBook(bookId, memberId, days);
        document.getElementById('issueReceiptBox').style.display = 'block';
        document.getElementById('issueReceiptOutput').textContent = res.output;
        showToast('Book Issued', `Loan ID ${res.loan.loan_id} created successfully!`, 'success');
        refreshAllViews();
      } catch (err) {
        showToast('PL/SQL Exception', err.message, 'error');
      }
    });
  }

  // Return Book Form (Dedicated tab)
  const returnForm = document.getElementById('returnBookForm');
  if (returnForm) {
    returnForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const loanId = document.getElementById('returnLoanSelect').value;
      const returnDate = document.getElementById('returnDatePicker').value;

      try {
        const res = db.returnBook(loanId, returnDate);
        document.getElementById('returnReceiptBox').style.display = 'block';
        document.getElementById('returnReceiptOutput').textContent = res.output;
        if (res.fineAmount > 0) {
          showToast('Return Processed', `Book returned. Overdue fine of $${res.fineAmount.toFixed(2)} recorded.`, 'warning');
        } else {
          showToast('Return Processed', `Book returned on time! Zero fine incurred.`, 'success');
        }
        refreshAllViews();
      } catch (err) {
        showToast('PL/SQL Exception', err.message, 'error');
      }
    });
  }

  // Return date auto-calculate fine preview
  const returnLoanSelect = document.getElementById('returnLoanSelect');
  const returnDatePicker = document.getElementById('returnDatePicker');
  if (returnDatePicker) {
    returnDatePicker.value = getToday();
    const updatePreview = () => {
      const loanId = returnLoanSelect?.value;
      const rDate = returnDatePicker?.value;
      const previewEl = document.getElementById('returnFinePreview');
      if (!loanId || !previewEl) return;
      try {
        const { overdueDays, fineAmount } = db.calculateFine(loanId, rDate);
        if (overdueDays > 0) {
          previewEl.innerHTML = `<span style="color:var(--danger); font-weight:600;">⚠️ ${overdueDays} Day(s) Overdue &rarr; Fine: $${fineAmount.toFixed(2)}</span>`;
        } else {
          previewEl.innerHTML = `<span style="color:var(--success); font-weight:600;">✓ On Time Return &rarr; Fine: $0.00</span>`;
        }
      } catch (e) {
        previewEl.innerHTML = `<span style="color:var(--danger);">${escapeHtml(e.message)}</span>`;
      }
    };

    returnLoanSelect?.addEventListener('change', updatePreview);
    returnDatePicker?.addEventListener('input', updatePreview);
  }

  // Search & Filter Books
  const bookSearch = document.getElementById('bookSearchInput');
  const bookCatFilter = document.getElementById('bookCategoryFilter');
  const bookStatusFilter = document.getElementById('bookStatusFilter');
  [bookSearch, bookCatFilter, bookStatusFilter].forEach(el => {
    el?.addEventListener('input', renderBooksTable);
  });

  // Search Members
  const memberSearch = document.getElementById('memberSearchInput');
  const memberStatusFilter = document.getElementById('memberStatusFilter');
  [memberSearch, memberStatusFilter].forEach(el => {
    el?.addEventListener('input', renderMembersTable);
  });

  // Member History Lookup
  const historySelect = document.getElementById('historyMemberSelect');
  if (historySelect) {
    historySelect.addEventListener('change', () => {
      renderMemberHistory(historySelect.value);
    });
  }

  // Quick action jump buttons
  document.querySelectorAll('[data-switch-tab]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const tab = btn.getAttribute('data-switch-tab');
      switchTab(tab);
    });
  });
}

// ============================================================================
// 6. VIEW RENDERERS
// ============================================================================

function refreshAllViews() {
  renderDashboard();
  renderBooksTable();
  renderMembersTable();
  populateIssueDropdowns();
  populateReturnDropdowns();
  populateHistoryDropdown();
  renderFinesTable();
  renderRawDatabaseInspector();
}

// --- Dashboard ---
function renderDashboard() {
  const totalBooks = db.books.length;
  const availableBooks = db.books.filter(b => b.status === 'AVAILABLE').length;
  const borrowedBooks = db.books.filter(b => b.status === 'BORROWED').length;
  const activeMembers = db.members.filter(m => m.status === 'ACTIVE').length;
  const suspendedMembers = db.members.filter(m => m.status === 'SUSPENDED').length;
  const activeLoans = db.loans.filter(l => l.status === 'ISSUED').length;

  // Calculate overdue loans
  const today = getToday();
  const overdueLoans = db.loans.filter(l => l.status === 'ISSUED' && l.due_date < today).length;

  const totalFines = db.fines.reduce((acc, f) => acc + f.fine_amount, 0);
  const pendingFines = db.fines.filter(f => f.payment_status === 'PENDING').reduce((acc, f) => acc + f.fine_amount, 0);

  // Update KPI counters
  document.getElementById('statTotalBooks').textContent = totalBooks;
  document.getElementById('statAvailableBooks').textContent = availableBooks;
  document.getElementById('statBorrowedBooks').textContent = borrowedBooks;
  document.getElementById('statActiveMembers').textContent = activeMembers;
  document.getElementById('statSuspendedMembers').textContent = suspendedMembers;
  document.getElementById('statActiveLoans').textContent = activeLoans;
  document.getElementById('statOverdueLoans').textContent = overdueLoans;
  document.getElementById('statTotalFines').textContent = `$${totalFines.toFixed(2)}`;
  document.getElementById('statPendingFines').textContent = `$${pendingFines.toFixed(2)}`;

  // Update Nav Badges
  document.getElementById('badgeBooksCount').textContent = totalBooks;
  document.getElementById('badgeMembersCount').textContent = activeMembers;
  document.getElementById('badgeLoansCount').textContent = activeLoans;

  // Render Recent Loans Table on Dashboard
  const recentLoansBody = document.getElementById('recentLoansTableBody');
  if (recentLoansBody) {
    const recent = [...db.loans].reverse().slice(0, 5);
    if (recent.length === 0) {
      recentLoansBody.innerHTML = `<tr><td colspan="6" style="text-align:center; color:var(--text-muted);">No loans recorded.</td></tr>`;
    } else {
      recentLoansBody.innerHTML = recent.map(l => {
        const book = db.books.find(b => b.book_id === l.book_id);
        const member = db.members.find(m => m.member_id === l.member_id);
        const isOverdue = l.status === 'ISSUED' && l.due_date < today;

        return `
          <tr>
            <td><strong>#${l.loan_id}</strong></td>
            <td>${escapeHtml(book ? book.title : 'Book #' + l.book_id)}</td>
            <td>${escapeHtml(member ? `${member.first_name} ${member.last_name}` : 'Member #' + l.member_id)}</td>
            <td>${l.loan_date}</td>
            <td>
              ${l.due_date}
              ${isOverdue ? '<span class="badge badge-suspended" style="margin-left:6px;">OVERDUE</span>' : ''}
            </td>
            <td>
              <span class="badge ${l.status === 'ISSUED' ? 'badge-issued' : 'badge-returned'}">${l.status}</span>
            </td>
          </tr>
        `;
      }).join('');
    }
  }
}

// --- Books View ---
function renderBooksTable() {
  const tbody = document.getElementById('booksTableBody');
  if (!tbody) return;

  const search = (document.getElementById('bookSearchInput')?.value || '').toLowerCase().trim();
  const catFilter = document.getElementById('bookCategoryFilter')?.value || 'ALL';
  const statusFilter = document.getElementById('bookStatusFilter')?.value || 'ALL';

  // Populate category dropdown
  const catSelect = document.getElementById('bookCategoryFilter');
  if (catSelect && catSelect.children.length <= 1) {
    const cats = Array.from(new Set(db.books.map(b => b.category)));
    cats.forEach(c => {
      const opt = document.createElement('option');
      opt.value = c;
      opt.textContent = c;
      catSelect.appendChild(opt);
    });
  }

  const filtered = db.books.filter(b => {
    const matchSearch = String(b.book_id).includes(search) ||
      b.title.toLowerCase().includes(search) ||
      b.author.toLowerCase().includes(search) ||
      b.category.toLowerCase().includes(search);
    const matchCat = catFilter === 'ALL' || b.category === catFilter;
    const matchStatus = statusFilter === 'ALL' || b.status === statusFilter;
    return matchSearch && matchCat && matchStatus;
  });

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align:center; padding:24px; color:var(--text-muted);">No books match the selected criteria.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map(b => `
    <tr>
      <td><strong>${b.book_id}</strong></td>
      <td><strong>${escapeHtml(b.title)}</strong></td>
      <td>${escapeHtml(b.author)}</td>
      <td><span class="plsql-code-badge">${escapeHtml(b.category)}</span></td>
      <td>
        <span class="badge ${b.status === 'AVAILABLE' ? 'badge-available' : 'badge-borrowed'}">
          ${b.status}
        </span>
      </td>
      <td>
        ${b.status === 'AVAILABLE' ? `
          <button class="header-btn btn-primary" style="padding:4px 10px; font-size:0.75rem;" onclick="quickIssueBook(${b.book_id})">
            Issue Book
          </button>
        ` : `
          <span style="font-size:0.75rem; color:var(--text-muted);">On Loan</span>
        `}
      </td>
    </tr>
  `).join('');
}

// Quick action from books table
window.quickIssueBook = function(bookId) {
  switchTab('tabIssue');
  const sel = document.getElementById('issueBookSelect');
  if (sel) {
    sel.value = String(bookId);
  }
};

// --- Members View ---
function renderMembersTable() {
  const tbody = document.getElementById('membersTableBody');
  if (!tbody) return;

  const search = (document.getElementById('memberSearchInput')?.value || '').toLowerCase().trim();
  const statusFilter = document.getElementById('memberStatusFilter')?.value || 'ALL';

  const filtered = db.members.filter(m => {
    const full = `${m.first_name} ${m.last_name}`.toLowerCase();
    const matchSearch = String(m.member_id).includes(search) ||
      full.includes(search) ||
      m.email.toLowerCase().includes(search) ||
      (m.phone && m.phone.includes(search));
    const matchStatus = statusFilter === 'ALL' || m.status === statusFilter;
    return matchSearch && matchStatus;
  });

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align:center; padding:24px; color:var(--text-muted);">No members found.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map(m => `
    <tr>
      <td><strong>#${m.member_id}</strong></td>
      <td><strong>${escapeHtml(m.first_name)} ${escapeHtml(m.last_name)}</strong></td>
      <td>${escapeHtml(m.email)}</td>
      <td>${escapeHtml(m.phone || 'N/A')}</td>
      <td>${m.join_date}</td>
      <td>
        <span class="badge ${m.status === 'ACTIVE' ? 'badge-active' : 'badge-suspended'}">
          ${m.status}
        </span>
      </td>
      <td>
        <div style="display:flex; gap:6px;">
          <button class="header-btn" style="padding:4px 8px; font-size:0.75rem;" onclick="viewMemberHistoryFromTable(${m.member_id})">
            History
          </button>
          <button class="header-btn" style="padding:4px 8px; font-size:0.75rem;" onclick="toggleMemberStatusAction(${m.member_id})">
            ${m.status === 'ACTIVE' ? 'Suspend' : 'Activate'}
          </button>
        </div>
      </td>
    </tr>
  `).join('');
}

window.viewMemberHistoryFromTable = function(memberId) {
  switchTab('tabHistory');
  const sel = document.getElementById('historyMemberSelect');
  if (sel) {
    sel.value = String(memberId);
    renderMemberHistory(memberId);
  }
};

window.toggleMemberStatusAction = function(memberId) {
  try {
    const updated = db.toggleMemberStatus(memberId);
    refreshAllViews();
    showToast('Member Updated', `${updated.first_name} ${updated.last_name} is now ${updated.status}.`, 'info');
  } catch (e) {
    showToast('Error', e.message, 'error');
  }
};

// --- Dropdowns for Issue Tab ---
function populateIssueDropdowns() {
  const bookSel = document.getElementById('issueBookSelect');
  const memberSel = document.getElementById('issueMemberSelect');

  if (bookSel) {
    const currentVal = bookSel.value;
    bookSel.innerHTML = '<option value="">-- Select Book to Issue --</option>' +
      db.books.map(b => `
        <option value="${b.book_id}" ${b.status !== 'AVAILABLE' ? 'disabled style="color:var(--text-muted);"' : ''}>
          [#${b.book_id}] ${escapeHtml(b.title)} (${b.status})
        </option>
      `).join('');
    if (currentVal) bookSel.value = currentVal;
  }

  if (memberSel) {
    const currentVal = memberSel.value;
    memberSel.innerHTML = '<option value="">-- Select Member --</option>' +
      db.members.map(m => `
        <option value="${m.member_id}" ${m.status === 'SUSPENDED' ? 'style="color:var(--danger);"' : ''}>
          [#${m.member_id}] ${escapeHtml(m.first_name)} ${escapeHtml(m.last_name)} (${m.status})
        </option>
      `).join('');
    if (currentVal) memberSel.value = currentVal;
  }
}

// --- Dropdowns for Return Tab ---
function populateReturnDropdowns() {
  const loanSel = document.getElementById('returnLoanSelect');
  if (!loanSel) return;

  const currentVal = loanSel.value;
  const activeLoans = db.loans.filter(l => l.status === 'ISSUED');

  if (activeLoans.length === 0) {
    loanSel.innerHTML = '<option value="">-- No active loans to return --</option>';
  } else {
    loanSel.innerHTML = '<option value="">-- Select Loan to Return --</option>' +
      activeLoans.map(l => {
        const book = db.books.find(b => b.book_id === l.book_id);
        const member = db.members.find(m => m.member_id === l.member_id);
        const isOverdue = l.due_date < getToday();
        return `
          <option value="${l.loan_id}">
            Loan #${l.loan_id} &rarr; "${escapeHtml(book ? book.title : 'Book ' + l.book_id)}" by ${member ? member.first_name : 'Member'} (Due: ${l.due_date}${isOverdue ? ' - OVERDUE' : ''})
          </option>
        `;
      }).join('');
  }

  if (currentVal) loanSel.value = currentVal;
}

// --- Dropdowns for History Tab ---
function populateHistoryDropdown() {
  const histSel = document.getElementById('historyMemberSelect');
  if (!histSel) return;

  const currentVal = histSel.value;
  histSel.innerHTML = '<option value="">-- Select Member to View History --</option>' +
    db.members.map(m => `
      <option value="${m.member_id}">
        [#${m.member_id}] ${escapeHtml(m.first_name)} ${escapeHtml(m.last_name)} (${m.email})
      </option>
    `).join('');

  if (currentVal) histSel.value = currentVal;
}

function renderMemberHistory(memberId) {
  const container = document.getElementById('memberHistoryResultContainer');
  if (!container) return;

  if (!memberId) {
    container.style.display = 'none';
    return;
  }

  try {
    const res = db.displayMemberHistory(memberId);
    container.style.display = 'block';

    // Info header
    document.getElementById('histMemberName').textContent = `${res.member.first_name} ${res.member.last_name} (ID: ${res.member.member_id})`;
    document.getElementById('histMemberEmail').textContent = res.member.email;
    document.getElementById('histMemberStatus').innerHTML = `<span class="badge ${res.member.status === 'ACTIVE' ? 'badge-active' : 'badge-suspended'}">${res.member.status}</span>`;
    document.getElementById('histMemberTotalLoans').textContent = res.history.length;

    // ASCII SQL*Plus Output Display
    document.getElementById('histAsciiOutput').textContent = res.ascii;

    // Interactive Table
    const tbody = document.getElementById('histTableBody');
    if (tbody) {
      if (res.history.length === 0) {
        tbody.innerHTML = `<tr><td colspan="7" style="text-align:center; padding:18px; color:var(--text-muted);">No borrowing records found for this member.</td></tr>`;
      } else {
        tbody.innerHTML = res.history.map(r => `
          <tr>
            <td><strong>#${r.loan_id}</strong></td>
            <td>${escapeHtml(r.title)}</td>
            <td>${r.loan_date}</td>
            <td>${r.due_date}</td>
            <td>${r.return_date}</td>
            <td><span class="badge ${r.loan_status === 'ISSUED' ? 'badge-issued' : 'badge-returned'}">${r.loan_status}</span></td>
            <td>
              ${r.fine_amount > 0 ? `
                <span style="font-weight:600; color:var(--danger);">$${r.fine_amount.toFixed(2)}</span>
                <span class="badge ${r.fine_status === 'PAID' ? 'badge-paid' : 'badge-pending'}" style="margin-left:6px;">${r.fine_status}</span>
              ` : `
                <span style="color:var(--text-muted);">$0.00</span>
              `}
            </td>
          </tr>
        `).join('');
      }
    }
  } catch (err) {
    showToast('PL/SQL Error', err.message, 'error');
  }
}

// --- Fines Table (In Return & Fines Tab) ---
function renderFinesTable() {
  const tbody = document.getElementById('finesTableBody');
  if (!tbody) return;

  if (db.fines.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align:center; padding:18px; color:var(--text-muted);">No fines assessed yet.</td></tr>`;
    return;
  }

  tbody.innerHTML = [...db.fines].reverse().map(f => {
    const loan = db.loans.find(l => l.loan_id === f.loan_id);
    const member = loan ? db.members.find(m => m.member_id === loan.member_id) : null;
    return `
      <tr>
        <td><strong>#${f.fine_id}</strong></td>
        <td>Loan #${f.loan_id}</td>
        <td>${member ? `${escapeHtml(member.first_name)} ${escapeHtml(member.last_name)}` : 'N/A'}</td>
        <td><strong style="color:var(--danger);">$${f.fine_amount.toFixed(2)}</strong></td>
        <td>${f.fine_date}</td>
        <td>
          <span class="badge ${f.payment_status === 'PAID' ? 'badge-paid' : 'badge-pending'}">${f.payment_status}</span>
        </td>
        <td>
          ${f.payment_status === 'PENDING' ? `
            <button class="header-btn btn-primary" style="padding:3px 9px; font-size:0.75rem;" onclick="payFineAction(${f.fine_id})">
              Pay Fine
            </button>
          ` : `
            <span style="font-size:0.75rem; color:var(--success);">Settled</span>
          `}
        </td>
      </tr>
    `;
  }).join('');
}

window.payFineAction = function(fineId) {
  try {
    db.payFine(fineId);
    refreshAllViews();
    showToast('Fine Settled', `Fine ID ${fineId} marked as PAID.`, 'success');
  } catch (e) {
    showToast('Error', e.message, 'error');
  }
};

// --- Raw Database Inspector View ---
function renderRawDatabaseInspector() {
  const inspector = document.getElementById('rawDbJsonOutput');
  if (inspector) {
    inspector.textContent = JSON.stringify({
      sequences: db.sequences,
      books: db.books,
      members: db.members,
      loans: db.loans,
      fines: db.fines
    }, null, 2);
  }
}

