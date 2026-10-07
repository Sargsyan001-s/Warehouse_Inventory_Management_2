import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';
import '../models/supplier.dart';
import 'supplier_repository.dart';

class PersistentSupplierRepository implements SupplierRepository {
  static const _key = 'suppliers_v2';

  final SharedPreferences _prefs;
  final void Function(String message)? onMigrationNotice;
  List<Supplier> _items = [];
  int _nextId = 1;

  PersistentSupplierRepository(this._prefs, {this.onMigrationNotice}) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _items = [...seedSuppliers];
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _items = list
          .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
          .toList();
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
    } catch (_) {
      _items = [...seedSuppliers];
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
      _persist();
      onMigrationNotice?.call(
        'Данные поставщиков сброшены из‑за смены формата.',
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
  Future<PageResult<Supplier>> find(EntityQuery q) async {
    await Future.delayed(const Duration(milliseconds: 120));
    var rows = _items.where((s) => q.includeDeleted || !s.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (s) =>
                s.name.toLowerCase().contains(needle) ||
                s.country.toLowerCase().contains(needle) ||
                s.city.toLowerCase().contains(needle) ||
                s.email.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.filter != null && q.filter!.isNotEmpty) {
      rows = rows.where((s) => s.country == q.filter).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Supplier>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Supplier?> findById(int id) async {
    try {
      return _items.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Supplier>> findAll({bool includeDeleted = false}) async {
    return _items.where((s) => includeDeleted || !s.isDeleted).toList();
  }

  @override
  Future<Supplier> create(Supplier supplier) async {
    final created = Supplier(
      id: _nextId++,
      name: supplier.name,
      country: supplier.country,
      city: supplier.city,
      phone: supplier.phone,
      email: supplier.email,
    );
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Supplier> update(Supplier supplier) async {
    final i = _items.indexWhere((s) => s.id == supplier.id);
    if (i == -1) throw StateError('Поставщик ${supplier.id} не найден');
    _items[i] = supplier;
    await _persist();
    return supplier;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((s) => s.id == id);
    if (i == -1) throw StateError('Поставщик $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((s) => s.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((s) => s.id == id);
    if (i == -1) throw StateError('Поставщик $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((s) => s.id == id && !s.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
