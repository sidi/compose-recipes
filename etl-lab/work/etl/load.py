import os, json, sqlite3

RUN_DIR = os.environ.get("RUN_DIR", "/tmp")
SQLITE_PATH = os.environ.get("SQLITE_PATH", "/shared/sqlite/etl.db")

def main():
    clean_path = os.path.join(RUN_DIR, "clean.json")
    with open(clean_path, "r", encoding="utf-8") as f:
        clean = json.load(f)

    os.makedirs(os.path.dirname(SQLITE_PATH), exist_ok=True)
    con = sqlite3.connect(SQLITE_PATH)
    con.execute("PRAGMA journal_mode=WAL;")

    for row in clean["rows"]:
        con.execute("""
          INSERT INTO mineral_prices(date, mineral_code, price_usd, fx_usd_mru, price_mru, source_url, source_ts)
          VALUES(?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(date, mineral_code) DO UPDATE SET
            price_usd=excluded.price_usd,
            fx_usd_mru=excluded.fx_usd_mru,
            price_mru=excluded.price_mru,
            source_url=excluded.source_url,
            source_ts=excluded.source_ts;
        """, (clean["date"], row["mineral_code"], row["price_usd"], clean["fx_usd_mru"], row["price_mru"], row["source_url"], clean["source_ts"]))

    con.commit()
    con.close()
    print(f"Loaded {len(clean['rows'])} rows into SQLite: {SQLITE_PATH}")

if __name__ == "__main__":
    main()
