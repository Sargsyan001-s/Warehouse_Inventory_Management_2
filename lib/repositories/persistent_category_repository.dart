import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/category.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';
import 'category_repository.dart';

class PersistentCategoryRepository implements CategoryRepository {
  static const _key = 'categories_v2';

  final SharedPreferences _prefs;
  final void Function(String message)? onMigrationNotice;
  List<Category> _items = [];
  int _nextId = 1;

  PersistentCategoryRepository(this._prefs, {this.onMigrationNotice}) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _items = [...seedCategories];
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _items = list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
    } catch (_) {
      _items = [...seedCategories];
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
      _persist();
      onMigrationNotice?.call('Данные категорий сброшены из‑за смены формата.');
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  @override
  Future<PageResult<Category>> find(EntityQuery q) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var rows = _items.where((c) => q.includeDeleted || !c.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((c) =>
              c.name.toLowerCase().contains(needle) ||
              c.description.toLowerCase().contains(needle))
          .toList();
    }

    rows.sort((a, b) {
      final result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Category>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Category?> findById(int id) async {
    try {
      return _items.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Category>> findAll({bool includeDeleted = false}) async {
    return _items.where((c) => includeDeleted || !c.isDeleted).toList();
  }

  @override
  Future<Category> create(Category category) async {
    final created = Category(
      id: _nextId++,
      name: category.name,
      description: category.description,
    );
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Category> update(Category category) async {
    final i = _items.indexWhere((c) => c.id == category.id);
    if (i == -1) throw StateError('Категория ${category.id} не найдена');
    _items[i] = category;
    await _persist();
    return category;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Категория $id не найдена');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((c) => c.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Категория $id не найдена');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((c) => c.id == id && !c.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
