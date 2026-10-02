import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/reference_cache.dart';
import 'repositories/api_category_repository.dart';
import 'repositories/api_employee_repository.dart';
import 'repositories/api_product_repository.dart';
import 'repositories/api_supplier_repository.dart';
import 'repositories/api_warehouse_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/employee_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/supplier_repository.dart';
import 'repositories/warehouse_repository.dart';
import 'router.dart';
import 'state/category_list_notifier.dart';
import 'state/employee_list_notifier.dart';
import 'state/product_list_notifier.dart';
import 'state/supplier_list_notifier.dart';
import 'state/warehouse_list_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(const WarehouseApp());
}

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Dio>(create: (_) => buildDio()),
        ProxyProvider<Dio, ProductRepository>(
          update: (_, dio, _) => ApiProductRepository(dio),
        ),
        ProxyProvider<Dio, SupplierRepository>(
          update: (_, dio, _) => ApiSupplierRepository(dio),
        ),
        ProxyProvider<Dio, CategoryRepository>(
          update: (_, dio, _) => ApiCategoryRepository(dio),
        ),
        ProxyProvider<Dio, WarehouseRepository>(
          update: (_, dio, _) => ApiWarehouseRepository(dio),
        ),
        ProxyProvider<Dio, EmployeeRepository>(
          update: (_, dio, _) => ApiEmployeeRepository(dio),
        ),
        ProxyProvider3<CategoryRepository, SupplierRepository, WarehouseRepository,
            ReferenceCache>(
          update: (_, cats, sups, whs, _) => ReferenceCache(cats, sups, whs),
        ),
        ChangeNotifierProvider(
          create: (context) => ProductListNotifier(context.read<ProductRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => SupplierListNotifier(context.read<SupplierRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CategoryListNotifier(context.read<CategoryRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => WarehouseListNotifier(context.read<WarehouseRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => EmployeeListNotifier(context.read<EmployeeRepository>()),
        ),
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
      ),
    );
  }
}
