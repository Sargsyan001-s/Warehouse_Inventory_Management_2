import '../core/json_maps.dart';
import '../core/supabase_bootstrap.dart';
import '../core/supabase_errors.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';
import '../models/warehouse.dart';
import 'warehouse_repository.dart';

class SupabaseWarehouseRepository implements WarehouseRepository {
  static const _select = '*, warehouse_categories(category_id)';

  Warehouse _map(Map<String, dynamic> row) {
    final cats = (row['warehouse_categories'] as List? ?? [])
        .whereType<Map>()
        .map((e) => asInt(e['category_id']) ?? 0)
        .where((id) => id > 0)
        .toList();
    return Warehouse(
      id: asInt(row['id']) ?? 0,
      name: row['name'] as String? ?? '',
      code: row['code'] as String? ?? '',
      address: row['address'] as String? ?? '',
      city: row['city'] as String? ?? '',
      categoryIds: cats,
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.tryParse(row['deleted_at'] as String),
    );
  }

  Future<void> _syncCats(int warehouseId, List<int> categoryIds) async {
    await supabase
        .from('warehouse_categories')
        .delete()
        .eq('warehouse_id', warehouseId);
    if (categoryIds.isNotEmpty) {
      await supabase.from('warehouse_categories').insert([
        for (final c in categoryIds)
          {'warehouse_id': warehouseId, 'category_id': c},
      ]);
    }
  }

  @override
  Future<PageResult<Warehouse>> find(EntityQuery q) => sbGuard(() async {
        var query = supabase.from('warehouses').select(_select);
        if (!q.includeDeleted) query = query.isFilter('deleted_at', null);
        if (q.search.trim().isNotEmpty) {
          final s = q.search.trim();
          query = query.or('name.ilike.%$s%,code.ilike.%$s%');
        }
        final from = (q.page - 1) * q.size;
        final to = from + q.size - 1;
        final rows =
            await query.order('name', ascending: q.sortAscending).range(from, to);
        final items = (rows as List)
            .whereType<Map>()
            .map((e) => _map(Map<String, dynamic>.from(e)))
            .toList();
        final all = await supabase.from('warehouses').select('id');
        return PageResult(
          items: items,
          page: q.page,
          size: q.size,
          total: (all as List).length,
        );
      });

  @override
  Future<Warehouse?> findById(int id) => sbGuard(() async {
        final row =
            await supabase.from('warehouses').select(_select).eq('id', id).maybeSingle();
        if (row == null) return null;
        return _map(Map<String, dynamic>.from(row));
      });

  @override
  Future<List<Warehouse>> findAll({bool includeDeleted = false}) => sbGuard(() async {
        var q = supabase.from('warehouses').select(_select);
        if (!includeDeleted) q = q.isFilter('deleted_at', null);
        final rows = await q.order('name').limit(500);
        return (rows as List)
            .whereType<Map>()
            .map((e) => _map(Map<String, dynamic>.from(e)))
            .toList();
      });

  @override
  Future<Warehouse> create(Warehouse warehouse) => sbGuard(() async {
        final row = await supabase
            .from('warehouses')
            .insert({
              'name': warehouse.name,
              'code': warehouse.code,
              'address': warehouse.address,
              'city': warehouse.city,
            })
            .select('id')
            .single();
        final id = asInt(row['id'])!;
        await _syncCats(id, warehouse.categoryIds);
        return (await findById(id))!;
      });

  @override
  Future<Warehouse> update(Warehouse warehouse) => sbGuard(() async {
        await supabase.from('warehouses').update({
          'name': warehouse.name,
          'code': warehouse.code,
          'address': warehouse.address,
          'city': warehouse.city,
        }).eq('id', warehouse.id);
        await _syncCats(warehouse.id, warehouse.categoryIds);
        return (await findById(warehouse.id))!;
      });

  @override
  Future<void> softDelete(int id) => sbGuard(() async {
        await supabase
            .from('warehouses')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id);
      });

  @override
  Future<void> hardDelete(int id) =>
      sbGuard(() => supabase.from('warehouses').delete().eq('id', id));

  @override
  Future<void> restore(int id) => sbGuard(() async {
        await supabase.from('warehouses').update({'deleted_at': null}).eq('id', id);
      });

  @override
  Future<int> deleteMany(List<int> ids) => sbGuard(() async {
        if (ids.isEmpty) return 0;
        await supabase
            .from('warehouses')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .inFilter('id', ids);
        return ids.length;
      });
}
