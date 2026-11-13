-- Shared data model for Service Book.
-- Apply with `supabase db push` or paste into the Supabase SQL editor.

create extension if not exists pgcrypto;
create extension if not exists btree_gist;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text not null unique,
  display_name text not null,
  role text not null default 'guest'
    check (role in ('guest', 'admin', 'chef', 'waiter', 'cook', 'bartender')),
  restaurant_id text,
  favorite_restaurant_ids text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.restaurants (
  id text primary key,
  owner_id uuid not null references public.profiles(id),
  name text not null,
  city text not null,
  address text not null default '',
  description text not null default '',
  cuisine text not null,
  phone text not null,
  open_minutes integer not null check (open_minutes between 0 and 1439),
  close_minutes integer not null check (close_minutes between 0 and 1439),
  timezone text not null default 'Asia/Almaty',
  photos text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.dining_tables (
  id text primary key,
  restaurant_id text not null references public.restaurants(id) on delete cascade,
  number integer not null check (number > 0),
  seats integer not null check (seats > 0),
  zone text not null check (zone in ('hall', 'cabin', 'terrace')),
  occupied boolean not null default false,
  guests integer not null default 0 check (guests >= 0),
  since timestamptz,
  unique (restaurant_id, number),
  unique (id, restaurant_id)
);

create table if not exists public.dishes (
  id text primary key,
  restaurant_id text not null references public.restaurants(id) on delete cascade,
  name text not null,
  price integer not null check (price >= 0),
  category text not null check (category in ('starters', 'mains', 'drinks', 'desserts')),
  description text not null default '',
  available boolean not null default true
);

create table if not exists public.reservations (
  id text primary key,
  restaurant_id text not null references public.restaurants(id),
  table_id text not null references public.dining_tables(id),
  user_id uuid not null references public.profiles(id),
  guest_name text not null,
  phone text not null,
  starts_at timestamptz not null,
  ends_at timestamptz generated always as (starts_at + interval '120 minutes') stored,
  guests integer not null check (guests > 0),
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'seated', 'completed', 'cancelled')),
  comment text not null default '',
  created_at timestamptz not null default now(),
  check (ends_at > starts_at),
  constraint reservation_table_matches_restaurant
    foreign key (table_id, restaurant_id)
    references public.dining_tables(id, restaurant_id)
);

alter table public.reservations
  add constraint no_overlapping_active_reservations
  exclude using gist (
    table_id with =,
    tstzrange(starts_at, ends_at, '[)') with &&
  ) where (status in ('pending', 'confirmed', 'seated'));

create index if not exists reservations_user_start_idx
  on public.reservations(user_id, starts_at desc);
create index if not exists reservations_restaurant_start_idx
  on public.reservations(restaurant_id, starts_at);

create table if not exists public.orders (
  id text primary key,
  restaurant_id text not null references public.restaurants(id),
  table_id text references public.dining_tables(id),
  reservation_id text references public.reservations(id),
  created_by_id uuid not null references public.profiles(id),
  created_by_name text not null,
  items jsonb not null default '[]'::jsonb check (jsonb_typeof(items) = 'array'),
  status text not null default 'fresh'
    check (status in ('fresh', 'cooking', 'ready', 'served', 'paid', 'cancelled')),
  comment text not null default '',
  created_at timestamptz not null default now(),
  for_time timestamptz,
  paid_at timestamptz
);

create table if not exists public.reviews (
  id text primary key,
  restaurant_id text not null references public.restaurants(id) on delete cascade,
  reservation_id text not null unique references public.reservations(id),
  user_id uuid not null references public.profiles(id),
  user_name text not null,
  stars integer not null check (stars between 1 and 5),
  text text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.service_entries (
  id text primary key,
  restaurant_id text not null references public.restaurants(id) on delete cascade,
  title text not null,
  description text not null default '',
  worker_name text not null,
  worker_role text not null,
  category text not null,
  entry_date timestamptz not null,
  resolved boolean not null default false
);

create table if not exists public.checklist_items (
  id text primary key,
  restaurant_id text not null references public.restaurants(id) on delete cascade,
  title text not null,
  type text not null check (type in ('opening', 'closing')),
  done_by text,
  done_at timestamptz
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android', 'ios', 'web')),
  updated_at timestamptz not null default now()
);

create or replace function public.current_role()
returns text language sql stable security definer set search_path = public
as $$ select role from public.profiles where id = auth.uid() $$;

create or replace function public.current_restaurant_id()
returns text language sql stable security definer set search_path = public
as $$ select restaurant_id from public.profiles where id = auth.uid() $$;

create or replace function public.can_manage_restaurant(target_id text)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and restaurant_id = target_id
      and role in ('admin', 'chef')
  )
$$;

create or replace function public.can_serve_restaurant(target_id text)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and restaurant_id = target_id
      and role in ('admin', 'chef', 'waiter')
  )
$$;

create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles(id, phone, display_name)
  values (
    new.id,
    coalesce(new.phone, ''),
    coalesce(new.raw_user_meta_data ->> 'display_name', '')
  )
  on conflict (id) do update set
    phone = excluded.phone,
    display_name = coalesce(nullif(excluded.display_name, ''), profiles.display_name);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert or update of phone on auth.users
  for each row execute function public.handle_new_auth_user();

create or replace function public.register_restaurant(
  p_restaurant_id text,
  p_name text,
  p_city text,
  p_address text,
  p_description text,
  p_cuisine text,
  p_phone text,
  p_open_minutes integer,
  p_close_minutes integer,
  p_tables_count integer
)
returns text language plpgsql security definer set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if p_tables_count < 1 or p_tables_count > 200 then
    raise exception 'Table count must be between 1 and 200';
  end if;
  if p_open_minutes not between 0 and 1439
     or p_close_minutes not between 0 and 1439
     or p_open_minutes = p_close_minutes then
    raise exception 'Invalid restaurant opening hours';
  end if;
  if exists (select 1 from public.profiles where id = v_user_id and role <> 'guest') then
    raise exception 'This account already owns a restaurant or staff role';
  end if;

  insert into public.restaurants(
    id, owner_id, name, city, address, description, cuisine, phone,
    open_minutes, close_minutes
  ) values (
    p_restaurant_id, v_user_id, trim(p_name), trim(p_city), trim(p_address),
    trim(p_description), trim(p_cuisine), trim(p_phone),
    p_open_minutes, p_close_minutes
  );
  update public.profiles
    set role = 'admin', restaurant_id = p_restaurant_id
    where id = v_user_id;
  insert into public.dining_tables(id, restaurant_id, number, seats, zone)
    select p_restaurant_id || '_' || n, p_restaurant_id, n, 4, 'hall'
    from generate_series(1, p_tables_count) as n;
  return p_restaurant_id;
end;
$$;

create or replace function public.create_reservation(
  p_id text,
  p_restaurant_id text,
  p_table_id text,
  p_starts_at timestamptz,
  p_guests integer,
  p_comment text default '',
  p_items jsonb default '[]'::jsonb
)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_profile public.profiles%rowtype;
  v_restaurant public.restaurants%rowtype;
  v_table public.dining_tables%rowtype;
  v_local_start timestamp;
  v_local_minutes integer;
  v_service_day date;
  v_offset integer;
  v_close_extended integer;
  v_items jsonb := '[]'::jsonb;
  v_item jsonb;
  v_dish public.dishes%rowtype;
  v_qty integer;
  v_order_id text;
  v_reservation public.reservations%rowtype;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  select * into v_profile from public.profiles where id = v_user_id;
  if not found or v_profile.role <> 'guest' then
    raise exception 'Only guest accounts can create reservations';
  end if;
  select * into v_restaurant from public.restaurants where id = p_restaurant_id;
  if not found then raise exception 'Restaurant not found'; end if;
  select * into v_table from public.dining_tables
    where id = p_table_id and restaurant_id = p_restaurant_id
    for update;
  if not found then raise exception 'Table does not belong to this restaurant'; end if;
  if p_guests < 1 or p_guests > v_table.seats then
    raise exception 'Guest count exceeds table capacity';
  end if;
  if p_starts_at < now() + interval '30 minutes' then
    raise exception 'Reservation must be at least 30 minutes in the future';
  end if;
  if v_table.occupied and p_starts_at < now() + interval '120 minutes' then
    raise exception 'Table is currently occupied';
  end if;

  v_local_start := p_starts_at at time zone v_restaurant.timezone;
  v_local_minutes := extract(hour from v_local_start)::integer * 60
    + extract(minute from v_local_start)::integer;
  v_service_day := v_local_start::date;
  v_close_extended := v_restaurant.close_minutes;
  if v_restaurant.close_minutes <= v_restaurant.open_minutes then
    v_close_extended := v_close_extended + 1440;
    if v_local_minutes < v_restaurant.close_minutes then
      v_service_day := v_service_day - 1;
      v_offset := v_local_minutes + 1440 - v_restaurant.open_minutes;
    else
      v_offset := v_local_minutes - v_restaurant.open_minutes;
    end if;
  else
    v_offset := v_local_minutes - v_restaurant.open_minutes;
  end if;
  if v_offset < 0
     or mod(v_offset, 30) <> 0
     or v_restaurant.open_minutes + v_offset + 120 > v_close_extended then
    raise exception 'Reservation time is outside opening hours';
  end if;

  if jsonb_typeof(p_items) <> 'array' then
    raise exception 'Preorder items must be an array';
  end if;
  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_qty := (v_item ->> 'qty')::integer;
    if v_qty < 1 then raise exception 'Item quantity must be positive'; end if;
    select * into v_dish from public.dishes
      where id = v_item ->> 'dishId'
        and restaurant_id = p_restaurant_id
        and available;
    if not found then raise exception 'A preorder dish is unavailable'; end if;
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'dishId', v_dish.id, 'name', v_dish.name, 'price', v_dish.price, 'qty', v_qty
    ));
  end loop;

  insert into public.reservations(
    id, restaurant_id, table_id, user_id, guest_name, phone,
    starts_at, guests, comment
  ) values (
    p_id, p_restaurant_id, p_table_id, v_user_id,
    v_profile.display_name, v_profile.phone,
    p_starts_at, p_guests, coalesce(p_comment, '')
  ) returning * into v_reservation;

  if jsonb_array_length(v_items) > 0 then
    v_order_id := gen_random_uuid()::text;
    insert into public.orders(
      id, restaurant_id, table_id, reservation_id, created_by_id,
      created_by_name, items, status, comment, for_time
    ) values (
      v_order_id, p_restaurant_id, p_table_id, p_id, v_user_id,
      v_profile.display_name, v_items, 'fresh', 'Preorder for reservation', p_starts_at
    );
  end if;
  return to_jsonb(v_reservation);
exception
  when exclusion_violation then
    raise exception 'This table is already reserved for that time';
end;
$$;

create or replace function public.cancel_reservation(p_id text)
returns void language plpgsql security definer set search_path = public
as $$
declare v_reservation public.reservations%rowtype;
begin
  select * into v_reservation from public.reservations where id = p_id for update;
  if not found then return; end if;
  if v_reservation.user_id <> auth.uid()
     and not public.can_serve_restaurant(v_reservation.restaurant_id) then
    raise exception 'Not allowed to cancel this reservation';
  end if;
  if v_reservation.status not in ('pending', 'confirmed') then
    raise exception 'Only pending or confirmed reservations can be cancelled';
  end if;
  update public.reservations set status = 'cancelled' where id = p_id;
  update public.orders set status = 'cancelled'
    where reservation_id = p_id and status not in ('paid', 'cancelled');
end;
$$;

create or replace function public.confirm_reservation(p_id text)
returns void language plpgsql security definer set search_path = public
as $$
declare v_reservation public.reservations%rowtype;
begin
  select * into v_reservation from public.reservations where id = p_id for update;
  if not found then raise exception 'Reservation not found'; end if;
  if not public.can_serve_restaurant(v_reservation.restaurant_id) then
    raise exception 'Not allowed to confirm this reservation';
  end if;
  if v_reservation.status <> 'pending' then
    raise exception 'Only pending reservations can be confirmed';
  end if;
  update public.reservations set status = 'confirmed' where id = p_id;
end;
$$;

create or replace function public.seat_reservation(p_id text)
returns void language plpgsql security definer set search_path = public
as $$
declare
  v_reservation public.reservations%rowtype;
  v_table public.dining_tables%rowtype;
begin
  select * into v_reservation from public.reservations where id = p_id for update;
  if not found then raise exception 'Reservation not found'; end if;
  if not public.can_serve_restaurant(v_reservation.restaurant_id) then
    raise exception 'Not allowed to seat this reservation';
  end if;
  if v_reservation.status <> 'confirmed' then
    raise exception 'Only confirmed reservations can be seated';
  end if;
  select * into v_table from public.dining_tables where id = v_reservation.table_id for update;
  if v_table.occupied then raise exception 'Table is already occupied'; end if;
  if v_table.seats < v_reservation.guests then raise exception 'Table capacity is too small'; end if;
  update public.dining_tables
    set occupied = true, guests = v_reservation.guests, since = now()
    where id = v_table.id;
  update public.reservations set status = 'seated' where id = p_id;
end;
$$;

create or replace function public.toggle_favorite(p_restaurant_id text)
returns text[] language plpgsql security definer set search_path = public
as $$
declare v_favorites text[];
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not exists (select 1 from public.restaurants where id = p_restaurant_id) then
    raise exception 'Restaurant not found';
  end if;
  update public.profiles
    set favorite_restaurant_ids = case
      when p_restaurant_id = any(favorite_restaurant_ids)
        then array_remove(favorite_restaurant_ids, p_restaurant_id)
      else array_append(favorite_restaurant_ids, p_restaurant_id)
    end
    where id = auth.uid()
    returning favorite_restaurant_ids into v_favorites;
  return v_favorites;
end;
$$;

create or replace function public.notify_reservation_changes()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.notifications(recipient_id, title, body, data)
    select p.id, 'New reservation request', new.guest_name || ' requested a table',
      jsonb_build_object('reservationId', new.id, 'event', 'reservation_created')
    from public.profiles p
    where p.restaurant_id = new.restaurant_id
      and p.role in ('admin', 'chef', 'waiter');
    return new;
  end if;
  if new.status is distinct from old.status then
    insert into public.notifications(recipient_id, title, body, data)
    values (
      new.user_id,
      'Reservation updated',
      'Your reservation status is ' || new.status,
      jsonb_build_object('reservationId', new.id, 'event', 'reservation_' || new.status)
    );
  end if;
  return new;
end;
$$;

drop trigger if exists reservation_notifications on public.reservations;
create trigger reservation_notifications
  after insert or update of status on public.reservations
  for each row execute function public.notify_reservation_changes();

alter table public.profiles enable row level security;
alter table public.restaurants enable row level security;
alter table public.dining_tables enable row level security;
alter table public.dishes enable row level security;
alter table public.reservations enable row level security;
alter table public.orders enable row level security;
alter table public.reviews enable row level security;
alter table public.service_entries enable row level security;
alter table public.checklist_items enable row level security;
alter table public.notifications enable row level security;
alter table public.device_tokens enable row level security;

create policy profiles_read_self_or_team on public.profiles
  for select to authenticated
  using (id = auth.uid() or restaurant_id = public.current_restaurant_id());
create policy restaurants_read_authenticated on public.restaurants
  for select to authenticated using (true);
create policy restaurants_insert_owner on public.restaurants
  for insert to authenticated with check (owner_id = auth.uid());
create policy restaurants_update_manager on public.restaurants
  for update to authenticated using (public.can_manage_restaurant(id))
  with check (public.can_manage_restaurant(id));
create policy tables_read_authenticated on public.dining_tables
  for select to authenticated using (true);
create policy tables_manage_restaurant on public.dining_tables
  for all to authenticated using (public.can_manage_restaurant(restaurant_id))
  with check (public.can_manage_restaurant(restaurant_id));
create policy dishes_read_authenticated on public.dishes
  for select to authenticated using (true);
create policy dishes_manage_restaurant on public.dishes
  for all to authenticated using (public.can_manage_restaurant(restaurant_id))
  with check (public.can_manage_restaurant(restaurant_id));
create policy reservations_read_guest_or_team on public.reservations
  for select to authenticated
  using (user_id = auth.uid() or public.can_serve_restaurant(restaurant_id));
create policy orders_read_guest_or_team on public.orders
  for select to authenticated
  using (
    created_by_id = auth.uid()
    or public.can_serve_restaurant(restaurant_id)
  );
create policy orders_update_service_team on public.orders
  for update to authenticated using (public.can_serve_restaurant(restaurant_id))
  with check (public.can_serve_restaurant(restaurant_id));
create policy reviews_read_authenticated on public.reviews
  for select to authenticated using (true);
create policy reviews_insert_completed_booking on public.reviews
  for insert to authenticated with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.reservations r
      where r.id = reservation_id and r.user_id = auth.uid()
        and r.restaurant_id = restaurant_id and r.status = 'completed'
    )
  );
create policy service_entries_team on public.service_entries
  for all to authenticated using (public.can_serve_restaurant(restaurant_id))
  with check (public.can_serve_restaurant(restaurant_id));
create policy checklist_team on public.checklist_items
  for all to authenticated using (public.can_serve_restaurant(restaurant_id))
  with check (public.can_serve_restaurant(restaurant_id));
create policy notifications_read_own on public.notifications
  for select to authenticated using (recipient_id = auth.uid());
create policy notifications_update_own on public.notifications
  for update to authenticated using (recipient_id = auth.uid())
  with check (recipient_id = auth.uid());
create policy device_tokens_manage_own on public.device_tokens
  for all to authenticated using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select on public.profiles to authenticated;
grant update (display_name, phone, favorite_restaurant_ids) on public.profiles to authenticated;
grant select on public.restaurants, public.dining_tables, public.dishes,
  public.reservations, public.orders, public.reviews, public.service_entries,
  public.checklist_items, public.notifications, public.device_tokens to authenticated;
grant insert, update, delete on public.dining_tables, public.dishes,
  public.service_entries, public.checklist_items to authenticated;
grant update on public.orders, public.notifications to authenticated;
grant insert on public.reviews to authenticated;
revoke execute on function public.register_restaurant(text, text, text, text, text, text, text, integer, integer, integer) from public, anon;
revoke execute on function public.create_reservation(text, text, text, timestamptz, integer, text, jsonb) from public, anon;
revoke execute on function public.cancel_reservation(text) from public, anon;
revoke execute on function public.confirm_reservation(text) from public, anon;
revoke execute on function public.seat_reservation(text) from public, anon;
revoke execute on function public.toggle_favorite(text) from public, anon;
grant execute on function public.register_restaurant(text, text, text, text, text, text, text, integer, integer, integer) to authenticated;
grant execute on function public.create_reservation(text, text, text, timestamptz, integer, text, jsonb) to authenticated;
grant execute on function public.cancel_reservation(text) to authenticated;
grant execute on function public.confirm_reservation(text) to authenticated;
grant execute on function public.seat_reservation(text) to authenticated;
grant execute on function public.toggle_favorite(text) to authenticated;
