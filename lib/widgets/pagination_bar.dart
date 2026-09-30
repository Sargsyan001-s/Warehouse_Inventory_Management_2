import 'package:flutter/material.dart';

import '../models/page_result.dart';

class PaginationBar extends StatelessWidget {
  final PageResult result;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  const PaginationBar({
    super.key,
    required this.result,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Всего: ${result.total}'),
            Text('Стр. ${result.page} / ${result.totalPages}'),
            IconButton(
              tooltip: 'Первая',
              onPressed: result.hasPrevious ? () => onPageChanged(1) : null,
              icon: const Icon(Icons.first_page),
            ),
            IconButton(
              tooltip: 'Предыдущая',
              onPressed: result.hasPrevious
                  ? () => onPageChanged(result.page - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Следующая',
              onPressed: result.hasNext
                  ? () => onPageChanged(result.page + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              tooltip: 'Последняя',
              onPressed: result.hasNext
                  ? () => onPageChanged(result.totalPages)
                  : null,
              icon: const Icon(Icons.last_page),
            ),
            const Text('На странице:'),
            DropdownButton<int>(
              value: result.size,
              items: const [10, 25, 50]
                  .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                  .toList(),
              onChanged: (v) {
                if (v != null) onSizeChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
