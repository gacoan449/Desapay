-- DesaPay hybrid backend. This migration was also executed in the Supabase
-- Dashboard SQL Editor. Drop these named policies first so `db push` remains
-- safe even though dashboard SQL execution is not recorded in migration history.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  provider_ref text not null unique default replace(gen_random_uuid()::text, '-', ''),
  amount bigint not null check (amount > 0),
  status text not null default 'PENDING'
    check (status in ('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED')),
  provider_message text,
  provider_sn text,
  provider_event_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists transactions_user_created_idx
  on public.transactions (user_id, created_at desc);

create table if not exists public.push_tokens (
  token text primary key,
  user_id text not null,
  platform text not null default 'android' check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now()
);

create index if not exists push_tokens_user_idx on public.push_tokens (user_id);

create table if not exists public.health_probe (
  id boolean primary key default true check (id = true),
  touched_at timestamptz not null default now()
);
insert into public.health_probe (id) values (true) on conflict (id) do nothing;

-- Provider callbacks are globally idempotent, including concurrent retries.
create table if not exists public.provider_callback_events (
  event_id text primary key,
  provider_ref text not null,
  created_at timestamptz not null default now()
);

alter table public.transactions enable row level security;
alter table public.push_tokens enable row level security;
alter table public.health_probe enable row level security;
alter table public.provider_callback_events enable row level security;

-- Firebase Auth ID tokens are verified by Supabase's configured third-party
-- Firebase integration. Firebase UID is the JWT `sub`, not auth.uid() UUID.
-- Policies cover role=anon too because Firebase tokens may omit a role claim.
drop policy if exists "read own transactions from configured Firebase project" on public.transactions;
drop policy if exists "read own push tokens" on public.push_tokens;
drop policy if exists "uid owns user files" on storage.objects;
drop policy if exists "uid manages own product images" on storage.objects;
drop policy if exists "user can read files in own UID folder" on storage.objects;
drop policy if exists "user can upload files in own UID folder" on storage.objects;
drop policy if exists "user can update files in own UID folder" on storage.objects;
drop policy if exists "user can delete files in own UID folder" on storage.objects;
drop policy if exists "user can upload own product images" on storage.objects;
drop policy if exists "user can replace own product images" on storage.objects;
drop policy if exists "user can delete own product images" on storage.objects;
drop policy if exists "user can upload own profile images" on storage.objects;
drop policy if exists "user can replace own profile images" on storage.objects;
drop policy if exists "user can delete own profile images" on storage.objects;
drop policy if exists "user can read own profile images" on storage.objects;
create policy "read own transactions from configured Firebase project"
  on public.transactions for select to anon, authenticated
  using (
    user_id = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  );

create policy "read own push tokens"
  on public.push_tokens for select to anon, authenticated
  using (
    user_id = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  );

-- Clients have read-only transaction access. Only trusted server code writes rows.
revoke all on public.transactions from anon, authenticated;
grant select on public.transactions to anon, authenticated;
revoke all on public.push_tokens from anon, authenticated;
revoke all on public.health_probe from anon, authenticated;
revoke all on public.provider_callback_events from anon, authenticated;

-- Lock the transaction row and claim the provider event atomically. This makes
-- concurrent callback retries safe and prevents terminal status regression.
drop function if exists public.record_payment_callback(text, text, text, text, text);
create or replace function public.record_payment_callback(
  p_provider_ref text,
  p_event_id text,
  p_status text,
  p_message text,
  p_sn text,
  p_amount bigint
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  tx public.transactions%rowtype;
  claimed_event text;
  did_change boolean := false;
begin
  if p_status not in ('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED') then
    raise exception 'invalid_callback_status';
  end if;

  select * into tx
  from public.transactions
  where provider_ref = p_provider_ref
  for update;

  if not found then
    return jsonb_build_object('found', false);
  end if;
  if tx.amount <> p_amount then
    return jsonb_build_object('found', true, 'amountMismatch', true);
  end if;

  insert into public.provider_callback_events(event_id, provider_ref)
  values (p_event_id, p_provider_ref)
  on conflict (event_id) do nothing
  returning event_id into claimed_event;

  if claimed_event is null then
    if exists (
      select 1 from public.provider_callback_events
      where event_id = p_event_id and provider_ref <> p_provider_ref
    ) then
      return jsonb_build_object('found', true, 'eventCollision', true);
    end if;
    return jsonb_build_object(
      'found', true, 'duplicate', true,
      'userId', tx.user_id, 'transactionId', tx.id, 'status', tx.status
    );
  end if;

  if tx.status not in ('SUCCESS', 'FAILED')
     and not (tx.status = 'PROCESSING' and p_status = 'PENDING') then
    update public.transactions
    set status = p_status,
        provider_message = nullif(left(coalesce(p_message, ''), 500), ''),
        provider_sn = nullif(left(coalesce(p_sn, ''), 180), ''),
        provider_event_id = p_event_id,
        updated_at = now()
    where id = tx.id;
    did_change := true;
  end if;

  return jsonb_build_object(
    'found', true, 'changed', did_change,
    'ignoredTerminal', tx.status in ('SUCCESS', 'FAILED'),
    'userId', tx.user_id, 'transactionId', tx.id,
    'status', case when did_change then p_status else tx.status end
  );
end;
$$;

revoke all on function public.record_payment_callback(text, text, text, text, text, bigint) from public, anon, authenticated;
grant execute on function public.record_payment_callback(text, text, text, text, text, bigint) to service_role;

-- Private Storage bucket; every object path must start with the Firebase UID.
insert into storage.buckets (id, name, public)
values ('user-files', 'user-files', false)
on conflict (id) do update set public = false;

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('profile-images', 'profile-images', false)
on conflict (id) do update set public = false;

create policy "user can read files in own UID folder"
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'user-files'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  );

create policy "user can upload files in own UID folder"
  on storage.objects for insert to anon, authenticated
  with check (
    bucket_id = 'user-files'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  );

create policy "user can update files in own UID folder"
  on storage.objects for update to anon, authenticated
  using (
    bucket_id = 'user-files'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  )
  with check (
    bucket_id = 'user-files'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  );

create policy "user can delete files in own UID folder"
  on storage.objects for delete to anon, authenticated
  using (
    bucket_id = 'user-files'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  );

create policy "user can upload own product images"
  on storage.objects for insert to anon, authenticated
  with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  );

create policy "user can replace own product images"
  on storage.objects for update to anon, authenticated
  using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  )
  with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  );

create policy "user can delete own product images"
  on storage.objects for delete to anon, authenticated
  using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  );

create policy "user can upload own profile images"
  on storage.objects for insert to anon, authenticated
  with check (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  );

create policy "user can replace own profile images"
  on storage.objects for update to anon, authenticated
  using (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  )
  with check (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  );

create policy "user can delete own profile images"
  on storage.objects for delete to anon, authenticated
  using (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  );

create policy "user can read own profile images"
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
    and (select auth.jwt() ->> 'iss') = 'https://securetoken.google.com/desapay-9918f'
    and (select auth.jwt() ->> 'aud') = 'desapay-9918f'
  );
