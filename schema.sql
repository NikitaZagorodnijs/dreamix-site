-- Dreamix Site: run this once in Supabase > SQL Editor > New query > Run

create table public.admins(user_id uuid primary key references auth.users on delete cascade);
create table public.sites(id uuid primary key default gen_random_uuid(), name text not null, address text default '', plan_path text, created_at timestamptz default now());
create table public.site_members(site_id uuid references public.sites on delete cascade, user_id uuid references auth.users on delete cascade, login text, primary key(site_id,user_id));
create table public.team(id uuid primary key default gen_random_uuid(), site_id uuid not null references public.sites on delete cascade, name text not null, role text default '', status text not null default 'planned' check (status in ('planned','progress','done')), created_at timestamptz default now());
create table public.photos(id uuid primary key default gen_random_uuid(), site_id uuid not null references public.sites on delete cascade, path text not null, caption text default '', created_at timestamptz default now());
create table public.messages(id uuid primary key default gen_random_uuid(), site_id uuid not null references public.sites on delete cascade, author_id uuid default auth.uid(), from_role text not null check (from_role in ('client','manager')), body text not null, created_at timestamptz default now());

create function public.is_admin() returns boolean language sql security definer stable set search_path=public as $$ select exists(select 1 from public.admins where user_id=auth.uid()) $$;
create function public.has_site(s uuid) returns boolean language sql security definer stable set search_path=public as $$ select public.is_admin() or exists(select 1 from public.site_members where site_id=s and user_id=auth.uid()) $$;

alter table public.admins enable row level security;
alter table public.sites enable row level security;
alter table public.site_members enable row level security;
alter table public.team enable row level security;
alter table public.photos enable row level security;
alter table public.messages enable row level security;

create policy admins_self on public.admins for select using (user_id=auth.uid());
create policy sites_read on public.sites for select using (public.has_site(id));
create policy sites_admin on public.sites for all using (public.is_admin()) with check (public.is_admin());
create policy members_read on public.site_members for select using (user_id=auth.uid() or public.is_admin());
create policy members_admin on public.site_members for all using (public.is_admin()) with check (public.is_admin());
create policy team_read on public.team for select using (public.has_site(site_id));
create policy team_admin on public.team for all using (public.is_admin()) with check (public.is_admin());
create policy photos_read on public.photos for select using (public.has_site(site_id));
create policy photos_admin on public.photos for all using (public.is_admin()) with check (public.is_admin());
create policy msg_read on public.messages for select using (public.has_site(site_id));
create policy msg_insert on public.messages for insert with check (
  author_id=auth.uid() and (
    (public.is_admin() and from_role='manager') or
    (not public.is_admin() and public.has_site(site_id) and from_role='client')));

insert into storage.buckets(id,name,public) values('site-files','site-files',false) on conflict do nothing;
create policy files_read on storage.objects for select using (bucket_id='site-files' and public.has_site(split_part(name,'/',1)::uuid));
create policy files_ins on storage.objects for insert with check (bucket_id='site-files' and public.is_admin());
create policy files_upd on storage.objects for update using (bucket_id='site-files' and public.is_admin());
create policy files_del on storage.objects for delete using (bucket_id='site-files' and public.is_admin());

alter publication supabase_realtime add table public.messages;

-- AFTER creating your admin user (see README step 4), run:
-- insert into public.admins select id from auth.users where email='YOUR-EMAIL@example.com';
