import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;
  final bool Function(T item)? isDeleted;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
    this.isDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Colors.blue.shade50,
                  ),
                  columns: [
                    if (onToggleSelect != null)
                      const DataColumn(label: Text('')),
                    ...columns.map((c) {
                      final active = c.sortField != null && c.sortField == sortField;
                      return DataColumn(
                        numeric: c.numeric,
                        label: InkWell(
                          onTap: c.sortField == null || onSort == null
                              ? null
                              : () => onSort!(c.sortField!),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c.label,
                                style: TextStyle(
                                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                                  color: active ? Colors.blue.shade800 : null,
                                ),
                              ),
                              if (active)
                                Icon(
                                  sortAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 16,
                                  color: Colors.blue.shade700,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (actions != null) const DataColumn(label: Text('Действия')),
                  ],
                  rows: items.map((item) {
                    final id = idOf(item);
                    final deleted = isDeleted?.call(item) ?? false;
                    return DataRow(
                      selected: selected.contains(id),
                      color: deleted
                          ? WidgetStateProperty.all(Colors.red.shade50)
                          : null,
                      cells: [
                        if (onToggleSelect != null)
                          DataCell(
                            Checkbox(
                              value: selected.contains(id),
                              onChanged: (_) => onToggleSelect!(id),
                            ),
                          ),
                        ...columns.map((c) => DataCell(c.build(item))),
                        if (actions != null)
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions!(item),
                          )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
