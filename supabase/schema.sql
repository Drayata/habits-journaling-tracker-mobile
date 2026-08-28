-- ============================================================
-- HabitFlow — Supabase Database Schema
-- Run this in the Supabase SQL Editor to set up all tables,
-- foreign keys, RLS policies, and triggers.
-- ============================================================

-- Enable UUID extension (usually already enabled)
create extension if not exists "uuid-ossp";

-- ============================================================
-- 1. PROFILES TABLE
-- ============================================================
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', '')
  );
  return new;
end;
$$;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- 2. HABITS TABLE
-- ============================================================
create table if not exists public.habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  title text not null,
  frequency text default 'daily',
  color_hint text default '#10b981',
  created_at timestamptz default now(),
  is_archived boolean default false,
  archived_at timestamptz,
  position integer default 0
);

alter table public.habits enable row level security;

create policy "Users can view own habits"
  on public.habits for select
  using (auth.uid() = user_id);

create policy "Users can create own habits"
  on public.habits for insert
  with check (auth.uid() = user_id);

create policy "Users can update own habits"
  on public.habits for update
  using (auth.uid() = user_id);

create policy "Users can delete own habits"
  on public.habits for delete
  using (auth.uid() = user_id);

-- ============================================================
-- 3. HABIT COMPLETIONS TABLE
-- ============================================================
create table if not exists public.habit_completions (
  id uuid primary key default gen_random_uuid(),
  habit_id uuid references public.habits on delete cascade not null,
  user_id uuid references auth.users on delete cascade not null,
  completed_date date not null,
  constraint unique_habit_date unique (habit_id, completed_date)
);

alter table public.habit_completions enable row level security;

create policy "Users can view own completions"
  on public.habit_completions for select
  using (auth.uid() = user_id);

create policy "Users can insert own completions"
  on public.habit_completions for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own completions"
  on public.habit_completions for delete
  using (auth.uid() = user_id);

-- ============================================================
-- 4. JOURNALS TABLE
-- ============================================================
create table if not exists public.journals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  entry_date date not null,
  content text default '',
  mood integer check (mood >= 1 and mood <= 5),
  updated_at timestamptz default now(),
  constraint unique_user_date unique (user_id, entry_date)
);

alter table public.journals enable row level security;

create policy "Users can view own journals"
  on public.journals for select
  using (auth.uid() = user_id);

create policy "Users can create own journals"
  on public.journals for insert
  with check (auth.uid() = user_id);

create policy "Users can update own journals"
  on public.journals for update
  using (auth.uid() = user_id);

create policy "Users can delete own journals"
  on public.journals for delete
  using (auth.uid() = user_id);

-- ============================================================
-- INDEXES for performance
-- ============================================================
create index if not exists idx_habits_user_id on public.habits (user_id);
create index if not exists idx_completions_habit_id on public.habit_completions (habit_id);
create index if not exists idx_completions_user_date on public.habit_completions (user_id, completed_date);
create index if not exists idx_journals_user_date on public.journals (user_id, entry_date);

-- ============================================================
-- 5. SLEEP LOGS TABLE
-- ============================================================
create table if not exists public.sleep_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  entry_date date not null,
  sleep_time time not null,
  wake_time time not null,
  duration_minutes integer not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  constraint unique_sleep_user_date unique (user_id, entry_date)
);

alter table public.sleep_logs enable row level security;

create policy "Users can view own sleep logs"
  on public.sleep_logs for select
  using (auth.uid() = user_id);

create policy "Users can insert own sleep logs"
  on public.sleep_logs for insert
  with check (auth.uid() = user_id);

create policy "Users can update own sleep logs"
  on public.sleep_logs for update
  using (auth.uid() = user_id);

create policy "Users can delete own sleep logs"
  on public.sleep_logs for delete
  using (auth.uid() = user_id);

create index if not exists idx_sleep_logs_user_date on public.sleep_logs (user_id, entry_date);
