# Складской учёт (Flutter Web)

## ПР4 — REST API

### 1. Сервер

```bash
cd api
npm install
node mock-server.js --port 8080 --origin http://localhost:5555
```

Проверка: http://localhost:8080/api/__health

### 2. Клиент

```bash
flutter pub get
flutter run -d chrome --web-port=5555
```

Другой адрес API:

```bash
flutter run -d chrome --web-port=5555 --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
```

### Демо ошибок

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
