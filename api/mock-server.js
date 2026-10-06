#!/usr/bin/env node
const express = require('express');
const cors = require('cors');
const { createAuth } = require('./auth');

function arg(name, fallback) {
  const i = process.argv.indexOf(`--${name}`);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}

const port = Number(arg('port', '8080'));
const origin = arg('origin', 'http://localhost:5555');
const ttlSeconds = Number(arg('ttl', '900'));

const app = express();
app.use(
  cors({
    origin,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }),
);
app.use(express.json());

app.use(async (req, res, next) => {
  const delay = Number(req.query.__delay || 0);
  if (delay > 0) await new Promise((r) => setTimeout(r, delay));
  const fail = req.query.__fail;
  if (fail) {
    const code = Number(fail) || 500;
    return res.status(code).json({ message: `Принудительная ошибка ${code}` });
  }
  next();
});

const auth = createAuth({ app, ttlSeconds });
const { authRequired, requireRole } = auth;

function clone(v) {
  return JSON.parse(JSON.stringify(v));
}

let categories = [
  { id: 1, name: 'Крепёж', description: 'Болты, гайки, саморезы', deletedAt: null },
  { id: 2, name: 'Инструменты', description: 'Ручной и измерительный инструмент', deletedAt: null },
  { id: 3, name: 'Электрика', description: 'Кабели, розетки, автоматы', deletedAt: null },
  { id: 4, name: 'Сантехника', description: 'Трубы, фитинги, краны', deletedAt: null },
  { id: 5, name: 'Упаковка', description: 'Коробки, плёнка, скотч', deletedAt: null },
];

let warehouses = [
  { id: 1, name: 'Склад Центральный', code: 'WH-C01', address: 'ул. Складская, 1', city: 'Москва', categoryIds: [1, 2, 3], deletedAt: null },
  { id: 2, name: 'Склад Север', code: 'WH-N02', address: 'пр. Индустриальный, 15', city: 'Санкт-Петербург', categoryIds: [1, 4, 5], deletedAt: null },
  { id: 3, name: 'Склад Юг', code: 'WH-S03', address: 'ул. Портовая, 8', city: 'Краснодар', categoryIds: [2, 3, 5], deletedAt: null },
  { id: 4, name: 'Склад Урал', code: 'WH-U04', address: 'ул. Заводская, 42', city: 'Екатеринбург', categoryIds: [1, 2, 4], deletedAt: null },
];

let suppliers = [
  { id: 1, name: 'МеталлПром', country: 'Россия', city: 'Москва', phone: '+7 495 111-11-11', email: 'info@metallprom.ru', deletedAt: null },
  { id: 2, name: 'ToolMaster', country: 'Германия', city: 'Берлин', phone: '+49 30 222-22', email: 'sales@toolmaster.de', deletedAt: null },
  { id: 3, name: 'ElectroSupply', country: 'Китай', city: 'Шэньчжэнь', phone: '+86 755 333', email: 'cn@electrosupply.com', deletedAt: null },
  { id: 4, name: 'СанТехОпт', country: 'Россия', city: 'Санкт-Петербург', phone: '+7 812 444-44-44', email: 'opt@santeh.ru', deletedAt: null },
  { id: 5, name: 'PackLine', country: 'Польша', city: 'Варшава', phone: '+48 22 555-55', email: 'hello@packline.pl', deletedAt: null },
  { id: 6, name: 'NordFix', country: 'Финляндия', city: 'Хельсинки', phone: '+358 9 666', email: 'nord@nordfix.fi', deletedAt: null },
  { id: 7, name: 'УралКреп', country: 'Россия', city: 'Екатеринбург', phone: '+7 343 777-77-77', email: 'ural@krep.ru', deletedAt: null },
  { id: 8, name: 'AsiaParts', country: 'Китай', city: 'Гуанчжоу', phone: '+86 20 888', email: 'parts@asia.cn', deletedAt: null },
  { id: 9, name: 'BalticTrade', country: 'Латвия', city: 'Рига', phone: '+371 67 999', email: 'riga@baltic.lv', deletedAt: null },
  { id: 10, name: 'ЮгСтрой', country: 'Россия', city: 'Краснодар', phone: '+7 861 101-01-01', email: 'yug@stroy.ru', deletedAt: null },
];

let employees = [
  { id: 1, fullName: 'Иванов Пётр Сергеевич', email: 'ivanov@warehouse.ru', phone: '+7 900 111-22-33', position: 'Кладовщик', badge: { number: 'BADGE-001', level: 'обычный', issuedAt: '2024-01-15T00:00:00.000Z', expiresAt: '2027-01-15T00:00:00.000Z' }, deletedAt: null },
  { id: 2, fullName: 'Петрова Анна Викторовна', email: 'petrova@warehouse.ru', phone: '+7 900 222-33-44', position: 'Менеджер склада', badge: { number: 'BADGE-002', level: 'админ', issuedAt: '2023-06-01T00:00:00.000Z', expiresAt: '2026-06-01T00:00:00.000Z' }, deletedAt: null },
  { id: 3, fullName: 'Сидоров Алексей Иванович', email: 'sidorov@warehouse.ru', phone: '+7 900 333-44-55', position: 'Грузчик', badge: { number: 'BADGE-003', level: 'обычный', issuedAt: '2025-03-10T00:00:00.000Z', expiresAt: null }, deletedAt: null },
  { id: 4, fullName: 'Козлова Мария Дмитриевна', email: 'kozlova@warehouse.ru', phone: '+7 900 444-55-66', position: 'Бухгалтер', badge: { number: 'BADGE-004', level: 'ограниченный', issuedAt: '2024-09-01T00:00:00.000Z', expiresAt: '2026-09-01T00:00:00.000Z' }, deletedAt: null },
  { id: 5, fullName: 'Морозов Дмитрий Олегович', email: 'morozov@warehouse.ru', phone: '+7 900 555-66-77', position: 'Начальник смены', badge: { number: 'BADGE-005', level: 'админ', issuedAt: '2022-11-20T00:00:00.000Z', expiresAt: '2027-11-20T00:00:00.000Z' }, deletedAt: null },
];

let products = [
  { id: 1, name: 'Болт М8х40', sku: 'BLT-M8-40', warehouseId: 1, categoryIds: [1], supplierIds: [1, 7], price: 3.5, quantity: 5000, unit: 'шт', yearReceived: 2023, deletedAt: null },
  { id: 2, name: 'Гайка М8', sku: 'NUT-M8', warehouseId: 1, categoryIds: [1], supplierIds: [1], price: 1.2, quantity: 8000, unit: 'шт', yearReceived: 2023, deletedAt: null },
  { id: 3, name: 'Шайба 8 мм', sku: 'WSH-8', warehouseId: 4, categoryIds: [1], supplierIds: [7], price: 0.5, quantity: 10000, unit: 'шт', yearReceived: 2024, deletedAt: null },
  { id: 4, name: 'Саморез 4х50', sku: 'SCR-4-50', warehouseId: 2, categoryIds: [1], supplierIds: [6], price: 0.8, quantity: 12000, unit: 'шт', yearReceived: 2024, deletedAt: null },
  { id: 5, name: 'Дюбель 6х40', sku: 'DUB-6-40', warehouseId: 4, categoryIds: [1], supplierIds: [7], price: 1.5, quantity: 6000, unit: 'шт', yearReceived: 2022, deletedAt: null },
  { id: 6, name: 'Молоток 500 г', sku: 'HAM-500', warehouseId: 1, categoryIds: [2], supplierIds: [2], price: 450, quantity: 80, unit: 'шт', yearReceived: 2023, deletedAt: null },
  { id: 7, name: 'Отвёртка PH2', sku: 'SCRD-PH2', warehouseId: 3, categoryIds: [2], supplierIds: [2, 6], price: 180, quantity: 150, unit: 'шт', yearReceived: 2024, deletedAt: null },
  { id: 8, name: 'Ключ разводной 250', sku: 'WRN-250', warehouseId: 1, categoryIds: [2], supplierIds: [2], price: 620, quantity: 60, unit: 'шт', yearReceived: 2023, deletedAt: null },
  { id: 9, name: 'Рулетка 5 м', sku: 'TPE-5M', warehouseId: 3, categoryIds: [2], supplierIds: [10], price: 220, quantity: 200, unit: 'шт', yearReceived: 2025, deletedAt: null },
  { id: 10, name: 'Плоскогубцы 180', sku: 'PLR-180', warehouseId: 4, categoryIds: [2], supplierIds: [6], price: 350, quantity: 90, unit: 'шт', yearReceived: 2024, deletedAt: null },
  { id: 11, name: 'Кабель ВВГ 3х2.5', sku: 'CBL-VVG-325', warehouseId: 1, categoryIds: [3], supplierIds: [3], price: 85, quantity: 400, unit: 'м', yearReceived: 2024, deletedAt: null },
  { id: 12, name: 'Розетка 16А', sku: 'SOC-16A', warehouseId: 1, categoryIds: [3], supplierIds: [3, 8], price: 95, quantity: 300, unit: 'шт', yearReceived: 2023, deletedAt: null },
  { id: 13, name: 'Выключатель 1-кл', sku: 'SW-1K', warehouseId: 3, categoryIds: [3], supplierIds: [8], price: 70, quantity: 250, unit: 'шт', yearReceived: 2025, deletedAt: null },
  { id: 14, name: 'Автомат C16', sku: 'BRK-C16', warehouseId: 1, categoryIds: [3], supplierIds: [3], price: 310, quantity: 120, unit: 'шт', yearReceived: 2024, deletedAt: null },
  { id: 15, name: 'Лампа LED 10Вт', sku: 'LED-10W', warehouseId: 3, categoryIds: [3], supplierIds: [8], price: 120, quantity: 500, unit: 'шт', yearReceived: 2025, deletedAt: null },
  { id: 16, name: 'Труба ППР 20', sku: 'PPR-20', warehouseId: 2, categoryIds: [4], supplierIds: [4], price: 45, quantity: 350, unit: 'м', yearReceived: 2023, deletedAt: null },
  { id: 17, name: 'Кран шаровой 1/2', sku: 'VLV-12', warehouseId: 2, categoryIds: [4], supplierIds: [4], price: 280, quantity: 180, unit: 'шт', yearReceived: 2024, deletedAt: null },
  { id: 18, name: 'Фитинг уголок 20', sku: 'FIT-20', warehouseId: 4, categoryIds: [4], supplierIds: [4], price: 25, quantity: 700, unit: 'шт', yearReceived: 2022, deletedAt: null },
  { id: 19, name: 'Сифон кухонный', sku: 'SPH-KIT', warehouseId: 2, categoryIds: [4], supplierIds: [10], price: 390, quantity: 70, unit: 'шт', yearReceived: 2025, deletedAt: null },
  { id: 20, name: 'Коробка картонная S', sku: 'BOX-S', warehouseId: 2, categoryIds: [5], supplierIds: [5], price: 15, quantity: 2000, unit: 'шт', yearReceived: 2024, deletedAt: null },
  { id: 21, name: 'Скотч упаковочный', sku: 'TAPE-48', warehouseId: 3, categoryIds: [5], supplierIds: [5], price: 55, quantity: 400, unit: 'шт', yearReceived: 2023, deletedAt: null },
  { id: 22, name: 'Стрейч-плёнка', sku: 'FLM-STR', warehouseId: 2, categoryIds: [5], supplierIds: [9, 5], price: 420, quantity: 100, unit: 'рул', yearReceived: 2024, deletedAt: null },
  { id: 23, name: 'Анкер клиновой М10', sku: 'ANK-M10', warehouseId: 1, categoryIds: [1], supplierIds: [1], price: 12, quantity: 1500, unit: 'шт', yearReceived: 2025, deletedAt: null },
  { id: 24, name: 'Уровень 60 см', sku: 'LVL-60', warehouseId: 4, categoryIds: [2], supplierIds: [2], price: 540, quantity: 0, unit: 'шт', yearReceived: 2023, deletedAt: null },
];

const nextId = {
  categories: 6,
  warehouses: 5,
  suppliers: 11,
  employees: 6,
  products: 25,
};

function parseSort(sort) {
  const [field, dir] = String(sort || 'name,asc').split(',');
  return { field: field || 'name', asc: dir !== 'desc' };
}

function pageOf(rows, query) {
  const page = Math.max(1, Number(query.page) || 1);
  const size = Math.max(1, Number(query.size) || 10);
  const total = rows.length;
  const from = (page - 1) * size;
  const items = from >= total ? [] : rows.slice(from, from + size);
  return { items, page, size, total };
}

function active(rows, includeDeleted) {
  return rows.filter((r) => includeDeleted || !r.deletedAt);
}

function expandProduct(p) {
  const warehouse = warehouses.find((w) => w.id === p.warehouseId) || null;
  const cats = categories.filter((c) => p.categoryIds.includes(c.id));
  const sups = suppliers.filter((s) => p.supplierIds.includes(s.id));
  return {
    ...p,
    warehouse,
    categories: cats,
    suppliers: sups,
  };
}

function sendValidation(res, errors, message = 'Ошибка валидации') {
  return res.status(422).json({ message, errors });
}

app.get('/api/__health', (_req, res) => {
  res.json({ ok: true, service: 'warehouse-mock-api', accessTtlSec: ttlSeconds });
});

/** Все бизнес-эндпоинты требуют вход. */
app.use('/api', (req, res, next) => {
  if (req.path.startsWith('/auth/') || req.path === '/__health') return next();
  return authRequired(req, res, next);
});

function crudList(collectionName, getRows, searchFields, extraFilter) {
  app.get(`/api/${collectionName}`, (req, res) => {
    let rows = active(getRows(), req.query.includeDeleted === 'true');
    const search = String(req.query.search || '').trim().toLowerCase();
    if (search) {
      rows = rows.filter((r) =>
        searchFields.some((f) => String(r[f] || '').toLowerCase().includes(search)),
      );
    }
    if (extraFilter) rows = extraFilter(rows, req.query);
    if (req.query.filter) {
      const f = String(req.query.filter).toLowerCase();
      rows = rows.filter((r) =>
        Object.values(r).some((v) => String(v).toLowerCase().includes(f)),
      );
    }
    const { field, asc } = parseSort(req.query.sort);
    rows = [...rows].sort((a, b) => {
      const av = a[field];
      const bv = b[field];
      const cmp =
        typeof av === 'number' && typeof bv === 'number'
          ? av - bv
          : String(av ?? '').localeCompare(String(bv ?? ''), 'ru');
      return asc ? cmp : -cmp;
    });
    const page = pageOf(rows, req.query);
    if (collectionName === 'products') {
      page.items = page.items.map(expandProduct);
    }
    res.json(page);
  });

  app.get(`/api/${collectionName}/:id`, (req, res) => {
    const id = Number(req.params.id);
    const item = getRows().find((r) => r.id === id);
    if (!item) return res.status(404).json({ message: 'Запись не найдена' });
    res.json(collectionName === 'products' ? expandProduct(item) : item);
  });
}

app.get('/api/meta/sku-unique', (req, res) => {
  const sku = String(req.query.sku || '').trim().toLowerCase();
  const excludeId = req.query.excludeId ? Number(req.query.excludeId) : null;
  const taken = products.some(
    (p) => p.sku.toLowerCase() === sku && (excludeId == null || p.id !== excludeId),
  );
  res.json({ unique: !taken });
});

app.get('/api/meta/count-by-warehouse', (req, res) => {
  const warehouseId = Number(req.query.warehouseId);
  const count = products.filter((p) => p.warehouseId === warehouseId && !p.deletedAt).length;
  res.json({ count });
});

app.get('/api/meta/email-unique', (req, res) => {
  const email = String(req.query.email || '').trim().toLowerCase();
  const excludeId = req.query.excludeId ? Number(req.query.excludeId) : null;
  const taken = employees.some(
    (e) => e.email.toLowerCase() === email && (excludeId == null || e.id !== excludeId),
  );
  res.json({ unique: !taken });
});

/** Списание со склада: 409 если нет остатка (аналог выдачи книги без экземпляров). */
app.post('/api/products/:id/issue', requireRole('operator'), (req, res) => {
  const id = Number(req.params.id);
  const item = products.find((p) => p.id === id);
  if (!item || item.deletedAt) return res.status(404).json({ message: 'Товар не найден' });
  const qty = Number(req.body?.quantity || 1);
  if (item.quantity < qty) {
    return res.status(409).json({
      message: `Недостаточно остатка для списания «${item.name}» (доступно: ${item.quantity}).`,
    });
  }
  item.quantity -= qty;
  res.json(expandProduct(item));
});

crudList('categories', () => categories, ['name', 'description']);
crudList('warehouses', () => warehouses, ['name', 'code', 'city', 'address']);
crudList('suppliers', () => suppliers, ['name', 'country', 'city', 'email']);
crudList('employees', () => employees, ['fullName', 'email', 'position', 'phone']);
crudList(
  'products',
  () => products,
  ['name', 'sku'],
  (rows, q) => {
    let out = rows;
    if (q.categoryId) out = out.filter((p) => p.categoryIds.includes(Number(q.categoryId)));
    if (q.supplierId) out = out.filter((p) => p.supplierIds.includes(Number(q.supplierId)));
    if (q.warehouseId) out = out.filter((p) => p.warehouseId === Number(q.warehouseId));
    if (q.yearFrom) out = out.filter((p) => p.yearReceived >= Number(q.yearFrom));
    if (q.yearTo) out = out.filter((p) => p.yearReceived <= Number(q.yearTo));
    return out;
  },
);
function createHandlers(name, getRows, setRows, key, validateCreate) {
  const writeRole = name === 'employees' ? 'operator' : 'operator';
  app.post(`/api/${name}`, requireRole(writeRole), (req, res) => {
    const body = req.body || {};
    const errors = validateCreate ? validateCreate(body, null) : null;
    if (errors) return sendValidation(res, errors);
    const id = nextId[key]++;
    const item = { ...body, id, deletedAt: null };
    setRows([...getRows(), item]);
    res.status(201).json(name === 'products' ? expandProduct(item) : item);
  });

  app.put(`/api/${name}/:id`, requireRole(writeRole), (req, res) => {
    const id = Number(req.params.id);
    const rows = getRows();
    const i = rows.findIndex((r) => r.id === id);
    if (i < 0) return res.status(404).json({ message: 'Запись не найдена' });
    const body = req.body || {};
    const errors = validateCreate ? validateCreate(body, id) : null;
    if (errors) return sendValidation(res, errors);
    rows[i] = { ...rows[i], ...body, id, deletedAt: rows[i].deletedAt };
    setRows(rows);
    res.json(name === 'products' ? expandProduct(rows[i]) : rows[i]);
  });

  app.delete(`/api/${name}/:id`, (req, res) => {
    const id = Number(req.params.id);
    const hard = req.query.hard === 'true';
    const need = hard ? 'admin' : 'operator';
    return requireRole(need)(req, res, () => {
      const rows = getRows();
      const i = rows.findIndex((r) => r.id === id);
      if (i < 0) return res.status(404).json({ message: 'Запись не найдена' });

      if (name === 'warehouses' && hard) {
        const used = products.some((p) => p.warehouseId === id && !p.deletedAt);
        if (used) {
          return res.status(409).json({
            message: 'Нельзя удалить склад: на нём есть активные товары.',
          });
        }
      }

      if (hard) {
        setRows(rows.filter((r) => r.id !== id));
      } else {
        rows[i].deletedAt = new Date().toISOString();
        setRows(rows);
      }
      res.status(204).end();
    });
  });

  app.post(`/api/${name}/:id/restore`, requireRole('admin'), (req, res) => {
    const id = Number(req.params.id);
    const rows = getRows();
    const i = rows.findIndex((r) => r.id === id);
    if (i < 0) return res.status(404).json({ message: 'Запись не найдена' });
    rows[i].deletedAt = null;
    setRows(rows);
    res.json(name === 'products' ? expandProduct(rows[i]) : rows[i]);
  });

  app.post(`/api/${name}/bulk-delete`, requireRole('operator'), (req, res) => {
    const ids = Array.isArray(req.body?.ids) ? req.body.ids.map(Number) : [];
    const rows = getRows();
    let deleted = 0;
    for (const id of ids) {
      const i = rows.findIndex((r) => r.id === id && !r.deletedAt);
      if (i >= 0) {
        rows[i].deletedAt = new Date().toISOString();
        deleted++;
      }
    }
    setRows(rows);
    res.json({ deleted });
  });
}

createHandlers(
  'categories',
  () => categories,
  (v) => (categories = v),
  'categories',
  (body) => {
    if (!body.name || String(body.name).trim().length < 2) {
      return { name: 'Название обязательно (мин. 2 символа)' };
    }
    return null;
  },
);

createHandlers(
  'warehouses',
  () => warehouses,
  (v) => (warehouses = v),
  'warehouses',
  (body) => {
    const errors = {};
    if (!body.name) errors.name = 'Укажите название';
    if (!body.code) errors.code = 'Укажите код';
    return Object.keys(errors).length ? errors : null;
  },
);

createHandlers(
  'suppliers',
  () => suppliers,
  (v) => (suppliers = v),
  'suppliers',
  (body) => {
    const errors = {};
    if (!body.name) errors.name = 'Укажите название';
    if (!body.country) errors.country = 'Укажите страну';
    return Object.keys(errors).length ? errors : null;
  },
);

createHandlers(
  'employees',
  () => employees,
  (v) => (employees = v),
  'employees',
  (body, excludeId) => {
    const errors = {};
    if (!body.fullName) errors.fullName = 'Укажите ФИО';
    if (!body.email) errors.email = 'Укажите email';
    else {
      const taken = employees.some(
        (e) =>
          e.email.toLowerCase() === String(body.email).toLowerCase() &&
          (excludeId == null || e.id !== excludeId),
      );
      if (taken) errors.email = 'Сотрудник с таким email уже существует';
    }
    return Object.keys(errors).length ? errors : null;
  },
);

createHandlers(
  'products',
  () => products,
  (v) => (products = v),
  'products',
  (body, excludeId) => {
    const errors = {};
    if (!body.name || String(body.name).trim().length < 2) {
      errors.name = 'Название обязательно';
    }
    if (!body.sku || String(body.sku).trim().length < 3) {
      errors.sku = 'Артикул обязателен';
    } else {
      const taken = products.some(
        (p) =>
          p.sku.toLowerCase() === String(body.sku).toLowerCase() &&
          (excludeId == null || p.id !== excludeId),
      );
      if (taken) errors.sku = 'Товар с таким артикулом уже существует';
    }
    if (!body.warehouseId) errors.warehouseId = 'Выберите склад';
    if (!Array.isArray(body.categoryIds) || body.categoryIds.length === 0) {
      errors.categoryIds = 'Выберите хотя бы одну категорию';
    }
    return Object.keys(errors).length ? errors : null;
  },
);

auth.setStatsProvider(() => ({
  products: products.filter((p) => !p.deletedAt).length,
  suppliers: suppliers.filter((s) => !s.deletedAt).length,
  warehouses: warehouses.filter((w) => !w.deletedAt).length,
  categories: categories.filter((c) => !c.deletedAt).length,
  employees: employees.filter((e) => !e.deletedAt).length,
}));

app.listen(port, () => {
  console.log(`Warehouse mock API: http://localhost:${port}/api`);
  console.log(`Health: http://localhost:${port}/api/__health`);
  console.log(`CORS origin: ${origin}`);
  console.log(`Access token TTL: ${ttlSeconds}s`);
  console.log('Users: viewer/viewer123!  operator/operator1!  admin/admin123!  masha/masha123!');
});
