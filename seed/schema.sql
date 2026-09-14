-- 등산 코스 앱 시드 스키마 (Supabase/Postgres)
-- CSV 임포트 순서: mountains -> nodes -> segments -> spots -> safety_points

create table mountains (
  mountain_group   text primary key,
  source_codes     text not null,
  regions          text not null,
  segment_count    int  not null,
  total_length_km  numeric not null,
  entrance_count   int  not null,
  center_lon       double precision,
  center_lat       double precision
);

create table nodes (
  node_id  text primary key,
  lon      double precision not null,
  lat      double precision not null,
  degree   int not null                     -- 1=막다른 끝, 3+=갈림길
);

create table segments (
  segment_id     text primary key,
  mountain_group text not null references mountains,
  source_code    text not null,
  region         text not null,
  section_name   text,
  length_km      numeric,
  difficulty     text,                      -- 쉬움/중간/어려움
  up_min         int,
  down_min       int,
  surface        text,
  risk_note      text,
  start_node     text references nodes,
  end_node       text references nodes,
  park_flag      int not null default 0,
  polyline       jsonb not null             -- [[lon,lat], ...] WGS84
);
create index on segments (mountain_group);
create index on segments (start_node);
create index on segments (end_node);

create table spots (
  spot_id        text primary key,
  mountain_group text not null references mountains,
  source_code    text not null,
  type           text,
  category       text,
  note           text,
  is_entrance    int not null default 0,
  lon            double precision not null,
  lat            double precision not null
);
create index on spots (mountain_group, type);

create table safety_points (
  safety_id      text primary key,
  mountain_group text not null references mountains,
  source_code    text not null,
  marker_type    text,
  marker_no      text,
  agency         text,
  location_desc  text,
  lon            double precision not null,
  lat            double precision not null
);

create view entrances as
  select * from spots where is_entrance = 1;

-- 앱에서 채울 테이블 (시드 없음, 직접 큐레이션)
create table courses (
  course_id      uuid primary key default gen_random_uuid(),
  mountain_group text not null references mountains,
  name           text not null,
  segment_ids    jsonb not null,
  entrance_spot  text references spots,
  length_km      numeric,
  est_up_min     int,
  difficulty_score numeric,
  description    text,
  created_at     timestamptz default now()
);

create table visits (
  visit_id   uuid primary key default gen_random_uuid(),
  user_id    uuid not null,
  course_id  uuid references courses,
  visited_at date not null default current_date,
  duration_min int,
  note       text
);
