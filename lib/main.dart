import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/category_repository.dart';
import 'repositories/employee_repository.dart';
import 'repositories/persistent_category_repository.dart';
import 'repositories/persistent_employee_repository.dart';
import 'repositories/persistent_product_repository.dart';
import 'repositories/persistent_supplier_repository.dart';
import 'repositories/persistent_warehouse_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/supplier_repository.dart';
import 'repositories/warehouse_repository.dart';
import 'router.dart';
import 'state/category_list_notifier.dart';
import 'state/employee_list_notifier.dart';
import 'state/product_list_notifier.dart';
import 'state/supplier_list_notifier.dart';
import 'state/warehouse_list_notifier.dart';

final _migrationMessages = <String>[];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();

  void notice(String message) => _migrationMessages.add(message);

  final productRepo = PersistentProductRepository(prefs, onMigrationNotice: notice);
  final supplierRepo = PersistentSupplierRepository(prefs, onMigrationNotice: notice);
  final categoryRepo = PersistentCategoryRepository(prefs, onMigrationNotice: notice);
  final warehouseRepo = PersistentWarehouseRepository(prefs, onMigrationNotice: notice);
  final employeeRepo = PersistentEmployeeRepository(prefs, onMigrationNotice: notice);

  runApp(
    WarehouseApp(
      productRepo: productRepo,
      supplierRepo: supplierRepo,
      categoryRepo: categoryRepo,
      warehouseRepo: warehouseRepo,
      employeeRepo: employeeRepo,
      migrationMessages: List.unmodifiable(_migrationMessages),
    ),
  );
}

class WarehouseApp extends StatelessWidget {
  final ProductRepository productRepo;
  final SupplierRepository supplierRepo;
  final CategoryRepository categoryRepo;
  final WarehouseRepository warehouseRepo;
  final EmployeeRepository employeeRepo;
  final List<String> migrationMessages;

  const WarehouseApp({
    super.key,
    required this.productRepo,
    required this.supplierRepo,
    required this.categoryRepo,
    required this.warehouseRepo,
    required this.employeeRepo,
    this.migrationMessages = const [],
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ProductRepository>.value(value: productRepo),
        Provider<SupplierRepository>.value(value: supplierRepo),
        Provider<CategoryRepository>.value(value: categoryRepo),
        Provider<WarehouseRepository>.value(value: warehouseRepo),
        Provider<EmployeeRepository>.value(value: employeeRepo),
        ChangeNotifierProvider(create: (_) => ProductListNotifier(productRepo)),
        ChangeNotifierProvider(create: (_) => SupplierListNotifier(supplierRepo)),
        ChangeNotifierProvider(create: (_) => CategoryListNotifier(categoryRepo)),
        ChangeNotifierProvider(create: (_) => WarehouseListNotifier(warehouseRepo)),
        ChangeNotifierProvider(create: (_) => EmployeeListNotifier(employeeRepo)),
      ],
      child: MaterialApp.router(
        title: 'Складской учёт',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          useMaterial3: true,
        ),
        routerConfig: createRouter(),
        builder: (context, child) {
          if (migrationMessages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              final messenger = ScaffoldMessenger.maybeOf(context);
              for (final msg in migrationMessages) {
                messenger?.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));
              }
              _migrationMessages.clear();
            });
          }
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
