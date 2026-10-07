# Складской учёт (Flutter Web)

## Supabase + GitHub Pages

Чтобы сайт открывался **только по ссылке** и работал с БД:

1. SQL: [supabase/schema.sql](supabase/schema.sql) в SQL Editor.
2. Пользователи Auth + роли — см. [supabase/README.md](supabase/README.md).
3. GitHub → **Settings → Secrets → Actions**:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`  
   (взять в Supabase → Project Settings → API).
4. Supabase → Authentication → URL Configuration → Site URL =  
   `https://sargsyan001-s.github.io/Warehouse_Inventory_Management_2/`
5. Push в `main` → Actions соберёт сайт с этими ключами.

Ссылка: https://sargsyan001-s.github.io/Warehouse_Inventory_Management_2/

Локально без облака — mock API; с облаком — те же `--dart-define=SUPABASE_*`.  
Особенность п.20: раздел **Остатки ₽**.

## ПР5 — Аутентификация

### Пользователи

| Логин | Пароль | Роль |
|-------|--------|------|
| viewer | viewer123! | Наблюдатель |
| operator | operator1! | Кладовщик |
| admin | admin123! | Администратор |
| masha | masha123! | Наблюдатель (для проверки смены ролей) |

### Запуск

```bash
# API
cd api
npm install
node mock-server.js --port 8080 --origin http://localhost:5555

# Клиент
flutter pub get
flutter run -d chrome --web-port=5555
```

Проверка API: http://localhost:8080/api/__health

### Пункт 17 (клиент ≠ защита)

1. Войти как `viewer`
2. DevTools → Application → Local Storage → `auth_user_json`
3. Поменять `"role":"viewer"` на `"role":"admin"`, обновить страницу
4. Кнопки админа могут появиться в UI
5. Операция (hard delete / admin/stats) → сервер ответит **403**

---

## ПР6 — Адаптив, сборка, публикация, тесты

Подробности: [docs/PR6-BUILD.md](docs/PR6-BUILD.md)

### Адаптив

| Ширина | Раскладка |
|--------|-----------|
| 360 | нижняя навигация, карточки |
| 768 | NavigationRail, подпись у выбранного |
| 1280 | таблицы, подписи у всех пунктов rail |
| 1920 | контент ограничен `maxWidth: 1400` |

### Сборка и публикация

```bash
flutter build web --release \
  --base-href /Warehouse_Inventory_Management_2/ \
  --dart-define=API_BASE_URL=http://localhost:8080/api

cp build/web/index.html build/web/404.html
```

Wasm: `flutter build web --release --wasm --base-href /Warehouse_Inventory_Management_2/`

| Сборка | Размер `build/web` | Основной файл |
|--------|--------------------|---------------|
| JS `--release` | 35,6 МБ | `main.dart.js` ≈ 2,95 МБ |
| `--wasm` | 38,2 МБ | `main.dart.wasm` ≈ 2,57 МБ (+ JS fallback) |
| Icons tree-shake | 1,6 МБ → 12 КБ | −99,3 % |

Автосборка: `.github/workflows/deploy-web.yml` (push в `main` → GitHub Pages).

Опубликованное приложение:  
https://sargsyan001-s.github.io/Warehouse_Inventory_Management_2/

### Проверки качества

```bash
flutter analyze
dart format --set-exit-if-changed lib test
flutter test
```

### Архитектура

Экраны → Notifier → `*Repository` → `Api*Repository` + Dio → сервер.

БД в Flutter нет: данные на сервере. Адрес API — только `--dart-define=API_BASE_URL`.
