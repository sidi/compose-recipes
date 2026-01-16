import os, json
from datetime import datetime, timezone
import requests

GOLD_URL = os.environ.get("GOLD_URL", "https://tradingeconomics.com/commodity/gold")
IRON_URL = os.environ.get("IRON_URL", "https://tradingeconomics.com/commodity/iron-ore")
COPPER_URL = os.environ.get("COPPER_URL", "https://tradingeconomics.com/commodity/copper")
FX_URL = os.environ.get("FX_URL", "https://api.exchangerate-api.com/v4/latest/USD")


RUN_DIR = os.environ.get("RUN_DIR", "/tmp")

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0"
}

def fetch_text(url: str) -> str:
    r = requests.get(url, headers=HEADERS, timeout=25)
    r.raise_for_status()
    return r.text

def fetch_json(url: str) -> dict:
    r = requests.get(url, headers=HEADERS, timeout=25)
    r.raise_for_status()
    return r.json()

def main():
    os.makedirs(RUN_DIR, exist_ok=True)
    now = datetime.now(timezone.utc).isoformat()

    raw = {
        "source_ts": now,
        "gold":  {"url": GOLD_URL,  "html": fetch_text(GOLD_URL)},
        "iron":  {"url": IRON_URL,  "html": fetch_text(IRON_URL)},
        "copper":{"url": COPPER_URL,"html": fetch_text(COPPER_URL)},
        "fx":    {"url": FX_URL,    "json": fetch_json(FX_URL)},
    }

    path = os.path.join(RUN_DIR, "raw.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(raw, f)
    print(f"Wrote raw payloads to {path}")

if __name__ == "__main__":
    main()
