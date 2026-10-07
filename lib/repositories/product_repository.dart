import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';

abstract interface class ProductRepository {
  Future<PageResult<Product>> find(ProductQuery query);
  Future<Product?> findById(int id);
  Future<List<Product>> findAll({bool includeDeleted = false});
  Future<Product> create(Product product);
  Future<Product> update(Product product);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<bool> isSkuUnique(String sku, {int? excludeId});
  Future<int> countByWarehouse(int warehouseId);
  Future<Product> issue(int id, {int quantity = 1});
}
