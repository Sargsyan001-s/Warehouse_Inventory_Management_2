class Supplier {
  final int id;
  final String name;
  final String country;
  final String city;
  final String phone;
  final String email;
  final DateTime? deletedAt;

  const Supplier({
    required this.id,
    required this.name,
    required this.country,
    required this.city,
    required this.phone,
    required this.email,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Supplier copyWith({
    String? name,
    String? country,
    String? city,
    String? phone,
    String? email,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Supplier(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'city': city,
    'phone': phone,
    'email': email,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    country: json['country'] as String? ?? '',
    city: json['city'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.tryParse(json['deletedAt'] as String),
  );
}
