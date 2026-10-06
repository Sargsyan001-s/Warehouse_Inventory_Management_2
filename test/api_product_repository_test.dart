import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:flutter_application_2/core/api_client.dart';
import 'package:flutter_application_2/core/api_exceptions.dart';
import 'package:flutter_application_2/core/auth_session.dart';
import 'package:flutter_application_2/models/product.dart';
import 'package:flutter_application_2/models/product_query.dart';
import 'package:flutter_application_2/repositories/api_product_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late ApiProductRepository repo;

  setUp(() {
    dio = buildDio(session: AuthSession());
    dio.options.baseUrl = 'http://localhost/api';
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    repo = ApiProductRepository(dio);
  });

  test('find разбирает страницу товаров', () async {
    adapter.onGet(
      '/products',
      (server) => server.reply(200, {
        'items': [
          {
            'id': 1,
            'name': 'Болт',
            'sku': 'B-1',
            'warehouseId': 1,
            'categoryIds': [1],
            'supplierIds': [1],
            'price': 10,
            'quantity': 5,
            'unit': 'шт',
            'yearReceived': 2024,
          }
        ],
        'page': 1,
        'size': 10,
        'total': 1,
      }),
      queryParameters: {
        'sort': 'name,asc',
        'page': 1,
        'size': 10,
      },
    );

    final page = await repo.find(const ProductQuery());
    expect(page.total, 1);
    expect(page.items.first.name, 'Болт');
  });

  test('create отправляет тело и возвращает товар', () async {
    adapter.onPost(
      '/products',
      (server) => server.reply(201, {
        'id': 99,
        'name': 'Новый',
        'sku': 'NEW-1',
        'warehouseId': 1,
        'categoryIds': [1],
        'supplierIds': [],
        'price': 1,
        'quantity': 1,
        'unit': 'шт',
        'yearReceived': 2025,
      }),
      data: Matchers.any,
    );

    final created = await repo.create(
      const Product(
        id: 0,
        name: 'Новый',
        sku: 'NEW-1',
        warehouseId: 1,
        categoryIds: [1],
        price: 1,
        quantity: 1,
        unit: 'шт',
        yearReceived: 2025,
      ),
    );
    expect(created.id, 99);
  });

  test('422 превращается в ValidationException с ошибками полей', () async {
    adapter.onPost(
      '/products',
      (server) => server.reply(422, {
        'message': 'Ошибка валидации',
        'errors': {'sku': 'Товар с таким артикулом уже существует'},
      }),
      data: Matchers.any,
    );

    expect(
      () => repo.create(
        const Product(
          id: 0,
          name: 'X',
          sku: 'BLT-M8-40',
          warehouseId: 1,
          categoryIds: [1],
          price: 1,
          quantity: 1,
          unit: 'шт',
          yearReceived: 2024,
        ),
      ),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.errors['sku'],
          'sku',
          contains('артикул'),
        ),
      ),
    );
  });

  test('недоступность сервера даёт NetworkException', () async {
    adapter.onGet(
      '/products',
      (server) => server.throws(
        0,
        DioException(
          requestOptions: RequestOptions(path: '/products'),
          type: DioExceptionType.connectionError,
        ),
      ),
      queryParameters: {
        'sort': 'name,asc',
        'page': 1,
        'size': 10,
      },
    );

    expect(
      () => repo.find(const ProductQuery()),
      throwsA(isA<NetworkException>()),
    );
  });

  test('softDelete вызывает DELETE', () async {
    adapter.onDelete('/products/3', (server) => server.reply(204, null));
    await repo.softDelete(3);
  });
}
