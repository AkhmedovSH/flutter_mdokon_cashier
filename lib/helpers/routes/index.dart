import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

import '/pages/splash.dart';

// auth
import '/pages/auth/login.dart';
import '/pages/auth/cashboxes.dart';

import '/pages/cashier/dashboard/dashboard.dart';
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
  initialLocation: storage.read('token') != null ? '/dashboard' : '/login',
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => cupertinoPageBuilder(context, state, const Login()),
    ),
    GoRoute(
      path: '/cashier',
      pageBuilder: (context, state) => cupertinoPageBuilder(context, state, const CashierDashboard()),
      routes: cashiers,
    ),
    GoRoute(
      path: '/director',
      pageBuilder: (context, state) => cupertinoPageBuilder(context, state, const Index()),
      routes: [],
    ),
  ],
);
