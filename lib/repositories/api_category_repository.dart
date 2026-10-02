import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/category.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';
import 'category_repository.dart';

class ApiCategoryRepository implements CategoryRepository {
  final Dio _dio;
  CancelToken? _findToken;

  ApiCategoryRepository(this._dio);

  @override
  Future<PageResult<Category>> find(EntityQuery q) => withReadRetry(() async {
        _findToken?.cancel('superseded');
        _findToken = CancelToken();
        final token = _findToken;
        return guard(() async {
          try {
            final response = await _dio.get(
              '/categories',
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
                  .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
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
  Future<Category?> findById(int id) => withReadRetry(() => guard(() async {
        try {
          final response = await _dio.get('/categories/$id');
          return Category.fromJson(Map<String, dynamic>.from(response.data as Map));
        } on DioException catch (e) {
          if (mapDioError(e) is NotFoundException) return null;
          rethrow;
        }
      }));

  @override
  Future<List<Category>> findAll({bool includeDeleted = false}) =>
      withReadRetry(() => guard(() async {
            final response = await _dio.get('/categories', queryParameters: {
              'page': 1,
              'size': 500,
              if (includeDeleted) 'includeDeleted': true,
            });
            final data = response.data as Map<String, dynamic>;
            return (data['items'] as List? ?? [])
                .whereType<Map>()
                .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }));

  @override
  Future<Category> create(Category category) => guard(() async {
        final response = await _dio.post('/categories', data: {
          'name': category.name,
          'description': category.description,
        });
        return Category.fromJson(Map<String, dynamic>.from(response.data as Map));
      });

  @override
  Future<Category> update(Category category) => guard(() async {
        final response = await _dio.put('/categories/${category.id}', data: {
          'name': category.name,
          'description': category.description,
        });
        return Category.fromJson(Map<String, dynamic>.from(response.data as Map));
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/categories/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/categories/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/categories/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response =
            await _dio.post('/categories/bulk-delete', data: {'ids': ids});
        return (response.data as Map)['deleted'] as int? ?? 0;
      });
}
