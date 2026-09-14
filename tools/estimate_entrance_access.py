"""OpenStreetMap 지하철역·출입구 좌표로 입구별 접근 정보 초안을 자동 생성해 CSV를 채운다.

사용법: python3 tools/estimate_entrance_access.py [--refresh] [--max-m 1500]
  --refresh : Overpass API에서 역 데이터를 다시 받음 (기본은 tools/osm_subway_cache.json 사용)

계산: 입구 → 가장 가까운 지하철 출입구(없으면 역 중심) 직선거리 × 우회계수 1.3 ÷ 분당 75m.
결과는 "추정"이며 note에 그렇게 표기된다. 로드뷰/답사로 확인한 값은 CSV에서 note를 바꿔 덮어쓰면 된다.
이미 note가 '자동 추정'으로 시작하지 않는(=사람이 검증한) 행은 건드리지 않는다.
"""
import argparse
import csv
import json
import math
import os
import sys
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(ROOT, "tools", "entrance_access_template.csv")
CACHE = os.path.join(ROOT, "tools", "osm_subway_cache.json")
BBOX = "37.40,126.90,37.72,127.16"  # 수도권 7개 산군 커버
DETOUR = 1.3
M_PER_MIN = 75
ESTIMATE_PREFIX = "자동 추정"


def km(a_lat, a_lon, b_lat, b_lon):
    h = math.sin(math.radians(b_lat - a_lat) / 2) ** 2 + math.cos(math.radians(a_lat)) * math.cos(
        math.radians(b_lat)) * math.sin(math.radians(b_lon - a_lon) / 2) ** 2
    return 6371 * 2 * math.asin(math.sqrt(h))


def fetch_osm():
    q = (f'[out:json][timeout:40];(node["railway"="station"]({BBOX});'
         f'node["railway"="subway_entrance"]({BBOX}););out body;')
    for mirror in ("https://lz4.overpass-api.de", "https://overpass-api.de", "https://z.overpass-api.de"):
        try:
            with urllib.request.urlopen(f"{mirror}/api/interpreter?data={urllib.parse.quote(q)}", timeout=90) as r:
                data = json.load(r)
            if len(data.get("elements", [])) > 50:
                json.dump(data, open(CACHE, "w"), ensure_ascii=False)
                return data
        except Exception as e:  # noqa: BLE001
            print(f"{mirror} 실패: {e}", file=sys.stderr)
    sys.exit("Overpass 서버에서 데이터를 받지 못했습니다. 잠시 후 다시 시도하세요.")


def load_osm(refresh):
    if refresh or not os.path.exists(CACHE):
        return fetch_osm()
    return json.load(open(CACHE))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--refresh", action="store_true")
    ap.add_argument("--max-m", type=int, default=1500, help="이 거리(m)보다 먼 입구는 비워둠")
    a = ap.parse_args()

    els = load_osm(a.refresh)["elements"]
    stations = [e for e in els if e.get("tags", {}).get("railway") == "station" and e["tags"].get("name")]
    exits = [e for e in els if e.get("tags", {}).get("railway") == "subway_entrance"]

    # 출입구 → 가장 가까운 역(300m 이내)
    for x in exits:
        best = min(stations, key=lambda s: km(x["lat"], x["lon"], s["lat"], s["lon"]))
        x["_station"] = best if km(x["lat"], x["lon"], best["lat"], best["lon"]) < 0.3 else None
    exits = [x for x in exits if x["_station"]]

    def station_name(s):
        n = s["tags"].get("name:ko") or s["tags"]["name"]
        return n if n.endswith("역") else n + "역"

    rows = list(csv.DictReader(open(CSV_PATH, encoding="utf-8")))
    filled = skipped_verified = too_far = 0
    for r in rows:
        if r["station_name"] and not (r["note"] or "").startswith(ESTIMATE_PREFIX):
            skipped_verified += 1
            continue
        lat, lon = float(r["lat"]), float(r["lon"])
        # 출입구 우선, 없으면 역 중심
        cand = [(km(lat, lon, x["lat"], x["lon"]) * 1000, x["_station"], x["tags"].get("ref")) for x in exits]
        cand += [(km(lat, lon, s["lat"], s["lon"]) * 1000, s, None) for s in stations]
        dist_m, st, ref = min(cand, key=lambda c: c[0])
        if dist_m > a.max_m:
            r.update(station_name="", line="", walk_min="", note="")
            too_far += 1
            continue
        walk = max(1, math.ceil(dist_m * DETOUR / M_PER_MIN))
        exit_txt = f" {ref}번 출구" if ref else ""
        r.update(
            station_name=station_name(st),
            line="",  # OSM 역 노드엔 호선 정보가 없음 → 검증 시 채움
            walk_min=str(walk),
            note=f"{ESTIMATE_PREFIX}(직선 {dist_m:.0f}m 기준){exit_txt} · 검증 전",
        )
        filled += 1

    with open(CSV_PATH, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader()
        w.writerows(rows)
    print(f"역 {len(stations)}곳 · 출입구 {len(exits)}곳 기준")
    print(f"추정 채움 {filled}건 · 검증값 유지 {skipped_verified}건 · {a.max_m}m 초과로 비움 {too_far}건 → {os.path.relpath(CSV_PATH, ROOT)}")


if __name__ == "__main__":
    main()
