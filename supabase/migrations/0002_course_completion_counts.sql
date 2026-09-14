-- M4: 코스별 총 완주자 수 (익명 집계). visits에 RLS를 걸어도(M5) 집계는 이 함수로 읽는다.
create or replace function course_completion_counts()
returns table (course_id uuid, count bigint)
language sql
security definer
set search_path = public
stable
as $$
  select course_id, count(*)::bigint
  from visits
  where course_id is not null
  group by course_id
$$;

grant execute on function course_completion_counts() to anon, authenticated;
