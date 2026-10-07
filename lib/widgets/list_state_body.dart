import 'package:flutter/material.dart';

import '../state/entity_list_notifier.dart';

class ListStateBody extends StatelessWidget {
  final LoadStatus status;
  final String? error;
  final bool isEmpty;
  final VoidCallback onRetry;
  final Widget child;
  final String emptyTitle;
  final String emptySubtitle;

  const ListStateBody({
    super.key,
    required this.status,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.child,
    this.emptyTitle = 'Ничего не найдено',
    this.emptySubtitle = 'Измените поиск или фильтры',
  });

  bool get _isOffline {
    final e = (error ?? '').toLowerCase();
    return e.contains('сервер недоступен') ||
        e.contains('соединени') ||
        e.contains('network') ||
        e.contains('connection');
  }

  @override
  Widget build(BuildContext context) {
    if (status == LoadStatus.loading || status == LoadStatus.idle) {
      return const Center(
        child: CircularProgressIndicator(key: Key('list_loading')),
      );
    }

    if (status == LoadStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isOffline ? Icons.cloud_off_outlined : Icons.error_outline,
                size: 56,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                _isOffline ? 'Нет связи с сервером' : (error ?? 'Ошибка'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _isOffline
                    ? 'Проверьте соединение и нажмите «Повторить» — перезагрузка страницы не нужна.'
                    : (error ?? 'Попробуйте ещё раз'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey.shade600),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('list_retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ),
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
            Text(emptyTitle, key: const Key('list_empty')),
            const SizedBox(height: 4),
            Text(
              emptySubtitle,
              style: TextStyle(color: Colors.blueGrey.shade400),
            ),
          ],
        ),
      );
    }

    return child;
  }
}
