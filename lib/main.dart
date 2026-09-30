import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'repositories/in_memory_product_repository.dart';
import 'repositories/in_memory_supplier_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/supplier_repository.dart';
import 'router.dart';
import 'state/product_list_notifier.dart';
import 'state/supplier_list_notifier.dart';

void main() {
  usePathUrlStrategy();
  runApp(const WarehouseApp());
}

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ProductRepository>(create: (_) => InMemoryProductRepository()),
        Provider<SupplierRepository>(create: (_) => InMemorySupplierRepository()),
        ChangeNotifierProvider(
          create: (context) => ProductListNotifier(context.read<ProductRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => SupplierListNotifier(context.read<SupplierRepository>()),
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
