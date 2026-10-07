import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/auth.dart';

/// Упрощённый фрагмент UI: кнопка админа видна только при достаточных правах.
class _AdminOnlyActions extends StatelessWidget {
  final Role role;
  const _AdminOnlyActions({required this.role});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Каталог'),
        if (Permissions.canAdminUsers(role))
          IconButton(
            key: const Key('admin_users_btn'),
            tooltip: 'Пользователи',
            icon: const Icon(Icons.manage_accounts),
            onPressed: () {},
          ),
        if (Permissions.canHardDelete(role))
          IconButton(
            key: const Key('hard_delete_btn'),
            tooltip: 'Удалить навсегда',
            icon: const Icon(Icons.delete_forever),
            onPressed: () {},
          ),
      ],
    );
  }
}

void main() {
  testWidgets('у viewer скрыты недоступные элементы админа', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: _AdminOnlyActions(role: Role.viewer)),
      ),
    );

    expect(find.text('Каталог'), findsOneWidget);
    expect(find.byKey(const Key('admin_users_btn')), findsNothing);
    expect(find.byKey(const Key('hard_delete_btn')), findsNothing);
  });

  testWidgets('у admin видны элементы администрирования', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: _AdminOnlyActions(role: Role.admin)),
      ),
    );

    expect(find.byKey(const Key('admin_users_btn')), findsOneWidget);
    expect(find.byKey(const Key('hard_delete_btn')), findsOneWidget);
    expect(find.byTooltip('Пользователи'), findsOneWidget);
  });
}
