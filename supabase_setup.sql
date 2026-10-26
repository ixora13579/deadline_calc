-- 업무 기한 계산기 : 공유 달력 표 · 권한
-- Supabase → SQL Editor 에 통째로 붙여 넣고 Run 합니다. (이미 표가 있어도 다시 실행해도 됩니다)

create table if not exists public.deadline_calcs (
  id           bigint generated always as identity primary key,
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  user_name    text check (char_length(user_name) <= 50),
  title        text check (char_length(title) <= 100),
  start_date   date not null,
  days         integer not null check (days between 0 and 3650),
  calendar_due date not null,
  workday_due  date not null,
  due_kind     text not null default 'workday' check (due_kind in ('calendar', 'workday')),
  created_at   timestamptz not null default now()
);

-- 예전 표에는 작성자 이름 · 등록 기준 칸이 없으므로 추가한다
-- due_kind : 공유 달력에 올린 마감일이 달력 기준(calendar)인지 근무일 기준(workday)인지
alter table public.deadline_calcs
  add column if not exists user_name text check (char_length(user_name) <= 50);
alter table public.deadline_calcs
  add column if not exists due_kind text not null default 'workday' check (due_kind in ('calendar', 'workday'));

create index if not exists deadline_calcs_user_idx on public.deadline_calcs (user_id, created_at desc);
create index if not exists deadline_calcs_calendar_due_idx on public.deadline_calcs (calendar_due);
create index if not exists deadline_calcs_workday_due_idx on public.deadline_calcs (workday_due);

-- 로그인한 사람은 모두의 일정을 보고, 자기 줄만 쓰고 · 지운다
alter table public.deadline_calcs enable row level security;

drop policy if exists "내 기록 보기" on public.deadline_calcs;
drop policy if exists "모든 기록 보기" on public.deadline_calcs;
drop policy if exists "내 기록 추가" on public.deadline_calcs;
drop policy if exists "내 기록 삭제" on public.deadline_calcs;

create policy "모든 기록 보기" on public.deadline_calcs
  for select to authenticated using (true);
create policy "내 기록 추가" on public.deadline_calcs
  for insert to authenticated with check (user_id = auth.uid());
create policy "내 기록 삭제" on public.deadline_calcs
  for delete to authenticated using (user_id = auth.uid());

revoke all on public.deadline_calcs from anon;
grant select, insert, delete on public.deadline_calcs to authenticated;
