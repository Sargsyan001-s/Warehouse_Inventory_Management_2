import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../state/product_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_state_body.dart';
import '../widgets/pagination_bar.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

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

  Future<void> _confirmDeleteSelected(BuildContext context) async {
    final n = context.read<ProductListNotifier>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить выбранные'),
        content: Text('Логически удалить ${n.selected.length} записей?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await n.deleteSelected();
      if (context.mounted) _syncUrl(context, n.query);
    }
  }

  String _categoryName(int id) =>
      seedCategories.firstWhere((c) => c.id == id, orElse: () => seedCategories.first).name;

  String _supplierName(int id) =>
      seedSuppliers.firstWhere((s) => s.id == id, orElse: () => seedSuppliers.first).name;

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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: Text('Выбрано: ${n.selected.length}')),
            ),
          if (n.hasSelection)
            IconButton(
              tooltip: 'Удалить выбранные',
              onPressed: () => _confirmDeleteSelected(context),
              icon: const Icon(Icons.delete_sweep),
            ),
          IconButton(
            tooltip: 'Симулировать ошибку',
            onPressed: () => n.simulateError(),
            icon: const Icon(Icons.bug_report_outlined),
          ),
        ],
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
                          TableColumnSpec(label: 'Категория', build: (p) => Text(_categoryName(p.categoryId))),
                          TableColumnSpec(label: 'Поставщик', build: (p) => Text(_supplierName(p.supplierId))),
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
                          TableColumnSpec(
                            label: 'Год',
                            sortField: 'yearReceived',
                            numeric: true,
                            build: (p) => Text('${p.yearReceived}'),
                          ),
                        ],
                        actions: (p) => [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('/products/${p.id}'),
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
                              leading: Checkbox(
                                value: n.selected.contains(p.id),
                                onChanged: (_) => n.toggleSelection(p.id),
                              ),
                              title: Text(p.name),
                              subtitle: Text(
                                '${p.sku} · ${_categoryName(p.categoryId)} · ${p.price.toStringAsFixed(2)} ₽',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () => context.go('/products/${p.id}'),
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

class _FiltersPanel extends StatefulWidget {
  final ProductQuery query;
  final ValueChanged<ProductQuery> onChanged;

  const _FiltersPanel({required this.query, required this.onChanged});

  @override
  State<_FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<_FiltersPanel> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: const Text('Фильтры'),
        onExpansionChanged: (v) => setState(() => _open = v),
        children: [
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<int?>(
                      key: ValueKey('cat-${q.categoryId}'),
                      initialValue: q.categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Категория',
                        border: OutlineInputBorder(),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все')),
                        ...seedCategories.map(
                          (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ),
                      ],
                      onChanged: (v) => widget.onChanged(q.copyWith(categoryId: v)),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<int?>(
                      key: ValueKey('sup-${q.supplierId}'),
                      initialValue: q.supplierId,
                      decoration: const InputDecoration(
                        labelText: 'Поставщик',
                        border: OutlineInputBorder(),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все')),
                        ...seedSuppliers.map(
                          (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                        ),
                      ],
                      onChanged: (v) => widget.onChanged(q.copyWith(supplierId: v)),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<int?>(
                      key: ValueKey('yf-${q.yearFrom}'),
                      initialValue: q.yearFrom,
                      decoration: const InputDecoration(
                        labelText: 'Год от',
                        border: OutlineInputBorder(),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ...[2022, 2023, 2024, 2025].map(
                          (y) => DropdownMenuItem(value: y, child: Text('$y')),
                        ),
                      ],
                      onChanged: (v) => widget.onChanged(q.copyWith(yearFrom: v)),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<int?>(
                      key: ValueKey('yt-${q.yearTo}'),
                      initialValue: q.yearTo,
                      decoration: const InputDecoration(
                        labelText: 'Год до',
                        border: OutlineInputBorder(),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ...[2022, 2023, 2024, 2025].map(
                          (y) => DropdownMenuItem(value: y, child: Text('$y')),
                        ),
                      ],
                      onChanged: (v) => widget.onChanged(q.copyWith(yearTo: v)),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Показать удалённые'),
                    selected: q.includeDeleted,
                    onSelected: (v) => widget.onChanged(q.copyWith(includeDeleted: v)),
                  ),
                  TextButton(
                    onPressed: () => widget.onChanged(const ProductQuery()),
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
