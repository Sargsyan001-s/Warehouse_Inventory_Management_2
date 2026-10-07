import 'package:flutter/material.dart';

/// Предупреждение о несохранённых изменениях через PopScope.
class UnsavedChangesScope extends StatelessWidget {
  final bool isDirty;
  final Widget child;
  final VoidCallback? onPopConfirmed;

  const UnsavedChangesScope({
    super.key,
    required this.isDirty,
    required this.child,
    this.onPopConfirmed,
  });

  Future<bool> _confirm(BuildContext context) async {
    if (!isDirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Уйти без сохранения? Изменения будут потеряны.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Уйти'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirm(context);
        if (ok && context.mounted) {
          onPopConfirmed?.call();
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
