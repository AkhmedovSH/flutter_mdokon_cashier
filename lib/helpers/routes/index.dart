import 'package:flutter/cupertino.dart';
import 'package:flutter_mdokon/helpers/helper.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import '/pages/cashier/dashboard/profile/balance.dart';
import '/pages/page_not_found.dart';

// auth
import '/pages/auth/login.dart';
import '/pages/auth/cashboxes.dart';

import '/pages/cashier/dashboard/dashboard.dart';
import '/pages/director/index.dart';
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
  initialLocation: '/',
  errorBuilder: (context, state) => PageNotFound(),
  redirect: (context, state) {
    final lastLogin = storage.read('lastLogin');
    final user = storage.read('user');
    final role = storage.read('role');

    bool isAuthorized = false;
    if (customIf(lastLogin) && customIf(user)) {
      if (minutesBetween(lastLogin, DateTime.now()) < 55) {
        isAuthorized = true;
      }
    }

    final isLoggingIn = state.matchedLocation == '/auth';
    if (!isAuthorized) {
      return isLoggingIn ? null : '/auth';
    }

    if (state.matchedLocation == '/' || isLoggingIn) {
      switch (role) {
        case "ROLE_CASHIER":
          return '/cashier';
        case "ROLE_OWNER":
          return '/director';
        case "ROLE_DIRECTOR":
          return '/director';
        case "ROLE_AGENT":
          return '/agent';
        default:
          return '/auth';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) {
        return cupertinoPageBuilder(context, state, const Login());
      },

      // builder: (context, start) => Login(),
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
