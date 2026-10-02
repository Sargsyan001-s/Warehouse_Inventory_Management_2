import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';
import '../models/warehouse.dart';
import 'warehouse_repository.dart';

class ApiWarehouseRepository implements WarehouseRepository {
  final Dio _dio;
  CancelToken? _findToken;

  ApiWarehouseRepository(this._dio);

  @override
  Future<PageResult<Warehouse>> find(EntityQuery q) => withReadRetry(() async {
        _findToken?.cancel('superseded');
        _findToken = CancelToken();
        final token = _findToken;
        return guard(() async {
          try {
            final response = await _dio.get(
              '/warehouses',
              queryParameters: {
                if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
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
                  .map((e) => Warehouse.fromJson(Map<String, dynamic>.from(e)))
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
  Future<Warehouse?> findById(int id) => withReadRetry(() => guard(() async {
        try {
          final response = await _dio.get('/warehouses/$id');
          return Warehouse.fromJson(Map<String, dynamic>.from(response.data as Map));
        } on DioException catch (e) {
          if (mapDioError(e) is NotFoundException) return null;
          rethrow;
        }
      }));

  @override
  Future<List<Warehouse>> findAll({bool includeDeleted = false}) =>
      withReadRetry(() => guard(() async {
            final response = await _dio.get('/warehouses', queryParameters: {
              'page': 1,
              'size': 500,
              if (includeDeleted) 'includeDeleted': true,
            });
            final data = response.data as Map<String, dynamic>;
            return (data['items'] as List? ?? [])
                .whereType<Map>()
                .map((e) => Warehouse.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }));

  @override
  Future<Warehouse> create(Warehouse warehouse) => guard(() async {
        final response = await _dio.post('/warehouses', data: {
          'name': warehouse.name,
          'code': warehouse.code,
          'address': warehouse.address,
          'city': warehouse.city,
          'categoryIds': warehouse.categoryIds,
        });
        return Warehouse.fromJson(Map<String, dynamic>.from(response.data as Map));
      });

  @override
  Future<Warehouse> update(Warehouse warehouse) => guard(() async {
        final response = await _dio.put('/warehouses/${warehouse.id}', data: {
          'name': warehouse.name,
          'code': warehouse.code,
          'address': warehouse.address,
          'city': warehouse.city,
          'categoryIds': warehouse.categoryIds,
        });
        return Warehouse.fromJson(Map<String, dynamic>.from(response.data as Map));
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/warehouses/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/warehouses/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/warehouses/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response =
            await _dio.post('/warehouses/bulk-delete', data: {'ids': ids});
        return (response.data as Map)['deleted'] as int? ?? 0;
      });
}
