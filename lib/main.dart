import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/auth_session.dart';
import 'core/config.dart';
import 'core/reference_cache.dart';
import 'core/supabase_bootstrap.dart';
import 'repositories/api_category_repository.dart';
import 'repositories/api_employee_repository.dart';
import 'repositories/api_product_repository.dart';
import 'repositories/api_supplier_repository.dart';
import 'repositories/api_warehouse_repository.dart';
import 'repositories/auth_api.dart';
import 'repositories/category_repository.dart';
import 'repositories/dio_auth_api.dart';
import 'repositories/employee_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/supabase_auth_api.dart';
import 'repositories/supabase_category_repository.dart';
import 'repositories/supabase_employee_repository.dart';
import 'repositories/supabase_product_repository.dart';
import 'repositories/supabase_supplier_repository.dart';
import 'repositories/supabase_warehouse_repository.dart';
import 'repositories/supplier_repository.dart';
import 'repositories/warehouse_repository.dart';
import 'router.dart';
import 'state/auth_notifier.dart';
import 'state/category_list_notifier.dart';
import 'state/employee_list_notifier.dart';
import 'state/product_list_notifier.dart';
import 'state/supplier_list_notifier.dart';
import 'state/warehouse_list_notifier.dart';
import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await initSupabaseIfConfigured();

  final prefs = await SharedPreferences.getInstance();
  final session = AuthSession();
  final dio = buildDio(session: session);

  final AuthApi authApi = useSupabase ? SupabaseAuthApi() : DioAuthApi(dio);
  final auth = AuthNotifier(prefs, authApi);
  session.notifier = auth;
  await auth.restore();

  runApp(
    WarehouseApp(
      dio: dio,
      auth: auth,
      authApi: authApi,
      useCloud: useSupabase,
    ),
  );
}

class WarehouseApp extends StatefulWidget {
  final Dio dio;
  final AuthNotifier auth;
  final AuthApi authApi;
  final bool useCloud;

  const WarehouseApp({
    super.key,
    required this.dio,
    required this.auth,
    required this.authApi,
    required this.useCloud,
  });

  @override
  State<WarehouseApp> createState() => _WarehouseAppState();
}

class _WarehouseAppState extends State<WarehouseApp> {
  late final GoRouter _router = createRouter(widget.auth);

  @override
  Widget build(BuildContext context) {
    final cloud = widget.useCloud;

    return MultiProvider(
      providers: [
        Provider<Dio>.value(value: widget.dio),
        Provider<AuthApi>.value(value: widget.authApi),
        ChangeNotifierProvider<AuthNotifier>.value(value: widget.auth),
        Provider<ProductRepository>(
          create: (_) => cloud
              ? SupabaseProductRepository()
              : ApiProductRepository(widget.dio),
        ),
        Provider<SupplierRepository>(
          create: (_) => cloud
              ? SupabaseSupplierRepository()
              : ApiSupplierRepository(widget.dio),
        ),
        Provider<CategoryRepository>(
          create: (_) => cloud
              ? SupabaseCategoryRepository()
              : ApiCategoryRepository(widget.dio),
        ),
        Provider<WarehouseRepository>(
          create: (_) => cloud
              ? SupabaseWarehouseRepository()
              : ApiWarehouseRepository(widget.dio),
        ),
        Provider<EmployeeRepository>(
          create: (_) => cloud
              ? SupabaseEmployeeRepository()
              : ApiEmployeeRepository(widget.dio),
        ),
        ProxyProvider3<
          CategoryRepository,
          SupplierRepository,
          WarehouseRepository,
          ReferenceCache
        >(update: (_, cats, sups, whs, _) => ReferenceCache(cats, sups, whs)),
        ChangeNotifierProvider(
          create: (context) =>
              ProductListNotifier(context.read<ProductRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SupplierListNotifier(context.read<SupplierRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CategoryListNotifier(context.read<CategoryRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              WarehouseListNotifier(context.read<WarehouseRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              EmployeeListNotifier(context.read<EmployeeRepository>()),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          useMaterial3: true,
        ),
        routerConfig: _router,
        builder: (context, child) {
          final auth = context.watch<AuthNotifier>();
          if (!auth.isAuthenticated) {
            return child ?? const SizedBox.shrink();
          }
          return InactivityWatcher(
            timeout: const Duration(minutes: 3),
            warnBefore: const Duration(seconds: 30),
            maxSession: const Duration(hours: 8),
            onActivity: () => auth.touchActivity(),
            onWarn: (left) {
              final messenger = ScaffoldMessenger.maybeOf(context);
              messenger?.showSnackBar(
                SnackBar(
                  content: Text(
                    'Сессия завершится через ${left.inSeconds} с из‑за неактивности',
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            },
            onTimeout: () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              await auth.logout();
              messenger?.showSnackBar(
                const SnackBar(content: Text('Сессия завершена')),
              );
              _router.go('/login');
            },
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
