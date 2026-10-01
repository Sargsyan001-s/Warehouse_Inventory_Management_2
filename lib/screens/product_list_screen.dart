import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/product_query.dart';
import '../repositories/category_repository.dart';
import '../repositories/supplier_repository.dart';
import '../repositories/warehouse_repository.dart';
import '../state/product_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_state_body.dart';
import '../widgets/pagination_bar.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  Map<int, String> _categories = {};
  Map<int, String> _suppliers = {};
  Map<int, String> _warehouses = {};

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final categoryRepo = context.read<CategoryRepository>();
    final supplierRepo = context.read<SupplierRepository>();
    final warehouseRepo = context.read<WarehouseRepository>();
    final cats = await categoryRepo.findAll(includeDeleted: true);
    final sups = await supplierRepo.findAll(includeDeleted: true);
    final whs = await warehouseRepo.findAll(includeDeleted: true);
    if (!mounted) return;
    setState(() {
      _categories = {for (final c in cats) c.id: c.name};
      _suppliers = {for (final s in sups) s.id: s.name};
      _warehouses = {for (final w in whs) w.id: w.name};
    });
  }

  void _syncUrl(BuildContext context, ProductQuery query) {
    final uri = Uri(path: '/products', queryParameters: query.toQueryParams());
    context.go(uri.toString());
  }

  Future<void> _confirmSoftDelete(BuildContext context, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Логическое удаление'),
        content: Text('Скрыть товар «${p.name}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<ProductListNotifier>().softDelete(p.id);
    }
  }

  Future<void> _confirmHardDelete(BuildContext context, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Физическое удаление'),
        content: Text('Удалить «${p.name}» навсегда?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<ProductListNotifier>().hardDelete(p.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<ProductListNotifier>();
    final q = n.query;
    final wide = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Товары'),
        actions: [
          if (n.hasSelection)
            IconButton(
              tooltip: 'Удалить выбранные',
              onPressed: () async {
                await n.deleteSelected();
              },
              icon: const Icon(Icons.delete_sweep),
            ),
          IconButton(
            tooltip: 'Добавить',
            onPressed: () => context.go('/products/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/products/new'),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DebouncedSearchField(
              initialValue: q.search,
              hintText: 'Поиск по названию или артикулу',
              onChanged: (v) {
                final next = q.copyWith(search: v);
                n.applyQuery(next);
                _syncUrl(context, next);
              },
            ),
            const SizedBox(height: 8),
            _FiltersPanel(
              query: q,
              categories: _categories,
              suppliers: _suppliers,
              warehouses: _warehouses,
              onChanged: (next) {
                n.applyQuery(next);
                _syncUrl(context, next);
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListStateBody(
                status: n.status,
                error: n.error,
                isEmpty: n.result.items.isEmpty,
                onRetry: () => n.load(),
                child: wide
                    ? EntityTable<Product>(
                        items: n.result.items,
                        idOf: (p) => p.id,
                        selected: n.selected,
                        onToggleSelect: n.toggleSelection,
                        sortField: q.sortField,
                        sortAscending: q.sortAscending,
                        isDeleted: (p) => p.isDeleted,
                        onSort: (field) {
                          final next = q.copyWith(
                            sortField: field,
                            sortAscending: field == q.sortField ? !q.sortAscending : true,
                          );
                          n.applyQuery(next);
                          _syncUrl(context, next);
                        },
                        columns: [
                          TableColumnSpec(label: 'Название', sortField: 'name', build: (p) => Text(p.name)),
                          TableColumnSpec(label: 'Артикул', sortField: 'sku', build: (p) => Text(p.sku)),
                          TableColumnSpec(
                            label: 'Склад',
                            build: (p) => Text(_warehouses[p.warehouseId] ?? '#${p.warehouseId}'),
                          ),
                          TableColumnSpec(
                            label: 'Категории',
                            build: (p) => Text(
                              p.categoryIds.map((id) => _categories[id] ?? '$id').join(', '),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Цена',
                            sortField: 'price',
                            numeric: true,
                            build: (p) => Text(p.price.toStringAsFixed(2)),
                          ),
                          TableColumnSpec(
                            label: 'Кол-во',
                            sortField: 'quantity',
                            numeric: true,
                            build: (p) => Text('${p.quantity}'),
                          ),
                        ],
                        actions: (p) => [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('/products/${p.id}'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => context.go('/products/${p.id}/edit'),
                          ),
                          if (p.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.restore),
                              onPressed: () => n.restore(p.id),
                            )
                          else ...[
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmSoftDelete(context, p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () => _confirmHardDelete(context, p),
                            ),
                          ],
                        ],
                      )
                    : ListView.builder(
                        itemCount: n.result.items.length,
                        itemBuilder: (context, i) {
                          final p = n.result.items[i];
                          return Card(
                            color: p.isDeleted ? Colors.red.shade50 : Colors.white,
                            child: ListTile(
                              title: Text(p.name),
                              subtitle: Text('${p.sku} · ${_warehouses[p.warehouseId] ?? ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => context.go('/products/${p.id}/edit'),
                              ),
                              onTap: () => context.go('/products/${p.id}'),
                            ),
                          );
                        },
                      ),
              ),
            ),
            PaginationBar(
              result: n.result,
              onPageChanged: (page) {
                final next = ProductQuery(
                  search: q.search,
                  categoryId: q.categoryId,
                  supplierId: q.supplierId,
                  warehouseId: q.warehouseId,
                  yearFrom: q.yearFrom,
                  yearTo: q.yearTo,
                  sortField: q.sortField,
                  sortAscending: q.sortAscending,
                  page: page,
                  size: q.size,
                  includeDeleted: q.includeDeleted,
                );
                n.applyQuery(next);
                _syncUrl(context, next);
              },
              onSizeChanged: (size) {
                final next = q.copyWith(size: size, page: 1);
                n.applyQuery(next);
                _syncUrl(context, next);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  final ProductQuery query;
  final Map<int, String> categories;
  final Map<int, String> suppliers;
  final Map<int, String> warehouses;
  final ValueChanged<ProductQuery> onChanged;

  const _FiltersPanel({
    required this.query,
    required this.categories,
    required this.suppliers,
    required this.warehouses,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final q = query;
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: const Text('Фильтры'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey('wh-${q.warehouseId}'),
                    initialValue: q.warehouseId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Склад',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все', overflow: TextOverflow.ellipsis)),
                      ...warehouses.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => onChanged(q.copyWith(warehouseId: v)),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey('cat-${q.categoryId}'),
                    initialValue: q.categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все', overflow: TextOverflow.ellipsis)),
                      ...categories.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => onChanged(q.copyWith(categoryId: v)),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey('sup-${q.supplierId}'),
                    initialValue: q.supplierId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Поставщик',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все', overflow: TextOverflow.ellipsis)),
                      ...suppliers.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => onChanged(q.copyWith(supplierId: v)),
                  ),
                ),
                FilterChip(
                  label: const Text('Показать удалённые'),
                  selected: q.includeDeleted,
                  onSelected: (v) => onChanged(q.copyWith(includeDeleted: v)),
                ),
                TextButton(
                  onPressed: () => onChanged(const ProductQuery()),
                  child: const Text('Сбросить'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
