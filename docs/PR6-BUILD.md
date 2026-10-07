# ПР6 — Сборка, публикация, тесты

## Цель

Довести веб-клиент складского учёта до состояния, пригодного к показу: адаптивная вёрстка на ширинах 360–1920, релизная сборка, публикация и покрытие тестами.

## Адаптив

| Ширина | Поведение |
|--------|-----------|
| 360 | нижняя горизонтальная навигация, списки карточками |
| 768 | `NavigationRail` с подписью у выбранного пункта |
| 1280 | таблицы вместо карточек, подписи у всех пунктов rail |
| 1920 | контент ограничен `maxWidth: 1400` (`ContentWidth`) |

Реализация: `lib/core/breakpoints.dart`, `lib/widgets/content_width.dart`, оболочки в `lib/router.dart`.

## Сборка

```bash
# Обычная релизная (JS)
flutter build web --release \
  --base-href /Warehouse_Inventory_Management_2/ \
  --dart-define=API_BASE_URL=http://localhost:8080/api

# WebAssembly (+ JS fallback)
flutter build web --release --wasm \
  --base-href /Warehouse_Inventory_Management_2/ \
  --dart-define=API_BASE_URL=http://localhost:8080/api

# Прямые ссылки на GitHub Pages
cp build/web/index.html build/web/404.html
```

Локальная проверка: `cd build/web && python -m http.server 8000` → http://localhost:8000

Адрес API задаётся только через `--dart-define=API_BASE_URL` (`lib/core/config.dart`).

## Хостинг (GitHub Pages)

1. Settings → Pages → Source: **GitHub Actions**.
2. Workflow: `.github/workflows/deploy-web.yml` (push в `main`).
3. `404.html` = копия `index.html` — обновление `/products` и др. без 404.
4. Mixed content: страница HTTPS не ходит на HTTP API; для демо API нужен HTTPS либо локальный клиент.

Публичный URL:  
https://sargsyan001-s.github.io/Warehouse_Inventory_Management_2/

Переменная репозитория (опционально): `API_BASE_URL` (Settings → Variables).

## Сравнение размеров сборки

Измерения каталога `build/web` (PowerShell: сумма Length файлов).

| Вариант | Размер каталога | Основной артефакт |
|---------|-----------------|-------------------|
| JS release | **35,6 МБ** | `main.dart.js` ≈ 2,95 МБ |
| WASM release (`--wasm`) | **38,2 МБ** | `main.dart.wasm` ≈ 2,57 МБ + JS fallback 2,95 МБ |

Большую часть каталога занимает CanvasKit/Skwasm (`canvaskit/*.wasm`). Браузер с WasmGC загружает WASM, остальные — JS.

### Оптимизация (до / после)

| Что | До | После | За счёт чего |
|-----|----|-------|--------------|
| Шрифт Material Icons | 1 645 184 байт | **12 020 байт (−99,3 %)** | tree-shake иконок в `--release` |
| Редкие разделы (admin/users, stats, viewer) | в общем бандле | отдельные `main.dart.js_*.part.js` | `deferred as` в `deferred_admin.dart` |
| Зависимости | — | только provider, go_router, dio, shared_preferences | без лишних пакетов и веб-шрифтов |
| Splash | белый экран | заглушка «Складской учёт» | правка `web/index.html` |

Время первой загрузки зависит от сети и кэша CDN CanvasKit; для отчёта зафиксируйте в DevTools → Network время до `flutter-first-frame` для JS и WASM на одной машине.

## Тесты

```bash
flutter test
flutter analyze
dart format --set-exit-if-changed lib test
```

### Модульные (≥ 8)

| Файл | Что проверяет |
|------|----------------|
| `validators_test.dart` | required, integer, цена, email, пароль |
| `models_parse_test.dart` | Product/AppUser/Supplier из неполного JSON |
| `permissions_test.dart` | роли viewer/operator/admin |
| `api_product_repository_test.dart` | разбор API, 422, сеть, DELETE |

### Виджеты (≥ 5)

| Файл | Что проверяет |
|------|----------------|
| `list_state_body_test.dart` | loading, пустой список, ошибка + «Повторить» |
| `login_form_test.dart` | валидация формы входа |
| `role_ui_test.dart` | скрытие админских кнопок у viewer / показ у admin |

## Доступность и офлайн

- У кнопок-иконок заданы `tooltip` (навигация, действия в таблицах).
- Нижняя навигация на узком экране прокручивается, у пунктов есть подсказки.
- При недоступности API `ListStateBody` показывает «Нет связи с сервером» и кнопку **Повторить** без перезагрузки страницы.
