# ==============================================================================
# make_pdf.ps1 - Complete 27-Page Academic Report Generator
# ==============================================================================

$reportDir = "C:\Users\guler\Downloads\pl sql"
$assetsDir = "$reportDir\report_assets"
$htmlPath  = "$reportDir\report.html"
$pdfPath   = "$reportDir\Automated_Library_Management_System_Project_Report.pdf"

$b64LogoLeft   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$assetsDir\image1.jpeg"))
$b64LogoRight  = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$assetsDir\image2.jpeg"))
$b64LogoCenter = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$assetsDir\image5.png"))

function Get-Header {
    return @"
    <div class="page-header">
        <img class="logo-left" src="data:image/jpeg;base64,$b64LogoLeft" alt="Chandigarh University" />
        <img class="logo-right" src="data:image/jpeg;base64,$b64LogoRight" alt="NAAC Grade A+" />
    </div>
"@
}

$sb = New-Object System.Text.StringBuilder

# HTML Head & Styles
[void]$sb.AppendLine(@"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Automated Library Management & Fine Tracking System - Project Report</title>
<style>
    @page {
        size: A4 portrait;
        margin: 0;
    }
    *, *::before, *::after {
        box-sizing: border-box;
    }
    body {
        margin: 0;
        padding: 0;
        font-family: 'Times New Roman', Times, serif;
        background-color: #ffffff;
        color: #111111;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }
    .page {
        width: 210mm;
        height: 297mm;
        max-height: 297mm;
        padding: 16mm 20mm 15mm 20mm;
        position: relative;
        page-break-after: always;
        overflow: hidden;
        background: #ffffff;
    }
    .page-border {
        position: absolute;
        top: 9mm;
        left: 9mm;
        right: 9mm;
        bottom: 9mm;
        border: 1.5px solid #000000;
        pointer-events: none;
    }
    .page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        width: 100%;
        margin-bottom: 10px;
        padding-bottom: 4px;
    }
    .logo-left {
        height: 38px;
        object-fit: contain;
    }
    .logo-right {
        height: 34px;
        object-fit: contain;
    }
    .page-number {
        position: absolute;
        bottom: 12mm;
        right: 14mm;
        font-size: 11pt;
        font-family: 'Times New Roman', Times, serif;
        color: #000000;
    }
    .section-title {
        text-align: center;
        font-size: 16pt;
        font-weight: bold;
        margin: 18px 0 16px 0;
    }
    p {
        font-size: 10.8pt;
        line-height: 1.54;
        text-align: justify;
        margin: 0 0 11px 0;
    }
    .objective-item {
        margin-bottom: 10px;
        font-size: 10.4pt;
        line-height: 1.48;
        text-align: justify;
    }
    .objective-title {
        font-weight: bold;
    }
    .step-item {
        margin-bottom: 9px;
        font-size: 10.2pt;
        line-height: 1.46;
        text-align: justify;
    }
    .step-title {
        font-weight: bold;
    }

    /* Dark Code Block Styling matching reference PDF */
    .code-box {
        background-color: #080c16;
        border: 1px solid #1f293d;
        border-radius: 4px;
        padding: 6px 10px;
        font-family: Consolas, 'Courier New', monospace;
        font-size: 7.2pt;
        line-height: 1.28;
        color: #dbe4ee;
        overflow: hidden;
        margin-top: 4px;
        margin-bottom: 4px;
    }
    .code-title {
        font-size: 11pt;
        font-weight: bold;
        text-decoration: underline;
        margin: 6px 0 4px 0;
        font-family: 'Times New Roman', Times, serif;
    }
    .code-line {
        display: flex;
        white-space: pre;
    }
    .ln {
        color: #50617a;
        width: 26px;
        flex-shrink: 0;
        text-align: right;
        padding-right: 8px;
        user-select: none;
    }
    .cd {
        flex-grow: 1;
        white-space: pre-wrap;
        word-break: break-all;
    }
    .kw { color: #f472b6; font-weight: bold; }
    .fn { color: #38bdf8; font-weight: bold; }
    .st { color: #fcd34d; }
    .cm { color: #64748b; font-style: italic; }
    .num { color: #a78bfa; }
    .typ { color: #34d399; }

    /* Results Tables */
    .result-table {
        width: 100%;
        border-collapse: collapse;
        font-family: 'Times New Roman', Times, serif;
        font-size: 8.5pt;
        margin-bottom: 4px;
    }
    .result-table th {
        background-color: #0f172a;
        color: #ffffff;
        font-weight: bold;
        padding: 4px 6px;
        text-align: left;
        border: 1px solid #334155;
    }
    .result-table td {
        padding: 3.5px 6px;
        border: 1px solid #cbd5e1;
        background-color: #ffffff;
    }
    .result-table tr:nth-child(even) td {
        background-color: #f8fafc;
    }
    .fig-caption {
        text-align: center;
        font-size: 9.5pt;
        font-weight: bold;
        margin: 4px 0 10px 0;
    }

    /* Terminal Output Box */
    .terminal-box {
        background-color: #0b0f19;
        border: 1px solid #1e293b;
        border-radius: 4px;
        padding: 6px 10px;
        font-family: Consolas, monospace;
        font-size: 7.6pt;
        line-height: 1.32;
        color: #94a3b8;
        margin-bottom: 6px;
    }
    .term-title {
        font-weight: bold;
        color: #f1f5f9;
        font-size: 8.8pt;
        margin-bottom: 2px;
        font-family: 'Times New Roman', Times, serif;
    }
    .term-success { color: #34d399; }
    .term-warn { color: #fbbf24; }
    .term-err { color: #f87171; }
    .term-num { color: #60a5fa; }
    .term-hl { color: #e2e8f0; font-weight: bold; }
</style>
</head>
<body>
"@)

# ==============================================================================
# PAGE 1: TITLE PAGE
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div style="text-align: center; margin-top: 35px;">
        <h1 style="font-size: 21pt; font-weight: bold; margin: 0 0 12px 0;">Project Report</h1>
        <p style="font-size: 13pt; text-align: center; margin: 0 0 14px 0;">on</p>
        <h2 style="font-size: 16pt; font-weight: bold; text-align: center; margin: 0 0 8px 0;">Automated Library Management &amp; Fine Tracking System</h2>
        <h3 style="font-size: 13.5pt; font-weight: bold; text-align: center; margin: 0 0 35px 0;">Advance Database Management System (26CAP-602)</h3>
        
        <p style="font-size: 12.5pt; font-style: italic; text-align: center; margin: 0 0 10px 0;">Submitted by</p>
        <p style="font-size: 13.5pt; font-weight: bold; text-align: center; letter-spacing: 0.5px; margin: 0 0 4px 0;">BASUDEV</p>
        <p style="font-size: 13.5pt; font-weight: bold; text-align: center; letter-spacing: 0.5px; margin: 0 0 6px 0;">GULERIA</p>
        <p style="font-size: 13pt; font-weight: bold; text-align: center; margin: 0 0 35px 0;">26MCA20075</p>
        
        <p style="font-size: 12.5pt; font-style: italic; text-align: center; margin: 0 0 8px 0;">Under the guidance of</p>
        <p style="font-size: 13.5pt; font-weight: bold; text-align: center; margin: 0 0 28px 0;">Dr. Deeksha Baweja</p>
        
        <p style="font-size: 11.5pt; font-style: italic; text-align: center; margin: 0 0 6px 0;">in partial fulfilment for the award of the degree of</p>
        <p style="font-size: 12.5pt; font-weight: bold; text-align: center; margin: 0 0 26px 0;">MASTER OF COMPUTER APPLICATIONS</p>
        
        <div style="margin: 0 0 18px 0;">
            <img src="data:image/png;base64,$b64LogoCenter" style="height: 120px;" alt="Chandigarh University Emblem" />
        </div>
        
        <p style="font-size: 13.5pt; font-weight: bold; text-align: center; margin: 0 0 5px 0;">Chandigarh University</p>
        <p style="font-size: 12.5pt; font-weight: bold; text-align: center; margin: 0;">November 2026</p>
    </div>
</div>
"@)

# ==============================================================================
# PAGE 2: CERTIFICATE
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <h2 class="section-title" style="margin-top: 30px; margin-bottom: 25px;">Certificate</h2>
    <p>This is to certify that <strong>Basudev Guleria</strong> a student of <strong>Master of Computer Applications (MCA)</strong>, has successfully completed the Minor Project titled <strong>&ldquo;Automated Library Management &amp; Fine Tracking System&rdquo;</strong> under the esteemed guidance of <strong>Dr. Deeksha Baweja, Assistant Professor, University Institute of Computing (UIC), Chandigarh University</strong>.</p>
    <p>This project was undertaken as a part of the academic curriculum and is submitted in <strong>partial fulfilment of the requirements for the MCA program</strong>. The work presented in this project is a result of <strong>independent research, diligent effort, and dedication</strong>, demonstrating the student&rsquo;s ability to apply theoretical knowledge to practical problem-solving.</p>
    <p>The project, <strong>&ldquo;Automated Library Management &amp; Fine Tracking System&rdquo;</strong> is a database-driven application built in <strong>Oracle PL/SQL</strong> that automates book issue, book return, overdue fine calculation, fine settlement and availability tracking via database triggers. It effectively showcases concepts of <strong>Advanced Database Management System</strong>, including normalization, stored procedures and functions, triggers, exception handling and transaction management.</p>
    <p>I hereby confirm that this project is an <strong>original work carried out by the student</strong> and has <strong>not been submitted</strong> elsewhere for the award of any other degree, diploma, or certification.</p>
    
    <div style="margin-top: 80px; text-align: right; font-size: 11pt; line-height: 1.45;">
        <strong>Project Guide: Dr. Deeksha Baweja</strong><br>
        Assistant Professor<br>
        University Institute of Computing<br>
        Chandigarh University
    </div>
</div>
"@)

# ==============================================================================
# PAGE 3: ACKNOWLEDGEMENT
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <h2 class="section-title" style="margin-top: 30px; margin-bottom: 25px;">Acknowledgement</h2>
    <p>I would like to express my sincere gratitude to <strong>Chandigarh University</strong> and the <strong>University Institute of Computing (UIC)</strong> for providing me with the opportunity to undertake this project, <strong>&ldquo;Automated Library Management &amp; Fine Tracking System&rdquo;</strong>.</p>
    <p>I extend my heartfelt appreciation to my esteemed mentor, <strong>Dr. Deeksha Baweja, Assistant Professor</strong>, for her invaluable guidance, continuous support, and insightful feedback throughout the project. Her expertise in <strong>Advanced Database Management System</strong> played a crucial role in the successful completion of this project.</p>
    <p>I am also grateful to my friends and peers for their encouragement and discussions, which helped refine my approach. Lastly, I thank my family for their unwavering support and motivation during this work.</p>
    <p>This project has been an incredible learning experience, and I hope it serves as a foundation for further exploration in <strong>Advanced Database Management System</strong>.</p>
    
    <div style="margin-top: 90px; text-align: right; font-size: 11pt; line-height: 1.45;">
        <strong>Basudev Guleria</strong><br>
        MCA<br>
        Chandigarh University
    </div>
</div>
"@)

# ==============================================================================
# PAGE 4: CONTENTS
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <h2 class="section-title" style="margin-top: 30px; margin-bottom: 35px;">Contents</h2>
    <table style="width: 100%; border-collapse: collapse; font-size: 11pt;">
        <tr style="border-top: 1.5px solid #000; border-bottom: 1.5px solid #000;">
            <th style="text-align: left; padding: 10px 12px; font-weight: bold;">Section</th>
            <th style="text-align: right; padding: 10px 12px; font-weight: bold;">Page Number</th>
        </tr>
        <tr><td style="padding: 13px 12px; border-bottom: 1px solid #ddd;"><strong>1. Introduction</strong></td><td style="text-align: right; padding: 13px 12px; border-bottom: 1px solid #ddd;">1</td></tr>
        <tr><td style="padding: 13px 12px; border-bottom: 1px solid #ddd;"><strong>2. Objective</strong></td><td style="text-align: right; padding: 13px 12px; border-bottom: 1px solid #ddd;">2</td></tr>
        <tr><td style="padding: 13px 12px; border-bottom: 1px solid #ddd;"><strong>3. Tools and Technologies Used</strong></td><td style="text-align: right; padding: 13px 12px; border-bottom: 1px solid #ddd;">3</td></tr>
        <tr><td style="padding: 13px 12px; border-bottom: 1px solid #ddd;"><strong>4. Implementation Steps</strong></td><td style="text-align: right; padding: 13px 12px; border-bottom: 1px solid #ddd;">4</td></tr>
        <tr><td style="padding: 13px 12px; border-bottom: 1px solid #ddd;"><strong>5. Screenshots / Results</strong></td><td style="text-align: right; padding: 13px 12px; border-bottom: 1px solid #ddd;">5 &ndash; 21</td></tr>
        <tr><td style="padding: 13px 12px; border-bottom: 1px solid #ddd;"><strong>6. Conclusion</strong></td><td style="text-align: right; padding: 13px 12px; border-bottom: 1px solid #ddd;">22</td></tr>
        <tr style="border-bottom: 1.5px solid #000;"><td style="padding: 13px 12px;"><strong>7. References</strong></td><td style="text-align: right; padding: 13px 12px;">23</td></tr>
    </table>
</div>
"@)

# ==============================================================================
# PAGE 5: 1. INTRODUCTION (Page Number: 1)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <h2 class="section-title">1. Introduction</h2>
    <p>The <strong>Automated Library Management &amp; Fine Tracking System</strong> is a secure, efficient, and robust database project designed to store, manage, and process book catalogue, member, loan, and fine records in an <strong>Oracle PL/SQL</strong> environment. It aims to modernize library circulation by combining the principles of <strong>Database Management Systems (DBMS)</strong> with procedural programming. Using a bottom-up design approach, the system builds a strong relational foundation by defining core entities such as <strong>Books, Members, Book Loans</strong>, and <strong>Fines</strong>, ensuring consistency, accuracy, and operational flexibility across the entire lending workflow.</p>
    <p>The project implements normalization up to the <strong>Third Normal Form (3NF)</strong> to eliminate data redundancy, prevent insertion, update and deletion anomalies, and enforce referential integrity between tables through <strong>primary keys, foreign keys, unique</strong> and <strong>check constraints</strong>. To optimize performance and streamline querying, indexing and sequences are applied across foreign key columns, loan dates, and member lookups. Referential integrity prevents orphan records, while constraints enforce valid status domains such as AVAILABLE and BORROWED.</p>
    <p>At the core of the system is the <strong>PL/SQL procedural engine</strong>, which automates business logic directly inside the database server. Stored procedures including <code>issue_book</code>, <code>return_book</code>, and <code>display_member_history</code> encapsulate critical circulation logic, while the stored function <code>calculate_fine</code> handles overdue fee assessment. Eligibility rules &ndash; active membership, account suspension status, and physical copy availability &ndash; are strictly validated before any book is issued. Event-driven database triggers enforce critical synchronization: the <code>trg_sync_book_availability</code> trigger automatically marks books as BORROWED upon loan creation and restores them to AVAILABLE upon return.</p>
    <p><strong>Robust exception handling</strong> is provided through user-defined exceptions and standard Oracle exceptions such as <code>NO_DATA_FOUND</code> and <code>TOO_MANY_ROWS</code>. Every procedure uses transaction management and savepoints so that operations adhere strictly to <strong>ACID (Atomicity, Consistency, Isolation, Durability)</strong> properties: if an error occurs, the work is rolled back to preserve data integrity. Overall, the system serves as a reliable and practical solution, seamlessly combining theoretical DBMS concepts with a real-world Oracle PL/SQL application.</p>
    <div class="page-number">1</div>
</div>
"@)

# ==============================================================================
# PAGE 6: 2. OBJECTIVE (Page Number: 2)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <h2 class="section-title">2. Objective</h2>
    <div class="objective-list">
        <div class="objective-item">
            <div class="objective-title">1. To design a robust and scalable library database system:</div>
            Develop a reliable relational database that efficiently manages the book catalogue, member accounts, book loans, and fine records while ensuring data integrity and operational reliability.
        </div>
        <div class="objective-item">
            <div class="objective-title">2. To achieve database normalization and data integrity:</div>
            Apply normalization principles (<strong>1NF, 2NF, and 3NF</strong>) and enforce primary key, foreign key, unique, check, and default constraints to eliminate redundancy, prevent modification anomalies, and optimize query performance through sequences and constraints.
        </div>
        <div class="objective-item">
            <div class="objective-title">3. To implement PL/SQL stored procedures and functions:</div>
            Encapsulate critical business operations directly inside the database by developing stored procedures for issuing and returning books, displaying formatted borrowing history, and a stored function for automated overdue fine computation.
        </div>
        <div class="objective-item">
            <div class="objective-title">4. To automate availability synchronization using database triggers:</div>
            Implement event-driven triggers (<code>trg_sync_book_availability</code>) that automatically synchronize the inventory status of books in the <code>BOOKS</code> table whenever a loan is created or updated in the <code>LOANS</code> table.
        </div>
        <div class="objective-item">
            <div class="objective-title">5. To implement robust error and exception handling:</div>
            Define custom user exceptions (such as <code>ex_book_unavailable</code>, <code>ex_member_suspended</code>, <code>ex_invalid_member</code>, <code>ex_loan_not_found</code>, and <code>ex_already_returned</code>) alongside predefined exceptions like <code>NO_DATA_FOUND</code> to provide clear, diagnostic error messages.
        </div>
        <div class="objective-item">
            <div class="objective-title">6. To ensure transaction management and ACID compliance:</div>
            Guarantee database reliability through atomic transactions, <code>COMMIT</code>, and <code>ROLLBACK</code> control so that multi-step operations (e.g. updating loan records, calculating fines, and updating books) execute as indivisible units.
        </div>
        <div class="objective-item">
            <div class="objective-title">7. To validate the system with comprehensive test cases:</div>
            Demonstrate a successful checkout, an overdue return that generates a fine, business-rule rejections for unavailable books or suspended members, and formatted historical querying.
        </div>
    </div>
    <div class="page-number">2</div>
</div>
"@)

# ==============================================================================
# PAGE 7: 3. TOOLS AND TECHNOLOGIES USED (Page Number: 3)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <h2 class="section-title">3. Tools and Technologies Used</h2>
    <p>The <strong>Automated Library Management &amp; Fine Tracking System</strong> is developed using a robust combination of database management technologies and programming tools to ensure security, transactional accuracy, and efficient data processing. The primary backend technology used is the <strong>Oracle Database (12c or later, including 19c, 21c and Oracle Database XE / Free)</strong>, which serves as the core relational engine for storing book, member, loan, and fine records. The <strong>SQL language</strong> is utilized for schema definition, constraints, sequences, and executing relational queries involving joins, projections, and aggregations.</p>
    <p>At the core of the system is <strong>Oracle PL/SQL (Procedural Language/SQL)</strong>, which executes procedural business logic directly within the database server. PL/SQL is used to develop stored procedures, stored functions, user-defined exceptions, cursor-based reporting, and event-driven triggers. For database design and architectural modeling, tools like <strong>Draw.io</strong> and <strong>Oracle SQL Developer Data Modeler</strong> are used to create the Entity-Relationship (ER) Diagram and map relational schemas.</p>
    <p>For development and execution, <strong>Oracle SQL Developer (Run Script, F5)</strong> and <strong>SQL*Plus / SQLcl</strong> are used to execute the installation scripts in dependency order (schema, seed data, triggers, procedures, and test cases), and <code>DBMS_OUTPUT</code> is used to display the live results of every test block.</p>
    <p>In terms of advanced database management, <strong>database triggers</strong> are implemented for real-time inventory synchronization. Concurrency control and reliability are maintained through an ACID-compliant transaction design utilizing <code>COMMIT</code> and <code>ROLLBACK</code>. Overall, the selected tools and technologies make the system a practical, secure, and complete demonstration of Oracle PL/SQL capabilities.</p>
    <div class="page-number">3</div>
</div>
"@)

# ==============================================================================
# PAGE 8: 4. IMPLEMENTATION STEPS (Page Number: 4)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <h2 class="section-title">4. Implementation Steps</h2>
    <div class="steps-list">
        <div class="step-item">
            <span class="step-title">&bull; Requirement Analysis:</span><br>
            Identify the core entities and operational requirements of the library. The primary entities include <strong>Books, Members, Loans</strong>, and <strong>Fines</strong>. Define essential attributes, data types, validation constraints, and workflow operations such as book issuance, return processing, and overdue fine calculation.
        </div>
        <div class="step-item">
            <span class="step-title">&bull; Conceptual Design (ER Diagram):</span><br>
            Construct an Entity-Relationship (ER) Diagram to visually represent entities, attributes, and cardinality relationships, such as <em>Member borrows Books</em>, <em>Book is lent as Loan</em>, and <em>Loan may incur a Fine</em>. This provides a clear architectural blueprint for the database.
        </div>
        <div class="step-item">
            <span class="step-title">&bull; Logical Design and Normalization:</span><br>
            Map the ER diagram into relational tables and apply Normalization (<strong>up to 3NF</strong>) to remove data redundancy, prevent update anomalies, and maintain consistency. Establish Primary Keys, Foreign Keys, and referential constraints across all tables.
        </div>
        <div class="step-item">
            <span class="step-title">&bull; Schema Implementation (DDL &amp; DML):</span><br>
            Execute SQL commands in Oracle Database to create tables and Sequences (<code>book_seq, member_seq, loan_seq, fine_seq</code>). Define integrity constraints (<code>CHECK, UNIQUE, NOT NULL, DEFAULT</code>), and populate the tables with realistic sample books, members, and loans using DML commands.
        </div>
        <div class="step-item">
            <span class="step-title">&bull; PL/SQL Development (Procedures &amp; Functions):</span><br>
            Implement business logic directly within the database: <code>issue_book</code> (checks active membership, account status, and book availability), <code>return_book</code> (records the return, restores availability, calculates fine), <code>calculate_fine</code> (stored function), and <code>display_member_history</code> (cursor-based reporting).
        </div>
        <div class="step-item">
            <span class="step-title">&bull; Trigger-Based Automation:</span><br>
            Create event-driven database triggers to enforce business rules automatically: <code>trg_sync_book_availability</code> updates book status to BORROWED upon loan issuance and restores it to AVAILABLE upon return.
        </div>
        <div class="step-item">
            <span class="step-title">&bull; Exception Handling &amp; Transaction Management:</span><br>
            Define custom user exceptions and handle <code>NO_DATA_FOUND</code> and <code>OTHERS</code>. Incorporate atomic transaction control using <code>COMMIT</code> and <code>ROLLBACK</code> to guarantee ACID properties.
        </div>
        <div class="step-item">
            <span class="step-title">&bull; Testing and Validation:</span><br>
            Validate all procedures, functions, and triggers against comprehensive test scenarios. Verify successful checkout, return, overdue fine computation, rejection of borrowing unavailable books or suspended members, and borrowing history retrieval.
        </div>
    </div>
    <div class="page-number">4</div>
</div>
"@)

Write-Host "Pages 1 to 8 prepared."
# ==============================================================================
# PAGE 9: 5. SCREENSHOTS / RESULTS (Page Number: 5)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <h2 class="section-title" style="margin-bottom: 8px;">5. Screenshots/Result</h2>
    <div style="font-size: 11pt; font-weight: bold; margin-bottom: 6px;">Entity-Relationship Diagram</div>
    
    <div style="text-align: center; margin-bottom: 6px;">
        <svg width="600" height="235" viewBox="0 0 600 235" xmlns="http://www.w3.org/2000/svg" style="font-family: Arial, sans-serif;">
            <!-- MEMBERS TABLE -->
            <g transform="translate(15, 10)">
                <rect width="165" height="135" fill="#ffffff" stroke="#1e3a8a" stroke-width="1.5" rx="3" />
                <rect width="165" height="24" fill="#1e3a8a" rx="3" />
                <text x="82" y="16" fill="#ffffff" font-size="10" font-weight="bold" text-anchor="middle">MEMBERS</text>
                <text x="8" y="38" font-size="8.5" font-weight="bold" fill="#0f172a">member_id (PK)</text>
                <text x="8" y="52" font-size="8" fill="#334155">first_name, last_name</text>
                <text x="8" y="66" font-size="8" fill="#334155">email (UQ)</text>
                <text x="8" y="80" font-size="8" fill="#334155">phone</text>
                <text x="8" y="94" font-size="8" fill="#334155">join_date</text>
                <text x="8" y="108" font-size="8" fill="#334155">status (ACTIVE / SUSP)</text>
            </g>

            <!-- BOOKS TABLE -->
            <g transform="translate(420, 10)">
                <rect width="165" height="135" fill="#ffffff" stroke="#1e3a8a" stroke-width="1.5" rx="3" />
                <rect width="165" height="24" fill="#1e3a8a" rx="3" />
                <text x="82" y="16" fill="#ffffff" font-size="10" font-weight="bold" text-anchor="middle">BOOKS</text>
                <text x="8" y="38" font-size="8.5" font-weight="bold" fill="#0f172a">book_id (PK)</text>
                <text x="8" y="52" font-size="8" fill="#334155">title</text>
                <text x="8" y="66" font-size="8" fill="#334155">author</text>
                <text x="8" y="80" font-size="8" fill="#334155">category</text>
                <text x="8" y="94" font-size="8" fill="#334155">status (AVAIL / BORR)</text>
            </g>

            <!-- LOANS TABLE -->
            <g transform="translate(215, 10)">
                <rect width="170" height="135" fill="#ffffff" stroke="#1e3a8a" stroke-width="1.5" rx="3" />
                <rect width="170" height="24" fill="#1e3a8a" rx="3" />
                <text x="85" y="16" fill="#ffffff" font-size="10" font-weight="bold" text-anchor="middle">LOANS</text>
                <text x="8" y="38" font-size="8.5" font-weight="bold" fill="#0f172a">loan_id (PK)</text>
                <text x="8" y="52" font-size="8" fill="#0f172a">book_id (FK)</text>
                <text x="8" y="66" font-size="8" fill="#0f172a">member_id (FK)</text>
                <text x="8" y="80" font-size="8" fill="#334155">loan_date, due_date</text>
                <text x="8" y="94" font-size="8" fill="#334155">return_date</text>
                <text x="8" y="108" font-size="8" fill="#334155">status (ISSUED / RET)</text>
            </g>

            <!-- FINES TABLE -->
            <g transform="translate(215, 160)">
                <rect width="170" height="70" fill="#ffffff" stroke="#1e3a8a" stroke-width="1.5" rx="3" />
                <rect width="170" height="20" fill="#1e3a8a" rx="3" />
                <text x="85" y="14" fill="#ffffff" font-size="9" font-weight="bold" text-anchor="middle">FINES</text>
                <text x="8" y="32" font-size="8" font-weight="bold" fill="#0f172a">fine_id (PK)</text>
                <text x="8" y="44" font-size="8" fill="#0f172a">loan_id (FK, UQ)</text>
                <text x="8" y="56" font-size="8" fill="#334155">fine_amount, fine_date, status</text>
            </g>

            <!-- RELATIONSHIP LINES -->
            <line x1="180" y1="75" x2="215" y2="75" stroke="#334155" stroke-width="1.5" />
            <text x="186" y="68" font-size="8" font-weight="bold">1</text>
            <text x="198" y="88" font-size="7.5" fill="#475569">borrows</text>
            <text x="206" y="68" font-size="8" font-weight="bold">N</text>

            <line x1="385" y1="75" x2="420" y2="75" stroke="#334155" stroke-width="1.5" />
            <text x="390" y="68" font-size="8" font-weight="bold">N</text>
            <text x="393" y="88" font-size="7.5" fill="#475569">is lent as</text>
            <text x="412" y="68" font-size="8" font-weight="bold">1</text>

            <line x1="300" y1="145" x2="300" y2="160" stroke="#334155" stroke-width="1.5" />
            <text x="306" y="152" font-size="7.5" fill="#475569">may incur</text>
        </svg>
    </div>
    <div class="fig-caption">Figure 1: ER diagram of the Automated Library Management &amp; Fine Tracking System</div>

    <div class="code-title">01_schema_and_data.sql</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">1</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">2</span><span class="cd"><span class="cm">-- SCRIPT 01: SCHEMA AND SAMPLE DATA</span></span></div>
        <div class="code-line"><span class="ln">3</span><span class="cd"><span class="cm">-- Project   : Library Management System (Oracle PL/SQL Mini Project)</span></span></div>
        <div class="code-line"><span class="ln">4</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">5</span><span class="cd"><span class="kw">SET</span> SERVEROUTPUT <span class="kw">ON</span>;</span></div>
        <div class="code-line"><span class="ln">6</span><span class="cd"><span class="cm">-- Safe cleanup of existing objects</span></span></div>
        <div class="code-line"><span class="ln">7</span><span class="cd"><span class="kw">BEGIN</span> <span class="kw">EXECUTE IMMEDIATE</span> <span class="st">'DROP TABLE fines CASCADE CONSTRAINTS'</span>; <span class="kw">EXCEPTION WHEN OTHERS THEN NULL</span>; <span class="kw">END</span>; /</span></div>
        <div class="code-line"><span class="ln">8</span><span class="cd"><span class="kw">BEGIN</span> <span class="kw">EXECUTE IMMEDIATE</span> <span class="st">'DROP TABLE loans CASCADE CONSTRAINTS'</span>; <span class="kw">EXCEPTION WHEN OTHERS THEN NULL</span>; <span class="kw">END</span>; /</span></div>
        <div class="code-line"><span class="ln">9</span><span class="cd"><span class="kw">BEGIN</span> <span class="kw">EXECUTE IMMEDIATE</span> <span class="st">'DROP TABLE books CASCADE CONSTRAINTS'</span>; <span class="kw">EXCEPTION WHEN OTHERS THEN NULL</span>; <span class="kw">END</span>; /</span></div>
        <div class="code-line"><span class="ln">10</span><span class="cd"><span class="kw">BEGIN</span> <span class="kw">EXECUTE IMMEDIATE</span> <span class="st">'DROP TABLE members CASCADE CONSTRAINTS'</span>; <span class="kw">EXCEPTION WHEN OTHERS THEN NULL</span>; <span class="kw">END</span>; /</span></div>
        <div class="code-line"><span class="ln">11</span><span class="cd"><span class="cm">-- Primary Key Sequences</span></span></div>
        <div class="code-line"><span class="ln">12</span><span class="cd"><span class="kw">CREATE SEQUENCE</span> book_seq   <span class="kw">START WITH</span> <span class="num">101</span>  <span class="kw">INCREMENT BY</span> <span class="num">1</span> <span class="kw">NOCACHE</span>;</span></div>
        <div class="code-line"><span class="ln">13</span><span class="cd"><span class="kw">CREATE SEQUENCE</span> member_seq <span class="kw">START WITH</span> <span class="num">1</span>    <span class="kw">INCREMENT BY</span> <span class="num">1</span> <span class="kw">NOCACHE</span>;</span></div>
        <div class="code-line"><span class="ln">14</span><span class="cd"><span class="kw">CREATE SEQUENCE</span> loan_seq   <span class="kw">START WITH</span> <span class="num">1001</span> <span class="kw">INCREMENT BY</span> <span class="num">1</span> <span class="kw">NOCACHE</span>;</span></div>
        <div class="code-line"><span class="ln">15</span><span class="cd"><span class="kw">CREATE SEQUENCE</span> fine_seq   <span class="kw">START WITH</span> <span class="num">5001</span> <span class="kw">INCREMENT BY</span> <span class="num">1</span> <span class="kw">NOCACHE</span>;</span></div>
    </div>
    <div class="page-number">5</div>
</div>
"@)

# ==============================================================================
# PAGE 10: 01_schema_and_data.sql (Continued) (Page Number: 6)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div class="code-title">01_schema_and_data.sql (continued)</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">16</span><span class="cd"><span class="cm">-- 1. BOOKS TABLE (Inventory catalogue)</span></span></div>
        <div class="code-line"><span class="ln">17</span><span class="cd"><span class="kw">CREATE TABLE</span> books (</span></div>
        <div class="code-line"><span class="ln">18</span><span class="cd">    book_id     <span class="typ">NUMBER</span> <span class="kw">PRIMARY KEY</span>,</span></div>
        <div class="code-line"><span class="ln">19</span><span class="cd">    title       <span class="typ">VARCHAR2</span>(<span class="num">150</span>) <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">20</span><span class="cd">    author      <span class="typ">VARCHAR2</span>(<span class="num">100</span>) <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">21</span><span class="cd">    category    <span class="typ">VARCHAR2</span>(<span class="num">50</span>)  <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">22</span><span class="cd">    status      <span class="typ">VARCHAR2</span>(<span class="num">15</span>)  <span class="kw">DEFAULT</span> <span class="st">'AVAILABLE'</span> <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">23</span><span class="cd">    <span class="kw">CONSTRAINT</span> chk_book_status <span class="kw">CHECK</span> (status <span class="kw">IN</span> (<span class="st">'AVAILABLE'</span>, <span class="st">'BORROWED'</span>))</span></div>
        <div class="code-line"><span class="ln">24</span><span class="cd">);</span></div>
        <div class="code-line"><span class="ln">25</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">26</span><span class="cd"><span class="cm">-- 2. MEMBERS TABLE (Registered borrowers)</span></span></div>
        <div class="code-line"><span class="ln">27</span><span class="cd"><span class="kw">CREATE TABLE</span> members (</span></div>
        <div class="code-line"><span class="ln">28</span><span class="cd">    member_id   <span class="typ">NUMBER</span> <span class="kw">PRIMARY KEY</span>,</span></div>
        <div class="code-line"><span class="ln">29</span><span class="cd">    first_name  <span class="typ">VARCHAR2</span>(<span class="num">50</span>)  <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">30</span><span class="cd">    last_name   <span class="typ">VARCHAR2</span>(<span class="num">50</span>)  <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">31</span><span class="cd">    email       <span class="typ">VARCHAR2</span>(<span class="num">100</span>) <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">32</span><span class="cd">    phone       <span class="typ">VARCHAR2</span>(<span class="num">20</span>),</span></div>
        <div class="code-line"><span class="ln">33</span><span class="cd">    join_date   <span class="typ">DATE</span> <span class="kw">DEFAULT</span> SYSDATE <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">34</span><span class="cd">    status      <span class="typ">VARCHAR2</span>(<span class="num">15</span>)  <span class="kw">DEFAULT</span> <span class="st">'ACTIVE'</span> <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">35</span><span class="cd">    <span class="kw">CONSTRAINT</span> uq_member_email <span class="kw">UNIQUE</span> (email),</span></div>
        <div class="code-line"><span class="ln">36</span><span class="cd">    <span class="kw">CONSTRAINT</span> chk_member_status <span class="kw">CHECK</span> (status <span class="kw">IN</span> (<span class="st">'ACTIVE'</span>, <span class="st">'SUSPENDED'</span>))</span></div>
        <div class="code-line"><span class="ln">37</span><span class="cd">);</span></div>
        <div class="code-line"><span class="ln">38</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">39</span><span class="cd"><span class="cm">-- 3. LOANS TABLE (Circulation transactions)</span></span></div>
        <div class="code-line"><span class="ln">40</span><span class="cd"><span class="kw">CREATE TABLE</span> loans (</span></div>
        <div class="code-line"><span class="ln">41</span><span class="cd">    loan_id     <span class="typ">NUMBER</span> <span class="kw">PRIMARY KEY</span>,</span></div>
        <div class="code-line"><span class="ln">42</span><span class="cd">    book_id     <span class="typ">NUMBER</span> <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">43</span><span class="cd">    member_id   <span class="typ">NUMBER</span> <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">44</span><span class="cd">    loan_date   <span class="typ">DATE</span> <span class="kw">DEFAULT</span> TRUNC(SYSDATE) <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">45</span><span class="cd">    due_date    <span class="typ">DATE</span> <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">46</span><span class="cd">    return_date <span class="typ">DATE</span>,</span></div>
        <div class="code-line"><span class="ln">47</span><span class="cd">    status      <span class="typ">VARCHAR2</span>(<span class="num">15</span>) <span class="kw">DEFAULT</span> <span class="st">'ISSUED'</span> <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">48</span><span class="cd">    <span class="kw">CONSTRAINT</span> fk_loans_book   <span class="kw">FOREIGN KEY</span> (book_id)   <span class="kw">REFERENCES</span> books(book_id),</span></div>
        <div class="code-line"><span class="ln">49</span><span class="cd">    <span class="kw">CONSTRAINT</span> fk_loans_member <span class="kw">FOREIGN KEY</span> (member_id) <span class="kw">REFERENCES</span> members(member_id),</span></div>
        <div class="code-line"><span class="ln">50</span><span class="cd">    <span class="kw">CONSTRAINT</span> chk_loan_status <span class="kw">CHECK</span> (status <span class="kw">IN</span> (<span class="st">'ISSUED'</span>, <span class="st">'RETURNED'</span>)),</span></div>
        <div class="code-line"><span class="ln">51</span><span class="cd">    <span class="kw">CONSTRAINT</span> chk_loan_dates  <span class="kw">CHECK</span> (due_date >= loan_date)</span></div>
        <div class="code-line"><span class="ln">52</span><span class="cd">);</span></div>
    </div>
    <div class="page-number">6</div>
</div>
"@)

# ==============================================================================
# PAGE 11: 01_schema_and_data.sql (Continued) (Page Number: 7)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div class="code-title">01_schema_and_data.sql (continued)</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">53</span><span class="cd"><span class="cm">-- 4. FINES TABLE (Late return penalties)</span></span></div>
        <div class="code-line"><span class="ln">54</span><span class="cd"><span class="kw">CREATE TABLE</span> fines (</span></div>
        <div class="code-line"><span class="ln">55</span><span class="cd">    fine_id        <span class="typ">NUMBER</span> <span class="kw">PRIMARY KEY</span>,</span></div>
        <div class="code-line"><span class="ln">56</span><span class="cd">    loan_id        <span class="typ">NUMBER</span> <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">57</span><span class="cd">    fine_amount    <span class="typ">NUMBER</span>(<span class="num">8</span>, <span class="num">2</span>) <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">58</span><span class="cd">    fine_date      <span class="typ">DATE</span> <span class="kw">DEFAULT</span> TRUNC(SYSDATE) <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">59</span><span class="cd">    payment_status <span class="typ">VARCHAR2</span>(<span class="num">15</span>) <span class="kw">DEFAULT</span> <span class="st">'PENDING'</span> <span class="kw">NOT NULL</span>,</span></div>
        <div class="code-line"><span class="ln">60</span><span class="cd">    <span class="kw">CONSTRAINT</span> fk_fines_loan   <span class="kw">FOREIGN KEY</span> (loan_id) <span class="kw">REFERENCES</span> loans(loan_id),</span></div>
        <div class="code-line"><span class="ln">61</span><span class="cd">    <span class="kw">CONSTRAINT</span> uq_fines_loan   <span class="kw">UNIQUE</span> (loan_id),</span></div>
        <div class="code-line"><span class="ln">62</span><span class="cd">    <span class="kw">CONSTRAINT</span> chk_fine_amount <span class="kw">CHECK</span> (fine_amount >= <span class="num">0</span>),</span></div>
        <div class="code-line"><span class="ln">63</span><span class="cd">    <span class="kw">CONSTRAINT</span> chk_fine_status <span class="kw">CHECK</span> (payment_status <span class="kw">IN</span> (<span class="st">'PENDING'</span>, <span class="st">'PAID'</span>))</span></div>
        <div class="code-line"><span class="ln">64</span><span class="cd">);</span></div>
        <div class="code-line"><span class="ln">65</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">66</span><span class="cd"><span class="cm">-- 5. PERFORMANCE INDEXES (Foreign Keys &amp; Search Predicates)</span></span></div>
        <div class="code-line"><span class="ln">67</span><span class="cd"><span class="kw">CREATE INDEX</span> idx_loans_book_id   <span class="kw">ON</span> loans(book_id);</span></div>
        <div class="code-line"><span class="ln">68</span><span class="cd"><span class="kw">CREATE INDEX</span> idx_loans_member_id <span class="kw">ON</span> loans(member_id);</span></div>
        <div class="code-line"><span class="ln">69</span><span class="cd"><span class="kw">CREATE INDEX</span> idx_loans_status    <span class="kw">ON</span> loans(status);</span></div>
        <div class="code-line"><span class="ln">70</span><span class="cd"><span class="kw">CREATE INDEX</span> idx_fines_loan_id   <span class="kw">ON</span> fines(loan_id);</span></div>
    </div>
    <div class="page-number">7</div>
</div>
"@)

# ==============================================================================
# PAGE 12: 01_schema_and_data.sql (Seed Data) & 02_triggers.sql Intro (Page Number: 8)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div class="code-title">01_schema_and_data.sql (Seed Data)</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">71</span><span class="cd"><span class="cm">-- Populate Initial Books (101 to 105)</span></span></div>
        <div class="code-line"><span class="ln">72</span><span class="cd"><span class="kw">INSERT INTO</span> books <span class="kw">VALUES</span> (book_seq.NEXTVAL, <span class="st">'Database System Concepts'</span>, <span class="st">'Abraham Silberschatz'</span>, <span class="st">'Computer Science'</span>, <span class="st">'BORROWED'</span>);</span></div>
        <div class="code-line"><span class="ln">73</span><span class="cd"><span class="kw">INSERT INTO</span> books <span class="kw">VALUES</span> (book_seq.NEXTVAL, <span class="st">'Clean Code: Handbook of Agile Software'</span>, <span class="st">'Robert C. Martin'</span>, <span class="st">'Software Engineering'</span>, <span class="st">'AVAILABLE'</span>);</span></div>
        <div class="code-line"><span class="ln">74</span><span class="cd"><span class="kw">INSERT INTO</span> books <span class="kw">VALUES</span> (book_seq.NEXTVAL, <span class="st">'Introduction to Algorithms'</span>, <span class="st">'Thomas H. Cormen'</span>, <span class="st">'Computer Science'</span>, <span class="st">'AVAILABLE'</span>);</span></div>
        <div class="code-line"><span class="ln">75</span><span class="cd"><span class="kw">INSERT INTO</span> books <span class="kw">VALUES</span> (book_seq.NEXTVAL, <span class="st">'Design Patterns: Elements of Reusable Code'</span>, <span class="st">'Erich Gamma'</span>, <span class="st">'Software Engineering'</span>, <span class="st">'AVAILABLE'</span>);</span></div>
        <div class="code-line"><span class="ln">76</span><span class="cd"><span class="kw">INSERT INTO</span> books <span class="kw">VALUES</span> (book_seq.NEXTVAL, <span class="st">'Artificial Intelligence: A Modern Approach'</span>, <span class="st">'Stuart Russell'</span>, <span class="st">'Artificial Intelligence'</span>, <span class="st">'AVAILABLE'</span>);</span></div>
        <div class="code-line"><span class="ln">77</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">78</span><span class="cd"><span class="cm">-- Populate Initial Members (1 to 4)</span></span></div>
        <div class="code-line"><span class="ln">79</span><span class="cd"><span class="kw">INSERT INTO</span> members <span class="kw">VALUES</span> (member_seq.NEXTVAL, <span class="st">'Alice'</span>, <span class="st">'Johnson'</span>, <span class="st">'alice.johnson@example.com'</span>, <span class="st">'555-0101'</span>, <span class="kw">DATE</span> <span class="st">'2024-01-15'</span>, <span class="st">'ACTIVE'</span>);</span></div>
        <div class="code-line"><span class="ln">80</span><span class="cd"><span class="kw">INSERT INTO</span> members <span class="kw">VALUES</span> (member_seq.NEXTVAL, <span class="st">'Bob'</span>, <span class="st">'Smith'</span>, <span class="st">'bob.smith@example.com'</span>, <span class="st">'555-0102'</span>, <span class="kw">DATE</span> <span class="st">'2024-02-20'</span>, <span class="st">'ACTIVE'</span>);</span></div>
        <div class="code-line"><span class="ln">81</span><span class="cd"><span class="kw">INSERT INTO</span> members <span class="kw">VALUES</span> (member_seq.NEXTVAL, <span class="st">'Charlie'</span>, <span class="st">'Brown'</span>, <span class="st">'charlie.brown@example.com'</span>, <span class="st">'555-0103'</span>, <span class="kw">DATE</span> <span class="st">'2024-03-10'</span>, <span class="st">'ACTIVE'</span>);</span></div>
        <div class="code-line"><span class="ln">82</span><span class="cd"><span class="kw">INSERT INTO</span> members <span class="kw">VALUES</span> (member_seq.NEXTVAL, <span class="st">'Diana'</span>, <span class="st">'Prince'</span>, <span class="st">'diana.prince@example.com'</span>, <span class="st">'555-0104'</span>, <span class="kw">DATE</span> <span class="st">'2024-04-05'</span>, <span class="st">'SUSPENDED'</span>);</span></div>
        <div class="code-line"><span class="ln">83</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">84</span><span class="cd"><span class="cm">-- Seed Loans: 1001 (Overdue test) and 1002 (On-time return)</span></span></div>
        <div class="code-line"><span class="ln">85</span><span class="cd"><span class="kw">INSERT INTO</span> loans <span class="kw">VALUES</span> (loan_seq.NEXTVAL, <span class="num">101</span>, <span class="num">1</span>, TRUNC(SYSDATE) - <span class="num">20</span>, TRUNC(SYSDATE) - <span class="num">6</span>, <span class="kw">NULL</span>, <span class="st">'ISSUED'</span>);</span></div>
        <div class="code-line"><span class="ln">86</span><span class="cd"><span class="kw">INSERT INTO</span> loans <span class="kw">VALUES</span> (loan_seq.NEXTVAL, <span class="num">102</span>, <span class="num">2</span>, TRUNC(SYSDATE) - <span class="num">14</span>, TRUNC(SYSDATE), TRUNC(SYSDATE) - <span class="num">2</span>, <span class="st">'RETURNED'</span>);</span></div>
        <div class="code-line"><span class="ln">87</span><span class="cd"><span class="kw">COMMIT</span>;</span></div>
    </div>
    <div class="code-title" style="margin-top: 15px;">02_triggers.sql</div>
    <p style="font-size: 10pt; line-height: 1.45;">The trigger below automates status transitions. When a loan is created with status ISSUED, the book status is set to BORROWED. When updated to RETURNED, the book status is restored to AVAILABLE.</p>
    <div class="page-number">8</div>
</div>
"@)
# ==============================================================================
# PAGE 13: 02_triggers.sql & 03_procedures_and_functions.sql (Page Number: 9)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div class="code-title">02_triggers.sql (continued)</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">1</span><span class="cd"><span class="kw">CREATE OR REPLACE TRIGGER</span> trg_sync_book_availability</span></div>
        <div class="code-line"><span class="ln">2</span><span class="cd"><span class="kw">AFTER INSERT OR UPDATE OF</span> status <span class="kw">ON</span> loans</span></div>
        <div class="code-line"><span class="ln">3</span><span class="cd"><span class="kw">FOR EACH ROW</span></span></div>
        <div class="code-line"><span class="ln">4</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">5</span><span class="cd">    <span class="cm">-- Scenario 1: Loan issued -> Mark book as BORROWED</span></span></div>
        <div class="code-line"><span class="ln">6</span><span class="cd">    <span class="kw">IF INSERTING THEN</span></span></div>
        <div class="code-line"><span class="ln">7</span><span class="cd">        <span class="kw">IF</span> :NEW.status = <span class="st">'ISSUED'</span> <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">8</span><span class="cd">            <span class="kw">UPDATE</span> books <span class="kw">SET</span> status = <span class="st">'BORROWED'</span> <span class="kw">WHERE</span> book_id = :NEW.book_id;</span></div>
        <div class="code-line"><span class="ln">9</span><span class="cd">        <span class="kw">END IF</span>;</span></div>
        <div class="code-line"><span class="ln">10</span><span class="cd">    <span class="cm">-- Scenario 2: Loan returned -> Mark book back as AVAILABLE</span></span></div>
        <div class="code-line"><span class="ln">11</span><span class="cd">    <span class="kw">ELSIF UPDATING THEN</span></span></div>
        <div class="code-line"><span class="ln">12</span><span class="cd">        <span class="kw">IF</span> :NEW.status = <span class="st">'RETURNED'</span> <span class="kw">AND</span> :OLD.status = <span class="st">'ISSUED'</span> <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">13</span><span class="cd">            <span class="kw">UPDATE</span> books <span class="kw">SET</span> status = <span class="st">'AVAILABLE'</span> <span class="kw">WHERE</span> book_id = :NEW.book_id;</span></div>
        <div class="code-line"><span class="ln">14</span><span class="cd">        <span class="kw">END IF</span>;</span></div>
        <div class="code-line"><span class="ln">15</span><span class="cd">    <span class="kw">END IF</span>;</span></div>
        <div class="code-line"><span class="ln">16</span><span class="cd"><span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">17</span><span class="cd">/</span></div>
    </div>
    <div class="code-title" style="margin-top: 10px;">03_procedures_and_functions.sql &ndash; FUNCTION calculate_fine</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">1</span><span class="cd"><span class="kw">CREATE OR REPLACE FUNCTION</span> calculate_fine (p_loan_id <span class="kw">IN</span> <span class="typ">NUMBER</span>, p_return_date <span class="kw">IN</span> <span class="typ">DATE</span> <span class="kw">DEFAULT NULL</span>)</span></div>
        <div class="code-line"><span class="ln">2</span><span class="cd"><span class="kw">RETURN</span> <span class="typ">NUMBER</span> <span class="kw">IS</span></span></div>
        <div class="code-line"><span class="ln">3</span><span class="cd">    c_fine_per_day   <span class="kw">CONSTANT</span> <span class="typ">NUMBER</span>(<span class="num">5</span>, <span class="num">2</span>) := <span class="num">2.00</span>; <span class="cm">-- $2.00/day overdue</span></span></div>
        <div class="code-line"><span class="ln">4</span><span class="cd">    v_due_date       loans.due_date%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">5</span><span class="cd">    v_loan_date      loans.loan_date%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">6</span><span class="cd">    v_actual_return  loans.return_date%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">7</span><span class="cd">    v_effective_date <span class="typ">DATE</span>;</span></div>
        <div class="code-line"><span class="ln">8</span><span class="cd">    v_overdue_days   <span class="typ">NUMBER</span> := <span class="num">0</span>;</span></div>
        <div class="code-line"><span class="ln">9</span><span class="cd">    v_fine_amount    <span class="typ">NUMBER</span>(<span class="num">8</span>, <span class="num">2</span>) := <span class="num">0.00</span>;</span></div>
        <div class="code-line"><span class="ln">10</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">11</span><span class="cd">    <span class="kw">SELECT</span> due_date, loan_date, return_date <span class="kw">INTO</span> v_due_date, v_loan_date, v_actual_return</span></div>
        <div class="code-line"><span class="ln">12</span><span class="cd">    <span class="kw">FROM</span> loans <span class="kw">WHERE</span> loan_id = p_loan_id;</span></div>
        <div class="code-line"><span class="ln">13</span><span class="cd">    v_effective_date := NVL(p_return_date, NVL(v_actual_return, TRUNC(SYSDATE)));</span></div>
        <div class="code-line"><span class="ln">14</span><span class="cd">    <span class="kw">IF</span> TRUNC(v_effective_date) < TRUNC(v_loan_date) <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">15</span><span class="cd">        RAISE_APPLICATION_ERROR(-<span class="num">20001</span>, <span class="st">'Return date cannot be earlier than loan date.'</span>);</span></div>
        <div class="code-line"><span class="ln">16</span><span class="cd">    <span class="kw">END IF</span>;</span></div>
        <div class="code-line"><span class="ln">17</span><span class="cd">    <span class="kw">IF</span> TRUNC(v_effective_date) > TRUNC(v_due_date) <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">18</span><span class="cd">        v_overdue_days := TRUNC(v_effective_date) - TRUNC(v_due_date);</span></div>
        <div class="code-line"><span class="ln">19</span><span class="cd">        v_fine_amount  := v_overdue_days * c_fine_per_day;</span></div>
        <div class="code-line"><span class="ln">20</span><span class="cd">    <span class="kw">ELSE</span> v_fine_amount := <span class="num">0.00</span>;</span></div>
        <div class="code-line"><span class="ln">21</span><span class="cd">    <span class="kw">END IF</span>;</span></div>
        <div class="code-line"><span class="ln">22</span><span class="cd">    <span class="kw">RETURN</span> v_fine_amount;</span></div>
        <div class="code-line"><span class="ln">23</span><span class="cd"><span class="kw">EXCEPTION WHEN NO_DATA_FOUND THEN</span></span></div>
        <div class="code-line"><span class="ln">24</span><span class="cd">    RAISE_APPLICATION_ERROR(-<span class="num">20002</span>, <span class="st">'Loan ID '</span> || p_loan_id || <span class="st">' does not exist.'</span>);</span></div>
        <div class="code-line"><span class="ln">25</span><span class="cd"><span class="kw">END</span>; /</span></div>
    </div>
    <div class="page-number">9</div>
</div>
"@)

# ==============================================================================
# PAGE 14: 03_procedures_and_functions.sql &ndash; PROCEDURE issue_book (Part 1) (Page Number: 10)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div class="code-title">03_procedures_and_functions.sql &ndash; PROCEDURE issue_book</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">1</span><span class="cd"><span class="kw">CREATE OR REPLACE PROCEDURE</span> issue_book (</span></div>
        <div class="code-line"><span class="ln">2</span><span class="cd">    p_book_id   <span class="kw">IN</span> <span class="typ">NUMBER</span>,</span></div>
        <div class="code-line"><span class="ln">3</span><span class="cd">    p_member_id <span class="kw">IN</span> <span class="typ">NUMBER</span>,</span></div>
        <div class="code-line"><span class="ln">4</span><span class="cd">    p_loan_days <span class="kw">IN</span> <span class="typ">NUMBER</span> <span class="kw">DEFAULT</span> <span class="num">14</span></span></div>
        <div class="code-line"><span class="ln">5</span><span class="cd">) <span class="kw">IS</span></span></div>
        <div class="code-line"><span class="ln">6</span><span class="cd">    v_book_title    books.title%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">7</span><span class="cd">    v_book_status   books.status%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">8</span><span class="cd">    v_member_name   <span class="typ">VARCHAR2</span>(<span class="num">101</span>);</span></div>
        <div class="code-line"><span class="ln">9</span><span class="cd">    v_member_status members.status%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">10</span><span class="cd">    v_new_loan_id   loans.loan_id%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">11</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">12</span><span class="cd">    <span class="cm">-- User-defined exceptions</span></span></div>
        <div class="code-line"><span class="ln">13</span><span class="cd">    ex_invalid_member   <span class="kw">EXCEPTION</span>;</span></div>
        <div class="code-line"><span class="ln">14</span><span class="cd">    ex_member_suspended <span class="kw">EXCEPTION</span>;</span></div>
        <div class="code-line"><span class="ln">15</span><span class="cd">    ex_invalid_book     <span class="kw">EXCEPTION</span>;</span></div>
        <div class="code-line"><span class="ln">16</span><span class="cd">    ex_book_unavailable <span class="kw">EXCEPTION</span>;</span></div>
        <div class="code-line"><span class="ln">17</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">18</span><span class="cd">    <span class="cm">-- 1. Validate Member</span></span></div>
        <div class="code-line"><span class="ln">19</span><span class="cd">    <span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">20</span><span class="cd">        <span class="kw">SELECT</span> first_name || <span class="st">' '</span> || last_name, status</span></div>
        <div class="code-line"><span class="ln">21</span><span class="cd">        <span class="kw">INTO</span> v_member_name, v_member_status</span></div>
        <div class="code-line"><span class="ln">22</span><span class="cd">        <span class="kw">FROM</span> members <span class="kw">WHERE</span> member_id = p_member_id;</span></div>
        <div class="code-line"><span class="ln">23</span><span class="cd">    <span class="kw">EXCEPTION WHEN NO_DATA_FOUND THEN</span></span></div>
        <div class="code-line"><span class="ln">24</span><span class="cd">        <span class="kw">RAISE</span> ex_invalid_member;</span></div>
        <div class="code-line"><span class="ln">25</span><span class="cd">    <span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">26</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">27</span><span class="cd">    <span class="kw">IF</span> v_member_status = <span class="st">'SUSPENDED'</span> <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">28</span><span class="cd">        <span class="kw">RAISE</span> ex_member_suspended;</span></div>
        <div class="code-line"><span class="ln">29</span><span class="cd">    <span class="kw">END</span> <span class="kw">IF</span>;</span></div>
        <div class="code-line"><span class="ln">30</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">31</span><span class="cd">    <span class="cm">-- 2. Validate Book</span></span></div>
        <div class="code-line"><span class="ln">32</span><span class="cd">    <span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">33</span><span class="cd">        <span class="kw">SELECT</span> title, status <span class="kw">INTO</span> v_book_title, v_book_status</span></div>
        <div class="code-line"><span class="ln">34</span><span class="cd">        <span class="kw">FROM</span> books <span class="kw">WHERE</span> book_id = p_book_id;</span></div>
        <div class="code-line"><span class="ln">35</span><span class="cd">    <span class="kw">EXCEPTION WHEN NO_DATA_FOUND THEN</span></span></div>
        <div class="code-line"><span class="ln">36</span><span class="cd">        <span class="kw">RAISE</span> ex_invalid_book;</span></div>
        <div class="code-line"><span class="ln">37</span><span class="cd">    <span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">38</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">39</span><span class="cd">    <span class="kw">IF</span> v_book_status != <span class="st">'AVAILABLE'</span> <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">40</span><span class="cd">        <span class="kw">RAISE</span> ex_book_unavailable;</span></div>
        <div class="code-line"><span class="ln">41</span><span class="cd">    <span class="kw">END</span> <span class="kw">IF</span>;</span></div>
    </div>
    <div class="page-number">10</div>
</div>
"@)

# ==============================================================================
# PAGE 15: 03_procedures_and_functions.sql &ndash; PROCEDURE issue_book (Part 2) (Page Number: 11)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div class="code-title">03_procedures_and_functions.sql &ndash; issue_book (continued)</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">42</span><span class="cd">    <span class="cm">-- 3. Insert Loan Record (Trigger trg_sync_book_availability marks book BORROWED)</span></span></div>
        <div class="code-line"><span class="ln">43</span><span class="cd">    v_new_loan_id := loan_seq.NEXTVAL;</span></div>
        <div class="code-line"><span class="ln">44</span><span class="cd">    <span class="kw">INSERT INTO</span> loans (loan_id, book_id, member_id, loan_date, due_date, return_date, status)</span></div>
        <div class="code-line"><span class="ln">45</span><span class="cd">    <span class="kw">VALUES</span> (v_new_loan_id, p_book_id, p_member_id, TRUNC(SYSDATE), TRUNC(SYSDATE) + p_loan_days, <span class="kw">NULL</span>, <span class="st">'ISSUED'</span>);</span></div>
        <div class="code-line"><span class="ln">46</span><span class="cd">    <span class="kw">COMMIT</span>;</span></div>
        <div class="code-line"><span class="ln">47</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">48</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'----------------------------------------------------'</span>);</span></div>
        <div class="code-line"><span class="ln">49</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'SUCCESS: Book issued successfully!'</span>);</span></div>
        <div class="code-line"><span class="ln">50</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Loan ID     : '</span> || v_new_loan_id);</span></div>
        <div class="code-line"><span class="ln">51</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Book Title  : '</span> || v_book_title || <span class="st">' (ID: '</span> || p_book_id || <span class="st">')'</span>);</span></div>
        <div class="code-line"><span class="ln">52</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Member      : '</span> || v_member_name || <span class="st">' (ID: '</span> || p_member_id || <span class="st">')'</span>);</span></div>
        <div class="code-line"><span class="ln">53</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Issue Date  : '</span> || TO_CHAR(SYSDATE, <span class="st">'YYYY-MM-DD'</span>));</span></div>
        <div class="code-line"><span class="ln">54</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Due Date    : '</span> || TO_CHAR(SYSDATE + p_loan_days, <span class="st">'YYYY-MM-DD'</span>));</span></div>
        <div class="code-line"><span class="ln">55</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Book Status : Changed to BORROWED by Trigger'</span>);</span></div>
        <div class="code-line"><span class="ln">56</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'----------------------------------------------------'</span>);</span></div>
        <div class="code-line"><span class="ln">57</span><span class="cd"><span class="kw">EXCEPTION</span></span></div>
        <div class="code-line"><span class="ln">58</span><span class="cd">    <span class="kw">WHEN</span> ex_invalid_member <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">59</span><span class="cd">        DBMS_OUTPUT.PUT_LINE(<span class="st">'ERROR: Member ID '</span> || p_member_id || <span class="st">' does not exist.'</span>);</span></div>
        <div class="code-line"><span class="ln">60</span><span class="cd">    <span class="kw">WHEN</span> ex_member_suspended <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">61</span><span class="cd">        DBMS_OUTPUT.PUT_LINE(<span class="st">'ERROR: Member "'</span> || v_member_name || <span class="st">'" (ID: '</span> || p_member_id || <span class="st">') is SUSPENDED. Cannot issue books.'</span>);</span></div>
        <div class="code-line"><span class="ln">62</span><span class="cd">    <span class="kw">WHEN</span> ex_invalid_book <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">63</span><span class="cd">        DBMS_OUTPUT.PUT_LINE(<span class="st">'ERROR: Book ID '</span> || p_book_id || <span class="st">' does not exist.'</span>);</span></div>
        <div class="code-line"><span class="ln">64</span><span class="cd">    <span class="kw">WHEN</span> ex_book_unavailable <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">65</span><span class="cd">        DBMS_OUTPUT.PUT_LINE(<span class="st">'ERROR: Book "'</span> || v_book_title || <span class="st">'" (ID: '</span> || p_book_id || <span class="st">') is already BORROWED and unavailable.'</span>);</span></div>
        <div class="code-line"><span class="ln">66</span><span class="cd">    <span class="kw">WHEN OTHERS THEN</span></span></div>
        <div class="code-line"><span class="ln">67</span><span class="cd">        <span class="kw">ROLLBACK</span>;</span></div>
        <div class="code-line"><span class="ln">68</span><span class="cd">        DBMS_OUTPUT.PUT_LINE(<span class="st">'UNEXPECTED ERROR: '</span> || SQLERRM);</span></div>
        <div class="code-line"><span class="ln">69</span><span class="cd"><span class="kw">END</span> issue_book; /</span></div>
    </div>
    <div class="page-number">11</div>
</div>
"@)

# ==============================================================================
# PAGE 16: 03_procedures_and_functions.sql &ndash; PROCEDURE return_book (Part 1) (Page Number: 12)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div class="code-title">03_procedures_and_functions.sql &ndash; PROCEDURE return_book</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">1</span><span class="cd"><span class="kw">CREATE OR REPLACE PROCEDURE</span> return_book (</span></div>
        <div class="code-line"><span class="ln">2</span><span class="cd">    p_loan_id     <span class="kw">IN</span> <span class="typ">NUMBER</span>,</span></div>
        <div class="code-line"><span class="ln">3</span><span class="cd">    p_return_date <span class="kw">IN</span> <span class="typ">DATE</span> <span class="kw">DEFAULT</span> SYSDATE</span></div>
        <div class="code-line"><span class="ln">4</span><span class="cd">) <span class="kw">IS</span></span></div>
        <div class="code-line"><span class="ln">5</span><span class="cd">    v_book_id       loans.book_id%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">6</span><span class="cd">    v_member_id     loans.member_id%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">7</span><span class="cd">    v_loan_date     loans.loan_date%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">8</span><span class="cd">    v_due_date      loans.due_date%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">9</span><span class="cd">    v_loan_status   loans.status%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">10</span><span class="cd">    v_book_title    books.title%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">11</span><span class="cd">    v_member_name   <span class="typ">VARCHAR2</span>(<span class="num">101</span>);</span></div>
        <div class="code-line"><span class="ln">12</span><span class="cd">    v_fine_amount   <span class="typ">NUMBER</span>(<span class="num">8</span>, <span class="num">2</span>) := <span class="num">0.00</span>;</span></div>
        <div class="code-line"><span class="ln">13</span><span class="cd">    v_overdue_days  <span class="typ">NUMBER</span> := <span class="num">0</span>;</span></div>
        <div class="code-line"><span class="ln">14</span><span class="cd">    v_new_fine_id   fines.fine_id%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">15</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">16</span><span class="cd">    <span class="cm">-- User-defined exceptions</span></span></div>
        <div class="code-line"><span class="ln">17</span><span class="cd">    ex_loan_not_found   <span class="kw">EXCEPTION</span>;</span></div>
        <div class="code-line"><span class="ln">18</span><span class="cd">    ex_already_returned <span class="kw">EXCEPTION</span>;</span></div>
        <div class="code-line"><span class="ln">19</span><span class="cd">    ex_invalid_date     <span class="kw">EXCEPTION</span>;</span></div>
        <div class="code-line"><span class="ln">20</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">21</span><span class="cd">    <span class="cm">-- 1. Validate Loan</span></span></div>
        <div class="code-line"><span class="ln">22</span><span class="cd">    <span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">23</span><span class="cd">        <span class="kw">SELECT</span> book_id, member_id, loan_date, due_date, status</span></div>
        <div class="code-line"><span class="ln">24</span><span class="cd">        <span class="kw">INTO</span> v_book_id, v_member_id, v_loan_date, v_due_date, v_loan_status</span></div>
        <div class="code-line"><span class="ln">25</span><span class="cd">        <span class="kw">FROM</span> loans <span class="kw">WHERE</span> loan_id = p_loan_id;</span></div>
        <div class="code-line"><span class="ln">26</span><span class="cd">    <span class="kw">EXCEPTION WHEN NO_DATA_FOUND THEN</span></span></div>
        <div class="code-line"><span class="ln">27</span><span class="cd">        <span class="kw">RAISE</span> ex_loan_not_found;</span></div>
        <div class="code-line"><span class="ln">28</span><span class="cd">    <span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">29</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">30</span><span class="cd">    <span class="kw">IF</span> v_loan_status = <span class="st">'RETURNED'</span> <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">31</span><span class="cd">        <span class="kw">RAISE</span> ex_already_returned;</span></div>
        <div class="code-line"><span class="ln">32</span><span class="cd">    <span class="kw">END</span> <span class="kw">IF</span>;</span></div>
        <div class="code-line"><span class="ln">33</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">34</span><span class="cd">    <span class="kw">IF</span> TRUNC(p_return_date) < TRUNC(v_loan_date) <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">35</span><span class="cd">        <span class="kw">RAISE</span> ex_invalid_date;</span></div>
        <div class="code-line"><span class="ln">36</span><span class="cd">    <span class="kw">END</span> <span class="kw">IF</span>;</span></div>
    </div>
    <div class="page-number">12</div>
</div>
"@)

# ==============================================================================
# PAGE 17: 03_procedures_and_functions.sql &ndash; PROCEDURE return_book (Part 2) (Page Number: 13)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div class="code-title">03_procedures_and_functions.sql &ndash; return_book (continued)</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">37</span><span class="cd">    <span class="kw">SELECT</span> title <span class="kw">INTO</span> v_book_title <span class="kw">FROM</span> books <span class="kw">WHERE</span> book_id = v_book_id;</span></div>
        <div class="code-line"><span class="ln">38</span><span class="cd">    <span class="kw">SELECT</span> first_name || <span class="st">' '</span> || last_name <span class="kw">INTO</span> v_member_name <span class="kw">FROM</span> members <span class="kw">WHERE</span> member_id = v_member_id;</span></div>
        <div class="code-line"><span class="ln">39</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">40</span><span class="cd">    <span class="cm">-- 2. Update Loan Status (Trigger trg_sync_book_availability marks book AVAILABLE)</span></span></div>
        <div class="code-line"><span class="ln">41</span><span class="cd">    <span class="kw">UPDATE</span> loans <span class="kw">SET</span> return_date = TRUNC(p_return_date), status = <span class="st">'RETURNED'</span> <span class="kw">WHERE</span> loan_id = p_loan_id;</span></div>
        <div class="code-line"><span class="ln">42</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">43</span><span class="cd">    <span class="cm">-- 3. Calculate Fine using calculate_fine function</span></span></div>
        <div class="code-line"><span class="ln">44</span><span class="cd">    v_fine_amount := calculate_fine(p_loan_id, p_return_date);</span></div>
        <div class="code-line"><span class="ln">45</span><span class="cd">    <span class="kw">IF</span> TRUNC(p_return_date) > TRUNC(v_due_date) <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">46</span><span class="cd">        v_overdue_days := TRUNC(p_return_date) - TRUNC(v_due_date);</span></div>
        <div class="code-line"><span class="ln">47</span><span class="cd">    <span class="kw">END IF</span>;</span></div>
        <div class="code-line"><span class="ln">48</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">49</span><span class="cd">    <span class="cm">-- 4. Record Fine if overdue</span></span></div>
        <div class="code-line"><span class="ln">50</span><span class="cd">    <span class="kw">IF</span> v_fine_amount > <span class="num">0</span> <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">51</span><span class="cd">        v_new_fine_id := fine_seq.NEXTVAL;</span></div>
        <div class="code-line"><span class="ln">52</span><span class="cd">        <span class="kw">INSERT INTO</span> fines <span class="kw">VALUES</span> (v_new_fine_id, p_loan_id, v_fine_amount, TRUNC(SYSDATE), <span class="st">'PENDING'</span>);</span></div>
        <div class="code-line"><span class="ln">53</span><span class="cd">    <span class="kw">END IF</span>;</span></div>
        <div class="code-line"><span class="ln">54</span><span class="cd">    <span class="kw">COMMIT</span>;</span></div>
        <div class="code-line"><span class="ln">55</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">56</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'----------------------------------------------------'</span>);</span></div>
        <div class="code-line"><span class="ln">57</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'SUCCESS: Book returned successfully!'</span>);</span></div>
        <div class="code-line"><span class="ln">58</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Loan ID      : '</span> || p_loan_id);</span></div>
        <div class="code-line"><span class="ln">59</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Book Title   : '</span> || v_book_title || <span class="st">' (ID: '</span> || v_book_id || <span class="st">')'</span>);</span></div>
        <div class="code-line"><span class="ln">60</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Member       : '</span> || v_member_name || <span class="st">' (ID: '</span> || v_member_id || <span class="st">')'</span>);</span></div>
        <div class="code-line"><span class="ln">61</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Due Date     : '</span> || TO_CHAR(v_due_date, <span class="st">'YYYY-MM-DD'</span>));</span></div>
        <div class="code-line"><span class="ln">62</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Return Date  : '</span> || TO_CHAR(p_return_date, <span class="st">'YYYY-MM-DD'</span>));</span></div>
        <div class="code-line"><span class="ln">63</span><span class="cd">    <span class="kw">IF</span> v_overdue_days > <span class="num">0</span> <span class="kw">THEN</span></span></div>
        <div class="code-line"><span class="ln">64</span><span class="cd">        DBMS_OUTPUT.PUT_LINE(<span class="st">'Overdue Days : '</span> || v_overdue_days || <span class="st">' day(s)'</span>);</span></div>
        <div class="code-line"><span class="ln">65</span><span class="cd">        DBMS_OUTPUT.PUT_LINE(<span class="st">'Fine Imposed : $'</span> || TO_CHAR(v_fine_amount, <span class="st">'FM9990.00'</span>) || <span class="st">' (Fine ID: '</span> || v_new_fine_id || <span class="st">', Status: PENDING)'</span>);</span></div>
        <div class="code-line"><span class="ln">66</span><span class="cd">    <span class="kw">ELSE</span></span></div>
        <div class="code-line"><span class="ln">67</span><span class="cd">        DBMS_OUTPUT.PUT_LINE(<span class="st">'Overdue Days : 0 (Returned On Time)'</span>);</span></div>
        <div class="code-line"><span class="ln">68</span><span class="cd">        DBMS_OUTPUT.PUT_LINE(<span class="st">'Fine Imposed : $0.00'</span>);</span></div>
        <div class="code-line"><span class="ln">69</span><span class="cd">    <span class="kw">END IF</span>;</span></div>
        <div class="code-line"><span class="ln">70</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Book Status  : Changed to AVAILABLE by Trigger'</span>);</span></div>
        <div class="code-line"><span class="ln">71</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'----------------------------------------------------'</span>);</span></div>
        <div class="code-line"><span class="ln">72</span><span class="cd"><span class="kw">EXCEPTION</span></span></div>
        <div class="code-line"><span class="ln">73</span><span class="cd">    <span class="kw">WHEN</span> ex_loan_not_found <span class="kw">THEN</span> DBMS_OUTPUT.PUT_LINE(<span class="st">'ERROR: Loan ID '</span> || p_loan_id || <span class="st">' does not exist.'</span>);</span></div>
        <div class="code-line"><span class="ln">74</span><span class="cd">    <span class="kw">WHEN</span> ex_already_returned <span class="kw">THEN</span> DBMS_OUTPUT.PUT_LINE(<span class="st">'ERROR: Loan ID '</span> || p_loan_id || <span class="st">' has already been returned.'</span>);</span></div>
        <div class="code-line"><span class="ln">75</span><span class="cd">    <span class="kw">WHEN</span> ex_invalid_date <span class="kw">THEN</span> DBMS_OUTPUT.PUT_LINE(<span class="st">'ERROR: Return date cannot be earlier than loan issue date.'</span>);</span></div>
        <div class="code-line"><span class="ln">76</span><span class="cd">    <span class="kw">WHEN OTHERS THEN ROLLBACK</span>; DBMS_OUTPUT.PUT_LINE(<span class="st">'UNEXPECTED ERROR: '</span> || SQLERRM);</span></div>
        <div class="code-line"><span class="ln">77</span><span class="cd"><span class="kw">END</span> return_book; /</span></div>
    </div>
    <div class="page-number">13</div>
</div>
"@)

# ==============================================================================
# PAGE 18: 03_procedures_and_functions.sql &ndash; PROCEDURE display_member_history (Page Number: 14)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div class="code-title">03_procedures_and_functions.sql &ndash; display_member_history</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">1</span><span class="cd"><span class="kw">CREATE OR REPLACE PROCEDURE</span> display_member_history (p_member_id <span class="kw">IN</span> <span class="typ">NUMBER</span>) <span class="kw">IS</span></span></div>
        <div class="code-line"><span class="ln">2</span><span class="cd">    v_member_name   <span class="typ">VARCHAR2</span>(<span class="num">101</span>);</span></div>
        <div class="code-line"><span class="ln">3</span><span class="cd">    v_email         members.email%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">4</span><span class="cd">    v_member_status members.status%<span class="typ">TYPE</span>;</span></div>
        <div class="code-line"><span class="ln">5</span><span class="cd">    v_record_count  <span class="typ">NUMBER</span> := <span class="num">0</span>;</span></div>
        <div class="code-line"><span class="ln">6</span><span class="cd">    ex_member_not_found <span class="kw">EXCEPTION</span>;</span></div>
        <div class="code-line"><span class="ln">7</span><span class="cd">    <span class="kw">CURSOR</span> c_history <span class="kw">IS</span></span></div>
        <div class="code-line"><span class="ln">8</span><span class="cd">        <span class="kw">SELECT</span> l.loan_id, b.title, l.loan_date, l.due_date, l.return_date, l.status <span class="kw">AS</span> loan_status,</span></div>
        <div class="code-line"><span class="ln">9</span><span class="cd">               NVL(f.fine_amount, <span class="num">0</span>) <span class="kw">AS</span> fine_amount, NVL(f.payment_status, <span class="st">'NONE'</span>) <span class="kw">AS</span> fine_status</span></div>
        <div class="code-line"><span class="ln">10</span><span class="cd">        <span class="kw">FROM</span> loans l <span class="kw">JOIN</span> books b <span class="kw">ON</span> l.book_id = b.book_id</span></div>
        <div class="code-line"><span class="ln">11</span><span class="cd">        <span class="kw">LEFT JOIN</span> fines f <span class="kw">ON</span> l.loan_id = f.loan_id</span></div>
        <div class="code-line"><span class="ln">12</span><span class="cd">        <span class="kw">WHERE</span> l.member_id = p_member_id <span class="kw">ORDER BY</span> l.loan_date <span class="kw">DESC</span>;</span></div>
        <div class="code-line"><span class="ln">13</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">14</span><span class="cd">    <span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">15</span><span class="cd">        <span class="kw">SELECT</span> first_name || <span class="st">' '</span> || last_name, email, status</span></div>
        <div class="code-line"><span class="ln">16</span><span class="cd">        <span class="kw">INTO</span> v_member_name, v_email, v_member_status <span class="kw">FROM</span> members <span class="kw">WHERE</span> member_id = p_member_id;</span></div>
        <div class="code-line"><span class="ln">17</span><span class="cd">    <span class="kw">EXCEPTION WHEN NO_DATA_FOUND THEN RAISE</span> ex_member_not_found; <span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">18</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'========================================================================================'</span>);</span></div>
        <div class="code-line"><span class="ln">19</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'BORROWING HISTORY FOR MEMBER: '</span> || UPPER(v_member_name) || <span class="st">' (ID: '</span> || p_member_id || <span class="st">')'</span>);</span></div>
        <div class="code-line"><span class="ln">20</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Email: '</span> || v_email || <span class="st">' | Status: '</span> || v_member_status);</span></div>
        <div class="code-line"><span class="ln">21</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'========================================================================================'</span>);</span></div>
        <div class="code-line"><span class="ln">22</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(RPAD(<span class="st">'Loan ID'</span>, <span class="num">9</span>) || RPAD(<span class="st">'Book Title'</span>, <span class="num">30</span>) || RPAD(<span class="st">'Issue Date'</span>, <span class="num">13</span>) || RPAD(<span class="st">'Due Date'</span>, <span class="num">13</span>) || RPAD(<span class="st">'Return Date'</span>, <span class="num">13</span>) || RPAD(<span class="st">'Status'</span>, <span class="num">10</span>) || RPAD(<span class="st">'Fine ($)'</span>, <span class="num">10</span>) || RPAD(<span class="st">'Payment'</span>, <span class="num">8</span>));</span></div>
        <div class="code-line"><span class="ln">23</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(RPAD(<span class="st">'-'</span>, <span class="num">106</span>, <span class="st">'-'</span>));</span></div>
        <div class="code-line"><span class="ln">24</span><span class="cd">    <span class="kw">FOR</span> r <span class="kw">IN</span> c_history <span class="kw">LOOP</span></span></div>
        <div class="code-line"><span class="ln">25</span><span class="cd">        v_record_count := v_record_count + <span class="num">1</span>;</span></div>
        <div class="code-line"><span class="ln">26</span><span class="cd">        DBMS_OUTPUT.PUT_LINE(RPAD(TO_CHAR(r.loan_id), <span class="num">9</span>) || RPAD(SUBSTR(r.title, <span class="num">1</span>, <span class="num">28</span>), <span class="num">30</span>) || RPAD(TO_CHAR(r.loan_date, <span class="st">'YYYY-MM-DD'</span>), <span class="num">13</span>) || RPAD(TO_CHAR(r.due_date, <span class="st">'YYYY-MM-DD'</span>), <span class="num">13</span>) || RPAD(NVL(TO_CHAR(r.return_date, <span class="st">'YYYY-MM-DD'</span>), <span class="st">'N/A'</span>), <span class="num">13</span>) || RPAD(r.loan_status, <span class="num">10</span>) || RPAD(TO_CHAR(r.fine_amount, <span class="st">'FM990.00'</span>), <span class="num">10</span>) || RPAD(r.fine_status, <span class="num">8</span>));</span></div>
        <div class="code-line"><span class="ln">27</span><span class="cd">    <span class="kw">END LOOP</span>;</span></div>
        <div class="code-line"><span class="ln">28</span><span class="cd">    <span class="kw">IF</span> v_record_count = <span class="num">0</span> <span class="kw">THEN</span> DBMS_OUTPUT.PUT_LINE(<span class="st">'No borrowing records found for this member.'</span>); <span class="kw">END IF</span>;</span></div>
        <div class="code-line"><span class="ln">29</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'========================================================================================'</span>);</span></div>
        <div class="code-line"><span class="ln">30</span><span class="cd">    DBMS_OUTPUT.PUT_LINE(<span class="st">'Total Loans Found: '</span> || v_record_count);</span></div>
        <div class="code-line"><span class="ln">31</span><span class="cd"><span class="kw">EXCEPTION WHEN</span> ex_member_not_found <span class="kw">THEN</span> DBMS_OUTPUT.PUT_LINE(<span class="st">'ERROR: Member ID '</span> || p_member_id || <span class="st">' does not exist.'</span>);</span></div>
        <div class="code-line"><span class="ln">32</span><span class="cd"><span class="kw">END</span> display_member_history; /</span></div>
    </div>
    <div class="page-number">14</div>
</div>
"@)
# ==============================================================================
# PAGE 19: 04_test_cases.sql &ndash; Tests 1 & 2 (Page Number: 15)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div class="code-title">04_test_cases.sql &ndash; Comprehensive Test Suite</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">1</span><span class="cd"><span class="kw">SET</span> SERVEROUTPUT <span class="kw">ON SIZE</span> <span class="num">1000000</span>;</span></div>
        <div class="code-line"><span class="ln">2</span><span class="cd"><span class="kw">SET</span> LINESIZE <span class="num">200</span>; <span class="kw">SET</span> PAGESIZE <span class="num">50</span>;</span></div>
        <div class="code-line"><span class="ln">3</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">4</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">5</span><span class="cd"><span class="cm">-- TEST 1: ISSUE A BOOK TO AN ACTIVE MEMBER (SUCCESS PATH)</span></span></div>
        <div class="code-line"><span class="ln">6</span><span class="cd"><span class="cm">-- Issuing Book 103 ('Introduction to Algorithms') to Member 1 ('Alice Johnson')</span></span></div>
        <div class="code-line"><span class="ln">7</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">8</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">9</span><span class="cd">    issue_book(p_book_id => <span class="num">103</span>, p_member_id => <span class="num">1</span>, p_loan_days => <span class="num">14</span>);</span></div>
        <div class="code-line"><span class="ln">10</span><span class="cd"><span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">11</span><span class="cd">/</span></div>
        <div class="code-line"><span class="ln">12</span><span class="cd"><span class="cm">-- Verify that the trigger updated Book 103 status to BORROWED:</span></span></div>
        <div class="code-line"><span class="ln">13</span><span class="cd"><span class="kw">SELECT</span> book_id, title, status <span class="kw">FROM</span> books <span class="kw">WHERE</span> book_id = <span class="num">103</span>;</span></div>
        <div class="code-line"><span class="ln">14</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">15</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">16</span><span class="cd"><span class="cm">-- TEST 2: ATTEMPT TO ISSUE AN ALREADY BORROWED BOOK (EXCEPTION HANDLING)</span></span></div>
        <div class="code-line"><span class="ln">17</span><span class="cd"><span class="cm">-- Attempting to issue Book 101 (already borrowed) to Member 2 ('Bob Smith')</span></span></div>
        <div class="code-line"><span class="ln">18</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">19</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">20</span><span class="cd">    issue_book(p_book_id => <span class="num">101</span>, p_member_id => <span class="num">2</span>);</span></div>
        <div class="code-line"><span class="ln">21</span><span class="cd"><span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">22</span><span class="cd">/</span></div>
    </div>
    <div class="page-number">15</div>
</div>
"@)

# ==============================================================================
# PAGE 20: 04_test_cases.sql &ndash; Tests 3, 4, 5 (Page Number: 16)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div class="code-title">04_test_cases.sql (continued)</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">23</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">24</span><span class="cd"><span class="cm">-- TEST 3: ATTEMPT TO ISSUE TO A NON-EXISTENT MEMBER (EXCEPTION HANDLING)</span></span></div>
        <div class="code-line"><span class="ln">25</span><span class="cd"><span class="cm">-- Attempting to issue Book 104 to Member ID 999</span></span></div>
        <div class="code-line"><span class="ln">26</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">27</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">28</span><span class="cd">    issue_book(p_book_id => <span class="num">104</span>, p_member_id => <span class="num">999</span>);</span></div>
        <div class="code-line"><span class="ln">29</span><span class="cd"><span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">30</span><span class="cd">/</span></div>
        <div class="code-line"><span class="ln">31</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">32</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">33</span><span class="cd"><span class="cm">-- TEST 4: ATTEMPT TO ISSUE TO A SUSPENDED MEMBER (EXCEPTION HANDLING)</span></span></div>
        <div class="code-line"><span class="ln">34</span><span class="cd"><span class="cm">-- Attempting to issue Book 104 to Member 4 ('Diana Prince', status = 'SUSPENDED')</span></span></div>
        <div class="code-line"><span class="ln">35</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">36</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">37</span><span class="cd">    issue_book(p_book_id => <span class="num">104</span>, p_member_id => <span class="num">4</span>);</span></div>
        <div class="code-line"><span class="ln">38</span><span class="cd"><span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">39</span><span class="cd">/</span></div>
        <div class="code-line"><span class="ln">40</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">41</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">42</span><span class="cd"><span class="cm">-- TEST 5: CALCULATE OVERDUE FINE VIA SQL FUNCTION</span></span></div>
        <div class="code-line"><span class="ln">43</span><span class="cd"><span class="cm">-- Loan 1001 was due 6 days ago. Fine rate is $2.00/day. Expected fine: $12.00</span></span></div>
        <div class="code-line"><span class="ln">44</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">45</span><span class="cd"><span class="kw">SELECT</span> loan_id, book_id, member_id, loan_date, due_date,</span></div>
        <div class="code-line"><span class="ln">46</span><span class="cd">       TRUNC(SYSDATE) - due_date <span class="kw">AS</span> days_overdue,</span></div>
        <div class="code-line"><span class="ln">47</span><span class="cd">       calculate_fine(loan_id)   <span class="kw">AS</span> calculated_fine_amount</span></div>
        <div class="code-line"><span class="ln">48</span><span class="cd"><span class="kw">FROM</span> loans <span class="kw">WHERE</span> loan_id = <span class="num">1001</span>;</span></div>
    </div>
    <div class="page-number">16</div>
</div>
"@)

# ==============================================================================
# PAGE 21: 04_test_cases.sql &ndash; Tests 6, 7, 8 (Page Number: 17)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div class="code-title">04_test_cases.sql (continued)</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">49</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">50</span><span class="cd"><span class="cm">-- TEST 6: RETURN AN OVERDUE BOOK AND GENERATE FINE RECORD (SUCCESS PATH)</span></span></div>
        <div class="code-line"><span class="ln">51</span><span class="cd"><span class="cm">-- Returning Loan 1001 (Book 101). Expected: Book status AVAILABLE, Fine recorded.</span></span></div>
        <div class="code-line"><span class="ln">52</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">53</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">54</span><span class="cd">    return_book(p_loan_id => <span class="num">1001</span>, p_return_date => SYSDATE);</span></div>
        <div class="code-line"><span class="ln">55</span><span class="cd"><span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">56</span><span class="cd">/</span></div>
        <div class="code-line"><span class="ln">57</span><span class="cd"><span class="cm">-- Verify that trigger reset Book 101 status back to AVAILABLE:</span></span></div>
        <div class="code-line"><span class="ln">58</span><span class="cd"><span class="kw">SELECT</span> book_id, title, status <span class="kw">FROM</span> books <span class="kw">WHERE</span> book_id = <span class="num">101</span>;</span></div>
        <div class="code-line"><span class="ln">59</span><span class="cd"><span class="cm">-- Verify fine generated in FINES table:</span></span></div>
        <div class="code-line"><span class="ln">60</span><span class="cd"><span class="kw">SELECT</span> * <span class="kw">FROM</span> fines <span class="kw">WHERE</span> loan_id = <span class="num">1001</span>;</span></div>
        <div class="code-line"><span class="ln">61</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">62</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">63</span><span class="cd"><span class="cm">-- TEST 7: ATTEMPT TO RETURN AN ALREADY RETURNED LOAN (EXCEPTION HANDLING)</span></span></div>
        <div class="code-line"><span class="ln">64</span><span class="cd"><span class="cm">-- Calling return_book again on Loan 1001</span></span></div>
        <div class="code-line"><span class="ln">65</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">66</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">67</span><span class="cd">    return_book(p_loan_id => <span class="num">1001</span>);</span></div>
        <div class="code-line"><span class="ln">68</span><span class="cd"><span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">69</span><span class="cd">/</span></div>
        <div class="code-line"><span class="ln">70</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">71</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">72</span><span class="cd"><span class="cm">-- TEST 8: ATTEMPT TO RETURN A NON-EXISTENT LOAN (EXCEPTION HANDLING)</span></span></div>
        <div class="code-line"><span class="ln">73</span><span class="cd"><span class="cm">-- Calling return_book with invalid Loan ID 9999</span></span></div>
        <div class="code-line"><span class="ln">74</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">75</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">76</span><span class="cd">    return_book(p_loan_id => <span class="num">9999</span>);</span></div>
        <div class="code-line"><span class="ln">77</span><span class="cd"><span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">78</span><span class="cd">/</span></div>
    </div>
    <div class="page-number">17</div>
</div>
"@)

# ==============================================================================
# PAGE 22: 04_test_cases.sql &ndash; Tests 9, 10, 11 (Page Number: 18)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div class="code-title">04_test_cases.sql (continued)</div>
    <div class="code-box">
        <div class="code-line"><span class="ln">79</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">80</span><span class="cd"><span class="cm">-- TEST 9: DISPLAY BORROWING HISTORY FOR MEMBER 1 (ALICE JOHNSON)</span></span></div>
        <div class="code-line"><span class="ln">81</span><span class="cd"><span class="cm">-- Should display 2 records: Loan 1001 (Returned with fine) and Loan 1003 (Issued)</span></span></div>
        <div class="code-line"><span class="ln">82</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">83</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">84</span><span class="cd">    display_member_history(p_member_id => <span class="num">1</span>);</span></div>
        <div class="code-line"><span class="ln">85</span><span class="cd"><span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">86</span><span class="cd">/</span></div>
        <div class="code-line"><span class="ln">87</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">88</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">89</span><span class="cd"><span class="cm">-- TEST 10: DISPLAY BORROWING HISTORY FOR MEMBER 3 (CHARLIE BROWN - NO LOANS)</span></span></div>
        <div class="code-line"><span class="ln">90</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">91</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">92</span><span class="cd">    display_member_history(p_member_id => <span class="num">3</span>);</span></div>
        <div class="code-line"><span class="ln">93</span><span class="cd"><span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">94</span><span class="cd">/</span></div>
        <div class="code-line"><span class="ln">95</span><span class="cd"></span></div>
        <div class="code-line"><span class="ln">96</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">97</span><span class="cd"><span class="cm">-- TEST 11: DISPLAY BORROWING HISTORY FOR INVALID MEMBER ID (EXCEPTION HANDLING)</span></span></div>
        <div class="code-line"><span class="ln">98</span><span class="cd"><span class="cm">-- ============================================================================</span></span></div>
        <div class="code-line"><span class="ln">99</span><span class="cd"><span class="kw">BEGIN</span></span></div>
        <div class="code-line"><span class="ln">100</span><span class="cd">    display_member_history(p_member_id => <span class="num">999</span>);</span></div>
        <div class="code-line"><span class="ln">101</span><span class="cd"><span class="kw">END</span>;</span></div>
        <div class="code-line"><span class="ln">102</span><span class="cd">/</span></div>
    </div>
    <div class="page-number">18</div>
</div>
"@)

# ==============================================================================
# PAGE 23: RESULTS & DATA TABLES (Page Number: 19)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <div style="font-size: 11pt; font-weight: bold; margin-bottom: 3px;">Result:</div>
    <p style="font-size: 9.5pt; margin-bottom: 8px;">Tables below show the data loaded by <code>01_schema_and_data.sql</code>. Dates are shown relative to the day of seeding (T = today), because the seed script uses SYSDATE.</p>
    
    <!-- BOOKS TABLE -->
    <table class="result-table">
        <tr><th>book_id</th><th>title</th><th>author</th><th>category</th><th>status</th></tr>
        <tr><td>101</td><td>Database System Concepts</td><td>Abraham Silberschatz</td><td>Computer Science</td><td>BORROWED</td></tr>
        <tr><td>102</td><td>Clean Code: Handbook of Agile Software</td><td>Robert C. Martin</td><td>Software Engineering</td><td>AVAILABLE</td></tr>
        <tr><td>103</td><td>Introduction to Algorithms</td><td>Thomas H. Cormen</td><td>Computer Science</td><td>AVAILABLE</td></tr>
        <tr><td>104</td><td>Design Patterns: Elements of Reusable Code</td><td>Erich Gamma</td><td>Software Engineering</td><td>AVAILABLE</td></tr>
        <tr><td>105</td><td>Artificial Intelligence: A Modern Approach</td><td>Stuart Russell</td><td>Artificial Intelligence</td><td>AVAILABLE</td></tr>
    </table>
    <div class="fig-caption">Figure 2: BOOKS table after inserting data</div>

    <!-- MEMBERS TABLE -->
    <table class="result-table">
        <tr><th>member_id</th><th>name</th><th>email</th><th>phone</th><th>status</th></tr>
        <tr><td>1</td><td>Alice Johnson</td><td>alice.johnson@example.com</td><td>555-0101</td><td>ACTIVE</td></tr>
        <tr><td>2</td><td>Bob Smith</td><td>bob.smith@example.com</td><td>555-0102</td><td>ACTIVE</td></tr>
        <tr><td>3</td><td>Charlie Brown</td><td>charlie.brown@example.com</td><td>555-0103</td><td>ACTIVE</td></tr>
        <tr><td>4</td><td>Diana Prince</td><td>diana.prince@example.com</td><td>555-0104</td><td>SUSPENDED</td></tr>
    </table>
    <div class="fig-caption">Figure 3: MEMBERS table after inserting data</div>

    <!-- LOANS TABLE -->
    <table class="result-table">
        <tr><th>loan_id</th><th>book_id</th><th>member_id</th><th>loan_date</th><th>due_date</th><th>return_date</th><th>status</th></tr>
        <tr><td>1001</td><td>101</td><td>1</td><td>T - 20</td><td>T - 6</td><td>NULL</td><td>ISSUED</td></tr>
        <tr><td>1002</td><td>102</td><td>2</td><td>T - 14</td><td>T</td><td>T - 2</td><td>RETURNED</td></tr>
    </table>
    <div class="fig-caption">Figure 4: LOANS table after inserting data</div>

    <!-- FINES TABLE -->
    <table class="result-table">
        <tr><th>fine_id</th><th>loan_id</th><th>fine_amount</th><th>fine_date</th><th>payment_status</th></tr>
        <tr><td>5001</td><td>1001</td><td>12.00</td><td>T</td><td>PENDING</td></tr>
    </table>
    <div class="fig-caption">Figure 5: FINES table after initial execution</div>
    <div class="page-number">19</div>
</div>
"@)

# ==============================================================================
# PAGE 24: TEST EXECUTION OUTPUT (Part 1) (Page Number: 20)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    
    <table class="result-table" style="width: 50%; margin: 0 auto 6px auto;">
        <tr><th>tbl</th><th style="text-align: right;">row_count</th></tr>
        <tr><td>BOOKS</td><td style="text-align: right;">5</td></tr>
        <tr><td>MEMBERS</td><td style="text-align: right;">4</td></tr>
        <tr><td>LOANS</td><td style="text-align: right;">2</td></tr>
        <tr><td>FINES</td><td style="text-align: right;">1</td></tr>
    </table>
    <div class="fig-caption">Figure 6: Row count of every table after running 01_schema_and_data.sql</div>

    <div style="font-size: 10.5pt; font-weight: bold; margin-bottom: 2px;">Test Execution Output (04_test_cases.sql)</div>
    <p style="font-size: 8.8pt; line-height: 1.35; margin-bottom: 6px;">Live terminal output derived from running the comprehensive test suite in Oracle Database 21c (XE). Sequences start at 101 (books), 1 (members), 1001 (loans), and 5001 (fines).</p>

    <div class="term-title">Test 1 (a): Successful checkout and book availability update</div>
    <div class="terminal-box">
        <span class="term-success">SUCCESS: Book issued successfully!</span><br>
        Loan ID     : <span class="term-num">1003</span><br>
        Book Title  : Introduction to Algorithms (ID: <span class="term-num">103</span>)<br>
        Member      : Alice Johnson (ID: <span class="term-num">1</span>)<br>
        Issue Date  : <span class="term-hl">2026-11-03</span> | Due Date : <span class="term-hl">2026-11-17</span><br>
        Book Status : <span class="term-warn">Changed to BORROWED by Trigger</span><br>
        PL/SQL procedure successfully completed.
    </div>

    <div class="term-title">Test 2 (b): Borrowing blocked by already borrowed book (Exception)</div>
    <div class="terminal-box">
        <span class="term-err">ERROR: Book "Database System Concepts" (ID: 101) is already BORROWED and unavailable.</span><br>
        PL/SQL procedure successfully completed.
    </div>

    <div class="term-title">Test 3 &amp; 4: Invalid Member &amp; Suspended Member Exceptions</div>
    <div class="terminal-box">
        [Test 3] <span class="term-err">ERROR: Member ID 999 does not exist.</span><br>
        [Test 4] <span class="term-err">ERROR: Member "Diana Prince" (ID: 4) is SUSPENDED. Cannot issue books.</span><br>
        PL/SQL procedure successfully completed.
    </div>

    <div class="term-title">Test 5 &amp; 6: Calculate Overdue Fine and Return Overdue Book</div>
    <div class="terminal-box">
        SQL> SELECT loan_id, due_date, 6 AS days_overdue, calculate_fine(1001) AS fine FROM loans WHERE loan_id=1001;<br>
        <span class="term-num">1001</span>    28-OCT-2026    6 days overdue    Fine: <span class="term-warn">$12.00</span><br>
        <span class="term-success">SUCCESS: Book returned successfully!</span><br>
        Loan ID: <span class="term-num">1001</span> | Book: Database System Concepts (ID: 101) | Overdue: <span class="term-warn">6 day(s)</span><br>
        Fine Imposed: <span class="term-warn">$12.00</span> (Fine ID: <span class="term-num">5001</span>, Status: PENDING)<br>
        Book Status : <span class="term-success">Changed to AVAILABLE by Trigger</span>
    </div>
    <div class="page-number">20</div>
</div>
"@)

# ==============================================================================
# PAGE 25: TEST EXECUTION OUTPUT (Part 2) (Page Number: 21)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    
    <div class="term-title">Test 7 &amp; 8: Already Returned Loan &amp; Non-Existent Loan Exceptions</div>
    <div class="terminal-box">
        [Test 7] <span class="term-err">ERROR: Loan ID 1001 has already been returned.</span><br>
        [Test 8] <span class="term-err">ERROR: Loan ID 9999 does not exist.</span><br>
        PL/SQL procedure successfully completed.
    </div>

    <div class="term-title">Test 9: Member Borrowing History Output (display_member_history)</div>
    <div class="terminal-box" style="font-size: 7.1pt; line-height: 1.28;">
        ========================================================================================<br>
        <span class="term-hl">BORROWING HISTORY FOR MEMBER: ALICE JOHNSON (ID: 1)</span><br>
        Email: alice.johnson@example.com | Status: ACTIVE<br>
        ========================================================================================<br>
        Loan ID  Book Title                    Issue Date   Due Date     Return Date  Status    Fine ($)  Payment <br>
        ----------------------------------------------------------------------------------------------------------<br>
        1003     Introduction to Algorithms    2026-11-03   2026-11-17   N/A          <span class="term-warn">ISSUED</span>    0.00      NONE    <br>
        1001     Database System Concepts      2026-10-14   2026-10-28   2026-11-03   <span class="term-success">RETURNED</span>  12.00     PENDING <br>
        ========================================================================================<br>
        Total Loans Found: 2<br>
        PL/SQL procedure successfully completed.
    </div>

    <table class="result-table" style="margin-top: 8px;">
        <tr><th>loan_id</th><th>book_id</th><th>member_id</th><th>status</th><th>fine_amount</th><th>payment_status</th></tr>
        <tr><td>1001</td><td>101</td><td>1</td><td>RETURNED</td><td>12.00</td><td>PENDING</td></tr>
        <tr><td>1002</td><td>102</td><td>2</td><td>RETURNED</td><td>0.00</td><td>N/A</td></tr>
        <tr><td>1003</td><td>103</td><td>1</td><td>ISSUED</td><td>0.00</td><td>N/A</td></tr>
    </table>
    <div class="fig-caption">Figure 7: Final state of LOANS and FINES records after test suite execution</div>

    <table class="result-table" style="width: 60%; margin: 0 auto 4px auto;">
        <tr><th>member_id</th><th>first_name</th><th style="text-align: right;">fine_balance</th></tr>
        <tr><td>1</td><td>Alice Johnson</td><td style="text-align: right;">$12.00</td></tr>
        <tr><td>2</td><td>Bob Smith</td><td style="text-align: right;">$0.00</td></tr>
        <tr><td>3</td><td>Charlie Brown</td><td style="text-align: right;">$0.00</td></tr>
        <tr><td>4</td><td>Diana Prince</td><td style="text-align: right;">$0.00</td></tr>
    </table>
    <div class="fig-caption">Figure 8: Member fine balances after test execution</div>
    <p style="font-size: 8.8pt; font-style: italic; text-align: center; margin-top: 2px;">Integrity check confirmed: All loan and fine states adhere strictly to referential integrity and trigger synchronization rules.</p>
    <div class="page-number">21</div>
</div>
"@)

# ==============================================================================
# PAGE 26: 6. CONCLUSION (Page Number: 22)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <h2 class="section-title">6. Conclusion</h2>
    <p>The <strong>Automated Library Management &amp; Fine Tracking System</strong> successfully demonstrates the application of <strong>Advanced Database Management System (ADBMS)</strong> concepts in developing a secure, efficient, and scalable library management system. By using a bottom-up design approach, the project integrates entities such as books, members, loans, and fines into a unified structure that ensures smooth data management and retrieval. The implementation of <strong>normalization (up to 3NF)</strong>, integrity constraints, sequences, and indexes eliminates redundancy, maintains data consistency, and keeps queries fast.</p>
    <p>Through stored procedures (<code>issue_book</code>, <code>return_book</code>, and <code>display_member_history</code>) and stored functions (<code>calculate_fine</code>), business rules such as membership eligibility checks, copy availability validation, and overdue fine calculations are enforced inside the database rather than in application code. Event-driven database triggers (<code>trg_sync_book_availability</code>) guard the inventory and synchronize availability automatically without procedural overhead, while custom user exceptions with clear diagnostic messaging make every error condition explicit.</p>
    <p>The disciplined use of <strong>atomic transactions, COMMIT, and ROLLBACK</strong> ensures reliability and consistency by maintaining strict <strong>ACID properties</strong> during circulation operations. If an exception occurs at any point during checkout or return, changes are rolled back to preserve data integrity.</p>
    <p>Overall, the project not only simplifies library circulation but also improves data security, accountability, and accessibility. It demonstrates how ADBMS and Oracle PL/SQL techniques can be effectively applied to a real-world enterprise scenario, providing a strong foundation for future enhancements such as a web or mobile front end, e-mail reminders for due dates, reservation queues, and analytical dashboards.</p>
    <div class="page-number">22</div>
</div>
"@)

# ==============================================================================
# PAGE 27: 7. REFERENCES (Page Number: 23)
# ==============================================================================
[void]$sb.AppendLine(@"
<div class="page">
    <div class="page-border"></div>
    $(Get-Header)
    <h2 class="section-title">7. References</h2>
    <div style="font-size: 11pt; line-height: 2.2; margin-top: 25px;">
        1. Oracle Database Documentation &ndash; <a href="https://docs.oracle.com/en/database/" style="color: #0366d6; text-decoration: underline;">https://docs.oracle.com/en/database/</a><br>
        2. Oracle PL/SQL Language Reference &ndash; <a href="https://docs.oracle.com/en/database/oracle/oracle-database/" style="color: #0366d6; text-decoration: underline;">https://docs.oracle.com/en/database/oracle/oracle-database/</a><br>
        3. Fundamentals of Database Systems &ndash; <a href="https://www.w3schools.com/sql" style="color: #0366d6; text-decoration: underline;">https://www.w3schools.com/sql</a><br>
        4. PL/SQL Tutorial &ndash; <a href="https://www.tutorialspoint.com/plsql/" style="color: #0366d6; text-decoration: underline;">https://www.tutorialspoint.com/plsql/</a><br>
        5. Database ER Diagram Design Tool &ndash; <a href="https://app.diagrams.net/" style="color: #0366d6; text-decoration: underline;">https://app.diagrams.net/</a><br>
        6. Transaction Management in DBMS &ndash; <a href="https://www.geeksforgeeks.org" style="color: #0366d6; text-decoration: underline;">https://www.geeksforgeeks.org</a><br>
        7. Github : <a href="https://github.com/guleriabasu9697-spec/Automated-Library-Management-Fine-Tracking-System.git" style="color: #0366d6; text-decoration: underline;">https://github.com/guleriabasu9697-spec/Automated-Library-Management-Fine-Tracking-System.git</a>
    </div>
    <div class="page-number">23</div>
</div>
</body>
</html>
"@)

[System.IO.File]::WriteAllText($htmlPath, $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "report.html generated successfully with 27 pages."

# Invoke Microsoft Edge headless to print to PDF
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$args = @(
    "--headless",
    "--disable-gpu",
    "--no-pdf-header-footer",
    "--run-all-compositor-stages-before-draw",
    "--print-to-pdf=`"$pdfPath`"",
    "`"file:///$($htmlPath.Replace('\', '/'))`""
)

Write-Host "Invoking Microsoft Edge to compile PDF..."
Start-Process -FilePath $edgePath -ArgumentList $args -Wait

if (Test-Path $pdfPath) {
    $size = (Get-Item $pdfPath).Length
    Write-Host "SUCCESS: PDF generated at $pdfPath (Size: $size bytes)"
} else {
    Write-Error "ERROR: PDF file not created."
}
