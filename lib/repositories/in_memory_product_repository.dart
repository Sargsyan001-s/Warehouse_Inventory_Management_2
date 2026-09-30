import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import 'product_repository.dart';

class InMemoryProductRepository implements ProductRepository {
  final List<Product> _items = [...seedProducts];
  int _nextId = seedProducts.length + 1;

  @override
  Future<PageResult<Product>> find(ProductQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _items.where((p) => q.includeDeleted || !p.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((p) =>
              p.name.toLowerCase().contains(needle) ||
              p.sku.toLowerCase().contains(needle))
          .toList();
    }

    if (q.categoryId != null) {
      rows = rows.where((p) => p.categoryId == q.categoryId).toList();
    }
    if (q.supplierId != null) {
      rows = rows.where((p) => p.supplierId == q.supplierId).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((p) => p.yearReceived >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((p) => p.yearReceived <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'price' => a.price.compareTo(b.price),
        'quantity' => a.quantity.compareTo(b.quantity),
        'yearReceived' => a.yearReceived.compareTo(b.yearReceived),
        'sku' => a.sku.toLowerCase().compareTo(b.sku.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Product>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Product?> findById(int id) async {
    try {
      return _items.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Product> create(Product product) async {
    final created = Product(
      id: _nextId++,
      name: product.name,
      sku: product.sku,
      categoryId: product.categoryId,
      supplierId: product.supplierId,
      price: product.price,
      quantity: product.quantity,
      unit: product.unit,
      yearReceived: product.yearReceived,
    );
    _items.add(created);
    return created;
  }

  @override
  Future<Product> update(Product product) async {
    final i = _items.indexWhere((p) => p.id == product.id);
    if (i == -1) throw StateError('Товар ${product.id} не найден');
    _items[i] = product;
    return product;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Товар $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Товар $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
