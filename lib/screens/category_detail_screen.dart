import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repositories/category_repository.dart';

class CategoryDetailScreen extends StatelessWidget {
  final int id;
  const CategoryDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CategoryRepository>().findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final c = snapshot.data;
        if (c == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Категория')),
            body: const Center(child: Text('Категория не найдена')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(c.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/categories'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/categories/${c.id}/edit'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Описание',
                        style: TextStyle(color: Colors.blueGrey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(c.description.isEmpty ? '—' : c.description),
                      const SizedBox(height: 16),
                      Text('Статус: ${c.isDeleted ? 'Удалена' : 'Активна'}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
