import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';
import '../models/supplier.dart';
import 'supplier_repository.dart';

class ApiSupplierRepository implements SupplierRepository {
  final Dio _dio;
  CancelToken? _findToken;

  ApiSupplierRepository(this._dio);

  Map<String, dynamic> _params(EntityQuery q) => {
    if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
    'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
    'page': q.page,
    'size': q.size,
    if (q.includeDeleted) 'includeDeleted': true,
    if (q.filter != null && q.filter!.isNotEmpty) 'filter': q.filter,
  };

  @override
  Future<PageResult<Supplier>> find(EntityQuery q) => withReadRetry(() async {
    _findToken?.cancel('superseded');
    _findToken = CancelToken();
    final token = _findToken;
    return guard(() async {
      try {
        final response = await _dio.get(
          '/suppliers',
          queryParameters: _params(q),
          cancelToken: token,
        );
        final data = response.data as Map<String, dynamic>;
        return PageResult(
          items: (data['items'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Supplier.fromJson(Map<String, dynamic>.from(e)))
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
  Future<Supplier?> findById(int id) => withReadRetry(
    () => guard(() async {
      try {
        final response = await _dio.get('/suppliers/$id');
        return Supplier.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      } on DioException catch (e) {
        if (mapDioError(e) is NotFoundException) return null;
        rethrow;
      }
    }),
  );

  @override
  Future<List<Supplier>> findAll({bool includeDeleted = false}) =>
      withReadRetry(
        () => guard(() async {
          final response = await _dio.get(
            '/suppliers',
            queryParameters: {
              'page': 1,
              'size': 500,
              if (includeDeleted) 'includeDeleted': true,
            },
          );
          final data = response.data as Map<String, dynamic>;
          return (data['items'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Supplier.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }),
      );

  @override
  Future<Supplier> create(Supplier supplier) => guard(() async {
    final response = await _dio.post(
      '/suppliers',
      data: {
        'name': supplier.name,
        'country': supplier.country,
        'city': supplier.city,
        'phone': supplier.phone,
        'email': supplier.email,
      },
    );
    return Supplier.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<Supplier> update(Supplier supplier) => guard(() async {
    final response = await _dio.put(
      '/suppliers/${supplier.id}',
      data: {
        'name': supplier.name,
        'country': supplier.country,
        'city': supplier.city,
        'phone': supplier.phone,
        'email': supplier.email,
      },
    );
    return Supplier.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/suppliers/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
    () => _dio.delete('/suppliers/$id', queryParameters: {'hard': true}),
  );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/suppliers/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post(
      '/suppliers/bulk-delete',
      data: {'ids': ids},
    );
    return (response.data as Map)['deleted'] as int? ?? 0;
  });
}
