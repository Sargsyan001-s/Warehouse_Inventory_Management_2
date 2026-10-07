import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/employee.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';
import 'employee_repository.dart';

class PersistentEmployeeRepository implements EmployeeRepository {
  static const _key = 'employees_v2';

  final SharedPreferences _prefs;
  final void Function(String message)? onMigrationNotice;
  List<Employee> _items = [];
  int _nextId = 1;

  PersistentEmployeeRepository(this._prefs, {this.onMigrationNotice}) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _items = [...seedEmployees];
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _items = list
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList();
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
    } catch (_) {
      _items = [...seedEmployees];
      _nextId = _items.fold<int>(0, (m, e) => e.id > m ? e.id : m) + 1;
      _persist();
      onMigrationNotice?.call(
        'Данные сотрудников сброшены из‑за смены формата.',
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
  Future<PageResult<Employee>> find(EntityQuery q) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var rows = _items.where((e) => q.includeDeleted || !e.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (e) =>
                e.fullName.toLowerCase().contains(needle) ||
                e.email.toLowerCase().contains(needle) ||
                e.position.toLowerCase().contains(needle) ||
                e.badge.number.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.filter != null && q.filter!.isNotEmpty) {
      rows = rows.where((e) => e.badge.level == q.filter).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        'position' => a.position.toLowerCase().compareTo(
          b.position.toLowerCase(),
        ),
        'badge' => a.badge.number.toLowerCase().compareTo(
          b.badge.number.toLowerCase(),
        ),
        _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Employee>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Employee?> findById(int id) async {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Employee>> findAll({bool includeDeleted = false}) async {
    return _items.where((e) => includeDeleted || !e.isDeleted).toList();
  }

  @override
  Future<bool> isEmailUnique(String email, {int? excludeId}) async {
    final needle = email.trim().toLowerCase();
    return !_items.any(
      (e) =>
          e.email.toLowerCase() == needle &&
          (excludeId == null || e.id != excludeId),
    );
  }

  @override
  Future<Employee> create(Employee employee) async {
    final created = Employee(
      id: _nextId++,
      fullName: employee.fullName,
      email: employee.email,
      phone: employee.phone,
      position: employee.position,
      badge: employee.badge,
    );
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Employee> update(Employee employee) async {
    final i = _items.indexWhere((e) => e.id == employee.id);
    if (i == -1) throw StateError('Сотрудник ${employee.id} не найден');
    _items[i] = employee;
    await _persist();
    return employee;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) throw StateError('Сотрудник $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((e) => e.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) throw StateError('Сотрудник $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((e) => e.id == id && !e.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
