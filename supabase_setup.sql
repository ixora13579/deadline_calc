-- 업무 기한 계산기 : 기록 표 · 권한
-- Supabase → SQL Editor 에 통째로 붙여 넣고 Run 합니다.

create table if not exists public.deadline_calcs (
  id           bigint generated always as identity primary key,
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title        text check (char_length(title) <= 100),
  start_date   date not null,
  days         integer not null check (days between 0 and 3650),
  calendar_due date not null,
  workday_due  date not null,
  created_at   timestamptz not null default now()
);

create index if not exists deadline_calcs_user_idx on public.deadline_calcs (user_id, created_at desc);

-- 로그인한 사람은 자기 줄만 보고 · 쓰고 · 지운다
alter table public.deadline_calcs enable row level security;

drop policy if exists "내 기록 보기" on public.deadline_calcs;
drop policy if exists "내 기록 추가" on public.deadline_calcs;
drop policy if exists "내 기록 삭제" on public.deadline_calcs;

create policy "내 기록 보기" on public.deadline_calcs
  for select to authenticated using (user_id = auth.uid());
create policy "내 기록 추가" on public.deadline_calcs
  for insert to authenticated with check (user_id = auth.uid());
create policy "내 기록 삭제" on public.deadline_calcs
  for delete to authenticated using (user_id = auth.uid());

revoke all on public.deadline_calcs from anon;
grant select, insert, delete on public.deadline_calcs to authenticated;
