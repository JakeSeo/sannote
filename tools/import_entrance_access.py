"""entrance_access_template.csv 에서 값이 채워진 행만 entrance_access 테이블에 upsert.

사용법: python3 tools/import_entrance_access.py [csv경로]   (기본: tools/entrance_access_template.csv)
station_name 과 walk_min 이 채워진 행만 올린다. lat/lon/course_start 컬럼은 참고용이라 무시.
"""
import csv
import json
import sys
import urllib.request

from _supabase import HEADERS, URL

path = sys.argv[1] if len(sys.argv) > 1 else "tools/entrance_access_template.csv"
rows = []
with open(path, encoding="utf-8") as f:
    for r in csv.DictReader(f):
        if r["station_name"].strip() and r["walk_min"].strip():
            rows.append({
                "spot_id": r["spot_id"], "mountain_group": r["mountain_group"],
                "station_name": r["station_name"].strip(), "line": r["line"].strip() or None,
                "walk_min": int(r["walk_min"]), "note": r["note"].strip() or None,
            })
if not rows:
    sys.exit("채워진 행이 없습니다 (station_name, walk_min 필수)")
req = urllib.request.Request(
    f"{URL}/entrance_access?on_conflict=spot_id",
    data=json.dumps(rows, ensure_ascii=False).encode(),
    headers={**HEADERS, "Prefer": "resolution=merge-duplicates,return=representation"},
    method="POST",
)
with urllib.request.urlopen(req) as res:
    print(f"upsert {len(json.load(res))}건 완료")
