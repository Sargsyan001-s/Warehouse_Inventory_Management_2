# Складской учёт (Flutter Web)

## ПР5 — Аутентификация

### Пользователи

| Логин | Пароль | Роль |
|-------|--------|------|
| viewer | viewer123! | Наблюдатель |
| operator | operator1! | Кладовщик |
| admin | admin123! | Администратор |
| masha | masha123! | Наблюдатель (для проверки смены ролей) |

### 1. Сервер

```bash
cd api
npm install
node mock-server.js --port 8080 --origin http://localhost:5555
# короткий TTL для проверки refresh:
node mock-server.js --port 8080 --origin http://localhost:5555 --ttl 60
```

Проверка: http://localhost:8080/api/__health

### 2. Клиент

```bash
flutter pub get
flutter run -d chrome --web-port=5555
# или Edge:
flutter run -d edge --web-port=5555
```

### Пункт 17 (клиент ≠ защита)

1. Войти как `viewer`
2. DevTools → Application → Local Storage → ключ с `auth_user_json`
3. Поменять `"role":"viewer"` на `"role":"admin"`, обновить страницу
4. Кнопки админа могут появиться в UI
5. Операция (например hard delete /admin/stats) → сервер ответит **403**

Другой адрес API:

```bash
flutter run -d chrome --web-port=5555 --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
```

### Проверка ошибок

| Что | Как |
|-----|-----|
| Загрузка | `?__delay=1500` в запросе / остановить сервер |
| Ошибка сети | остановить `mock-server` → Повторить |
| 500 | открыть URL с `__fail=500` через Network или временно в query |
| 422 | создать товар с SKU `BLT-M8-40` |
| 409 | карточка «Уровень 60 см» → «Списать 1 шт» |

### Архитектура

Экраны → Notifier → `*Repository` (интерфейс) → `Api*Repository` + Dio → сервер.

БД в Flutter нет: данные на сервере.
