import '../models/category.dart';
import '../models/product.dart';
import '../models/supplier.dart';

const seedCategories = [
  Category(id: 1, name: 'Крепёж'),
  Category(id: 2, name: 'Инструменты'),
  Category(id: 3, name: 'Электрика'),
  Category(id: 4, name: 'Сантехника'),
  Category(id: 5, name: 'Упаковка'),
];

const seedSuppliers = [
  Supplier(id: 1, name: 'МеталлПром', country: 'Россия', city: 'Москва', phone: '+7 495 111-11-11', email: 'info@metallprom.ru'),
  Supplier(id: 2, name: 'ToolMaster', country: 'Германия', city: 'Берлин', phone: '+49 30 222-22', email: 'sales@toolmaster.de'),
  Supplier(id: 3, name: 'ElectroSupply', country: 'Китай', city: 'Шэньчжэнь', phone: '+86 755 333', email: 'cn@electrosupply.com'),
  Supplier(id: 4, name: 'СанТехОпт', country: 'Россия', city: 'Санкт-Петербург', phone: '+7 812 444-44-44', email: 'opt@santeh.ru'),
  Supplier(id: 5, name: 'PackLine', country: 'Польша', city: 'Варшава', phone: '+48 22 555-55', email: 'hello@packline.pl'),
  Supplier(id: 6, name: 'NordFix', country: 'Финляндия', city: 'Хельсинки', phone: '+358 9 666', email: 'nord@nordfix.fi'),
  Supplier(id: 7, name: 'УралКреп', country: 'Россия', city: 'Екатеринбург', phone: '+7 343 777-77-77', email: 'ural@krep.ru'),
  Supplier(id: 8, name: 'AsiaParts', country: 'Китай', city: 'Гуанчжоу', phone: '+86 20 888', email: 'parts@asia.cn'),
  Supplier(id: 9, name: 'BalticTrade', country: 'Латвия', city: 'Рига', phone: '+371 67 999', email: 'riga@baltic.lv'),
  Supplier(id: 10, name: 'ЮгСтрой', country: 'Россия', city: 'Краснодар', phone: '+7 861 101-01-01', email: 'yug@stroy.ru'),
];

const seedProducts = [
  Product(id: 1, name: 'Болт М8х40', sku: 'BLT-M8-40', categoryId: 1, supplierId: 1, price: 3.5, quantity: 5000, unit: 'шт', yearReceived: 2023),
  Product(id: 2, name: 'Гайка М8', sku: 'NUT-M8', categoryId: 1, supplierId: 1, price: 1.2, quantity: 8000, unit: 'шт', yearReceived: 2023),
  Product(id: 3, name: 'Шайба 8 мм', sku: 'WSH-8', categoryId: 1, supplierId: 7, price: 0.5, quantity: 10000, unit: 'шт', yearReceived: 2024),
  Product(id: 4, name: 'Саморез 4х50', sku: 'SCR-4-50', categoryId: 1, supplierId: 6, price: 0.8, quantity: 12000, unit: 'шт', yearReceived: 2024),
  Product(id: 5, name: 'Дюбель 6х40', sku: 'DUB-6-40', categoryId: 1, supplierId: 7, price: 1.5, quantity: 6000, unit: 'шт', yearReceived: 2022),
  Product(id: 6, name: 'Молоток 500 г', sku: 'HAM-500', categoryId: 2, supplierId: 2, price: 450, quantity: 80, unit: 'шт', yearReceived: 2023),
  Product(id: 7, name: 'Отвёртка PH2', sku: 'SCRD-PH2', categoryId: 2, supplierId: 2, price: 180, quantity: 150, unit: 'шт', yearReceived: 2024),
  Product(id: 8, name: 'Ключ разводной 250', sku: 'WRN-250', categoryId: 2, supplierId: 2, price: 620, quantity: 60, unit: 'шт', yearReceived: 2023),
  Product(id: 9, name: 'Рулетка 5 м', sku: 'TPE-5M', categoryId: 2, supplierId: 10, price: 220, quantity: 200, unit: 'шт', yearReceived: 2025),
  Product(id: 10, name: 'Плоскогубцы 180', sku: 'PLR-180', categoryId: 2, supplierId: 6, price: 350, quantity: 90, unit: 'шт', yearReceived: 2024),
  Product(id: 11, name: 'Кабель ВВГ 3х2.5', sku: 'CBL-VVG-325', categoryId: 3, supplierId: 3, price: 85, quantity: 400, unit: 'м', yearReceived: 2024),
  Product(id: 12, name: 'Розетка 16А', sku: 'SOC-16A', categoryId: 3, supplierId: 3, price: 95, quantity: 300, unit: 'шт', yearReceived: 2023),
  Product(id: 13, name: 'Выключатель 1-кл', sku: 'SW-1K', categoryId: 3, supplierId: 8, price: 70, quantity: 250, unit: 'шт', yearReceived: 2025),
  Product(id: 14, name: 'Автомат C16', sku: 'BRK-C16', categoryId: 3, supplierId: 3, price: 310, quantity: 120, unit: 'шт', yearReceived: 2024),
  Product(id: 15, name: 'Лампа LED 10Вт', sku: 'LED-10W', categoryId: 3, supplierId: 8, price: 120, quantity: 500, unit: 'шт', yearReceived: 2025),
  Product(id: 16, name: 'Труба ППР 20', sku: 'PPR-20', categoryId: 4, supplierId: 4, price: 45, quantity: 350, unit: 'м', yearReceived: 2023),
  Product(id: 17, name: 'Кран шаровой 1/2', sku: 'VLV-12', categoryId: 4, supplierId: 4, price: 280, quantity: 180, unit: 'шт', yearReceived: 2024),
  Product(id: 18, name: 'Фитинг уголок 20', sku: 'FIT-20', categoryId: 4, supplierId: 4, price: 25, quantity: 700, unit: 'шт', yearReceived: 2022),
  Product(id: 19, name: 'Сифон кухонный', sku: 'SPH-KIT', categoryId: 4, supplierId: 10, price: 390, quantity: 70, unit: 'шт', yearReceived: 2025),
  Product(id: 20, name: 'Коробка картонная S', sku: 'BOX-S', categoryId: 5, supplierId: 5, price: 15, quantity: 2000, unit: 'шт', yearReceived: 2024),
  Product(id: 21, name: 'Скотч упаковочный', sku: 'TAPE-48', categoryId: 5, supplierId: 5, price: 55, quantity: 400, unit: 'шт', yearReceived: 2023),
  Product(id: 22, name: 'Стрейч-плёнка', sku: 'FLM-STR', categoryId: 5, supplierId: 9, price: 420, quantity: 100, unit: 'рул', yearReceived: 2024),
  Product(id: 23, name: 'Анкер клиновой М10', sku: 'ANK-M10', categoryId: 1, supplierId: 1, price: 12, quantity: 1500, unit: 'шт', yearReceived: 2025),
  Product(id: 24, name: 'Уровень 60 см', sku: 'LVL-60', categoryId: 2, supplierId: 2, price: 540, quantity: 45, unit: 'шт', yearReceived: 2023),
];
