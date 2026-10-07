# Подключение Supabase (облачная PostgreSQL)

## 1. В панели Supabase

1. Откройте проект → **SQL Editor** → New query.
2. Вставьте содержимое [`schema.sql`](schema.sql) и нажмите **Run**.
3. **Authentication → Providers → Email**: включите Email; для учебного демо отключите «Confirm email».
4. **Settings → API**: скопируйте **Project URL** и **anon public** key.

## 2. Демо-пользователи

В **Authentication → Users → Add user** создайте (пароли с цифрой и спецсимволом):

| Email | Password | Затем в SQL |
|-------|----------|-------------|
| `admin@warehouse.local` | `admin123!` | см. ниже |
| `operator@warehouse.local` | `operator1!` | |
| `viewer@warehouse.local` | `viewer123!` | |

После создания пользователей выполните в SQL Editor:

```sql
update public.profiles set role = 'admin', username = 'admin', display_name = 'Админ Системы'
  where id = (select id from auth.users where email = 'admin@warehouse.local');
update public.profiles set role = 'operator', username = 'operator', display_name = 'Ольга Кладовщик'
  where id = (select id from auth.users where email = 'operator@warehouse.local');
update public.profiles set role = 'viewer', username = 'viewer', display_name = 'Иван Просмотр'
  where id = (select id from auth.users where email = 'viewer@warehouse.local');
```

В приложении логин: `admin` / `admin123!` (к email добавится `@warehouse.local`).

## 3. Связать с GitHub Pages (чтобы работало только по ссылке)

Сайт: https://sargsyan001-s.github.io/Warehouse_Inventory_Management_2/

Ключи **нельзя** хранить в коде — их передают при сборке.

### A. Ключи из Supabase

1. Открой карточку проекта **Sargsyan001-s's Project**.
2. Шестерёнка **Project Settings** → **API**.
3. Скопируй:
   - **Project URL** → это `SUPABASE_URL`
   - **anon public** → это `SUPABASE_ANON_KEY`

### B. Secrets в GitHub

Репозиторий → **Settings → Secrets and variables → Actions → New repository secret**:

| Name | Value |
|------|--------|
| `SUPABASE_URL` | `https://xxxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | длинный `eyJ...` |

### C. Auth URL в Supabase

**Authentication → URL Configuration**:

- **Site URL:** `https://sargsyan001-s.github.io/Warehouse_Inventory_Management_2/`
- **Redirect URLs** добавь ту же ссылку (и при необходимости `http://localhost:5555/**`).

### D. Пересобрать сайт

После сохранения secrets: push в `main` или **Actions → Build and deploy web → Run workflow**.  
Когда job зелёный — открой ссылку Pages: логин уже ходит в облачную БД, локальный mock не нужен.

## 4. Локальный запуск с Supabase

```bash
flutter run -d chrome --web-port=5555 \
  --dart-define=SUPABASE_URL=https://XXXX.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

Без этих флагов приложение работает с локальным mock API (`api/mock-server.js`).

## 4. Сущности и связи (для отчёта)

| # | Таблица | Связь |
|---|--------|--------|
| 1 | profiles | 1:1 с auth.users |
| 2 | warehouses | — |
| 3 | categories | — |
| 4 | suppliers | — |
| 5 | products | N:1 → warehouses |
| 6 | employees | — |
| 7 | access_badges | **1:1** → employees |
| 8 | stock_movements | N:1 → products |
| 9 | product_categories | **M:N** products↔categories |
| 10 | product_suppliers | **M:N** products↔suppliers |
| 11 | warehouse_categories | **M:N** warehouses↔categories |

Особенность п.20: представление `inventory_valuation` и экран **Остатки ₽** (стоимость остатков + диаграмма по складам).
