# API — Складской учёт

Базовый URL: `http://localhost:8080/api`  
Клиент: `http://localhost:5555` 

## 2. Аутентификация

| Метод | Путь | Описание |
|-------|------|----------|
| POST | `/auth/login` | вход |
| POST | `/auth/register` | регистрация (роль viewer) |
| POST | `/auth/refresh` | обновление токена |
| GET | `/auth/me` | текущий пользователь |

Учётные записи: `viewer/viewer123!`, `operator/operator1!`, `admin/admin123!`, `masha/masha123!` (viewer, для проверки смены ролей).  
Роли: viewer &lt; operator &lt; admin. Параметр сервера `--ttl 60`.

| Метод | Путь | Роль | Описание |
|-------|------|------|----------|
| GET | `/admin/users` | admin | список пользователей |
| PUT / PATCH | `/admin/users/:id/role` | admin | смена роли (`{"role":"viewer\|operator\|admin"}`) |
| GET | `/admin/stats` | admin | сводная статистика |
| GET | `/viewer/requests` | viewer | заявки наблюдателя |

## Служебные

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/__health` | Проверка сервера |
| GET | `/meta/sku-unique?sku=&excludeId=` | Уникальность артикула |
| GET | `/meta/email-unique?email=&excludeId=` | Уникальность email |
| GET | `/meta/count-by-warehouse?warehouseId=` | Число товаров на складе |

Параметры диагностики: `?__delay=1500`, `?__fail=500`.

## Ресурсы

`/products`, `/suppliers`, `/categories`, `/warehouses`, `/employees`

Для каждого:

- `GET /` — список (`search`, `sort`, `page`, `size`, `includeDeleted`, фильтры)
- `GET /:id` — карточка
- `POST /` — создание
- `PUT /:id` — изменение
- `DELETE /:id` — soft delete; `?hard=true` — физическое
- `POST /:id/restore` — восстановление
- `POST /bulk-delete` — `{ "ids": [...] }` → `{ "deleted": n }`

Дополнительно:

- `POST /products/:id/issue` — списание; **409**, если остатка недостаточно
- `DELETE /warehouses/:id?hard=true` — **409**, если на складе есть товары
- создание товара с занятым SKU — **422** `{ errors: { sku: "..." } }`

Ответ списка:

```json
{ "items": [], "page": 1, "size": 10, "total": 24 }
```
