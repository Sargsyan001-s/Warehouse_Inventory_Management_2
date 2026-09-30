import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/supplier.dart';
import '../models/supplier_query.dart';
import '../state/supplier_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_state_body.dart';
import '../widgets/pagination_bar.dart';

class SupplierListScreen extends StatelessWidget {
  const SupplierListScreen({super.key});

  void _syncUrl(BuildContext context, SupplierQuery query) {
    final uri = Uri(path: '/suppliers', queryParameters: query.toQueryParams());
    context.go(uri.toString());
  }

  Future<void> _confirmSoftDelete(BuildContext context, Supplier s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Логическое удаление'),
        content: Text('Скрыть поставщика «${s.name}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<SupplierListNotifier>().softDelete(s.id);
    }
  }

  Future<void> _confirmHardDelete(BuildContext context, Supplier s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Физическое удаление'),
        content: Text('Удалить «${s.name}» навсегда?'),
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
      await context.read<SupplierListNotifier>().hardDelete(s.id);
    }
  }

  Future<void> _confirmDeleteSelected(BuildContext context) async {
    final n = context.read<SupplierListNotifier>();
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

  static const countries = ['Россия', 'Германия', 'Китай', 'Польша', 'Финляндия', 'Латвия'];

  @override
  Widget build(BuildContext context) {
    final n = context.watch<SupplierListNotifier>();
    final q = n.query;
    final wide = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поставщики'),
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
              hintText: 'Поиск по названию или стране',
              onChanged: (v) {
                final next = q.copyWith(search: v);
                n.applyQuery(next);
                _syncUrl(context, next);
              },
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String?>(
                        key: ValueKey('country-${q.country}'),
                        initialValue: q.country,
                        decoration: const InputDecoration(
                          labelText: 'Страна',
                          border: OutlineInputBorder(),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Все')),
                          ...countries.map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          ),
                        ],
                        onChanged: (v) {
                          final next = q.copyWith(country: v);
                          n.applyQuery(next);
                          _syncUrl(context, next);
                        },
                      ),
                    ),
                    FilterChip(
                      label: const Text('Показать удалённые'),
                      selected: q.includeDeleted,
                      onSelected: (v) {
                        final next = q.copyWith(includeDeleted: v);
                        n.applyQuery(next);
                        _syncUrl(context, next);
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        const next = SupplierQuery();
                        n.applyQuery(next);
                        _syncUrl(context, next);
                      },
                      child: const Text('Сбросить'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListStateBody(
                status: n.status,
                error: n.error,
                isEmpty: n.result.items.isEmpty,
                onRetry: () => n.load(),
                child: wide
                    ? EntityTable<Supplier>(
                        items: n.result.items,
                        idOf: (s) => s.id,
                        selected: n.selected,
                        onToggleSelect: n.toggleSelection,
                        sortField: q.sortField,
                        sortAscending: q.sortAscending,
                        isDeleted: (s) => s.isDeleted,
                        onSort: (field) {
                          final next = q.copyWith(
                            sortField: field,
                            sortAscending: field == q.sortField ? !q.sortAscending : true,
                          );
                          n.applyQuery(next);
                          _syncUrl(context, next);
                        },
                        columns: [
                          TableColumnSpec(label: 'Название', sortField: 'name', build: (s) => Text(s.name)),
                          TableColumnSpec(label: 'Страна', sortField: 'country', build: (s) => Text(s.country)),
                          TableColumnSpec(label: 'Город', sortField: 'city', build: (s) => Text(s.city)),
                          TableColumnSpec(label: 'Телефон', build: (s) => Text(s.phone)),
                          TableColumnSpec(label: 'Email', build: (s) => Text(s.email)),
                        ],
                        actions: (s) => [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('/suppliers/${s.id}'),
                          ),
                          if (s.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.restore),
                              onPressed: () => n.restore(s.id),
                            )
                          else ...[
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmSoftDelete(context, s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () => _confirmHardDelete(context, s),
                            ),
                          ],
                        ],
                      )
                    : ListView.builder(
                        itemCount: n.result.items.length,
                        itemBuilder: (context, i) {
                          final s = n.result.items[i];
                          return Card(
                            color: s.isDeleted ? Colors.red.shade50 : Colors.white,
                            child: ListTile(
                              leading: Checkbox(
                                value: n.selected.contains(s.id),
                                onChanged: (_) => n.toggleSelection(s.id),
                              ),
                              title: Text(s.name),
                              subtitle: Text('${s.country}, ${s.city}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () => context.go('/suppliers/${s.id}'),
                              ),
                              onTap: () => context.go('/suppliers/${s.id}'),
                            ),
                          );
                        },
                      ),
              ),
            ),
            PaginationBar(
              result: n.result,
              onPageChanged: (page) {
                final next = SupplierQuery(
                  search: q.search,
                  country: q.country,
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
