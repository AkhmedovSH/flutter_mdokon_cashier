import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '/pages/cashier/dashboard/cheques/cheq_detail.dart';

import '/pages/cashier/dashboard/return.dart';

import '/pages/cashier/dashboard/home/search.dart';
import '/pages/cashier/payment/payment_sample.dart';
import '/pages/cashier/dashboard/profile/x_report.dart';
import '/pages/cashier/dashboard/profile/balance.dart';
import '/pages/cashier/dashboard/profile/info.dart';
import '/pages/cashier/dashboard/profile/settings.dart';

// import '/pages/cashier/client_debt.dart';
// import '/pages/cashier/sales_on_credit.dart';

Page<T> cupertinoPageBuilder<T>(BuildContext context, GoRouterState state, Widget child) {
  return CupertinoPage(
    child: child,
    key: state.pageKey,
    name: state.name,
    arguments: state.extra,
  );
}

List<RouteBase> cashiers = [
  GoRoute(
    path: '/search',
    pageBuilder: (context, state) {
      final extraData = state.extra as Map<String, dynamic>?;
      print(extraData);
      return cupertinoPageBuilder(context, state, Search(arguments: extraData));
    },
  ),
  GoRoute(
    path: '/cheque/detail/:id',
    pageBuilder: (context, state) {
      final String id = state.pathParameters['id']!;
      return cupertinoPageBuilder(context, state, CheqDetail(id: id));
    },
  ),
  GoRoute(
    path: '/payment',
    pageBuilder: (context, state) {
      print(state.extra);
      final extraData = state.extra as Map<String, dynamic>?;
      return cupertinoPageBuilder(context, state, PaymentSample(data: extraData!));
    },
  ),
  GoRoute(
    path: '/profile/x-report',
    pageBuilder: (context, state) => cupertinoPageBuilder(context, state, XReport()),
  ),
  GoRoute(
    path: '/profile/balance',
    pageBuilder: (context, state) => cupertinoPageBuilder(context, state, Balance()),
  ),
  GoRoute(
    path: '/profile/info',
    pageBuilder: (context, state) => cupertinoPageBuilder(context, state, Info()),
  ),
  GoRoute(
    path: '/profile/settings',
    pageBuilder: (context, state) => cupertinoPageBuilder(context, state, Settings()),
  ),
  GoRoute(
    path: '/return',
    pageBuilder: (context, state) => cupertinoPageBuilder(context, state, Return()),
  ),
];
