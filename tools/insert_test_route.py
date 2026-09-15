"""실기기 GPS 검증용 '테스트 산군'을 만든다: 출퇴근 같은 도보 경로를 OSRM(도보)으로 받아
mountains / nodes / segments / spots / courses 에 넣는다. 산군 이름은 반드시 "[테스트]"로 시작하며,
앱은 릴리즈 빌드에서 이 접두어 산군을 숨긴다 (lib/core/config/test_data.dart).

사용법:
  python3 tools/insert_test_route.py --name "출근길" --from 37.5405559,127.0683955 --to <lat>,<lon> \
      [--via <lat>,<lon> ...] [--group "[테스트] 출퇴근"] [--segment-m 250] [--dry-run]
  python3 tools/insert_test_route.py --delete-group "[테스트] 출퇴근"     # 전부 삭제
  --manual : OSRM을 쓰지 않고 --from/--via/--to 점들을 직선으로 이어 폴리라인을 만든다 (직접 찍은 좌표용)

같은 이름으로 다시 넣으면 코스는 새로 추가되고 구간은 id(경로 해시) 기준으로 upsert 된다.
"""
import argparse
import hashlib
import json
import math
import sys
import urllib.parse
import urllib.request

from _supabase import HEADERS, URL, get, post

TEST_PREFIX = "[테스트]"
WALK_M_PER_MIN = 75


def km(a, b):  # (lat, lon)
    h = math.sin(math.radians(b[0] - a[0]) / 2) ** 2 + math.cos(math.radians(a[0])) * math.cos(
        math.radians(b[0])) * math.sin(math.radians(b[1] - a[1]) / 2) ** 2
    return 6371 * 2 * math.asin(math.sqrt(h))


def osrm_foot(points):
    coords = ";".join(f"{lon},{lat}" for lat, lon in points)
    url = f"https://router.project-osrm.org/route/v1/foot/{coords}?overview=full&geometries=geojson&steps=false"
    with urllib.request.urlopen(url, timeout=30) as r:
        d = json.load(r)
    if d.get("code") != "Ok":
        sys.exit(f"OSRM 실패: {d}")
    route = d["routes"][0]
    return [(c[1], c[0]) for c in route["geometry"]["coordinates"]], route["distance"]


def split_route(line, seg_m):
    """누적 거리 기준으로 seg_m 마다 끊어 구간 폴리라인 목록을 만든다 (끝점 공유)."""
    segs, cur, acc = [], [line[0]], 0.0
    for i in range(1, len(line)):
        d = km(line[i - 1], line[i]) * 1000
        cur.append(line[i])
        acc += d
        if acc >= seg_m and i < len(line) - 1:
            segs.append(cur)
            cur, acc = [line[i]], 0.0
    if len(cur) >= 2:
        segs.append(cur)
    elif segs:
        segs[-1].extend(cur[1:])
    return segs


def hid(prefix, *parts):
    return prefix + hashlib.sha1("|".join(str(p) for p in parts).encode()).hexdigest()[:8]


def upsert(table, rows, on_conflict):
    req = urllib.request.Request(
        f"{URL}/{table}?on_conflict={on_conflict}",
        data=json.dumps(rows, ensure_ascii=False).encode(),
        headers={**HEADERS, "Prefer": "resolution=merge-duplicates,return=minimal"},
        method="POST",
    )
    urllib.request.urlopen(req).read()


def delete(table, filt):
    req = urllib.request.Request(f"{URL}/{table}?{filt}", headers={**HEADERS, "Prefer": "return=representation"}, method="DELETE")
    with urllib.request.urlopen(req) as r:
        return len(json.load(r))


def delete_group(group):
    g = urllib.parse.quote(group)
    print("courses", delete("courses", f"mountain_group=eq.{g}"))
    print("segments", delete("segments", f"mountain_group=eq.{g}"))
    print("spots", delete("spots", f"mountain_group=eq.{g}"))
    print("nodes", delete("nodes", f"node_id=like.TN{urllib.parse.quote(hashlib.sha1(group.encode()).hexdigest()[:4])}*"))
    print("mountains", delete("mountains", f"mountain_group=eq.{g}"))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--name")
    ap.add_argument("--from", dest="src", help="lat,lon")
    ap.add_argument("--to", dest="dst", help="lat,lon")
    ap.add_argument("--via", nargs="*", default=[], help="lat,lon ... (경유지)")
    ap.add_argument("--group", default=f"{TEST_PREFIX} 출퇴근")
    ap.add_argument("--segment-m", type=int, default=250)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--delete-group")
    ap.add_argument("--manual", action="store_true", help="OSRM 없이 찍은 점들을 직선으로 연결")
    a = ap.parse_args()

    if a.delete_group:
        if not a.delete_group.startswith(TEST_PREFIX):
            sys.exit(f"안전장치: '{TEST_PREFIX}'로 시작하는 산군만 삭제할 수 있습니다")
        delete_group(a.delete_group)
        return
    if not (a.name and a.src and a.dst):
        ap.error("--name, --from, --to 필수")
    if not a.group.startswith(TEST_PREFIX):
        sys.exit(f"테스트 산군 이름은 '{TEST_PREFIX}'로 시작해야 합니다 (릴리즈에서 숨기기 위해)")

    pts = [tuple(map(float, p.split(","))) for p in [a.src, *a.via, a.dst]]
    if a.manual:
        line = pts
        dist_m = sum(km(pts[i - 1], pts[i]) for i in range(1, len(pts))) * 1000
    else:
        line, dist_m = osrm_foot(pts)
    parts = split_route(line, a.segment_m)
    gkey = hashlib.sha1(a.group.encode()).hexdigest()[:4]

    nodes, segments, seg_ids = {}, [], []
    for i, p in enumerate(parts):
        n1 = hid(f"TN{gkey}", p[0]); n2 = hid(f"TN{gkey}", p[-1])
        nodes[n1] = {"node_id": n1, "lat": p[0][0], "lon": p[0][1], "degree": 1 if i == 0 else 2}
        nodes[n2] = {"node_id": n2, "lat": p[-1][0], "lon": p[-1][1], "degree": 1 if i == len(parts) - 1 else 2}
        length = sum(km(p[j - 1], p[j]) for j in range(1, len(p)))
        sid = hid(f"TS{gkey}", n1, n2, len(p))
        seg_ids.append(sid)
        segments.append({
            "segment_id": sid, "mountain_group": a.group, "source_code": "test", "region": "테스트",
            "section_name": f"{a.name} {i + 1}/{len(parts)}", "length_km": round(length, 3),
            "difficulty": "쉬움", "up_min": max(1, round(length * 1000 / WALK_M_PER_MIN)),
            "down_min": max(1, round(length * 1000 / WALK_M_PER_MIN)), "surface": "보도", "risk_note": None,
            "start_node": n1, "end_node": n2, "park_flag": 0,
            "polyline": [[lon, lat] for lat, lon in p],
        })
    entrance_id = hid(f"TP{gkey}", line[0])
    spot = {"spot_id": entrance_id, "mountain_group": a.group, "source_code": "test", "type": "시종점",
            "category": "시종점", "note": f"{a.name} 출발점", "is_entrance": 1, "lat": line[0][0], "lon": line[0][1]}
    total_km = round(sum(s["length_km"] for s in segments), 2)
    up = sum(s["up_min"] for s in segments)
    mountain = {"mountain_group": a.group, "source_codes": "test", "regions": "서울", "segment_count": len(segments),
                "total_length_km": total_km, "entrance_count": 1,
                "center_lon": sum(p[1] for p in line) / len(line), "center_lat": sum(p[0] for p in line) / len(line)}
    course = {"mountain_group": a.group, "name": f"{TEST_PREFIX} {a.name}", "segment_ids": seg_ids,
              "entrance_spot": entrance_id, "length_km": total_km, "est_up_min": up,
              "difficulty_score": round(total_km * 0.6 + up / 60 * 2, 2),
              "description": f"실기기 GPS 검증용 테스트 경로 ({'직접 찍은 경로' if a.manual else 'OSRM 도보 경로'}, {dist_m:.0f}m). 릴리즈에는 표시되지 않음."}
    print(f"경로 {dist_m:.0f}m · 점 {len(line)}개 → 구간 {len(segments)}개 · 도보 예상 {up}분")
    if a.dry_run:
        print(json.dumps({"mountain": mountain, "course": course}, ensure_ascii=False, indent=1)[:800])
        return
    # 기존 산군 행이 있으면 구간 수만 갱신되도록 upsert (mountain → nodes → segments → spots → courses)
    existing = get("mountains", {"mountain_group": f"eq.{a.group}", "select": "segment_count,total_length_km"})
    if existing:
        mountain["segment_count"] += existing[0]["segment_count"]
        mountain["total_length_km"] = round(float(existing[0]["total_length_km"]) + total_km, 2)
    upsert("mountains", [mountain], "mountain_group")
    upsert("nodes", list(nodes.values()), "node_id")
    upsert("segments", segments, "segment_id")
    upsert("spots", [spot], "spot_id")
    created = post("courses", course)
    print("저장 완료 → course_id:", created[0]["course_id"])


if __name__ == "__main__":
    main()
