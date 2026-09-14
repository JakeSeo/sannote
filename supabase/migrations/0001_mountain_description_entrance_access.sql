-- M3: 산 소개 + 입구 지하철 접근 정보
-- 실행: Supabase 대시보드 > SQL Editor 에 붙여넣고 Run (publishable key로는 DDL 불가)

-- 1) 산 소개 문구 (운영자가 채움. 비어 있으면 앱이 통계 기반 기본 문장을 보여준다)
alter table mountains add column if not exists description text;

-- 2) 입구별 지하철 접근 정보 (답사/로드뷰로 채움. tools/entrance_access_template.csv 참고)
create table if not exists entrance_access (
  spot_id        text primary key references spots,
  mountain_group text not null references mountains,
  station_name   text not null,          -- 예: 아차산역
  line           text,                   -- 예: 5호선
  walk_min       int  not null,          -- 역 출구 → 입구 도보 예상 분
  note           text,                   -- 예: 2번 출구, 생태공원 방향
  updated_at     timestamptz default now()
);
create index if not exists entrance_access_mountain_idx on entrance_access (mountain_group);

-- 예시 (첫 코스 출발점). 답사 후 값 확정할 것:
-- insert into entrance_access (spot_id, mountain_group, station_name, line, walk_min, note)
-- values ('P58170', '아차산·용마산', '아차산역', '5호선', 8, '2번 출구 → 아차산생태공원 방향')
-- on conflict (spot_id) do update set station_name = excluded.station_name, line = excluded.line,
--   walk_min = excluded.walk_min, note = excluded.note, updated_at = now();
