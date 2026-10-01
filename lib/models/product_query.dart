class ProductQuery {
  final String search;
  final int? categoryId;
  final int? supplierId;
  final int? warehouseId;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const ProductQuery({
    this.search = '',
    this.categoryId,
    this.supplierId,
    this.warehouseId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  ProductQuery copyWith({
    String? search,
    Object? categoryId = _unset,
    Object? supplierId = _unset,
    Object? warehouseId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ProductQuery(
      search: search ?? this.search,
      categoryId: categoryId == _unset ? this.categoryId : categoryId as int?,
      supplierId: supplierId == _unset ? this.supplierId : supplierId as int?,
      warehouseId: warehouseId == _unset ? this.warehouseId : warehouseId as int?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  Map<String, String> toQueryParams() {
    final map = <String, String>{
      'page': '$page',
      'size': '$size',
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
    };
    if (search.isNotEmpty) map['search'] = search;
    if (categoryId != null) map['categoryId'] = '$categoryId';
    if (supplierId != null) map['supplierId'] = '$supplierId';
    if (warehouseId != null) map['warehouseId'] = '$warehouseId';
    if (yearFrom != null) map['yearFrom'] = '$yearFrom';
    if (yearTo != null) map['yearTo'] = '$yearTo';
    if (includeDeleted) map['includeDeleted'] = 'true';
    return map;
  }

  factory ProductQuery.fromQueryParams(Map<String, String> params) {
    final sort = params['sort'] ?? 'name,asc';
    final parts = sort.split(',');
    return ProductQuery(
      search: params['search'] ?? '',
      categoryId: int.tryParse(params['categoryId'] ?? ''),
      supplierId: int.tryParse(params['supplierId'] ?? ''),
      warehouseId: int.tryParse(params['warehouseId'] ?? ''),
      yearFrom: int.tryParse(params['yearFrom'] ?? ''),
      yearTo: int.tryParse(params['yearTo'] ?? ''),
      sortField: parts.isNotEmpty ? parts[0] : 'name',
      sortAscending: parts.length < 2 || parts[1] != 'desc',
      page: int.tryParse(params['page'] ?? '') ?? 1,
      size: int.tryParse(params['size'] ?? '') ?? 10,
      includeDeleted: params['includeDeleted'] == 'true',
    );
  }

  static const _unset = Object();
}
