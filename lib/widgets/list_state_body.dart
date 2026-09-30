import 'package:flutter/material.dart';

import '../state/product_list_notifier.dart';

class ListStateBody extends StatelessWidget {
  final LoadStatus status;
  final String? error;
  final bool isEmpty;
  final VoidCallback onRetry;
  final Widget child;

  const ListStateBody({
    super.key,
    required this.status,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (status == LoadStatus.loading || status == LoadStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == LoadStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(error ?? 'Ошибка', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.blue.shade300),
            const SizedBox(height: 12),
            const Text('Ничего не найдено'),
            const SizedBox(height: 4),
            Text(
              'Измените поиск или фильтры',
              style: TextStyle(color: Colors.blueGrey.shade400),
            ),
          ],
        ),
      );
    }

    return child;
  }
}
