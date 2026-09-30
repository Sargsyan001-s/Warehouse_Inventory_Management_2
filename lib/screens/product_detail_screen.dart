import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/seed_data.dart';
import '../repositories/product_repository.dart';

class ProductDetailScreen extends StatelessWidget {
  final int id;

  const ProductDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<ProductRepository>().findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final p = snapshot.data;
        if (p == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Товар')),
            body: const Center(child: Text('Товар не найден')),
          );
        }

        final category = seedCategories
            .firstWhere((c) => c.id == p.categoryId, orElse: () => seedCategories.first)
            .name;
        final supplier = seedSuppliers
            .firstWhere((s) => s.id == p.supplierId, orElse: () => seedSuppliers.first)
            .name;

        return Scaffold(
          appBar: AppBar(
            title: Text(p.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/products'),
            ),
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
                      _row('Артикул', p.sku),
                      _row('Категория', category),
                      _row('Поставщик', supplier),
                      _row('Цена', '${p.price.toStringAsFixed(2)} ₽'),
                      _row('Количество', '${p.quantity} ${p.unit}'),
                      _row('Год поступления', '${p.yearReceived}'),
                      _row('Статус', p.isDeleted ? 'Удалён' : 'Активен'),
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 160, child: Text(label, style: const TextStyle(color: Colors.blueGrey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
