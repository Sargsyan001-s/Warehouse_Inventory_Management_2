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
    // Совместимость со старым форматом PR2 (categoryId / supplierId).
    final categoryIds = (json['categoryIds'] as List?)?.map((e) => e as int).toList() ??
        (json['categoryId'] != null ? [json['categoryId'] as int] : <int>[]);
    final supplierIds = (json['supplierIds'] as List?)?.map((e) => e as int).toList() ??
        (json['supplierId'] != null ? [json['supplierId'] as int] : <int>[]);

    return Product(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      warehouseId: json['warehouseId'] as int? ?? 1,
      categoryIds: categoryIds,
      supplierIds: supplierIds,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      unit: json['unit'] as String? ?? 'шт',
      yearReceived: json['yearReceived'] as int? ?? 2024,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }
}
