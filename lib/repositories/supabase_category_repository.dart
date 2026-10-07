import '../core/json_maps.dart';
import '../core/supabase_bootstrap.dart';
import '../core/supabase_errors.dart';
import '../models/category.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';
import 'category_repository.dart';

class SupabaseCategoryRepository implements CategoryRepository {
  Category _map(Map<String, dynamic> row) => Category(
        id: asInt(row['id']) ?? 0,
        name: row['name'] as String? ?? '',
        description: row['description'] as String? ?? '',
        deletedAt: row['deleted_at'] == null
            ? null
            : DateTime.tryParse(row['deleted_at'] as String),
      );

  @override
  Future<PageResult<Category>> find(EntityQuery q) => sbGuard(() async {
        var query = supabase.from('categories').select();
        if (!q.includeDeleted) query = query.isFilter('deleted_at', null);
        if (q.search.trim().isNotEmpty) {
          query = query.ilike('name', '%${q.search.trim()}%');
        }
        final from = (q.page - 1) * q.size;
        final to = from + q.size - 1;
        final rows =
            await query.order('name', ascending: q.sortAscending).range(from, to);
        final items = (rows as List)
            .whereType<Map>()
            .map((e) => _map(Map<String, dynamic>.from(e)))
            .toList();
        final all = await supabase.from('categories').select('id');
        return PageResult(
          items: items,
          page: q.page,
          size: q.size,
          total: (all as List).length,
        );
      });

  @override
  Future<Category?> findById(int id) => sbGuard(() async {
        final row = await supabase.from('categories').select().eq('id', id).maybeSingle();
        if (row == null) return null;
        return _map(Map<String, dynamic>.from(row));
      });

  @override
  Future<List<Category>> findAll({bool includeDeleted = false}) => sbGuard(() async {
        var q = supabase.from('categories').select();
        if (!includeDeleted) q = q.isFilter('deleted_at', null);
        final rows = await q.order('name').limit(500);
        return (rows as List)
            .whereType<Map>()
            .map((e) => _map(Map<String, dynamic>.from(e)))
            .toList();
      });

  @override
  Future<Category> create(Category category) => sbGuard(() async {
        final row = await supabase
            .from('categories')
            .insert({'name': category.name, 'description': category.description})
            .select()
            .single();
        return _map(Map<String, dynamic>.from(row));
      });

  @override
  Future<Category> update(Category category) => sbGuard(() async {
        final row = await supabase
            .from('categories')
            .update({'name': category.name, 'description': category.description})
            .eq('id', category.id)
            .select()
            .single();
        return _map(Map<String, dynamic>.from(row));
      });

  @override
  Future<void> softDelete(int id) => sbGuard(() async {
        await supabase
            .from('categories')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id);
      });

  @override
  Future<void> hardDelete(int id) =>
      sbGuard(() => supabase.from('categories').delete().eq('id', id));

  @override
  Future<void> restore(int id) => sbGuard(() async {
        await supabase.from('categories').update({'deleted_at': null}).eq('id', id);
      });

  @override
  Future<int> deleteMany(List<int> ids) => sbGuard(() async {
        if (ids.isEmpty) return 0;
        await supabase
            .from('categories')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .inFilter('id', ids);
        return ids.length;
      });
}
