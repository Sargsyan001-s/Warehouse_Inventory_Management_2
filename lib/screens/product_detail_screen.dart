import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repositories/category_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/supplier_repository.dart';
import '../repositories/warehouse_repository.dart';

class ProductDetailScreen extends StatelessWidget {
  final int id;

  const ProductDetailScreen({super.key, required this.id});

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
            appBar: AppBar(title: const Text('Товар')),
            body: const Center(child: Text('Товар не найден')),
          );
        }
        final p = data.$1;
        return Scaffold(
          appBar: AppBar(
            title: Text(p.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/products'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/products/${p.id}/edit'),
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
                    children: [
                      _row('Артикул', p.sku),
                      _row('Склад', data.$2),
                      _row('Категории', data.$3),
                      _row('Поставщики', data.$4),
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

  Future<(dynamic, String, String, String)?> _load(BuildContext context) async {
    final productRepo = context.read<ProductRepository>();
    final warehouseRepo = context.read<WarehouseRepository>();
    final categoryRepo = context.read<CategoryRepository>();
    final supplierRepo = context.read<SupplierRepository>();
    final p = await productRepo.findById(id);
    if (p == null) return null;
    final wh = await warehouseRepo.findById(p.warehouseId);
    final cats = await categoryRepo.findAll(includeDeleted: true);
    final sups = await supplierRepo.findAll(includeDeleted: true);
    final catMap = {for (final c in cats) c.id: c.name};
    final supMap = {for (final s in sups) s.id: s.name};
    final catNames = p.categoryIds.map((id) => catMap[id] ?? '$id').join(', ');
    final supNames = p.supplierIds.map((id) => supMap[id] ?? '$id').join(', ');
    return (p, wh?.name ?? '#${p.warehouseId}', catNames, supNames);
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(label, style: const TextStyle(color: Colors.blueGrey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
