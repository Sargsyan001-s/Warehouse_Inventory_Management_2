import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';
import 'auth_session.dart';

Dio buildDio({required AuthSession session}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) {
        final token = session.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API] → ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] ← ${response.statusCode} ${response.requestOptions.method} '
            '${response.requestOptions.uri}',
          );
        }
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint(
            '[API] сбой ${error.requestOptions.uri}: ${error.type}',
          );
        }

        final status = error.response?.statusCode;
        final path = error.requestOptions.path;
        final auth = session.notifier;

        if (status == 401 &&
            auth != null &&
            !path.contains('/auth/') &&
            error.requestOptions.extra['retried'] != true) {
          try {
            await auth.refreshTokens();
            final options = error.requestOptions;
            options.headers['Authorization'] = 'Bearer ${auth.accessToken}';
            options.extra['retried'] = true;
            final response = await dio.fetch(options);
            return handler.resolve(response);
          } catch (_) {
            await auth.logout();
            return handler.reject(error);
          }
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
}
