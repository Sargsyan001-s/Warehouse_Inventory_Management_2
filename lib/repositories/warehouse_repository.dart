import '../models/entity_query.dart';
import '../models/page_result.dart';
import '../models/warehouse.dart';

abstract interface class WarehouseRepository {
  Future<PageResult<Warehouse>> find(EntityQuery query);
  Future<Warehouse?> findById(int id);
  Future<List<Warehouse>> findAll({bool includeDeleted = false});
  Future<Warehouse> create(Warehouse warehouse);
  Future<Warehouse> update(Warehouse warehouse);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
