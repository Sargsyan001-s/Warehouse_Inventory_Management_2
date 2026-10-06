import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/auth.dart';

void main() {
  test('viewer может смотреть каталог, но не управлять', () {
    expect(Permissions.canViewCatalog(Role.viewer), isTrue);
    expect(Permissions.canManageCatalog(Role.viewer), isFalse);
    expect(Permissions.canIssue(Role.viewer), isFalse);
  });

  test('operator управляет каталогом и списывает, но не админ', () {
    expect(Permissions.canManageCatalog(Role.operator), isTrue);
    expect(Permissions.canIssue(Role.operator), isTrue);
    expect(Permissions.canHardDelete(Role.operator), isFalse);
    expect(Permissions.canAdminUsers(Role.operator), isFalse);
  });

  test('admin имеет hard delete, restore и пользователей', () {
    expect(Permissions.canHardDelete(Role.admin), isTrue);
    expect(Permissions.canRestore(Role.admin), isTrue);
    expect(Permissions.canAdminUsers(Role.admin), isTrue);
    expect(Permissions.canViewStats(Role.admin), isTrue);
  });

  test('заявки наблюдателя доступны только viewer', () {
    expect(Permissions.canViewOwnRequests(Role.viewer), isTrue);
    expect(Permissions.canViewOwnRequests(Role.operator), isFalse);
    expect(Permissions.canViewOwnRequests(Role.admin), isFalse);
  });

  test('atLeast учитывает иерархию ролей', () {
    expect(Role.admin.atLeast(Role.operator), isTrue);
    expect(Role.operator.atLeast(Role.viewer), isTrue);
    expect(Role.viewer.atLeast(Role.admin), isFalse);
  });
}
