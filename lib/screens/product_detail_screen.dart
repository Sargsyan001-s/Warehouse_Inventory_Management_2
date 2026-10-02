import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/reference_cache.dart';
import '../models/product.dart';
import '../repositories/api_product_repository.dart';
import '../repositories/product_repository.dart';
import '../state/product_list_notifier.dart';

class ProductDetailScreen extends StatefulWidget {
  final int id;

  const ProductDetailScreen({super.key, required this.id});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<(Product, String, String, String)?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(Product, String, String, String)?> _load() async {
    final productRepo = context.read<ProductRepository>();
    final cache = context.read<ReferenceCache>();
    final p = await productRepo.findById(widget.id);
    if (p == null) return null;
    final warehouses = await cache.warehouses();
    final categories = await cache.categories();
    final suppliers = await cache.suppliers();
    final wh = warehouses.where((w) => w.id == p.warehouseId).firstOrNull;
    final catMap = {for (final c in categories) c.id: c.name};
    final supMap = {for (final s in suppliers) s.id: s.name};
    final catNames = p.categoryIds.map((id) => catMap[id] ?? '$id').join(', ');
    final supNames = p.supplierIds.map((id) => supMap[id] ?? '$id').join(', ');
    return (p, wh?.name ?? '#${p.warehouseId}', catNames, supNames);
  }

  Future<void> _issue(Product p) async {
    final repo = context.read<ProductRepository>();
    if (repo is! ApiProductRepository) return;
    try {
      await repo.issue(p.id, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Списана 1 единица')),
      );
      setState(() => _future = _load());
      await context.read<ProductListNotifier>().load();
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.orange.shade800),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
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
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: p.isDeleted ? null : () => _issue(p),
                icon: const Icon(Icons.outbox),
                label: const Text('Списать 1 шт (демо 409 при нуле)'),
              ),
              const SizedBox(height: 8),
              Text(
                'Товар «Уровень 60 см» (LVL-60) имеет остаток 0 — списание даст конфликт 409.',
                style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(label, style: const TextStyle(color: Colors.blueGrey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
