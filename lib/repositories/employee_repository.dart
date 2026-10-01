import '../models/employee.dart';
import '../models/entity_query.dart';
import '../models/page_result.dart';

abstract interface class EmployeeRepository {
  Future<PageResult<Employee>> find(EntityQuery query);
  Future<Employee?> findById(int id);
  Future<List<Employee>> findAll({bool includeDeleted = false});
  Future<Employee> create(Employee employee);
  Future<Employee> update(Employee employee);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<bool> isEmailUnique(String email, {int? excludeId});
}
