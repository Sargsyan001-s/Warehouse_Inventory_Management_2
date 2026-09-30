class Product {
  final int id;
  final String name;
  final String sku;
  final int categoryId;
  final int supplierId;
  final double price;
  final int quantity;
  final String unit;
  final int yearReceived;
  final DateTime? deletedAt;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.supplierId,
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
    int? categoryId,
    int? supplierId,
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
      categoryId: categoryId ?? this.categoryId,
      supplierId: supplierId ?? this.supplierId,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      yearReceived: yearReceived ?? this.yearReceived,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
