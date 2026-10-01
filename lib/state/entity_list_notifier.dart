import 'package:flutter/foundation.dart';

import '../models/entity_query.dart';
import '../models/page_result.dart';

enum LoadStatus { idle, loading, success, error }

/// Универсальный нотификатор списка с поиском/сортировкой/удалением.
class EntityListNotifier<T> extends ChangeNotifier {
  final Future<PageResult<T>> Function(EntityQuery query) loader;
  final Future<void> Function(int id) softDeleter;
  final Future<void> Function(int id) hardDeleter;
  final Future<void> Function(int id) restorer;
  final Future<int> Function(List<int> ids) manyDeleter;
  final int Function(T item) idOf;
  final bool Function(T item) isDeletedOf;

  EntityListNotifier({
    required this.loader,
    required this.softDeleter,
    required this.hardDeleter,
    required this.restorer,
    required this.manyDeleter,
    required this.idOf,
    required this.isDeletedOf,
  });

  EntityQuery _query = const EntityQuery();
  PageResult<T> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  EntityQuery get query => _query;
  PageResult<T> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await loader(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(EntityQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await manyDeleter(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await softDeleter(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await hardDeleter(id);
    await load();
  }

  Future<void> restore(int id) async {
    await restorer(id);
    await load();
  }

  Future<void> simulateError() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));
    _error = 'Симулированная ошибка загрузки';
    _status = LoadStatus.error;
    notifyListeners();
  }
}
