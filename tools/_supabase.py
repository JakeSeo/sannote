"""tools/ 스크립트 공용: .env에서 Supabase 접속 정보를 읽어 REST 호출 (표준 라이브러리만 사용)."""
import json
import os
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_env(path=os.path.join(ROOT, ".env")):
    env = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip()
    return env


ENV = load_env()
URL = ENV["SUPABASE_URL"].rstrip("/") + "/rest/v1"
KEY = ENV["SUPABASE_PUBLISHABLE_KEY"]
HEADERS = {"apikey": KEY, "Authorization": f"Bearer {KEY}", "Content-Type": "application/json"}


def get(table, params, page_size=1000):
    """PostgREST max-rows(1000) 우회용 페이지네이션 GET."""
    rows, offset = [], 0
    while True:
        q = dict(params)
        q["offset"] = offset
        q["limit"] = page_size
        req = urllib.request.Request(f"{URL}/{table}?{urllib.parse.urlencode(q)}", headers=HEADERS)
        with urllib.request.urlopen(req) as res:
            page = json.load(res)
        rows.extend(page)
        if len(page) < page_size:
            return rows
        offset += page_size


def post(table, body):
    req = urllib.request.Request(
        f"{URL}/{table}",
        data=json.dumps(body, ensure_ascii=False).encode("utf-8"),
        headers={**HEADERS, "Prefer": "return=representation"},
        method="POST",
    )
    with urllib.request.urlopen(req) as res:
        return json.load(res)
