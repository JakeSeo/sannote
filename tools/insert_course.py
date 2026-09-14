"""courses 테이블에 코스 1개를 수동 입력하는 운영자용 스크립트 (어드민 화면 대신).

사용법:
  python3 tools/insert_course.py --name "아차산역 출발 해맞이 코스" --group "아차산·용마산" \
      --segments S40227,S40255,... [--entrance P58128] [--description "..."] [--dry-run]

segment_ids는 출발→도착 순서. 거리/오름시간/난이도 점수는 구간 합산으로 자동 계산해 캐시 컬럼에 함께 저장한다.
난이도 공식은 앱(lib/features/courses/domain/entities/course_stats.dart)과 동일하게 유지할 것.
"""
import argparse
import json
import sys

from _supabase import get, post


def difficulty_score(length_km, up_min, hard_ratio, medium_ratio):
    # = DifficultyFormula.score (Dart) — 두 곳을 항상 같이 수정
    return length_km * 0.6 + (up_min / 60) * 2 + hard_ratio * 3 + medium_ratio * 1.5


def level(score):
    return "초급" if score < 5 else ("중급" if score <= 9 else "상급")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--name", required=True)
    ap.add_argument("--group", required=True, help="mountain_group (예: 아차산·용마산)")
    ap.add_argument("--segments", required=True, help="segment_id를 쉼표로, 출발→도착 순서")
    ap.add_argument("--entrance", help="출발 입구 spot_id")
    ap.add_argument("--description", default=None)
    ap.add_argument("--dry-run", action="store_true", help="계산 결과만 출력하고 저장하지 않음")
    a = ap.parse_args()

    ids = [s.strip() for s in a.segments.split(",") if s.strip()]
    rows = get("segments", {"segment_id": f"in.({','.join(ids)})",
                            "select": "segment_id,mountain_group,length_km,up_min,down_min,difficulty,park_flag"})
    by_id = {r["segment_id"]: r for r in rows}
    missing = [i for i in ids if i not in by_id]
    if missing:
        sys.exit(f"segments 테이블에 없는 id: {missing}")
    wrong = [i for i in ids if by_id[i]["mountain_group"] != a.group]
    if wrong:
        sys.exit(f"{a.group} 소속이 아닌 구간: {wrong}")

    segs = [by_id[i] for i in ids]
    length = sum(float(s["length_km"] or 0) for s in segs)
    up = sum(s["up_min"] or 0 for s in segs)
    n = len(segs)
    hard = sum(1 for s in segs if s["difficulty"] == "어려움") / n
    med = sum(1 for s in segs if s["difficulty"] == "중간") / n
    score = round(difficulty_score(length, up, hard, med), 2)
    park = sum(1 for s in segs if s["park_flag"] == 1)

    body = {
        "mountain_group": a.group,
        "name": a.name,
        "segment_ids": ids,
        "entrance_spot": a.entrance,
        "length_km": round(length, 2),
        "est_up_min": up,
        "difficulty_score": score,
        "description": a.description,
    }
    print(f"구간 {n}개 (공원형 {park}개) · {length:.2f}km · 오름 예상 {up}분 · 난이도 {score} ({level(score)})")
    print(json.dumps(body, ensure_ascii=False, indent=2))
    if a.dry_run:
        return
    created = post("courses", body)
    print("\n저장 완료 → course_id:", created[0]["course_id"])


if __name__ == "__main__":
    main()
