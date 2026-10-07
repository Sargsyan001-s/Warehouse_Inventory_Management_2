import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import 'product_repository.dart';

class PersistentProductRepository implements ProductRepository {
  static const _key = 'products_v2';
  static const _legacyKey = 'products_v1';

  final SharedPreferences _prefs;
  final void Function(String message)? onMigrationNotice;
  List<Product> _items = [];
  int _nextId = 1;

  PersistentProductRepository(this._prefs, {this.onMigrationNotice}) {
    _restore();
  }

  void _restore() {
    var raw = _prefs.getString(_key);
    var migrated = false;

    if (raw == null) {
      final legacy = _prefs.getString(_legacyKey);
      if (legacy != null) {
        raw = legacy;
        migrated = true;
      }
    }

    if (raw == null) {
      _items = [...seedProducts];
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
      _persist();
      return;
    }

    try {
      final list = jsonDecode(raw) as List;
      _items = list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
      if (migrated) {
        _persist();
        _prefs.remove(_legacyKey);
        onMigrationNotice?.call(
          'Данные товаров перенесены в новый формат хранилища (v2).',
        );
      }
    } catch (_) {
      _items = [...seedProducts];
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
      _persist();
      onMigrationNotice?.call(
        'Старые данные товаров повреждены — загружен начальный набор.',
      );
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<PageResult<Product>> find(ProductQuery q) async {
    await Future.delayed(const Duration(milliseconds: 150));

    var rows = _items.where((p) => q.includeDeleted || !p.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (p) =>
                p.name.toLowerCase().contains(needle) ||
                p.sku.toLowerCase().contains(needle),
          )
          .toList();
    }

    if (q.categoryId != null) {
      rows = rows.where((p) => p.categoryIds.contains(q.categoryId)).toList();
    }
    if (q.supplierId != null) {
      rows = rows.where((p) => p.supplierIds.contains(q.supplierId)).toList();
    }
    if (q.warehouseId != null) {
      rows = rows.where((p) => p.warehouseId == q.warehouseId).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((p) => p.yearReceived >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((p) => p.yearReceived <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'price' => a.price.compareTo(b.price),
        'quantity' => a.quantity.compareTo(b.quantity),
        'yearReceived' => a.yearReceived.compareTo(b.yearReceived),
        'sku' => a.sku.toLowerCase().compareTo(b.sku.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Product>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Product?> findById(int id) async {
    try {
      return _items.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isSkuUnique(String sku, {int? excludeId}) async {
    final needle = sku.trim().toLowerCase();
    return !_items.any(
      (p) =>
          p.sku.toLowerCase() == needle &&
          (excludeId == null || p.id != excludeId),
    );
  }

  @override
  Future<int> countByWarehouse(int warehouseId) async {
    return _items
        .where((p) => p.warehouseId == warehouseId && !p.isDeleted)
        .length;
  }

  @override
  Future<List<Product>> findAll({bool includeDeleted = false}) async {
    return _items.where((p) => includeDeleted || !p.isDeleted).toList();
  }

  @override
  Future<Product> create(Product product) async {
    final withId = Product(
      id: _nextId++,
      name: product.name,
      sku: product.sku,
      warehouseId: product.warehouseId,
      categoryIds: product.categoryIds,
      supplierIds: product.supplierIds,
      price: product.price,
      quantity: product.quantity,
      unit: product.unit,
      yearReceived: product.yearReceived,
    );
    _items.add(withId);
    await _persist();
    return withId;
  }

  @override
  Future<Product> update(Product product) async {
    final i = _items.indexWhere((p) => p.id == product.id);
    if (i == -1) throw StateError('Товар ${product.id} не найден');
    _items[i] = product;
    await _persist();
    return product;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Товар $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((p) => p.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Товар $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<Product> issue(int id, {int quantity = 1}) async {
    final i = _items.indexWhere((p) => p.id == id && !p.isDeleted);
    if (i == -1) throw StateError('Товар $id не найден');
    final p = _items[i];
    if (p.quantity < quantity) {
      throw StateError('Недостаточно остатка (доступно: ${p.quantity})');
    }
    _items[i] = p.copyWith(quantity: p.quantity - quantity);
    await _persist();
    return _items[i];
  }
}
