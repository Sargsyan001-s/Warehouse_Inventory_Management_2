enum Role {
  viewer(1, 'viewer', 'Наблюдатель'),
  operator(2, 'operator', 'Кладовщик'),
  admin(3, 'admin', 'Администратор');

  final int level;
  final String apiName;
  final String title;
  const Role(this.level, this.apiName, this.title);

  static Role fromApi(String? value) {
    return Role.values.firstWhere(
      (r) => r.apiName == value,
      orElse: () => Role.viewer,
    );
  }

  bool atLeast(Role other) => level >= other.level;
}

class AppUser {
  final int id;
  final String username;
  final String displayName;
  final Role role;

  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: (json['id'] as num?)?.toInt() ?? 0,
    username: json['username'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    role: Role.fromApi(json['role'] as String?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'displayName': displayName,
    'role': role.apiName,
  };
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final AppUser user;
  final int expiresIn;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String? ?? '',
    refreshToken: json['refreshToken'] as String? ?? '',
    user: AppUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 900,
  );
}

/// Клиентские правила UI (не защита).
class Permissions {
  static bool canViewCatalog(Role r) => true;
  static bool canManageCatalog(Role r) => r.atLeast(Role.operator);
  static bool canHardDelete(Role r) => r == Role.admin;
  static bool canRestore(Role r) => r == Role.admin;
  static bool canManageEmployees(Role r) => r.atLeast(Role.operator);
  static bool canIssue(Role r) => r.atLeast(Role.operator);
  static bool canAdminUsers(Role r) => r == Role.admin;
  static bool canViewStats(Role r) => r == Role.admin;
  static bool canViewOwnRequests(Role r) => r == Role.viewer;
}
