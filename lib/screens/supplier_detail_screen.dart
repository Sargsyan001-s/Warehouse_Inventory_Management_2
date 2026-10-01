import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repositories/supplier_repository.dart';

class SupplierDetailScreen extends StatelessWidget {
  final int id;
  const SupplierDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<SupplierRepository>().findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final s = snapshot.data;
        if (s == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Поставщик')),
            body: const Center(child: Text('Поставщик не найден')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(s.name),
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/suppliers')),
            actions: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/suppliers/${s.id}/edit')),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Страна', s.country),
                      _row('Город', s.city),
                      _row('Телефон', s.phone),
                      _row('Email', s.email),
                      _row('Статус', s.isDeleted ? 'Удалён' : 'Активен'),
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

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.blueGrey))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
