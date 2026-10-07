import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/auth.dart';
import 'package:flutter_application_2/models/product.dart';
import 'package:flutter_application_2/models/supplier.dart';

void main() {
  group('Product.fromJson', () {
    test('отсутствующие поля не приводят к исключению', () {
      final p = Product.fromJson({'id': 1});
      expect(p.name, '');
      expect(p.sku, '');
      expect(p.categoryIds, isEmpty);
      expect(p.supplierIds, isEmpty);
      expect(p.unit, 'шт');
    });

    test('разбирает вложенные связи categories/suppliers', () {
      final p = Product.fromJson({
        'id': 2,
        'name': 'Гайка',
        'sku': 'G-1',
        'warehouse': {'id': 3},
        'categories': [
          {'id': 10},
          {'id': 11},
        ],
        'suppliers': [
          {'id': 20},
        ],
        'price': 5.5,
        'quantity': 100,
      });
      expect(p.warehouseId, 3);
      expect(p.categoryIds, [10, 11]);
      expect(p.supplierIds, [20]);
      expect(p.price, 5.5);
    });
  });

  group('AppUser.fromJson', () {
    test('неизвестная роль становится viewer', () {
      final u = AppUser.fromJson({
        'id': 1,
        'username': 'x',
        'displayName': 'X',
        'role': 'unknown',
      });
      expect(u.role, Role.viewer);
      expect(u.id, '1');
    });

    test('корректно читает admin и UUID', () {
      final u = AppUser.fromJson({
        'id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'username': 'admin',
        'display_name': 'Админ',
        'role': 'admin',
      });
      expect(u.role, Role.admin);
      expect(u.displayName, 'Админ');
      expect(u.id.length, greaterThan(10));
    });
  });

  group('Supplier.fromJson', () {
    test('пустой объект безопасен', () {
      final s = Supplier.fromJson({'id': 1});
      expect(s.name, '');
      expect(s.isDeleted, isFalse);
    });
  });
}
