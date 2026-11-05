"""
Optional Backend REST API for Oracle Database Integration
Uses `oracledb` (official Oracle Python driver) and Flask to connect
the frontend directly to your real Oracle Database instance.

Installation:
    pip install flask flask-cors oracledb

Usage:
    python server.py
"""

import os
from flask import Flask, request, jsonify
from flask_cors import CORS

try:
    import oracledb
except ImportError:
    oracledb = None

app = Flask(__name__)
CORS(app)

# Database Connection Config (Adjust to match your Oracle setup)
DB_CONFIG = {
    "user": os.environ.get("DB_USER", "system"),
    "password": os.environ.get("DB_PASSWORD", "oracle"),
    "dsn": os.environ.get("DB_DSN", "localhost:1521/XE")
}

def get_connection():
    if not oracledb:
        raise RuntimeError("oracledb package not installed. Run: pip install oracledb")
    return oracledb.connect(
        user=DB_CONFIG["user"],
        password=DB_CONFIG["password"],
        dsn=DB_CONFIG["dsn"]
    )

@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "running", "engine": "Oracle PL/SQL REST Backend"})

@app.route("/api/books", methods=["GET"])
def get_books():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT book_id, title, author, category, status FROM books ORDER BY book_id")
    rows = cursor.fetchall()
    books = [
        {"book_id": r[0], "title": r[1], "author": r[2], "category": r[3], "status": r[4]}
        for r in rows
    ]
    cursor.close()
    conn.close()
    return jsonify(books)

@app.route("/api/members", methods=["GET"])
def get_members():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT member_id, first_name, last_name, email, phone, TO_CHAR(join_date, 'YYYY-MM-DD'), status FROM members ORDER BY member_id")
    rows = cursor.fetchall()
    members = [
        {"member_id": r[0], "first_name": r[1], "last_name": r[2], "email": r[3], "phone": r[4], "join_date": r[5], "status": r[6]}
        for r in rows
    ]
    cursor.close()
    conn.close()
    return jsonify(members)

@app.route("/api/loans/issue", methods=["POST"])
def issue_book():
    data = request.json or {}
    book_id = data.get("book_id")
    member_id = data.get("member_id")
    loan_days = data.get("loan_days", 14)

    conn = get_connection()
    cursor = conn.cursor()
    try:
        # Call the PL/SQL stored procedure
        cursor.callproc("issue_book", [book_id, member_id, loan_days])
        conn.commit()
        return jsonify({"success": True, "message": "Book issued successfully!"})
    except Exception as e:
        conn.rollback()
        return jsonify({"success": False, "error": str(e)}), 400
    finally:
        cursor.close()
        conn.close()

@app.route("/api/loans/return", methods=["POST"])
def return_book():
    data = request.json or {}
    loan_id = data.get("loan_id")
    return_date = data.get("return_date") # optional YYYY-MM-DD

    conn = get_connection()
    cursor = conn.cursor()
    try:
        if return_date:
            cursor.execute("BEGIN return_book(:1, TO_DATE(:2, 'YYYY-MM-DD')); END;", [loan_id, return_date])
        else:
            cursor.execute("BEGIN return_book(:1); END;", [loan_id])
        conn.commit()
        return jsonify({"success": True, "message": "Book returned successfully!"})
    except Exception as e:
        conn.rollback()
        return jsonify({"success": False, "error": str(e)}), 400
    finally:
        cursor.close()
        conn.close()

@app.route("/api/members/<int:member_id>/history", methods=["GET"])
def member_history(member_id):
    conn = get_connection()
    cursor = conn.cursor()
    query = """
        SELECT l.loan_id, b.title, TO_CHAR(l.loan_date, 'YYYY-MM-DD'),
               TO_CHAR(l.due_date, 'YYYY-MM-DD'), NVL(TO_CHAR(l.return_date, 'YYYY-MM-DD'), 'N/A'),
               l.status, NVL(f.fine_amount, 0), NVL(f.payment_status, 'NONE')
        FROM loans l
        JOIN books b ON l.book_id = b.book_id
        LEFT JOIN fines f ON l.loan_id = f.loan_id
        WHERE l.member_id = :member_id
        ORDER BY l.loan_date DESC, l.loan_id DESC
    """
    cursor.execute(query, [member_id])
    rows = cursor.fetchall()
    history = [
        {
            "loan_id": r[0], "title": r[1], "loan_date": r[2], "due_date": r[3],
            "return_date": r[4], "loan_status": r[5], "fine_amount": float(r[6]),
            "fine_status": r[7]
        }
        for r in rows
    ]
    cursor.close()
    conn.close()
    return jsonify(history)

if __name__ == "__main__":
    print("Starting Oracle PL/SQL REST API on http://localhost:5000 ...")
    app.run(host="0.0.0.0", port=5000, debug=True)

