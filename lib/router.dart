import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/entity_query.dart';
import '../models/product_query.dart';
import '../screens/category_detail_screen.dart';
import '../screens/category_form_screen.dart';
import '../screens/category_list_screen.dart';
import '../screens/employee_detail_screen.dart';
import '../screens/employee_form_screen.dart';
import '../screens/employee_list_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_form_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/supplier_detail_screen.dart';
import '../screens/supplier_form_screen.dart';
import '../screens/supplier_list_screen.dart';
import '../screens/warehouse_detail_screen.dart';
import '../screens/warehouse_form_screen.dart';
import '../screens/warehouse_list_screen.dart';
import '../state/category_list_notifier.dart';
import '../state/employee_list_notifier.dart';
import '../state/entity_list_notifier.dart';
import '../state/product_list_notifier.dart';
import '../state/supplier_list_notifier.dart';
import '../state/warehouse_list_notifier.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/products',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          ..._entityRoutes(
            path: '/products',
            listBuilder: (context, state) {
              final query = ProductQuery.fromQueryParams(state.uri.queryParameters);
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
          ),
          ..._entityRoutes(
            path: '/suppliers',
            listBuilder: (context, state) {
              final query = EntityQuery.fromQueryParams(state.uri.queryParameters);
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
          ),
          ..._entityRoutes(
            path: '/categories',
            listBuilder: (context, state) {
              final query = EntityQuery.fromQueryParams(state.uri.queryParameters);
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
          ),
          ..._entityRoutes(
            path: '/warehouses',
            listBuilder: (context, state) {
              final query = EntityQuery.fromQueryParams(state.uri.queryParameters);
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
          ),
          ..._entityRoutes(
            path: '/employees',
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
}) {
  return [
    GoRoute(
      path: path,
      builder: listBuilder,
      routes: [
        GoRoute(path: 'new', builder: (c, s) => formNew),
        GoRoute(
          path: ':id/edit',
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

  static const _destinations = [
    (path: '/products', label: 'Товары', icon: Icons.inventory_2_outlined, selected: Icons.inventory_2),
    (path: '/suppliers', label: 'Поставщики', icon: Icons.local_shipping_outlined, selected: Icons.local_shipping),
    (path: '/categories', label: 'Категории', icon: Icons.category_outlined, selected: Icons.category),
    (path: '/warehouses', label: 'Склады', icon: Icons.warehouse_outlined, selected: Icons.warehouse),
    (path: '/employees', label: 'Сотрудники', icon: Icons.badge_outlined, selected: Icons.badge),
  ];

  int _index(String location) {
    for (var i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _index(location);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    if (!wide) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => context.go(_destinations[i].path),
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selected),
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            backgroundColor: Colors.blue.shade50,
            indicatorColor: Colors.blue.shade200,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (i) => context.go(_destinations[i].path),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selected),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
