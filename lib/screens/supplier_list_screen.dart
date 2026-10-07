import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/entity_query.dart';
import '../models/supplier.dart';
import '../state/supplier_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/ellipsis_text.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_state_body.dart';
import '../widgets/pagination_bar.dart';

class SupplierListScreen extends StatelessWidget {
  const SupplierListScreen({super.key});

  void _syncUrl(BuildContext context, EntityQuery query) {
    context.go(
      Uri(
        path: '/suppliers',
        queryParameters: query.toQueryParams(),
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<SupplierListNotifier>();
    final q = n.query;
    final useTable = context.useDataTable;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поставщики'),
        actions: [
          IconButton(
            tooltip: 'Добавить',
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/suppliers/new'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить поставщика',
        onPressed: () => context.go('/suppliers/new'),
        child: const Icon(Icons.add),
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
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Показать удалённые'),
                  selected: q.includeDeleted,
                  onSelected: (v) {
                    final next = q.copyWith(includeDeleted: v);
                    n.applyQuery(next);
                    _syncUrl(context, next);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListStateBody(
                status: n.status,
                error: n.error,
                isEmpty: n.result.items.isEmpty,
                onRetry: n.load,
                child: useTable
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
                            sortAscending: field == q.sortField
                                ? !q.sortAscending
                                : true,
                          );
                          n.applyQuery(next);
                          _syncUrl(context, next);
                        },
                        columns: [
                          TableColumnSpec(
                            label: 'Название',
                            sortField: 'name',
                            build: (s) => SizedBox(
                              width: 180,
                              child: EllipsisText(s.name),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Страна',
                            sortField: 'country',
                            build: (s) => EllipsisText(s.country),
                          ),
                          TableColumnSpec(
                            label: 'Город',
                            sortField: 'city',
                            build: (s) => EllipsisText(s.city),
                          ),
                          TableColumnSpec(
                            label: 'Email',
                            sortField: 'email',
                            build: (s) => EllipsisText(s.email),
                          ),
                        ],
                        actions: (s) => [
                          IconButton(
                            tooltip: 'Открыть',
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('/suppliers/${s.id}'),
                          ),
                          IconButton(
                            tooltip: 'Изменить',
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                context.go('/suppliers/${s.id}/edit'),
                          ),
                          if (s.isDeleted)
                            IconButton(
                              tooltip: 'Восстановить',
                              icon: const Icon(Icons.restore),
                              onPressed: () => n.restore(s.id),
                            )
                          else ...[
                            IconButton(
                              tooltip: 'Скрыть',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => n.softDelete(s.id),
                            ),
                            IconButton(
                              tooltip: 'Удалить навсегда',
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                              ),
                              onPressed: () => n.hardDelete(s.id),
                            ),
                          ],
                        ],
                      )
                    : ListView.builder(
                        itemCount: n.result.items.length,
                        itemBuilder: (_, i) {
                          final s = n.result.items[i];
                          return Card(
                            child: ListTile(
                              title: EllipsisText(s.name),
                              subtitle: EllipsisText('${s.country}, ${s.city}'),
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
                final next = EntityQuery(
                  search: q.search,
                  filter: q.filter,
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
