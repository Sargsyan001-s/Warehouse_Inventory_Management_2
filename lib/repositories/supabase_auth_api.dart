import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/api_exceptions.dart';
import '../core/supabase_bootstrap.dart';
import '../models/auth.dart';
import 'auth_api.dart';

/// Auth + админ-операции через Supabase.
class SupabaseAuthApi implements AuthApi {
  Future<AppUser> _profileFor(String userId) async {
    final row = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return AppUser(
      id: row['id'].toString(),
      username: row['username'] as String? ?? '',
      displayName: row['display_name'] as String? ?? '',
      role: Role.fromApi(row['role'] as String?),
    );
  }

  AuthTokens _tokens(Session session, AppUser user) => AuthTokens(
    accessToken: session.accessToken,
    refreshToken: session.refreshToken ?? '',
    user: user,
    expiresIn: session.expiresIn ?? 3600,
  );

  @override
  Future<AuthTokens> login(String username, String password) async {
    try {
      final email = username.contains('@')
          ? username
          : '$username@warehouse.local';
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = res.session;
      final uid = res.user?.id;
      if (session == null || uid == null) {
        throw const UnauthorizedException('Неверный логин или пароль.');
      }
      final user = await _profileFor(uid);
      return _tokens(session, user);
    } on AuthException catch (e) {
      throw UnauthorizedException(e.message);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<AuthTokens> register({
    required String username,
    required String password,
    required String displayName,
  }) async {
    try {
      final email = '$username@warehouse.local';
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'display_name': displayName},
      );
      final session = res.session;
      final uid = res.user?.id;
      if (uid == null) {
        throw const ValidationException(
          'Регистрация не завершена. Проверьте настройки Auth в Supabase.',
          {},
        );
      }
      if (session == null) {
        return login(username, password);
      }
      final user = await _profileFor(uid);
      return _tokens(session, user);
    } on AuthException catch (e) {
      throw ValidationException(e.message, {'username': e.message});
    }
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    try {
      final res = await supabase.auth.refreshSession();
      final session = res.session;
      final uid = res.user?.id ?? session?.user.id;
      if (session == null || uid == null) {
        throw const UnauthorizedException();
      }
      final user = await _profileFor(uid);
      return _tokens(session, user);
    } on AuthException catch (e) {
      throw UnauthorizedException(e.message);
    }
  }

  @override
  Future<AppUser> me() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw const UnauthorizedException();
    return _profileFor(uid);
  }

  @override
  Future<List<AppUser>> listUsers() async {
    final rows = await supabase.from('profiles').select().order('username');
    return (rows as List)
        .whereType<Map>()
        .map(
          (e) => AppUser(
            id: e['id'].toString(),
            username: e['username'] as String? ?? '',
            displayName: e['display_name'] as String? ?? '',
            role: Role.fromApi(e['role'] as String?),
          ),
        )
        .toList();
  }

  @override
  Future<AppUser> setRole(String id, Role role) async {
    final row = await supabase
        .from('profiles')
        .update({'role': role.apiName})
        .eq('id', id)
        .select()
        .single();
    return AppUser(
      id: row['id'].toString(),
      username: row['username'] as String? ?? '',
      displayName: row['display_name'] as String? ?? '',
      role: Role.fromApi(row['role'] as String?),
    );
  }

  @override
  Future<Map<String, dynamic>> stats() async {
    final products = await supabase
        .from('products')
        .select('id')
        .isFilter('deleted_at', null);
    final suppliers = await supabase
        .from('suppliers')
        .select('id')
        .isFilter('deleted_at', null);
    final warehouses = await supabase
        .from('warehouses')
        .select('id')
        .isFilter('deleted_at', null);
    final users = await supabase.from('profiles').select('id');
    return {
      'products': (products as List).length,
      'suppliers': (suppliers as List).length,
      'warehouses': (warehouses as List).length,
      'users': (users as List).length,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> viewerRequests() async {
    return [
      {
        'id': 1,
        'title': 'Заявка на сверку остатков',
        'status': 'открыта',
        'createdAt': '2026-10-01',
      },
      {
        'id': 2,
        'title': 'Запрос продления резерва',
        'status': 'в работе',
        'createdAt': '2026-10-03',
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> inventoryValuation() async {
    try {
      final rows = await supabase.from('inventory_valuation').select();
      return (rows as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
