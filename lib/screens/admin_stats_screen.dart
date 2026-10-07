import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/auth_api.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: FutureBuilder(
        future: context.read<AuthApi>().stats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final s = snapshot.data ?? {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final e in s.entries)
                Card(
                  child: ListTile(
                    title: Text(e.key),
                    trailing: Text(
                      '${e.value}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
