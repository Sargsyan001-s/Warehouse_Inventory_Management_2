import '../core/json_maps.dart';
import '../core/supabase_bootstrap.dart';
import '../core/supabase_errors.dart';
import '../models/access_badge.dart';
import '../models/employee.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';
import 'employee_repository.dart';

class SupabaseEmployeeRepository implements EmployeeRepository {
  static const _select = '*, access_badges(*)';

  Employee _map(Map<String, dynamic> row) {
    final badgeRaw = row['access_badges'];
    Map<String, dynamic>? badgeMap;
    if (badgeRaw is List && badgeRaw.isNotEmpty && badgeRaw.first is Map) {
      badgeMap = Map<String, dynamic>.from(badgeRaw.first as Map);
    } else if (badgeRaw is Map) {
      badgeMap = Map<String, dynamic>.from(badgeRaw);
    }
    final badge = badgeMap == null
        ? AccessBadge(number: '', level: 'обычный', issuedAt: DateTime.now())
        : AccessBadge(
            number: badgeMap['number'] as String? ?? '',
            level: badgeMap['level'] as String? ?? 'обычный',
            issuedAt: DateTime.tryParse('${badgeMap['issued_at']}') ?? DateTime.now(),
            expiresAt: badgeMap['expires_at'] == null
                ? null
                : DateTime.tryParse('${badgeMap['expires_at']}'),
          );
    return Employee(
      id: asInt(row['id']) ?? 0,
      fullName: row['full_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      position: row['position'] as String? ?? '',
      badge: badge,
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.tryParse(row['deleted_at'] as String),
    );
  }

  Future<void> _upsertBadge(int employeeId, AccessBadge badge) async {
    await supabase.from('access_badges').upsert({
      'employee_id': employeeId,
      'number': badge.number,
      'level': badge.level,
      'issued_at': badge.issuedAt.toIso8601String().substring(0, 10),
      'expires_at': badge.expiresAt?.toIso8601String().substring(0, 10),
    }, onConflict: 'employee_id');
  }

  @override
  Future<PageResult<Employee>> find(EntityQuery q) => sbGuard(() async {
        var query = supabase.from('employees').select(_select);
        if (!q.includeDeleted) query = query.isFilter('deleted_at', null);
        if (q.search.trim().isNotEmpty) {
          final s = q.search.trim();
          query = query.or(
            'full_name.ilike.%$s%,email.ilike.%$s%,position.ilike.%$s%',
          );
        }
        final from = (q.page - 1) * q.size;
        final to = from + q.size - 1;
        final rows = await query
            .order('full_name', ascending: q.sortAscending)
            .range(from, to);
        var items = (rows as List)
            .whereType<Map>()
            .map((e) => _map(Map<String, dynamic>.from(e)))
            .toList();
        if (q.filter != null && q.filter!.isNotEmpty) {
          items = items.where((e) => e.badge.level == q.filter).toList();
        }
        final all = await supabase.from('employees').select('id');
        return PageResult(
          items: items,
          page: q.page,
          size: q.size,
          total: (all as List).length,
        );
      });

  @override
  Future<Employee?> findById(int id) => sbGuard(() async {
        final row =
            await supabase.from('employees').select(_select).eq('id', id).maybeSingle();
        if (row == null) return null;
        return _map(Map<String, dynamic>.from(row));
      });

  @override
  Future<List<Employee>> findAll({bool includeDeleted = false}) => sbGuard(() async {
        var q = supabase.from('employees').select(_select);
        if (!includeDeleted) q = q.isFilter('deleted_at', null);
        final rows = await q.order('full_name').limit(500);
        return (rows as List)
            .whereType<Map>()
            .map((e) => _map(Map<String, dynamic>.from(e)))
            .toList();
      });

  @override
  Future<Employee> create(Employee employee) => sbGuard(() async {
        final row = await supabase
            .from('employees')
            .insert({
              'full_name': employee.fullName,
              'email': employee.email,
              'phone': employee.phone,
              'position': employee.position,
            })
            .select('id')
            .single();
        final id = asInt(row['id'])!;
        await _upsertBadge(id, employee.badge);
        return (await findById(id))!;
      });

  @override
  Future<Employee> update(Employee employee) => sbGuard(() async {
        await supabase.from('employees').update({
          'full_name': employee.fullName,
          'email': employee.email,
          'phone': employee.phone,
          'position': employee.position,
        }).eq('id', employee.id);
        await _upsertBadge(employee.id, employee.badge);
        return (await findById(employee.id))!;
      });

  @override
  Future<void> softDelete(int id) => sbGuard(() async {
        await supabase
            .from('employees')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id);
      });

  @override
  Future<void> hardDelete(int id) =>
      sbGuard(() => supabase.from('employees').delete().eq('id', id));

  @override
  Future<void> restore(int id) => sbGuard(() async {
        await supabase.from('employees').update({'deleted_at': null}).eq('id', id);
      });

  @override
  Future<int> deleteMany(List<int> ids) => sbGuard(() async {
        if (ids.isEmpty) return 0;
        await supabase
            .from('employees')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .inFilter('id', ids);
        return ids.length;
      });

  @override
  Future<bool> isEmailUnique(String email, {int? excludeId}) => sbGuard(() async {
        final rows = await supabase.from('employees').select('id').eq('email', email);
        final list = rows as List;
        if (list.isEmpty) return true;
        if (excludeId != null &&
            list.length == 1 &&
            asInt((list.first as Map)['id']) == excludeId) {
          return true;
        }
        return false;
      });
}
