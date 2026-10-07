import 'package:flutter/material.dart';

import '../widgets/deferred_screen.dart';
import 'admin_stats_screen.dart' deferred as stats;
import 'admin_users_screen.dart' deferred as users;
import 'viewer_requests_screen.dart' deferred as viewer;

/// Отложенная загрузка редких разделов — уменьшает размер первой загрузки.
Widget deferredAdminUsers() => DeferredScreen(
  loader: () async {
    await users.loadLibrary();
    return users.AdminUsersScreen();
  },
);

Widget deferredAdminStats() => DeferredScreen(
  loader: () async {
    await stats.loadLibrary();
    return stats.AdminStatsScreen();
  },
);

Widget deferredViewerRequests() => DeferredScreen(
  loader: () async {
    await viewer.loadLibrary();
    return viewer.ViewerRequestsScreen();
  },
);
