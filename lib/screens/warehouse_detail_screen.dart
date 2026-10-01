import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repositories/category_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/warehouse_repository.dart';

class WarehouseDetailScreen extends StatelessWidget {
  final int id;
  const WarehouseDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _load(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snapshot.data;
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Склад')),
            body: const Center(child: Text('Склад не найден')),
          );
        }
        final w = data.$1;
        return Scaffold(
          appBar: AppBar(
            title: Text(w.name),
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/warehouses')),
            actions: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/warehouses/${w.id}/edit')),
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
                      _row('Код', w.code),
                      _row('Город', w.city),
                      _row('Адрес', w.address),
                      _row('Категории', data.$2),
                      _row('Товаров на складе', '${data.$3}'),
                      _row('Статус', w.isDeleted ? 'Удалён' : 'Активен'),
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

  Future<(dynamic, String, int)?> _load(BuildContext context) async {
    final warehouseRepo = context.read<WarehouseRepository>();
    final categoryRepo = context.read<CategoryRepository>();
    final productRepo = context.read<ProductRepository>();
    final w = await warehouseRepo.findById(id);
    if (w == null) return null;
    final cats = await categoryRepo.findAll(includeDeleted: true);
    final catMap = {for (final c in cats) c.id: c.name};
    final names = w.categoryIds.map((id) => catMap[id] ?? '$id').join(', ');
    final count = await productRepo.countByWarehouse(w.id);
    return (w, names.isEmpty ? '—' : names, count);
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 160, child: Text(label, style: const TextStyle(color: Colors.blueGrey))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
