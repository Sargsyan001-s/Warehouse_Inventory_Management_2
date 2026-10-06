import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../models/auth.dart';
import '../repositories/auth_api.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user_json';
  static const _kSessionStarted = 'auth_session_started_ms';
  static const _kLastActive = 'auth_last_active_ms';

  final SharedPreferences _prefs;
  final AuthApi _api;

  AuthNotifier(this._prefs, this._api);

  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _refreshing = false;

  AppUser? get user {
    final raw = _prefs.getString(_kUser);
    if (raw != null) {
      try {
        return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return _user;
  }

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null && user != null;

  bool has(Role role) {
    final u = user;
    return u != null && u.role.atLeast(role);
  }

  /// Для пункта 17: роль берётся из кэша UI (localStorage), не из токена.
  void applyTamperedUserFromStorage() {
    final raw = _prefs.getString(_kUser);
    if (raw == null) return;
    try {
      _user = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> restore() async {
    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    final rawUser = _prefs.getString(_kUser);
    if (access == null) return;

    _accessToken = access;
    _refreshToken = refresh;
    if (rawUser != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
      } catch (_) {}
    }

    try {
      // Проверяем, что токен ещё принят сервером.
      // Роль для UI берём из localStorage (может быть подменена — пункт 17).
      await _api.me();
      if (rawUser != null) {
        _user = AppUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
      }
    } on UnauthorizedException {
      if (refresh != null) {
        try {
          await refreshTokens();
        } catch (_) {
          await logout();
        }
      } else {
        await logout();
      }
    } catch (_) {
      // Сервер недоступен — оставляем кэш сессии.
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username, password);
    await _persist(result);
  }

  Future<void> register({
    required String username,
    required String password,
    required String displayName,
  }) async {
    final result = await _api.register(
      username: username,
      password: password,
      displayName: displayName,
    );
    await _persist(result);
  }

  Future<void> _persist(AuthTokens result) async {
    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;
    await _prefs.setString(_kAccess, result.accessToken);
    await _prefs.setString(_kRefresh, result.refreshToken);
    await _prefs.setString(_kUser, jsonEncode(result.user.toJson()));
    await _prefs.setInt(_kSessionStarted, DateTime.now().millisecondsSinceEpoch);
    await touchActivity();
    notifyListeners();
  }

  Future<void> refreshTokens() async {
    if (_refreshing) return;
    final refresh = _refreshToken ?? _prefs.getString(_kRefresh);
    if (refresh == null) throw const UnauthorizedException();
    _refreshing = true;
    try {
      final result = await _api.refresh(refresh);
      _accessToken = result.accessToken;
      _refreshToken = result.refreshToken;
      _user = result.user;
      await _prefs.setString(_kAccess, result.accessToken);
      await _prefs.setString(_kRefresh, result.refreshToken);
      await _prefs.setString(_kUser, jsonEncode(result.user.toJson()));
      notifyListeners();
    } finally {
      _refreshing = false;
    }
  }

  /// Обновить пользователя в UI/localStorage (например после смены своей роли).
  Future<void> applyUser(AppUser user) async {
    _user = user;
    await _prefs.setString(_kUser, jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kSessionStarted);
    await _prefs.remove(_kLastActive);
    notifyListeners();
  }

  Future<void> touchActivity() async {
    await _prefs.setInt(_kLastActive, DateTime.now().millisecondsSinceEpoch);
  }

  /// true если нужно завершить сессию.
  bool isSessionExpired({
    required Duration maxSession,
    required Duration inactivity,
  }) {
    final started = _prefs.getInt(_kSessionStarted);
    final last = _prefs.getInt(_kLastActive);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (started != null && now - started > maxSession.inMilliseconds) {
      return true;
    }
    if (last != null && now - last > inactivity.inMilliseconds) {
      return true;
    }
    return false;
  }

  Duration? inactivityRemaining(Duration inactivity) {
    final last = _prefs.getInt(_kLastActive);
    if (last == null) return inactivity;
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    final left = inactivity.inMilliseconds - elapsed;
    if (left <= 0) return Duration.zero;
    return Duration(milliseconds: left);
  }
}
