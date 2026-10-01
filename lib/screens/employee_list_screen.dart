import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../models/entity_query.dart';
import '../state/employee_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_state_body.dart';
import '../widgets/pagination_bar.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  void _sync(BuildContext context, EntityQuery q) {
    context.go(Uri(path: '/employees', queryParameters: q.toQueryParams()).toString());
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<EmployeeListNotifier>();
    final q = n.query;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сотрудники'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/employees/new')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/employees/new'),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DebouncedSearchField(
              initialValue: q.search,
              hintText: 'Поиск по ФИО, email или пропуску',
              onChanged: (v) {
                final next = q.copyWith(search: v);
                n.applyQuery(next);
                _sync(context, next);
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('lvl-${q.filter}'),
                    initialValue: q.filter,
                    decoration: const InputDecoration(
                      labelText: 'Уровень пропуска',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Все')),
                      DropdownMenuItem(value: 'обычный', child: Text('обычный')),
                      DropdownMenuItem(value: 'ограниченный', child: Text('ограниченный')),
                      DropdownMenuItem(value: 'админ', child: Text('админ')),
                    ],
                    onChanged: (v) {
                      final next = q.copyWith(filter: v);
                      n.applyQuery(next);
                      _sync(context, next);
                    },
                  ),
                ),
                FilterChip(
                  label: const Text('Показать удалённые'),
                  selected: q.includeDeleted,
                  onSelected: (v) {
                    final next = q.copyWith(includeDeleted: v);
                    n.applyQuery(next);
                    _sync(context, next);
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
                child: EntityTable<Employee>(
                  items: n.result.items,
                  idOf: (e) => e.id,
                  selected: n.selected,
                  onToggleSelect: n.toggleSelection,
                  sortField: q.sortField,
                  sortAscending: q.sortAscending,
                  isDeleted: (e) => e.isDeleted,
                  onSort: (field) {
                    final next = q.copyWith(
                      sortField: field,
                      sortAscending: field == q.sortField ? !q.sortAscending : true,
                    );
                    n.applyQuery(next);
                    _sync(context, next);
                  },
                  columns: [
                    TableColumnSpec(label: 'ФИО', sortField: 'fullName', build: (e) => Text(e.fullName)),
                    TableColumnSpec(label: 'Email', sortField: 'email', build: (e) => Text(e.email)),
                    TableColumnSpec(label: 'Должность', sortField: 'position', build: (e) => Text(e.position)),
                    TableColumnSpec(label: 'Пропуск', sortField: 'badge', build: (e) => Text(e.badge.number)),
                    TableColumnSpec(label: 'Уровень', build: (e) => Text(e.badge.level)),
                  ],
                  actions: (e) => [
                    IconButton(icon: const Icon(Icons.visibility), onPressed: () => context.go('/employees/${e.id}')),
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/employees/${e.id}/edit')),
                    if (e.isDeleted)
                      IconButton(icon: const Icon(Icons.restore), onPressed: () => n.restore(e.id))
                    else ...[
                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => n.softDelete(e.id)),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => n.hardDelete(e.id),
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
                  filter: q.filter,
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
