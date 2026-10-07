import '../models/auth.dart';

/// Контракт аутентификации (mock Dio или Supabase).
abstract class AuthApi {
  Future<AuthTokens> login(String username, String password);

  Future<AuthTokens> register({
    required String username,
    required String password,
    required String displayName,
  });

  Future<AuthTokens> refresh(String refreshToken);

  Future<AppUser> me();

  Future<List<AppUser>> listUsers();

  Future<AppUser> setRole(String id, Role role);

  Future<Map<String, dynamic>> stats();

  Future<List<Map<String, dynamic>>> viewerRequests();

  Future<List<Map<String, dynamic>>> inventoryValuation();
}
