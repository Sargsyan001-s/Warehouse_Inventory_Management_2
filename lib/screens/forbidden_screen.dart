import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ запрещён')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.orange.shade700),
            const SizedBox(height: 12),
            const Text('Недостаточно прав для этого раздела'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    );
  }
}
