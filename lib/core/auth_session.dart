import '../state/auth_notifier.dart';

/// Разрывает циклическую зависимость Dio ↔ AuthNotifier.
class AuthSession {
  AuthNotifier? notifier;

  String? get accessToken => notifier?.accessToken;
}
