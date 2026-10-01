import 'access_badge.dart';

class Employee {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String position;
  final AccessBadge badge;
  final DateTime? deletedAt;

  const Employee({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.position,
    required this.badge,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Employee copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? position,
    AccessBadge? badge,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Employee(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      position: position ?? this.position,
      badge: badge ?? this.badge,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'position': position,
        'badge': badge.toJson(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as int? ?? 0,
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        position: json['position'] as String? ?? '',
        badge: json['badge'] is Map<String, dynamic>
            ? AccessBadge.fromJson(json['badge'] as Map<String, dynamic>)
            : AccessBadge(
                number: '',
                level: 'обычный',
                issuedAt: DateTime.now(),
              ),
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );
}
