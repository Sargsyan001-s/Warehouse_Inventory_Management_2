import '../models/access_badge.dart';
import '../models/category.dart';
import '../models/employee.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/warehouse.dart';

final seedCategories = [
  const Category(id: 1, name: 'Крепёж', description: 'Болты, гайки, саморезы'),
  const Category(id: 2, name: 'Инструменты', description: 'Ручной и измерительный инструмент'),
  const Category(id: 3, name: 'Электрика', description: 'Кабели, розетки, автоматы'),
  const Category(id: 4, name: 'Сантехника', description: 'Трубы, фитинги, краны'),
  const Category(id: 5, name: 'Упаковка', description: 'Коробки, плёнка, скотч'),
];

final seedWarehouses = [
  const Warehouse(
    id: 1,
    name: 'Склад Центральный',
    code: 'WH-C01',
    address: 'ул. Складская, 1',
    city: 'Москва',
    categoryIds: [1, 2, 3],
  ),
  const Warehouse(
    id: 2,
    name: 'Склад Север',
    code: 'WH-N02',
    address: 'пр. Индустриальный, 15',
    city: 'Санкт-Петербург',
    categoryIds: [1, 4, 5],
  ),
  const Warehouse(
    id: 3,
    name: 'Склад Юг',
    code: 'WH-S03',
    address: 'ул. Портовая, 8',
    city: 'Краснодар',
    categoryIds: [2, 3, 5],
  ),
  const Warehouse(
    id: 4,
    name: 'Склад Урал',
    code: 'WH-U04',
    address: 'ул. Заводская, 42',
    city: 'Екатеринбург',
    categoryIds: [1, 2, 4],
  ),
];

final seedSuppliers = [
  const Supplier(id: 1, name: 'МеталлПром', country: 'Россия', city: 'Москва', phone: '+7 495 111-11-11', email: 'info@metallprom.ru'),
  const Supplier(id: 2, name: 'ToolMaster', country: 'Германия', city: 'Берлин', phone: '+49 30 222-22', email: 'sales@toolmaster.de'),
  const Supplier(id: 3, name: 'ElectroSupply', country: 'Китай', city: 'Шэньчжэнь', phone: '+86 755 333', email: 'cn@electrosupply.com'),
  const Supplier(id: 4, name: 'СанТехОпт', country: 'Россия', city: 'Санкт-Петербург', phone: '+7 812 444-44-44', email: 'opt@santeh.ru'),
  const Supplier(id: 5, name: 'PackLine', country: 'Польша', city: 'Варшава', phone: '+48 22 555-55', email: 'hello@packline.pl'),
  const Supplier(id: 6, name: 'NordFix', country: 'Финляндия', city: 'Хельсинки', phone: '+358 9 666', email: 'nord@nordfix.fi'),
  const Supplier(id: 7, name: 'УралКреп', country: 'Россия', city: 'Екатеринбург', phone: '+7 343 777-77-77', email: 'ural@krep.ru'),
  const Supplier(id: 8, name: 'AsiaParts', country: 'Китай', city: 'Гуанчжоу', phone: '+86 20 888', email: 'parts@asia.cn'),
  const Supplier(id: 9, name: 'BalticTrade', country: 'Латвия', city: 'Рига', phone: '+371 67 999', email: 'riga@baltic.lv'),
  const Supplier(id: 10, name: 'ЮгСтрой', country: 'Россия', city: 'Краснодар', phone: '+7 861 101-01-01', email: 'yug@stroy.ru'),
];

final seedEmployees = [
  Employee(
    id: 1,
    fullName: 'Иванов Пётр Сергеевич',
    email: 'ivanov@warehouse.ru',
    phone: '+7 900 111-22-33',
    position: 'Кладовщик',
    badge: AccessBadge(
      number: 'BADGE-001',
      level: 'обычный',
      issuedAt: DateTime(2024, 1, 15),
      expiresAt: DateTime(2027, 1, 15),
    ),
  ),
  Employee(
    id: 2,
    fullName: 'Петрова Анна Викторовна',
    email: 'petrova@warehouse.ru',
    phone: '+7 900 222-33-44',
    position: 'Менеджер склада',
    badge: AccessBadge(
      number: 'BADGE-002',
      level: 'админ',
      issuedAt: DateTime(2023, 6, 1),
      expiresAt: DateTime(2026, 6, 1),
    ),
  ),
  Employee(
    id: 3,
    fullName: 'Сидоров Алексей Иванович',
    email: 'sidorov@warehouse.ru',
    phone: '+7 900 333-44-55',
    position: 'Грузчик',
    badge: AccessBadge(
      number: 'BADGE-003',
      level: 'обычный',
      issuedAt: DateTime(2025, 3, 10),
    ),
  ),
  Employee(
    id: 4,
    fullName: 'Козлова Мария Дмитриевна',
    email: 'kozlova@warehouse.ru',
    phone: '+7 900 444-55-66',
    position: 'Бухгалтер',
    badge: AccessBadge(
      number: 'BADGE-004',
      level: 'ограниченный',
      issuedAt: DateTime(2024, 9, 1),
      expiresAt: DateTime(2026, 9, 1),
    ),
  ),
  Employee(
    id: 5,
    fullName: 'Морозов Дмитрий Олегович',
    email: 'morozov@warehouse.ru',
    phone: '+7 900 555-66-77',
    position: 'Начальник смены',
    badge: AccessBadge(
      number: 'BADGE-005',
      level: 'админ',
      issuedAt: DateTime(2022, 11, 20),
      expiresAt: DateTime(2027, 11, 20),
    ),
  ),
];

final seedProducts = [
  const Product(id: 1, name: 'Болт М8х40', sku: 'BLT-M8-40', warehouseId: 1, categoryIds: [1], supplierIds: [1, 7], price: 3.5, quantity: 5000, unit: 'шт', yearReceived: 2023),
  const Product(id: 2, name: 'Гайка М8', sku: 'NUT-M8', warehouseId: 1, categoryIds: [1], supplierIds: [1], price: 1.2, quantity: 8000, unit: 'шт', yearReceived: 2023),
  const Product(id: 3, name: 'Шайба 8 мм', sku: 'WSH-8', warehouseId: 4, categoryIds: [1], supplierIds: [7], price: 0.5, quantity: 10000, unit: 'шт', yearReceived: 2024),
  const Product(id: 4, name: 'Саморез 4х50', sku: 'SCR-4-50', warehouseId: 2, categoryIds: [1], supplierIds: [6], price: 0.8, quantity: 12000, unit: 'шт', yearReceived: 2024),
  const Product(id: 5, name: 'Дюбель 6х40', sku: 'DUB-6-40', warehouseId: 4, categoryIds: [1], supplierIds: [7], price: 1.5, quantity: 6000, unit: 'шт', yearReceived: 2022),
  const Product(id: 6, name: 'Молоток 500 г', sku: 'HAM-500', warehouseId: 1, categoryIds: [2], supplierIds: [2], price: 450, quantity: 80, unit: 'шт', yearReceived: 2023),
  const Product(id: 7, name: 'Отвёртка PH2', sku: 'SCRD-PH2', warehouseId: 3, categoryIds: [2], supplierIds: [2, 6], price: 180, quantity: 150, unit: 'шт', yearReceived: 2024),
  const Product(id: 8, name: 'Ключ разводной 250', sku: 'WRN-250', warehouseId: 1, categoryIds: [2], supplierIds: [2], price: 620, quantity: 60, unit: 'шт', yearReceived: 2023),
  const Product(id: 9, name: 'Рулетка 5 м', sku: 'TPE-5M', warehouseId: 3, categoryIds: [2], supplierIds: [10], price: 220, quantity: 200, unit: 'шт', yearReceived: 2025),
  const Product(id: 10, name: 'Плоскогубцы 180', sku: 'PLR-180', warehouseId: 4, categoryIds: [2], supplierIds: [6], price: 350, quantity: 90, unit: 'шт', yearReceived: 2024),
  const Product(id: 11, name: 'Кабель ВВГ 3х2.5', sku: 'CBL-VVG-325', warehouseId: 1, categoryIds: [3], supplierIds: [3], price: 85, quantity: 400, unit: 'м', yearReceived: 2024),
  const Product(id: 12, name: 'Розетка 16А', sku: 'SOC-16A', warehouseId: 1, categoryIds: [3], supplierIds: [3, 8], price: 95, quantity: 300, unit: 'шт', yearReceived: 2023),
  const Product(id: 13, name: 'Выключатель 1-кл', sku: 'SW-1K', warehouseId: 3, categoryIds: [3], supplierIds: [8], price: 70, quantity: 250, unit: 'шт', yearReceived: 2025),
  const Product(id: 14, name: 'Автомат C16', sku: 'BRK-C16', warehouseId: 1, categoryIds: [3], supplierIds: [3], price: 310, quantity: 120, unit: 'шт', yearReceived: 2024),
  const Product(id: 15, name: 'Лампа LED 10Вт', sku: 'LED-10W', warehouseId: 3, categoryIds: [3], supplierIds: [8], price: 120, quantity: 500, unit: 'шт', yearReceived: 2025),
  const Product(id: 16, name: 'Труба ППР 20', sku: 'PPR-20', warehouseId: 2, categoryIds: [4], supplierIds: [4], price: 45, quantity: 350, unit: 'м', yearReceived: 2023),
  const Product(id: 17, name: 'Кран шаровой 1/2', sku: 'VLV-12', warehouseId: 2, categoryIds: [4], supplierIds: [4], price: 280, quantity: 180, unit: 'шт', yearReceived: 2024),
  const Product(id: 18, name: 'Фитинг уголок 20', sku: 'FIT-20', warehouseId: 4, categoryIds: [4], supplierIds: [4], price: 25, quantity: 700, unit: 'шт', yearReceived: 2022),
  const Product(id: 19, name: 'Сифон кухонный', sku: 'SPH-KIT', warehouseId: 2, categoryIds: [4], supplierIds: [10], price: 390, quantity: 70, unit: 'шт', yearReceived: 2025),
  const Product(id: 20, name: 'Коробка картонная S', sku: 'BOX-S', warehouseId: 2, categoryIds: [5], supplierIds: [5], price: 15, quantity: 2000, unit: 'шт', yearReceived: 2024),
  const Product(id: 21, name: 'Скотч упаковочный', sku: 'TAPE-48', warehouseId: 3, categoryIds: [5], supplierIds: [5], price: 55, quantity: 400, unit: 'шт', yearReceived: 2023),
  const Product(id: 22, name: 'Стрейч-плёнка', sku: 'FLM-STR', warehouseId: 2, categoryIds: [5], supplierIds: [9, 5], price: 420, quantity: 100, unit: 'рул', yearReceived: 2024),
  const Product(id: 23, name: 'Анкер клиновой М10', sku: 'ANK-M10', warehouseId: 1, categoryIds: [1], supplierIds: [1], price: 12, quantity: 1500, unit: 'шт', yearReceived: 2025),
  const Product(id: 24, name: 'Уровень 60 см', sku: 'LVL-60', warehouseId: 4, categoryIds: [2], supplierIds: [2], price: 540, quantity: 45, unit: 'шт', yearReceived: 2023),
];
