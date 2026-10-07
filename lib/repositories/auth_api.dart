import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/auth.dart';

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<AuthTokens> login(String username, String password) => guard(() async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return AuthTokens.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  Future<AuthTokens> register({
    required String username,
    required String password,
    required String displayName,
  }) => guard(() async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'username': username,
        'password': password,
        'displayName': displayName,
      },
    );
    return AuthTokens.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  Future<AuthTokens> refresh(String refreshToken) => guard(() async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthTokens.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  Future<AppUser> me() => guard(() async {
    final response = await _dio.get('/auth/me');
    return AppUser.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  Future<List<AppUser>> listUsers() => guard(() async {
    final response = await _dio.get('/admin/users');
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  });

  Future<AppUser> setRole(int id, Role role) => guard(() async {
    final response = await _dio.patch(
      '/admin/users/$id/role',
      data: {'role': role.apiName},
    );
    return AppUser.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  Future<Map<String, dynamic>> stats() => guard(() async {
    final response = await _dio.get('/admin/stats');
    return Map<String, dynamic>.from(response.data as Map);
  });

  Future<List<Map<String, dynamic>>> viewerRequests() => guard(() async {
    final response = await _dio.get('/viewer/requests');
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  });
}
