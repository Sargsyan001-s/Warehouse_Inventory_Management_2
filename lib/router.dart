import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/auth.dart';
import '../models/entity_query.dart';
import '../models/product_query.dart';
import '../core/breakpoints.dart';
import '../screens/category_detail_screen.dart';
import '../screens/category_form_screen.dart';
import '../screens/category_list_screen.dart';
import '../screens/deferred_admin.dart';
import '../screens/employee_detail_screen.dart';
import '../screens/employee_form_screen.dart';
import '../screens/employee_list_screen.dart';
import '../screens/forbidden_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_form_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/register_screen.dart';
import '../screens/supplier_detail_screen.dart';
import '../screens/supplier_form_screen.dart';
import '../screens/supplier_list_screen.dart';
import '../screens/warehouse_detail_screen.dart';
import '../screens/warehouse_form_screen.dart';
import '../screens/warehouse_list_screen.dart';
import '../state/auth_notifier.dart';
import '../state/category_list_notifier.dart';
import '../state/employee_list_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../state/product_list_notifier.dart';
import '../state/supplier_list_notifier.dart';
import '../state/warehouse_list_notifier.dart';
import '../widgets/content_width.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthNotifier auth) {
  String? roleGuard(Role need) => auth.has(need) ? null : '/forbidden';

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (c, s) => LoginScreen(from: s.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/register',
        builder: (c, s) => RegisterScreen(from: s.uri.queryParameters['from']),
      ),
      GoRoute(path: '/forbidden', builder: (c, s) => const ForbiddenScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
          GoRoute(
            path: '/viewer/requests',
            redirect: (c, s) =>
                auth.user?.role == Role.viewer ? null : '/forbidden',
            builder: (c, s) => deferredViewerRequests(),
          ),
          GoRoute(
            path: '/admin/stats',
            redirect: (c, s) => roleGuard(Role.admin),
            builder: (c, s) => deferredAdminStats(),
          ),
          GoRoute(
            path: '/admin/users',
            redirect: (c, s) => roleGuard(Role.admin),
            builder: (c, s) => deferredAdminUsers(),
          ),
          ..._entityRoutes(
            path: '/products',
            listBuilder: (context, state) {
              final query = ProductQuery.fromQueryParams(
                state.uri.queryParameters,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final n = context.read<ProductListNotifier>();
                if (!_sameProductQuery(n.query, query)) {
                  n.applyQuery(query);
                } else if (n.status == LoadStatus.idle) {
                  n.load();
                }
              });
              return const ProductListScreen();
            },
            detailBuilder: (id) => ProductDetailScreen(id: id),
            formNew: const ProductFormScreen(),
            formEdit: (id) => ProductFormScreen(id: id),
            writeRedirect: () => roleGuard(Role.operator),
          ),
          ..._entityRoutes(
            path: '/suppliers',
            listBuilder: (context, state) {
              final query = EntityQuery.fromQueryParams(
                state.uri.queryParameters,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final n = context.read<SupplierListNotifier>();
                if (!_sameEntityQuery(n.query, query)) {
                  n.applyQuery(query);
                } else if (n.status == LoadStatus.idle) {
                  n.load();
                }
              });
              return const SupplierListScreen();
            },
            detailBuilder: (id) => SupplierDetailScreen(id: id),
            formNew: const SupplierFormScreen(),
            formEdit: (id) => SupplierFormScreen(id: id),
            writeRedirect: () => roleGuard(Role.operator),
          ),
          ..._entityRoutes(
            path: '/categories',
            listBuilder: (context, state) {
              final query = EntityQuery.fromQueryParams(
                state.uri.queryParameters,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final n = context.read<CategoryListNotifier>();
                if (!_sameEntityQuery(n.query, query)) {
                  n.applyQuery(query);
                } else if (n.status == LoadStatus.idle) {
                  n.load();
                }
              });
              return const CategoryListScreen();
            },
            detailBuilder: (id) => CategoryDetailScreen(id: id),
            formNew: const CategoryFormScreen(),
            formEdit: (id) => CategoryFormScreen(id: id),
            writeRedirect: () => roleGuard(Role.operator),
          ),
          ..._entityRoutes(
            path: '/warehouses',
            listBuilder: (context, state) {
              final query = EntityQuery.fromQueryParams(
                state.uri.queryParameters,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final n = context.read<WarehouseListNotifier>();
                if (!_sameEntityQuery(n.query, query)) {
                  n.applyQuery(query);
                } else if (n.status == LoadStatus.idle) {
                  n.load();
                }
              });
              return const WarehouseListScreen();
            },
            detailBuilder: (id) => WarehouseDetailScreen(id: id),
            formNew: const WarehouseFormScreen(),
            formEdit: (id) => WarehouseFormScreen(id: id),
            writeRedirect: () => roleGuard(Role.operator),
          ),
          ..._entityRoutes(
            path: '/employees',
            listRedirect: () => roleGuard(Role.operator),
            listBuilder: (context, state) {
              final query = EntityQuery.fromQueryParams(
                state.uri.queryParameters,
                defaultSort: 'fullName',
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final n = context.read<EmployeeListNotifier>();
                if (!_sameEntityQuery(n.query, query)) {
                  n.applyQuery(query);
                } else if (n.status == LoadStatus.idle) {
                  n.load();
                }
              });
              return const EmployeeListScreen();
            },
            detailBuilder: (id) => EmployeeDetailScreen(id: id),
            formNew: const EmployeeFormScreen(),
            formEdit: (id) => EmployeeFormScreen(id: id),
            writeRedirect: () => roleGuard(Role.operator),
          ),
        ],
      ),
    ],
  );
}

List<RouteBase> _entityRoutes({
  required String path,
  required Widget Function(BuildContext, GoRouterState) listBuilder,
  required Widget Function(int id) detailBuilder,
  required Widget formNew,
  required Widget Function(int id) formEdit,
  String? Function()? listRedirect,
  String? Function()? writeRedirect,
}) {
  return [
    GoRoute(
      path: path,
      redirect: (c, s) => listRedirect?.call(),
      builder: listBuilder,
      routes: [
        GoRoute(
          path: 'new',
          redirect: (c, s) => writeRedirect?.call(),
          builder: (c, s) => formNew,
        ),
        GoRoute(
          path: ':id/edit',
          redirect: (c, s) => writeRedirect?.call(),
          builder: (c, s) {
            final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
            return formEdit(id);
          },
        ),
        GoRoute(
          path: ':id',
          builder: (c, s) {
            final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
            return detailBuilder(id);
          },
        ),
      ],
    ),
  ];
}

bool _sameProductQuery(ProductQuery a, ProductQuery b) {
  return a.search == b.search &&
      a.categoryId == b.categoryId &&
      a.supplierId == b.supplierId &&
      a.warehouseId == b.warehouseId &&
      a.yearFrom == b.yearFrom &&
      a.yearTo == b.yearTo &&
      a.sortField == b.sortField &&
      a.sortAscending == b.sortAscending &&
      a.page == b.page &&
      a.size == b.size &&
      a.includeDeleted == b.includeDeleted;
}

bool _sameEntityQuery(EntityQuery a, EntityQuery b) {
  return a.search == b.search &&
      a.filter == b.filter &&
      a.sortField == b.sortField &&
      a.sortAscending == b.sortAscending &&
      a.page == b.page &&
      a.size == b.size &&
      a.includeDeleted == b.includeDeleted;
}

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final role = auth.user?.role ?? Role.viewer;
    final destinations =
        <({String path, String label, IconData icon, IconData selected})>[
          (
            path: '/',
            label: 'Главная',
            icon: Icons.home_outlined,
            selected: Icons.home,
          ),
          (
            path: '/products',
            label: 'Товары',
            icon: Icons.inventory_2_outlined,
            selected: Icons.inventory_2,
          ),
          (
            path: '/suppliers',
            label: 'Поставщики',
            icon: Icons.local_shipping_outlined,
            selected: Icons.local_shipping,
          ),
          (
            path: '/categories',
            label: 'Категории',
            icon: Icons.category_outlined,
            selected: Icons.category,
          ),
          (
            path: '/warehouses',
            label: 'Склады',
            icon: Icons.warehouse_outlined,
            selected: Icons.warehouse,
          ),
          if (Permissions.canManageEmployees(role))
            (
              path: '/employees',
              label: 'Сотрудники',
              icon: Icons.badge_outlined,
              selected: Icons.badge,
            ),
          if (Permissions.canViewOwnRequests(role))
            (
              path: '/viewer/requests',
              label: 'Заявки',
              icon: Icons.assignment_outlined,
              selected: Icons.assignment,
            ),
          if (Permissions.canViewStats(role))
            (
              path: '/admin/stats',
              label: 'Статистика',
              icon: Icons.bar_chart_outlined,
              selected: Icons.bar_chart,
            ),
          if (Permissions.canAdminUsers(role))
            (
              path: '/admin/users',
              label: 'Пользователи',
              icon: Icons.manage_accounts_outlined,
              selected: Icons.manage_accounts,
            ),
        ];

    final location = GoRouterState.of(context).uri.toString();
    var index = 0;
    for (var i = 0; i < destinations.length; i++) {
      final p = destinations[i].path;
      if (p == '/') {
        if (location == '/' || location.startsWith('/?')) index = i;
      } else if (location.startsWith(p)) {
        index = i;
      }
    }
    index = index.clamp(0, destinations.length - 1);

    final phone = context.isPhone;
    final desktop = context.isDesktop;
    final userLabel = auth.user == null
        ? ''
        : '${auth.user!.displayName} · ${role.title}';

    Widget navBody(Widget body) {
      return Column(
        children: [
          Material(
            color: const Color(0xFF1976D2),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Text(
                      'Склад',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        userLabel,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    IconButton(
                      color: Colors.white,
                      tooltip: 'Выйти',
                      onPressed: () async {
                        await auth.logout();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: ContentWidth(child: body)),
        ],
      );
    }

    if (phone) {
      return navBody(
        Scaffold(
          body: child,
          bottomNavigationBar: Material(
            elevation: 3,
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: destinations.length,
                  itemBuilder: (context, i) {
                    final d = destinations[i];
                    final selected = i == index;
                    return Tooltip(
                      message: d.label,
                      child: InkWell(
                        onTap: () => context.go(d.path),
                        child: SizedBox(
                          width: 72,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                selected ? d.selected : d.icon,
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                d.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    return navBody(
      Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              backgroundColor: Colors.blue.shade50,
              indicatorColor: Colors.blue.shade200,
              // 768 — подпись у выбранного; 1280+ — все подписи.
              labelType: desktop
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.selected,
              onDestinationSelected: (i) => context.go(destinations[i].path),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Tooltip(message: d.label, child: Icon(d.icon)),
                    selectedIcon: Tooltip(
                      message: d.label,
                      child: Icon(d.selected),
                    ),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
