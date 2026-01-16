import os, json, re
from datetime import datetime, timezone, date
from bs4 import BeautifulSoup

RUN_DIR = os.environ.get("RUN_DIR", "/tmp")

def parse_number_loose(text: str) -> float:
    """
    Extract the first plausible number, supporting formats like:
    $4,340  |  106.05 USD/T  |  3.91
    """
    m = re.search(r"(\d[\d,]*\.?\d*)", text)
    if not m:
        raise ValueError("No numeric value found in text fragment.")
    return float(m.group(1).replace(",", ""))

def extract_price_from_tradingeconomics(html: str) -> float:
    """
    TradingEconomics pages change over time. For teaching, we use a layered approach:
    - text scan on the full page
    - reduced noise by parsing visible text
    """
    soup = BeautifulSoup(html, "lxml")
    text = " ".join(soup.stripped_strings)

    # Common patterns students already used in the TD (robust-ish)
    patterns = [
        r"\$\s?\d[\d,]*\.?\d*",          # $4,340
        r"\d[\d,]*\.?\d*\s?USD/T",       # 106.05 USD/T
        r"\d[\d,]*\.?\d*\s?USD",         # 3.91 USD
        r"\d[\d,]*\.?\d*",               # fallback: first number
    ]

    for pat in patterns:
        m = re.search(pat, text)
        if m:
            return parse_number_loose(m.group(0))

    # last resort: try page text again
    return parse_number_loose(text)

def main():
    raw_path = os.path.join(RUN_DIR, "raw.json")
    with open(raw_path, "r", encoding="utf-8") as f:
        raw = json.load(f)

    fx = raw["fx"]["json"]
    fx_usd_mru = float(fx["rates"]["MRU"])
    today = date.today().isoformat()
    ts = raw["source_ts"]

    gold_usd   = extract_price_from_tradingeconomics(raw["gold"]["html"])
    iron_usd   = extract_price_from_tradingeconomics(raw["iron"]["html"])
    copper_usd = extract_price_from_tradingeconomics(raw["copper"]["html"])

    clean = {
        "date": today,
        "source_ts": ts,
        "fx_usd_mru": fx_usd_mru,
        "rows": [
            {"mineral_code":"GOLD",   "price_usd": gold_usd,   "price_mru": gold_usd * fx_usd_mru,   "source_url": raw["gold"]["url"]},
            {"mineral_code":"IRON",   "price_usd": iron_usd,   "price_mru": iron_usd * fx_usd_mru,   "source_url": raw["iron"]["url"]},
            {"mineral_code":"COPPER", "price_usd": copper_usd, "price_mru": copper_usd * fx_usd_mru, "source_url": raw["copper"]["url"]},
        ]
    }

    out_path = os.path.join(RUN_DIR, "clean.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(clean, f)
    print(f"Wrote transformed dataset to {out_path}")

if __name__ == "__main__":
    main()
