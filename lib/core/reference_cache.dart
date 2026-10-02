import '../models/category.dart';
import '../models/supplier.dart';
import '../models/warehouse.dart';
import '../repositories/category_repository.dart';
import '../repositories/supplier_repository.dart';
import '../repositories/warehouse_repository.dart';

class ReferenceCache {
  final CategoryRepository _categories;
  final SupplierRepository _suppliers;
  final WarehouseRepository _warehouses;

  List<Category>? _categoryCache;
  List<Supplier>? _supplierCache;
  List<Warehouse>? _warehouseCache;

  ReferenceCache(this._categories, this._suppliers, this._warehouses);

  Future<List<Category>> categories({bool force = false}) async {
    if (!force && _categoryCache != null) return _categoryCache!;
    _categoryCache = await _categories.findAll();
    return _categoryCache!;
  }

  Future<List<Supplier>> suppliers({bool force = false}) async {
    if (!force && _supplierCache != null) return _supplierCache!;
    _supplierCache = await _suppliers.findAll();
    return _supplierCache!;
  }

  Future<List<Warehouse>> warehouses({bool force = false}) async {
    if (!force && _warehouseCache != null) return _warehouseCache!;
    _warehouseCache = await _warehouses.findAll();
    return _warehouseCache!;
  }

  void invalidate() {
    _categoryCache = null;
    _supplierCache = null;
    _warehouseCache = null;
  }
}
