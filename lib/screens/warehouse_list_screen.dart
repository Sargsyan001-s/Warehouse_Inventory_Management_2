import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/entity_query.dart';
import '../models/warehouse.dart';
import '../repositories/product_repository.dart';
import '../state/warehouse_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_state_body.dart';
import '../widgets/pagination_bar.dart';

class WarehouseListScreen extends StatelessWidget {
  const WarehouseListScreen({super.key});

  void _sync(BuildContext context, EntityQuery q) {
    context.go(Uri(path: '/warehouses', queryParameters: q.toQueryParams()).toString());
  }

  Future<void> _tryDelete(BuildContext context, Warehouse w, {required bool hard}) async {
    final linked = await context.read<ProductRepository>().countByWarehouse(w.id);
    if (!context.mounted) return;
    if (linked > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удаление невозможно'),
          content: Text(
            'Склад «${w.name}» связан с $linked товар(ами). '
            'Сначала перенесите или удалите эти товары.',
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно')),
          ],
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hard ? 'Физическое удаление' : 'Логическое удаление'),
        content: Text(hard ? 'Удалить склад «${w.name}» навсегда?' : 'Скрыть склад «${w.name}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final n = context.read<WarehouseListNotifier>();
      try {
        if (hard) {
          await n.hardDelete(w.id);
        } else {
          await n.softDelete(w.id);
        }
      } on ConflictException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<WarehouseListNotifier>();
    final q = n.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Склады'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/warehouses/new')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/warehouses/new'),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DebouncedSearchField(
              initialValue: q.search,
              hintText: 'Поиск по названию или коду',
              onChanged: (v) {
                final next = q.copyWith(search: v);
                n.applyQuery(next);
                _sync(context, next);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Показать удалённые'),
                selected: q.includeDeleted,
                onSelected: (v) {
                  final next = q.copyWith(includeDeleted: v);
                  n.applyQuery(next);
                  _sync(context, next);
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListStateBody(
                status: n.status,
                error: n.error,
                isEmpty: n.result.items.isEmpty,
                onRetry: n.load,
                child: EntityTable<Warehouse>(
                  items: n.result.items,
                  idOf: (w) => w.id,
                  selected: n.selected,
                  onToggleSelect: n.toggleSelection,
                  sortField: q.sortField,
                  sortAscending: q.sortAscending,
                  isDeleted: (w) => w.isDeleted,
                  onSort: (field) {
                    final next = q.copyWith(
                      sortField: field,
                      sortAscending: field == q.sortField ? !q.sortAscending : true,
                    );
                    n.applyQuery(next);
                    _sync(context, next);
                  },
                  columns: [
                    TableColumnSpec(label: 'Название', sortField: 'name', build: (w) => Text(w.name)),
                    TableColumnSpec(label: 'Код', sortField: 'code', build: (w) => Text(w.code)),
                    TableColumnSpec(label: 'Город', sortField: 'city', build: (w) => Text(w.city)),
                    TableColumnSpec(label: 'Адрес', build: (w) => Text(w.address)),
                  ],
                  actions: (w) => [
                    IconButton(icon: const Icon(Icons.visibility), onPressed: () => context.go('/warehouses/${w.id}')),
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/warehouses/${w.id}/edit')),
                    if (w.isDeleted)
                      IconButton(icon: const Icon(Icons.restore), onPressed: () => n.restore(w.id))
                    else ...[
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _tryDelete(context, w, hard: false),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _tryDelete(context, w, hard: true),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            PaginationBar(
              result: n.result,
              onPageChanged: (page) {
                final next = EntityQuery(
                  search: q.search,
                  sortField: q.sortField,
                  sortAscending: q.sortAscending,
                  page: page,
                  size: q.size,
                  includeDeleted: q.includeDeleted,
                );
                n.applyQuery(next);
                _sync(context, next);
              },
              onSizeChanged: (size) {
                final next = q.copyWith(size: size, page: 1);
                n.applyQuery(next);
                _sync(context, next);
              },
            ),
          ],
        ),
      ),
    );
  }
}
