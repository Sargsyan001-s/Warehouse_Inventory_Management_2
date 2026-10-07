import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/json_maps.dart';
import '../core/supabase_bootstrap.dart';
import '../core/supabase_errors.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import 'product_repository.dart';

class SupabaseProductRepository implements ProductRepository {
  static const _select =
      '*, product_categories(category_id), product_suppliers(supplier_id)';

  Product _map(Map<String, dynamic> row) {
    final cats = (row['product_categories'] as List? ?? [])
        .whereType<Map>()
        .map((e) => asInt(e['category_id']) ?? 0)
        .where((id) => id > 0)
        .toList();
    final sups = (row['product_suppliers'] as List? ?? [])
        .whereType<Map>()
        .map((e) => asInt(e['supplier_id']) ?? 0)
        .where((id) => id > 0)
        .toList();
    return Product(
      id: asInt(row['id']) ?? 0,
      name: row['name'] as String? ?? '',
      sku: row['sku'] as String? ?? '',
      warehouseId: asInt(row['warehouse_id']) ?? 0,
      categoryIds: cats,
      supplierIds: sups,
      price: asDouble(row['price']),
      quantity: asInt(row['quantity']) ?? 0,
      unit: row['unit'] as String? ?? 'шт',
      yearReceived: asInt(row['year_received']) ?? 2024,
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.tryParse(row['deleted_at'] as String),
    );
  }

  Future<void> _syncLinks(int productId, Product p) async {
    await supabase.from('product_categories').delete().eq('product_id', productId);
    await supabase.from('product_suppliers').delete().eq('product_id', productId);
    if (p.categoryIds.isNotEmpty) {
      await supabase.from('product_categories').insert([
        for (final c in p.categoryIds) {'product_id': productId, 'category_id': c},
      ]);
    }
    if (p.supplierIds.isNotEmpty) {
      await supabase.from('product_suppliers').insert([
        for (final s in p.supplierIds) {'product_id': productId, 'supplier_id': s},
      ]);
    }
  }

  @override
  Future<PageResult<Product>> find(ProductQuery q) => sbGuard(() async {
        var query = supabase.from('products').select(_select);

        if (!q.includeDeleted) {
          query = query.isFilter('deleted_at', null);
        }
        if (q.search.trim().isNotEmpty) {
          final s = q.search.trim();
          query = query.or('name.ilike.%$s%,sku.ilike.%$s%');
        }
        if (q.warehouseId != null) {
          query = query.eq('warehouse_id', q.warehouseId!);
        }
        if (q.yearFrom != null) {
          query = query.gte('year_received', q.yearFrom!);
        }
        if (q.yearTo != null) {
          query = query.lte('year_received', q.yearTo!);
        }

        final sortCol = switch (q.sortField) {
          'sku' => 'sku',
          'price' => 'price',
          'quantity' => 'quantity',
          'yearReceived' => 'year_received',
          _ => 'name',
        };
        final from = (q.page - 1) * q.size;
        final to = from + q.size - 1;

        final res = await query.order(sortCol, ascending: q.sortAscending).range(from, to);

        var items = (res as List)
            .whereType<Map>()
            .map((e) => _map(Map<String, dynamic>.from(e)))
            .toList();

        if (q.categoryId != null) {
          items = items.where((p) => p.categoryIds.contains(q.categoryId)).toList();
        }
        if (q.supplierId != null) {
          items = items.where((p) => p.supplierIds.contains(q.supplierId)).toList();
        }

        var countQ = supabase.from('products').select('id');
        if (!q.includeDeleted) countQ = countQ.isFilter('deleted_at', null);
        if (q.warehouseId != null) countQ = countQ.eq('warehouse_id', q.warehouseId!);
        final all = await countQ;
        final resolvedTotal = (all as List).length;

        return PageResult(
          items: items,
          page: q.page,
          size: q.size,
          total: resolvedTotal,
        );
      });

  @override
  Future<Product?> findById(int id) => sbGuard(() async {
        try {
          final row =
              await supabase.from('products').select(_select).eq('id', id).single();
          return _map(Map<String, dynamic>.from(row));
        } on PostgrestException catch (e) {
          if (e.code == 'PGRST116') return null;
          rethrow;
        }
      });

  @override
  Future<List<Product>> findAll({bool includeDeleted = false}) => sbGuard(() async {
        var q = supabase.from('products').select(_select);
        if (!includeDeleted) q = q.isFilter('deleted_at', null);
        final rows = await q.order('name').limit(500);
        return (rows as List)
            .whereType<Map>()
            .map((e) => _map(Map<String, dynamic>.from(e)))
            .toList();
      });

  @override
  Future<Product> create(Product product) => sbGuard(() async {
        final inserted = await supabase
            .from('products')
            .insert({
              'name': product.name,
              'sku': product.sku,
              'warehouse_id': product.warehouseId,
              'price': product.price,
              'quantity': product.quantity,
              'unit': product.unit,
              'year_received': product.yearReceived,
            })
            .select('id')
            .single();
        final id = asInt(inserted['id'])!;
        await _syncLinks(id, product);
        return (await findById(id))!;
      });

  @override
  Future<Product> update(Product product) => sbGuard(() async {
        await supabase.from('products').update({
          'name': product.name,
          'sku': product.sku,
          'warehouse_id': product.warehouseId,
          'price': product.price,
          'quantity': product.quantity,
          'unit': product.unit,
          'year_received': product.yearReceived,
        }).eq('id', product.id);
        await _syncLinks(product.id, product);
        return (await findById(product.id))!;
      });

  @override
  Future<void> softDelete(int id) => sbGuard(() async {
        await supabase
            .from('products')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id);
      });

  @override
  Future<void> hardDelete(int id) => sbGuard(() async {
        await supabase.from('products').delete().eq('id', id);
      });

  @override
  Future<void> restore(int id) => sbGuard(() async {
        await supabase.from('products').update({'deleted_at': null}).eq('id', id);
      });

  @override
  Future<int> deleteMany(List<int> ids) => sbGuard(() async {
        if (ids.isEmpty) return 0;
        await supabase
            .from('products')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .inFilter('id', ids);
        return ids.length;
      });

  @override
  Future<bool> isSkuUnique(String sku, {int? excludeId}) => sbGuard(() async {
        final rows = await supabase.from('products').select('id').eq('sku', sku);
        final list = rows as List;
        if (list.isEmpty) return true;
        if (excludeId != null &&
            list.length == 1 &&
            asInt((list.first as Map)['id']) == excludeId) {
          return true;
        }
        return false;
      });

  @override
  Future<int> countByWarehouse(int warehouseId) => sbGuard(() async {
        final rows = await supabase
            .from('products')
            .select('id')
            .eq('warehouse_id', warehouseId)
            .isFilter('deleted_at', null);
        return (rows as List).length;
      });

  @override
  Future<Product> issue(int id, {int quantity = 1}) => sbGuard(() async {
        await supabase.rpc(
          'issue_product',
          params: {'p_id': id, 'p_qty': quantity, 'p_note': ''},
        );
        return (await findById(id))!;
      });
}
