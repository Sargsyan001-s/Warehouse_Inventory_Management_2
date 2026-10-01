class EntityQuery {
  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;
  final String? filter;

  const EntityQuery({
    this.search = '',
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
    this.filter,
  });

  EntityQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
    Object? filter = _unset,
  }) {
    return EntityQuery(
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
      filter: filter == _unset ? this.filter : filter as String?,
    );
  }

  Map<String, String> toQueryParams() {
    final map = <String, String>{
      'page': '$page',
      'size': '$size',
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
    };
    if (search.isNotEmpty) map['search'] = search;
    if (includeDeleted) map['includeDeleted'] = 'true';
    if (filter != null && filter!.isNotEmpty) map['filter'] = filter!;
    return map;
  }

  factory EntityQuery.fromQueryParams(Map<String, String> params, {String defaultSort = 'name'}) {
    final sort = params['sort'] ?? '$defaultSort,asc';
    final parts = sort.split(',');
    return EntityQuery(
      search: params['search'] ?? '',
      sortField: parts.isNotEmpty ? parts[0] : defaultSort,
      sortAscending: parts.length < 2 || parts[1] != 'desc',
      page: int.tryParse(params['page'] ?? '') ?? 1,
      size: int.tryParse(params['size'] ?? '') ?? 10,
      includeDeleted: params['includeDeleted'] == 'true',
      filter: params['filter'],
    );
  }

  static const _unset = Object();
}
