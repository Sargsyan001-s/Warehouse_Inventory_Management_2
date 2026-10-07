import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import 'product_repository.dart';

class ApiProductRepository implements ProductRepository {
  final Dio _dio;
  CancelToken? _findToken;

  ApiProductRepository(this._dio);

  @override
  Future<PageResult<Product>> find(ProductQuery q) => withReadRetry(() async {
    _findToken?.cancel('superseded');
    _findToken = CancelToken();
    final token = _findToken;

    return guard(() async {
      try {
        final response = await _dio.get(
          '/products',
          queryParameters: {
            if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
            if (q.categoryId != null) 'categoryId': q.categoryId,
            if (q.supplierId != null) 'supplierId': q.supplierId,
            if (q.warehouseId != null) 'warehouseId': q.warehouseId,
            if (q.yearFrom != null) 'yearFrom': q.yearFrom,
            if (q.yearTo != null) 'yearTo': q.yearTo,
            'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
            'page': q.page,
            'size': q.size,
            if (q.includeDeleted) 'includeDeleted': true,
          },
          cancelToken: token,
        );
        final data = response.data as Map<String, dynamic>;
        return PageResult(
          items: (data['items'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
          page: (data['page'] as num?)?.toInt() ?? 1,
          size: (data['size'] as num?)?.toInt() ?? q.size,
          total: (data['total'] as num?)?.toInt() ?? 0,
        );
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) throw const CancelledException();
        rethrow;
      }
    });
  });

  @override
  Future<Product?> findById(int id) => withReadRetry(
    () => guard(() async {
      try {
        final response = await _dio.get('/products/$id');
        return Product.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      } on DioException catch (e) {
        final mapped = mapDioError(e);
        if (mapped is NotFoundException) return null;
        throw mapped;
      }
    }),
  );

  @override
  Future<List<Product>> findAll({bool includeDeleted = false}) => withReadRetry(
    () => guard(() async {
      final response = await _dio.get(
        '/products',
        queryParameters: {
          'page': 1,
          'size': 500,
          if (includeDeleted) 'includeDeleted': true,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return (data['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }),
  );

  @override
  Future<Product> create(Product product) => guard(() async {
    final response = await _dio.post('/products', data: product.toApiBody());
    return Product.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<Product> update(Product product) => guard(() async {
    final response = await _dio.put(
      '/products/${product.id}',
      data: product.toApiBody(),
    );
    return Product.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/products/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
    () => _dio.delete('/products/$id', queryParameters: {'hard': true}),
  );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/products/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post(
      '/products/bulk-delete',
      data: {'ids': ids},
    );
    return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
  });

  @override
  Future<bool> isSkuUnique(String sku, {int? excludeId}) => withReadRetry(
    () => guard(() async {
      final response = await _dio.get(
        '/meta/sku-unique',
        queryParameters: {'sku': sku, 'excludeId': ?excludeId},
      );
      return (response.data as Map)['unique'] == true;
    }),
  );

  @override
  Future<int> countByWarehouse(int warehouseId) => withReadRetry(
    () => guard(() async {
      final response = await _dio.get(
        '/meta/count-by-warehouse',
        queryParameters: {'warehouseId': warehouseId},
      );
      return (response.data as Map)['count'] as int? ?? 0;
    }),
  );

  /// Проверка ответа 409: списание при нулевом остатке.
  Future<Product> issue(int id, {int quantity = 1}) => guard(() async {
    final response = await _dio.post(
      '/products/$id/issue',
      data: {'quantity': quantity},
    );
    return Product.fromJson(Map<String, dynamic>.from(response.data as Map));
  });
}
