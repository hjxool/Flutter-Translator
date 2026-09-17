import csv
import sqlite3
import time
import os

def build_sqlite(csv_path="ecdict.csv", db_path="ecdict.db"):
    current_dir = os.path.dirname(os.path.abspath(__file__))
    full_csv = os.path.join(current_dir, csv_path)
    full_db = os.path.join(current_dir, db_path)

    print(f"Reading from {full_csv}...")
    start = time.time()

    conn = sqlite3.connect(full_db)
    cur = conn.cursor()

    cur.execute("PRAGMA synchronous = OFF;")
    cur.execute("PRAGMA journal_mode = MEMORY;")

    cur.execute("""
    CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL COLLATE NOCASE,
        phonetic TEXT,
        definition TEXT,
        translation TEXT,
        pos TEXT,
        collins INTEGER,
        oxford INTEGER,
        tag TEXT,
        bnc INTEGER,
        frq INTEGER,
        exchange TEXT,
        detail TEXT,
        audio TEXT
    );
    """)

    with open(full_csv, "r", encoding="utf-8", errors="replace") as f:
        reader = csv.reader(f)
        header = next(reader)
        batch = []
        total = 0
        for row in reader:
            if len(row) < 13:
                row += [""] * (13 - len(row))
            elif len(row) > 13:
                row = row[:13]
            batch.append(row)
            if len(batch) >= 10000:
                cur.executemany("""
                    INSERT INTO words (word, phonetic, definition, translation, pos, collins, oxford, tag, bnc, frq, exchange, detail, audio)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, batch)
                total += len(batch)
                batch = []
        if batch:
            cur.executemany("""
                INSERT INTO words (word, phonetic, definition, translation, pos, collins, oxford, tag, bnc, frq, exchange, detail, audio)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, batch)
            total += len(batch)

    print(f"Inserted {total} rows. Creating index on 'word'...")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_words_word ON words(word COLLATE NOCASE);")
    conn.commit()
    conn.close()
    print(f"Finished building {full_db} in {time.time() - start:.2f}s")

if __name__ == "__main__":
    build_sqlite()
