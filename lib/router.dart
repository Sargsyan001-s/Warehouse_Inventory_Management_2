import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_query.dart';
import '../models/supplier_query.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/supplier_detail_screen.dart';
import '../screens/supplier_list_screen.dart';
import '../state/product_list_notifier.dart';
import '../state/supplier_list_notifier.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/products',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/products',
            builder: (context, state) {
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
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                  return ProductDetailScreen(id: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/suppliers',
            builder: (context, state) {
              final query = SupplierQuery.fromQueryParams(state.uri.queryParameters);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final n = context.read<SupplierListNotifier>();
                if (!_sameSupplierQuery(n.query, query)) {
                  n.applyQuery(query);
                } else if (n.status == LoadStatus.idle) {
                  n.load();
                }
              });
              return const SupplierListScreen();
            },
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                  return SupplierDetailScreen(id: id);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

bool _sameProductQuery(ProductQuery a, ProductQuery b) {
  return a.search == b.search &&
      a.categoryId == b.categoryId &&
      a.supplierId == b.supplierId &&
      a.yearFrom == b.yearFrom &&
      a.yearTo == b.yearTo &&
      a.sortField == b.sortField &&
      a.sortAscending == b.sortAscending &&
      a.page == b.page &&
      a.size == b.size &&
      a.includeDeleted == b.includeDeleted;
}

bool _sameSupplierQuery(SupplierQuery a, SupplierQuery b) {
  return a.search == b.search &&
      a.country == b.country &&
      a.sortField == b.sortField &&
      a.sortAscending == b.sortAscending &&
      a.page == b.page &&
      a.size == b.size &&
      a.includeDeleted == b.includeDeleted;
}

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _index(String location) {
    if (location.startsWith('/suppliers')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _index(location);
    final wide = MediaQuery.sizeOf(context).width >= 600;

    if (!wide) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) {
            context.go(i == 0 ? '/products' : '/suppliers');
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Товары',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Поставщики',
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
            onDestinationSelected: (i) {
              context.go(i == 0 ? '/products' : '/suppliers');
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Товары'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping),
                label: Text('Поставщики'),
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
