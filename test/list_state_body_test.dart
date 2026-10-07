import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/state/entity_list_notifier.dart';
import 'package:flutter_application_2/widgets/list_state_body.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('отображает состояние загрузки', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ListStateBody(
          status: LoadStatus.loading,
          error: null,
          isEmpty: true,
          onRetry: () {},
          child: const Text('data'),
        ),
      ),
    );

    expect(find.byKey(const Key('list_loading')), findsOneWidget);
    expect(find.text('data'), findsNothing);
  });

  testWidgets('отображает пустой результат', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ListStateBody(
          status: LoadStatus.success,
          error: null,
          isEmpty: true,
          onRetry: () {},
          emptyTitle: 'Товаров не найдено',
          child: const Text('data'),
        ),
      ),
    );

    expect(find.byKey(const Key('list_empty')), findsOneWidget);
    expect(find.textContaining('Товаров не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('отображает ошибку с кнопкой повтора', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _wrap(
        ListStateBody(
          status: LoadStatus.error,
          error: 'Сервер недоступен. Проверьте соединение.',
          isEmpty: true,
          onRetry: () => retried = true,
          child: const Text('data'),
        ),
      ),
    );

    expect(find.textContaining('Нет связи с сервером'), findsOneWidget);
    expect(find.byKey(const Key('list_retry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('list_retry')));
    await tester.pump();
    expect(retried, isTrue);
  });
}
