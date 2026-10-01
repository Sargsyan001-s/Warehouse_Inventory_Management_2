import '../models/category.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';

abstract interface class CategoryRepository {
  Future<PageResult<Category>> find(EntityQuery query);
  Future<Category?> findById(int id);
  Future<List<Category>> findAll({bool includeDeleted = false});
  Future<Category> create(Category category);
  Future<Category> update(Category category);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
