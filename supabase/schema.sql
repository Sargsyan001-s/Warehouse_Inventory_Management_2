-- =============================================================================
-- Складской учёт — схема PostgreSQL для Supabase (оценка «5»)
-- Выполнить в SQL Editor проекта Supabase целиком.
-- Сущностей ≥ 8; связи: 1:1, 1:N, M:N.
-- =============================================================================

-- Роли приложения
create type public.app_role as enum ('viewer', 'operator', 'admin');

-- 1. Профили (1:1 с auth.users)
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  display_name text not null,
  role public.app_role not null default 'viewer',
  created_at timestamptz not null default now()
);

-- 2. Склады
create table public.warehouses (
  id bigint generated always as identity primary key,
  name text not null check (char_length(name) between 2 and 200),
  code text not null unique check (char_length(code) between 2 and 20),
  address text not null default '',
  city text not null default '',
  deleted_at timestamptz
);

-- 3. Категории
create table public.categories (
  id bigint generated always as identity primary key,
  name text not null check (char_length(name) between 2 and 120),
  description text not null default '',
  deleted_at timestamptz
);

-- 4. Поставщики
create table public.suppliers (
  id bigint generated always as identity primary key,
  name text not null check (char_length(name) between 2 and 200),
  country text not null default '',
  city text not null default '',
  phone text not null default '',
  email text not null default '',
  deleted_at timestamptz
);

-- 5. Товары (N:1 → warehouse)
create table public.products (
  id bigint generated always as identity primary key,
  name text not null check (char_length(name) between 2 and 200),
  sku text not null unique check (char_length(sku) between 3 and 40),
  warehouse_id bigint not null references public.warehouses (id),
  price numeric(12, 2) not null check (price > 0),
  quantity integer not null check (quantity >= 0),
  unit text not null default 'шт' check (char_length(unit) between 1 and 20),
  year_received integer not null check (year_received between 2000 and 2100),
  deleted_at timestamptz
);

-- 6. Сотрудники
create table public.employees (
  id bigint generated always as identity primary key,
  full_name text not null check (char_length(full_name) between 2 and 200),
  email text not null unique,
  phone text not null default '',
  position text not null default '',
  deleted_at timestamptz
);

-- 7. Пропуска (1:1 с employees)
create table public.access_badges (
  id bigint generated always as identity primary key,
  employee_id bigint not null unique references public.employees (id) on delete cascade,
  number text not null unique check (char_length(number) between 3 and 40),
  level text not null check (level in ('обычный', 'ограниченный', 'админ')),
  issued_at date not null default current_date,
  expires_at date
);

-- 8. Движения склада (особенность предметной области / списания)
create table public.stock_movements (
  id bigint generated always as identity primary key,
  product_id bigint not null references public.products (id),
  quantity integer not null check (quantity > 0),
  kind text not null check (kind in ('issue', 'receive')),
  note text not null default '',
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- M:N товар ↔ категория
create table public.product_categories (
  product_id bigint not null references public.products (id) on delete cascade,
  category_id bigint not null references public.categories (id) on delete cascade,
  primary key (product_id, category_id)
);

-- M:N товар ↔ поставщик
create table public.product_suppliers (
  product_id bigint not null references public.products (id) on delete cascade,
  supplier_id bigint not null references public.suppliers (id) on delete cascade,
  primary key (product_id, supplier_id)
);

-- M:N склад ↔ категория (ограничение ассортимента склада)
create table public.warehouse_categories (
  warehouse_id bigint not null references public.warehouses (id) on delete cascade,
  category_id bigint not null references public.categories (id) on delete cascade,
  primary key (warehouse_id, category_id)
);

-- Индексы
create index products_warehouse_idx on public.products (warehouse_id);
create index products_deleted_idx on public.products (deleted_at);
create index stock_movements_product_idx on public.stock_movements (product_id);

-- -----------------------------------------------------------------------------
-- Вспомогательные функции ролей
-- -----------------------------------------------------------------------------
create or replace function public.current_role()
returns public.app_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role = 'admin' from public.profiles where id = auth.uid()), false);
$$;

create or replace function public.is_operator_or_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role in ('operator', 'admin') from public.profiles where id = auth.uid()), false);
$$;

-- Профиль при регистрации
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username, display_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    'viewer'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Списание с проверкой остатка (409-аналог через exception)
create or replace function public.issue_product(p_id bigint, p_qty integer default 1, p_note text default '')
returns public.products
language plpgsql
security definer
set search_path = public
as $$
declare
  row public.products;
begin
  if not public.is_operator_or_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select * into row from public.products where id = p_id and deleted_at is null for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if row.quantity < p_qty then
    raise exception 'Недостаточно остатка для списания (доступно: %)', row.quantity
      using errcode = 'P0001';
  end if;
  update public.products set quantity = quantity - p_qty where id = p_id
    returning * into row;
  insert into public.stock_movements (product_id, quantity, kind, note, created_by)
  values (p_id, p_qty, 'issue', p_note, auth.uid());
  return row;
end;
$$;

-- Представление для отчёта стоимости остатков (п.20)
create or replace view public.inventory_valuation as
select
  w.id as warehouse_id,
  w.name as warehouse_name,
  c.id as category_id,
  c.name as category_name,
  count(p.id)::int as product_count,
  coalesce(sum(p.quantity), 0)::int as total_qty,
  coalesce(sum(p.price * p.quantity), 0)::numeric(14, 2) as total_value
from public.warehouses w
left join public.products p on p.warehouse_id = w.id and p.deleted_at is null
left join public.product_categories pc on pc.product_id = p.id
left join public.categories c on c.id = pc.category_id and c.deleted_at is null
where w.deleted_at is null
group by w.id, w.name, c.id, c.name;

-- -----------------------------------------------------------------------------
-- RLS
-- -----------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.warehouses enable row level security;
alter table public.categories enable row level security;
alter table public.suppliers enable row level security;
alter table public.products enable row level security;
alter table public.employees enable row level security;
alter table public.access_badges enable row level security;
alter table public.stock_movements enable row level security;
alter table public.product_categories enable row level security;
alter table public.product_suppliers enable row level security;
alter table public.warehouse_categories enable row level security;

-- profiles
create policy profiles_select on public.profiles for select to authenticated
  using (true);
create policy profiles_update_admin on public.profiles for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- чтение каталога всем авторизованным
create policy wh_select on public.warehouses for select to authenticated using (true);
create policy cat_select on public.categories for select to authenticated using (true);
create policy sup_select on public.suppliers for select to authenticated using (true);
create policy prod_select on public.products for select to authenticated using (true);
create policy emp_select on public.employees for select to authenticated using (true);
create policy badge_select on public.access_badges for select to authenticated using (true);
create policy mov_select on public.stock_movements for select to authenticated using (true);
create policy pc_select on public.product_categories for select to authenticated using (true);
create policy ps_select on public.product_suppliers for select to authenticated using (true);
create policy wc_select on public.warehouse_categories for select to authenticated using (true);

-- запись operator/admin
create policy wh_write on public.warehouses for all to authenticated
  using (public.is_operator_or_admin()) with check (public.is_operator_or_admin());
create policy cat_write on public.categories for all to authenticated
  using (public.is_operator_or_admin()) with check (public.is_operator_or_admin());
create policy sup_write on public.suppliers for all to authenticated
  using (public.is_operator_or_admin()) with check (public.is_operator_or_admin());
create policy prod_write on public.products for all to authenticated
  using (public.is_operator_or_admin()) with check (public.is_operator_or_admin());
create policy emp_write on public.employees for all to authenticated
  using (public.is_operator_or_admin()) with check (public.is_operator_or_admin());
create policy badge_write on public.access_badges for all to authenticated
  using (public.is_operator_or_admin()) with check (public.is_operator_or_admin());
create policy mov_write on public.stock_movements for all to authenticated
  using (public.is_operator_or_admin()) with check (public.is_operator_or_admin());
create policy pc_write on public.product_categories for all to authenticated
  using (public.is_operator_or_admin()) with check (public.is_operator_or_admin());
create policy ps_write on public.product_suppliers for all to authenticated
  using (public.is_operator_or_admin()) with check (public.is_operator_or_admin());
create policy wc_write on public.warehouse_categories for all to authenticated
  using (public.is_operator_or_admin()) with check (public.is_operator_or_admin());

grant usage on schema public to anon, authenticated;
grant select on public.inventory_valuation to authenticated;
grant execute on function public.issue_product(bigint, integer, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Демо-данные (после создания пользователей Auth вручную — см. supabase/README.md)
-- -----------------------------------------------------------------------------
insert into public.warehouses (name, code, address, city) values
  ('Центральный', 'WH-C', 'ул. Складская 1', 'Москва'),
  ('Северный', 'WH-N', 'пр. Индустриальный 12', 'Санкт-Петербург');

insert into public.categories (name, description) values
  ('Крепёж', 'Болты, гайки, саморезы'),
  ('Инструменты', 'Ручной инструмент'),
  ('Электрика', 'Кабели и арматура');

insert into public.suppliers (name, country, city, phone, email) values
  ('МетизТорг', 'Россия', 'Москва', '+7-495-111-22-33', 'sales@metiz.ru'),
  ('ToolPro', 'Россия', 'Казань', '+7-843-222-33-44', 'info@toolpro.ru');

insert into public.warehouse_categories (warehouse_id, category_id)
select w.id, c.id from public.warehouses w cross join public.categories c;

insert into public.products (name, sku, warehouse_id, price, quantity, unit, year_received) values
  ('Болт М8×40', 'BLT-M8-40', 1, 2.50, 1000, 'шт', 2024),
  ('Гайка М8', 'NUT-M8', 1, 1.20, 2000, 'шт', 2024),
  ('Отвёртка PH2', 'SCR-PH2', 2, 350.00, 40, 'шт', 2025),
  ('Уровень 60 см', 'LVL-60', 2, 890.00, 0, 'шт', 2023);

insert into public.product_categories (product_id, category_id) values
  (1, 1), (2, 1), (3, 2), (4, 2);

insert into public.product_suppliers (product_id, supplier_id) values
  (1, 1), (2, 1), (3, 2), (4, 2);

insert into public.employees (full_name, email, phone, position) values
  ('Иванова Анна', 'anna@warehouse.local', '+7-900-111-22-33', 'Кладовщик'),
  ('Петров Сергей', 'sergey@warehouse.local', '+7-900-222-33-44', 'Старший кладовщик');

insert into public.access_badges (employee_id, number, level, issued_at, expires_at) values
  (1, 'BADGE-001', 'обычный', '2024-01-10', '2027-01-10'),
  (2, 'BADGE-002', 'админ', '2023-06-01', null);
