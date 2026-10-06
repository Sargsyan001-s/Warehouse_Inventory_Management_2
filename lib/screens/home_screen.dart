import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Главная', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'Добро пожаловать${user != null ? ', ${user.displayName}' : ''}!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
