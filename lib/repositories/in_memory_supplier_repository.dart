import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/supplier.dart';
import '../models/supplier_query.dart';
import 'supplier_repository.dart';

class InMemorySupplierRepository implements SupplierRepository {
  final List<Supplier> _items = [...seedSuppliers];
  int _nextId = seedSuppliers.length + 1;

  @override
  Future<PageResult<Supplier>> find(SupplierQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _items.where((s) => q.includeDeleted || !s.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((s) =>
              s.name.toLowerCase().contains(needle) ||
              s.country.toLowerCase().contains(needle) ||
              s.city.toLowerCase().contains(needle))
          .toList();
    }

    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((s) => s.country == q.country).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Supplier>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Supplier?> findById(int id) async {
    try {
      return _items.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Supplier> create(Supplier supplier) async {
    final created = Supplier(
      id: _nextId++,
      name: supplier.name,
      country: supplier.country,
      city: supplier.city,
      phone: supplier.phone,
      email: supplier.email,
    );
    _items.add(created);
    return created;
  }

  @override
  Future<Supplier> update(Supplier supplier) async {
    final i = _items.indexWhere((s) => s.id == supplier.id);
    if (i == -1) throw StateError('Поставщик ${supplier.id} не найден');
    _items[i] = supplier;
    return supplier;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((s) => s.id == id);
    if (i == -1) throw StateError('Поставщик $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((s) => s.id == id);
    if (i == -1) throw StateError('Поставщик $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((s) => s.id == id && !s.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
