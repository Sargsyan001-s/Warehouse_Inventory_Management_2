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
}
