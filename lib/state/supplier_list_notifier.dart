import 'package:flutter/foundation.dart';

import '../models/page_result.dart';
import '../models/supplier.dart';
import '../models/supplier_query.dart';
import '../repositories/supplier_repository.dart';
import 'product_list_notifier.dart';

class SupplierListNotifier extends ChangeNotifier {
  final SupplierRepository _repository;

  SupplierListNotifier(this._repository);

  SupplierQuery _query = const SupplierQuery();
  PageResult<Supplier> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  SupplierQuery get query => _query;
  PageResult<Supplier> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(SupplierQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
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
