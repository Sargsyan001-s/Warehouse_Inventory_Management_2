import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_2/repositories/auth_api.dart';
import 'package:flutter_application_2/screens/login_screen.dart';
import 'package:flutter_application_2/state/auth_notifier.dart';
import 'package:dio/dio.dart';

void main() {
  testWidgets('форма входа не отправляется с пустым логином', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthNotifier(prefs, AuthApi(Dio()));

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider<AuthNotifier>.value(value: auth)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Войти'));
    await tester.pump();

    expect(find.text('Введите логин'), findsOneWidget);
  });
}
