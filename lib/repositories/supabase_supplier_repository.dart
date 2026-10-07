import '../core/json_maps.dart';
import '../core/supabase_bootstrap.dart';
import '../core/supabase_errors.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';
import '../models/supplier.dart';
import 'supplier_repository.dart';

class SupabaseSupplierRepository implements SupplierRepository {
  Supplier _map(Map<String, dynamic> row) => Supplier(
        id: asInt(row['id']) ?? 0,
        name: row['name'] as String? ?? '',
        country: row['country'] as String? ?? '',
        city: row['city'] as String? ?? '',
        phone: row['phone'] as String? ?? '',
        email: row['email'] as String? ?? '',
        deletedAt: row['deleted_at'] == null
            ? null
            : DateTime.tryParse(row['deleted_at'] as String),
      );

  Map<String, dynamic> _body(Supplier s) => {
        'name': s.name,
        'country': s.country,
        'city': s.city,
        'phone': s.phone,
        'email': s.email,
      };

  @override
  Future<PageResult<Supplier>> find(EntityQuery q) => sbGuard(() async {
        var query = supabase.from('suppliers').select();
        if (!q.includeDeleted) query = query.isFilter('deleted_at', null);
        if (q.search.trim().isNotEmpty) {
          final s = q.search.trim();
          query = query.or('name.ilike.%$s%,country.ilike.%$s%,city.ilike.%$s%');
        }
        final from = (q.page - 1) * q.size;
        final to = from + q.size - 1;
        final rows =
            await query.order('name', ascending: q.sortAscending).range(from, to);
        final items = (rows as List)
            .whereType<Map>()
            .map((e) => _map(Map<String, dynamic>.from(e)))
            .toList();
        final all = await supabase.from('suppliers').select('id');
        return PageResult(
          items: items,
          page: q.page,
          size: q.size,
          total: (all as List).length,
        );
      });

  @override
  Future<Supplier?> findById(int id) => sbGuard(() async {
        final row = await supabase.from('suppliers').select().eq('id', id).maybeSingle();
        if (row == null) return null;
        return _map(Map<String, dynamic>.from(row));
      });

  @override
  Future<List<Supplier>> findAll({bool includeDeleted = false}) => sbGuard(() async {
        var q = supabase.from('suppliers').select();
        if (!includeDeleted) q = q.isFilter('deleted_at', null);
        final rows = await q.order('name').limit(500);
        return (rows as List)
            .whereType<Map>()
            .map((e) => _map(Map<String, dynamic>.from(e)))
            .toList();
      });

  @override
  Future<Supplier> create(Supplier supplier) => sbGuard(() async {
        final row =
            await supabase.from('suppliers').insert(_body(supplier)).select().single();
        return _map(Map<String, dynamic>.from(row));
      });

  @override
  Future<Supplier> update(Supplier supplier) => sbGuard(() async {
        final row = await supabase
            .from('suppliers')
            .update(_body(supplier))
            .eq('id', supplier.id)
            .select()
            .single();
        return _map(Map<String, dynamic>.from(row));
      });

  @override
  Future<void> softDelete(int id) => sbGuard(() async {
        await supabase
            .from('suppliers')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id);
      });

  @override
  Future<void> hardDelete(int id) =>
      sbGuard(() => supabase.from('suppliers').delete().eq('id', id));

  @override
  Future<void> restore(int id) => sbGuard(() async {
        await supabase.from('suppliers').update({'deleted_at': null}).eq('id', id);
      });

  @override
  Future<int> deleteMany(List<int> ids) => sbGuard(() async {
        if (ids.isEmpty) return 0;
        await supabase
            .from('suppliers')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .inFilter('id', ids);
        return ids.length;
      });
}
