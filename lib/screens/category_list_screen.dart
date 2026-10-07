import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/category.dart';
import '../models/entity_query.dart';
import '../state/category_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/ellipsis_text.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_state_body.dart';
import '../widgets/pagination_bar.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  void _sync(BuildContext context, EntityQuery q) {
    context.go(
      Uri(path: '/categories', queryParameters: q.toQueryParams()).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<CategoryListNotifier>();
    final q = n.query;
    final useTable = context.useDataTable;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории'),
        actions: [
          IconButton(
            tooltip: 'Добавить',
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/categories/new'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить категорию',
        onPressed: () => context.go('/categories/new'),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DebouncedSearchField(
              initialValue: q.search,
              hintText: 'Поиск по названию',
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
                child: useTable
                    ? EntityTable<Category>(
                        items: n.result.items,
                        idOf: (c) => c.id,
                        selected: n.selected,
                        onToggleSelect: n.toggleSelection,
                        sortField: q.sortField,
                        sortAscending: q.sortAscending,
                        isDeleted: (c) => c.isDeleted,
                        onSort: (field) {
                          final next = q.copyWith(
                            sortField: field,
                            sortAscending: field == q.sortField
                                ? !q.sortAscending
                                : true,
                          );
                          n.applyQuery(next);
                          _sync(context, next);
                        },
                        columns: [
                          TableColumnSpec(
                            label: 'Название',
                            sortField: 'name',
                            build: (c) => SizedBox(
                              width: 200,
                              child: EllipsisText(c.name),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Описание',
                            build: (c) => SizedBox(
                              width: 280,
                              child: EllipsisText(c.description),
                            ),
                          ),
                        ],
                        actions: (c) => [
                          IconButton(
                            tooltip: 'Открыть',
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('/categories/${c.id}'),
                          ),
                          IconButton(
                            tooltip: 'Изменить',
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                context.go('/categories/${c.id}/edit'),
                          ),
                          if (c.isDeleted)
                            IconButton(
                              tooltip: 'Восстановить',
                              icon: const Icon(Icons.restore),
                              onPressed: () => n.restore(c.id),
                            )
                          else ...[
                            IconButton(
                              tooltip: 'Скрыть',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => n.softDelete(c.id),
                            ),
                            IconButton(
                              tooltip: 'Удалить навсегда',
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                              ),
                              onPressed: () => n.hardDelete(c.id),
                            ),
                          ],
                        ],
                      )
                    : ListView.builder(
                        itemCount: n.result.items.length,
                        itemBuilder: (_, i) {
                          final c = n.result.items[i];
                          return Card(
                            color: c.isDeleted ? Colors.red.shade50 : null,
                            child: ListTile(
                              title: EllipsisText(c.name),
                              subtitle: EllipsisText(c.description),
                              onTap: () => context.go('/categories/${c.id}'),
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
