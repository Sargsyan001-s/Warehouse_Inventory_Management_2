# API — Складской учёт

Базовый URL: `http://localhost:8080/api`  
Клиент: `http://localhost:5555` 

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
