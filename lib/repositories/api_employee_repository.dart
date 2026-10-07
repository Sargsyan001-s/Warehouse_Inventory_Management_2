import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/employee.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';
import 'employee_repository.dart';

class ApiEmployeeRepository implements EmployeeRepository {
  final Dio _dio;
  CancelToken? _findToken;

  ApiEmployeeRepository(this._dio);

  @override
  Future<PageResult<Employee>> find(EntityQuery q) => withReadRetry(() async {
    _findToken?.cancel('superseded');
    _findToken = CancelToken();
    final token = _findToken;
    return guard(() async {
      try {
        final response = await _dio.get(
          '/employees',
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
              .map((e) => Employee.fromJson(Map<String, dynamic>.from(e)))
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
  Future<Employee?> findById(int id) => withReadRetry(
    () => guard(() async {
      try {
        final response = await _dio.get('/employees/$id');
        return Employee.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      } on DioException catch (e) {
        if (mapDioError(e) is NotFoundException) return null;
        rethrow;
      }
    }),
  );

  @override
  Future<List<Employee>> findAll({bool includeDeleted = false}) =>
      withReadRetry(
        () => guard(() async {
          final response = await _dio.get(
            '/employees',
            queryParameters: {
              'page': 1,
              'size': 500,
              if (includeDeleted) 'includeDeleted': true,
            },
          );
          final data = response.data as Map<String, dynamic>;
          return (data['items'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Employee.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }),
      );

  @override
  Future<Employee> create(Employee employee) => guard(() async {
    final response = await _dio.post(
      '/employees',
      data: {
        'fullName': employee.fullName,
        'email': employee.email,
        'phone': employee.phone,
        'position': employee.position,
        'badge': employee.badge.toJson(),
      },
    );
    return Employee.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<Employee> update(Employee employee) => guard(() async {
    final response = await _dio.put(
      '/employees/${employee.id}',
      data: {
        'fullName': employee.fullName,
        'email': employee.email,
        'phone': employee.phone,
        'position': employee.position,
        'badge': employee.badge.toJson(),
      },
    );
    return Employee.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/employees/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
    () => _dio.delete('/employees/$id', queryParameters: {'hard': true}),
  );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/employees/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post(
      '/employees/bulk-delete',
      data: {'ids': ids},
    );
    return (response.data as Map)['deleted'] as int? ?? 0;
  });

  @override
  Future<bool> isEmailUnique(String email, {int? excludeId}) => withReadRetry(
    () => guard(() async {
      final response = await _dio.get(
        '/meta/email-unique',
        queryParameters: {'email': email, 'excludeId': ?excludeId},
      );
      return (response.data as Map)['unique'] == true;
    }),
  );
}
