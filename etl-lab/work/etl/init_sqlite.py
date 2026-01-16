import os
import sqlite3

SQLITE_PATH = os.environ.get("SQLITE_PATH", "/shared/sqlite/etl.db")

def main():
    os.makedirs(os.path.dirname(SQLITE_PATH), exist_ok=True)
    con = sqlite3.connect(SQLITE_PATH)
    con.execute("""
    CREATE TABLE IF NOT EXISTS mineral_prices (
      date TEXT NOT NULL,
      mineral_code TEXT NOT NULL,
      price_usd REAL NOT NULL,
      fx_usd_mru REAL NOT NULL,
      price_mru REAL NOT NULL,
      source_url TEXT NOT NULL,
      source_ts TEXT NOT NULL,
      PRIMARY KEY (date, mineral_code)
    );
    """)
    con.commit()
    con.close()
    print(f"SQLite initialized at {SQLITE_PATH}")

if __name__ == "__main__":
    main()
