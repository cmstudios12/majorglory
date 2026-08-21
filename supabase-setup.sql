-- ============================================================
-- CM CAREER STUDIO - COMPLETE SUPABASE SETUP
-- Run this whole file in Supabase Dashboard > SQL Editor.
-- ============================================================

create extension if not exists pgcrypto;

-- USER PROFILES
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text not null default '',
  last_name text not null default '',
  email text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- CV DOCUMENTS
create table if not exists public.cvs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'My Professional CV',
  template text not null default 'modern',
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint cvs_title_length check (char_length(title) between 1 and 120)
);

-- COVER LETTERS
create table if not exists public.cover_letters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'Untitled Cover Letter',
  document jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint cover_letters_title_length check (char_length(title) between 1 and 160)
);

-- INDEXES
create index if not exists cvs_user_id_idx on public.cvs(user_id);
create index if not exists cvs_user_id_updated_at_idx on public.cvs(user_id, updated_at desc);
create index if not exists cover_letters_user_id_idx on public.cover_letters(user_id);
create index if not exists cover_letters_user_id_updated_at_idx on public.cover_letters(user_id, updated_at desc);

-- UPDATED_AT TRIGGER
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_cvs_updated_at on public.cvs;
create trigger set_cvs_updated_at before update on public.cvs
for each row execute function public.set_updated_at();

drop trigger if exists set_cover_letters_updated_at on public.cover_letters;
create trigger set_cover_letters_updated_at before update on public.cover_letters
for each row execute function public.set_updated_at();

-- AUTO CREATE / SYNC PROFILE FROM AUTH
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, first_name, last_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'first_name',''),
    coalesce(new.raw_user_meta_data->>'last_name',''),
    coalesce(new.email,'')
  )
  on conflict (id) do update set
    first_name = coalesce(nullif(excluded.first_name,''), public.profiles.first_name),
    last_name = coalesce(nullif(excluded.last_name,''), public.profiles.last_name),
    email = excluded.email,
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert or update of email, raw_user_meta_data on auth.users
for each row execute function public.handle_new_user();

insert into public.profiles (id, first_name, last_name, email)
select id,
       coalesce(raw_user_meta_data->>'first_name',''),
       coalesce(raw_user_meta_data->>'last_name',''),
       coalesce(email,'')
from auth.users
on conflict (id) do nothing;

-- ROW LEVEL SECURITY
alter table public.profiles enable row level security;
alter table public.cvs enable row level security;
alter table public.cover_letters enable row level security;

-- PROFILES
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
FOR SELECT TO authenticated USING ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
FOR UPDATE TO authenticated
USING ((select auth.uid()) = id)
WITH CHECK ((select auth.uid()) = id);

-- CVS
DROP POLICY IF EXISTS "Users can view own CVs" ON public.cvs;
CREATE POLICY "Users can view own CVs" ON public.cvs
FOR SELECT TO authenticated USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can create own CVs" ON public.cvs;
CREATE POLICY "Users can create own CVs" ON public.cvs
FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own CVs" ON public.cvs;
CREATE POLICY "Users can update own CVs" ON public.cvs
FOR UPDATE TO authenticated
USING ((select auth.uid()) = user_id)
WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own CVs" ON public.cvs;
CREATE POLICY "Users can delete own CVs" ON public.cvs
FOR DELETE TO authenticated USING ((select auth.uid()) = user_id);

-- COVER LETTERS
DROP POLICY IF EXISTS "Users can view own cover letters" ON public.cover_letters;
CREATE POLICY "Users can view own cover letters" ON public.cover_letters
FOR SELECT TO authenticated USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can create own cover letters" ON public.cover_letters;
CREATE POLICY "Users can create own cover letters" ON public.cover_letters
FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own cover letters" ON public.cover_letters;
CREATE POLICY "Users can update own cover letters" ON public.cover_letters
FOR UPDATE TO authenticated
USING ((select auth.uid()) = user_id)
WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own cover letters" ON public.cover_letters;
CREATE POLICY "Users can delete own cover letters" ON public.cover_letters
FOR DELETE TO authenticated USING ((select auth.uid()) = user_id);

-- PRIVILEGES
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cvs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cover_letters TO authenticated;

REVOKE ALL ON public.profiles FROM anon;
REVOKE ALL ON public.cvs FROM anon;
REVOKE ALL ON public.cover_letters FROM anon;

-- OPTIONAL HARDENING: keep public schema defaults conservative
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon;

-- ============================================================
-- AFTER RUNNING
-- 1. Authentication > Providers > Email: enable Email.
-- 2. Set Site URL / Redirect URLs for your production domain.
-- 3. Register on auth.html.
-- 4. profiles, cvs and cover_letters will be protected by RLS.
-- ============================================================
