class SupplierQuery {
  final String search;
  final String? country;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const SupplierQuery({
    this.search = '',
    this.country,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  SupplierQuery copyWith({
    String? search,
    Object? country = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return SupplierQuery(
      search: search ?? this.search,
      country: country == _unset ? this.country : country as String?,
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
    if (country != null && country!.isNotEmpty) map['country'] = country!;
    if (includeDeleted) map['includeDeleted'] = 'true';
    return map;
  }

  factory SupplierQuery.fromQueryParams(Map<String, String> params) {
    final sort = params['sort'] ?? 'name,asc';
    final parts = sort.split(',');
    return SupplierQuery(
      search: params['search'] ?? '',
      country: params['country'],
      sortField: parts.isNotEmpty ? parts[0] : 'name',
      sortAscending: parts.length < 2 || parts[1] != 'desc',
      page: int.tryParse(params['page'] ?? '') ?? 1,
      size: int.tryParse(params['size'] ?? '') ?? 10,
      includeDeleted: params['includeDeleted'] == 'true',
    );
  }

  static const _unset = Object();
}
