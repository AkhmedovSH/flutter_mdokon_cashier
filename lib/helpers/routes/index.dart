import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:kassa/pages/cashier/dashboard/profile/balance.dart';
import 'package:kassa/pages/page_not_found.dart';

import '/pages/splash.dart';

// auth
import '/pages/auth/login.dart';
import '/pages/auth/cashboxes.dart';

import '/pages/cashier/dashboard/dashboard.dart';
import 'package:kassa/pages/director/index.dart';
import '/pages/agent/dashboard.dart';

import 'cashier.dart';
import 'director.dart';

GetStorage storage = GetStorage();

// Функция для создания страниц с Cupertino анимацией
Page<T> cupertinoPageBuilder<T>(BuildContext context, GoRouterState state, Widget child) {
  return CupertinoPage(
    child: child,
    key: state.pageKey,
    name: state.name,
    arguments: state.extra,
  );
}

final globalRouter = GoRouter(
  initialLocation: '/splash',
  errorBuilder: (context, state) => PageNotFound(),
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, start) => Login(),
      routes: [
        GoRoute(
          path: '/cashboxes',
          pageBuilder: (context, state) {
            final extraData = state.extra as Map<String, dynamic>?;
            print(extraData?['posList']);
            return cupertinoPageBuilder(
              context,
              state,
              CashBoxes(
                poses: extraData?['posList'] ?? [],
              ),
            );
          },
          routes: cashiers,
        ),
      ],
    ),
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => cupertinoPageBuilder(context, state, const Splash()),
    ),
    GoRoute(
      path: '/cashier',
      pageBuilder: (context, state) => cupertinoPageBuilder(context, state, const CashierDashboard()),
      routes: cashiers,
    ),
    GoRoute(
      path: '/director',
      pageBuilder: (context, state) => cupertinoPageBuilder(context, state, const DirectorDashboard()),
      routes: directors,
    ),
    GoRoute(
      path: '/agent',
      pageBuilder: (context, state) => cupertinoPageBuilder(context, state, const AgentDashboard()),
      routes: [
        ...cashiers,
        GoRoute(
          path: '/profile/balance',
          pageBuilder: (context, state) => cupertinoPageBuilder(context, state, Balance()),
        ),
      ],
    ),
    // GoRoute(
    //   path: '/',
    //   pageBuilder: (context, state) => cupertinoPageBuilder(context, state, const PageNotFound()),
    // ),
  ],
);
