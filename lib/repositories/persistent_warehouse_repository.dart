import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';
import '../models/warehouse.dart';
import 'warehouse_repository.dart';

class PersistentWarehouseRepository implements WarehouseRepository {
  static const _key = 'warehouses_v2';

  final SharedPreferences _prefs;
  final void Function(String message)? onMigrationNotice;
  List<Warehouse> _items = [];
  int _nextId = 1;

  PersistentWarehouseRepository(this._prefs, {this.onMigrationNotice}) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _items = [...seedWarehouses];
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _items = list.map((e) => Warehouse.fromJson(e as Map<String, dynamic>)).toList();
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
    } catch (_) {
      _items = [...seedWarehouses];
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
      _persist();
      onMigrationNotice?.call('Данные складов сброшены из‑за смены формата.');
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  @override
  Future<PageResult<Warehouse>> find(EntityQuery q) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var rows = _items.where((w) => q.includeDeleted || !w.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((w) =>
              w.name.toLowerCase().contains(needle) ||
              w.code.toLowerCase().contains(needle) ||
              w.city.toLowerCase().contains(needle))
          .toList();
    }
    if (q.filter != null && q.filter!.isNotEmpty) {
      rows = rows.where((w) => w.city == q.filter).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'code' => a.code.toLowerCase().compareTo(b.code.toLowerCase()),
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Warehouse>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Warehouse?> findById(int id) async {
    try {
      return _items.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Warehouse>> findAll({bool includeDeleted = false}) async {
    return _items.where((w) => includeDeleted || !w.isDeleted).toList();
  }

  @override
  Future<Warehouse> create(Warehouse warehouse) async {
    final created = Warehouse(
      id: _nextId++,
      name: warehouse.name,
      code: warehouse.code,
      address: warehouse.address,
      city: warehouse.city,
      categoryIds: warehouse.categoryIds,
    );
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Warehouse> update(Warehouse warehouse) async {
    final i = _items.indexWhere((w) => w.id == warehouse.id);
    if (i == -1) throw StateError('Склад ${warehouse.id} не найден');
    _items[i] = warehouse;
    await _persist();
    return warehouse;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((w) => w.id == id);
    if (i == -1) throw StateError('Склад $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((w) => w.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((w) => w.id == id);
    if (i == -1) throw StateError('Склад $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((w) => w.id == id && !w.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
