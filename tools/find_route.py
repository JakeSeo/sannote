"""등산로 그래프에서 두 지점 사이 최단 경로(segment_id 순서)를 찾는 운영자용 도구.

사용법:
  python3 tools/find_route.py "<산군>" <출발 lat> <출발 lon> <도착 lat> <도착 lon> [--allow-park]

출발/도착 좌표에서 가장 가까운 노드를 잡아 Dijkstra(거리 기준). park_flag=1 구간은 기본 제외.
결과는 코스 후보일 뿐이며, 실제 코스 확정은 답사 후 insert_course.py로 입력한다.
"""
import heapq
import math
import sys

from _supabase import get


BRIDGE_M = 25  # 이 거리 이내의 노드는 같은 지점으로 보고 연결


def km(lat1, lon1, lat2, lon2):
    a = math.sin(math.radians(lat2 - lat1) / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(
        math.radians(lat2)) * math.sin(math.radians(lon2 - lon1) / 2) ** 2
    return 6371 * 2 * math.asin(math.sqrt(a))


def load_graph(group, allow_park):
    segs = get("segments", {
        "mountain_group": f"eq.{group}",
        "select": "segment_id,start_node,end_node,length_km,up_min,down_min,difficulty,park_flag,polyline",
    })
    if not allow_park:
        segs = [s for s in segs if s["park_flag"] != 1]
    node_ids = {s["start_node"] for s in segs} | {s["end_node"] for s in segs}
    nodes = {n["node_id"]: n for n in get("nodes", {"select": "node_id,lat,lon,degree"}) if n["node_id"] in node_ids}
    adj = {}
    # 원본 노드 클러스터링(5m) 잔여로 끊긴 지점을 잇는 가상 연결 (BRIDGE_M 이내, 구간 없음 → seg=None)
    ids = list(nodes)
    for i in range(len(ids)):
        for j in range(i + 1, len(ids)):
            a, b = nodes[ids[i]], nodes[ids[j]]
            d = km(a["lat"], a["lon"], b["lat"], b["lon"])
            if d < BRIDGE_M / 1000:
                adj.setdefault(a["node_id"], []).append((b["node_id"], d, None))
                adj.setdefault(b["node_id"], []).append((a["node_id"], d, None))
    for s in segs:
        if not s["start_node"] or not s["end_node"]:
            continue
        w = float(s["length_km"] or 0) or 0.01
        adj.setdefault(s["start_node"], []).append((s["end_node"], w, s))
        adj.setdefault(s["end_node"], []).append((s["start_node"], w, s))
    return nodes, adj, segs


def nearest_node(nodes, lat, lon):
    return min(nodes.values(), key=lambda n: km(lat, lon, n["lat"], n["lon"]))


def dijkstra(adj, src, dst):
    dist = {src: 0.0}
    prev = {}
    pq = [(0.0, src)]
    while pq:
        d, u = heapq.heappop(pq)
        if u == dst:
            break
        if d > dist.get(u, float("inf")):
            continue
        for v, w, seg in adj.get(u, []):
            nd = d + w
            if nd < dist.get(v, float("inf")):
                dist[v] = nd
                prev[v] = (u, seg)
                heapq.heappush(pq, (nd, v))
    if dst not in dist:
        return None
    path = []
    cur = dst
    while cur != src:
        u, seg = prev[cur]
        if seg is not None:  # 가상 연결은 구간이 아니므로 제외
            path.append(seg)
        cur = u
    return list(reversed(path))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    allow_park = "--allow-park" in sys.argv
    if len(args) != 5:
        print(__doc__)
        sys.exit(1)
    group, slat, slon, dlat, dlon = args[0], *map(float, args[1:])
    nodes, adj, _ = load_graph(group, allow_park)
    src, dst = nearest_node(nodes, slat, slon), nearest_node(nodes, dlat, dlon)
    print(f"출발 노드 {src['node_id']} ({km(slat, slon, src['lat'], src['lon'])*1000:.0f}m 떨어짐), "
          f"도착 노드 {dst['node_id']} ({km(dlat, dlon, dst['lat'], dst['lon'])*1000:.0f}m 떨어짐)")
    path = dijkstra(adj, src["node_id"], dst["node_id"])
    if not path:
        print("경로 없음 (park 구간 제외 때문일 수 있음 → --allow-park)")
        sys.exit(2)
    total_km = sum(float(s["length_km"] or 0) for s in path)
    up = sum(s["up_min"] or 0 for s in path)
    down = sum(s["down_min"] or 0 for s in path)
    print(f"\n구간 {len(path)}개 · {total_km:.2f}km · 오름 예상 {up}분 · 내림 예상 {down}분")
    print("난이도:", {d: sum(1 for s in path if s['difficulty'] == d) for d in ('쉬움', '중간', '어려움')})
    print("\nsegment_ids (순서대로):")
    print(",".join(s["segment_id"] for s in path))


if __name__ == "__main__":
    main()
