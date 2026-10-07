class Product {
  final int id;
  final String name;
  final String sku;
  final int warehouseId;
  final List<int> categoryIds;
  final List<int> supplierIds;
  final double price;
  final int quantity;
  final String unit;
  final int yearReceived;
  final DateTime? deletedAt;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.warehouseId,
    this.categoryIds = const [],
    this.supplierIds = const [],
    required this.price,
    required this.quantity,
    required this.unit,
    required this.yearReceived,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Product copyWith({
    String? name,
    String? sku,
    int? warehouseId,
    List<int>? categoryIds,
    List<int>? supplierIds,
    double? price,
    int? quantity,
    String? unit,
    int? yearReceived,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      warehouseId: warehouseId ?? this.warehouseId,
      categoryIds: categoryIds ?? this.categoryIds,
      supplierIds: supplierIds ?? this.supplierIds,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      yearReceived: yearReceived ?? this.yearReceived,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'warehouseId': warehouseId,
    'categoryIds': categoryIds,
    'supplierIds': supplierIds,
    'price': price,
    'quantity': quantity,
    'unit': unit,
    'yearReceived': yearReceived,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) {
    List<int> readIds(String listKey, String singleKey, String? nestedKey) {
      if (json[listKey] is List) {
        return (json[listKey] as List)
            .map((e) {
              if (e is int) return e;
              if (e is num) return e.toInt();
              if (e is Map && e['id'] != null) return (e['id'] as num).toInt();
              return int.tryParse('$e') ?? 0;
            })
            .where((id) => id > 0)
            .toList();
      }
      if (nestedKey != null && json[nestedKey] is List) {
        return (json[nestedKey] as List)
            .whereType<Map>()
            .map((e) => (e['id'] as num?)?.toInt() ?? 0)
            .where((id) => id > 0)
            .toList();
      }
      if (json[singleKey] != null) {
        return [(json[singleKey] as num).toInt()];
      }
      return <int>[];
    }

    final warehouseId = json['warehouseId'] != null
        ? (json['warehouseId'] as num).toInt()
        : (json['warehouse'] is Map
              ? ((json['warehouse'] as Map)['id'] as num?)?.toInt() ?? 1
              : 1);

    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      warehouseId: warehouseId,
      categoryIds: readIds('categoryIds', 'categoryId', 'categories'),
      supplierIds: readIds('supplierIds', 'supplierId', 'suppliers'),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? 'шт',
      yearReceived: (json['yearReceived'] as num?)?.toInt() ?? 2024,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }

  /// Тело для POST/PUT (без развёрнутых связей).
  Map<String, dynamic> toApiBody() => {
    'name': name,
    'sku': sku,
    'warehouseId': warehouseId,
    'categoryIds': categoryIds,
    'supplierIds': supplierIds,
    'price': price,
    'quantity': quantity,
    'unit': unit,
    'yearReceived': yearReceived,
  };
}
