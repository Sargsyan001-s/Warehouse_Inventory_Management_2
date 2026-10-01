import '../models/entity_query.dart';
import '../models/page_result.dart';
import '../models/supplier.dart';

abstract interface class SupplierRepository {
  Future<PageResult<Supplier>> find(EntityQuery query);
  Future<Supplier?> findById(int id);
  Future<List<Supplier>> findAll({bool includeDeleted = false});
  Future<Supplier> create(Supplier supplier);
  Future<Supplier> update(Supplier supplier);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
