import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_exceptions.dart';

Never _rethrowMapped(Object e) {
  if (e is AuthException) {
    throw UnauthorizedException(e.message);
  }
  if (e is PostgrestException) {
    final code = e.code ?? '';
    final msg = e.message;
    if (code == '42501' ||
        msg.toLowerCase().contains('permission') ||
        msg.contains('forbidden')) {
      throw ForbiddenException(msg);
    }
    if (code == 'P0001' ||
        msg.contains('Недостаточно') ||
        msg.contains('conflict')) {
      throw ConflictException(msg);
    }
    if (code == 'P0002' || code == 'PGRST116') {
      throw NotFoundException(msg);
    }
    if (code == '23505') {
      throw ConflictException('Конфликт уникальности: $msg');
    }
    if (code == '23514' || code.startsWith('23')) {
      throw ValidationException(msg, {});
    }
    throw ServerException(msg);
  }
  if (e is ApiException) throw e;
  throw NetworkException('$e');
}

Future<T> sbGuard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e) {
    _rethrowMapped(e);
  }
}
