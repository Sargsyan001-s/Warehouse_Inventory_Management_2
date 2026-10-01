class AccessBadge {
  final String number;
  final String level;
  final DateTime issuedAt;
  final DateTime? expiresAt;

  const AccessBadge({
    required this.number,
    required this.level,
    required this.issuedAt,
    this.expiresAt,
  });

  AccessBadge copyWith({
    String? number,
    String? level,
    DateTime? issuedAt,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
  }) {
    return AccessBadge(
      number: number ?? this.number,
      level: level ?? this.level,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'level': level,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory AccessBadge.fromJson(Map<String, dynamic> json) => AccessBadge(
        number: json['number'] as String? ?? '',
        level: json['level'] as String? ?? 'обычный',
        issuedAt: json['issuedAt'] == null
            ? DateTime.now()
            : DateTime.tryParse(json['issuedAt'] as String) ?? DateTime.now(),
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.tryParse(json['expiresAt'] as String),
      );
}
