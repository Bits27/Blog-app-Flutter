-- Step 3: Profile table + storage bucket + RLS policies

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text,
  avatar_url text,
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view all profiles"
on public.profiles
for select
using (true);

create policy "Users can insert their own profile"
on public.profiles
for insert
with check (auth.uid() = id);

create policy "Users can update their own profile"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- Storage bucket for profile photos
insert into storage.buckets (id, name, public)
values ('profile_images', 'profile_images', true)
on conflict (id) do nothing;

-- Allow public read of profile images
create policy "Public can view profile images"
on storage.objects
for select
using (bucket_id = 'profile_images');

-- Allow authenticated users to upload into their own folder (user_id/...)
create policy "Users can upload own profile image"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'profile_images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can update own profile image"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'profile_images'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'profile_images'
  and (storage.foldername(name))[1] = auth.uid()::text
);
