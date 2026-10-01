class Warehouse {
  final int id;
  final String name;
  final String code;
  final String address;
  final String city;
  /// категории, доступные на этом складе для каскадного выбора
  final List<int> categoryIds;
  final DateTime? deletedAt;

  const Warehouse({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.city,
    this.categoryIds = const [],
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Warehouse copyWith({
    String? name,
    String? code,
    String? address,
    String? city,
    List<int>? categoryIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Warehouse(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      city: city ?? this.city,
      categoryIds: categoryIds ?? this.categoryIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'address': address,
        'city': city,
        'categoryIds': categoryIds,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        code: json['code'] as String? ?? '',
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
        categoryIds: (json['categoryIds'] as List?)?.map((e) => e as int).toList() ?? const [],
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );
}
