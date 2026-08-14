import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mdokon/features/cashier/pages/dashboard/cheques/cheque_detail.dart';

import 'package:flutter_mdokon/features/cashier/pages/dashboard/return.dart';

import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/search.dart';
import 'package:flutter_mdokon/features/cashier/pages/payment/payment_sample.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/profile/x_report.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/profile/balance.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/profile/info.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/profile/settings.dart';

// import 'package:flutter_mdokon/features/cashier/pages/client_debt.dart';
// import 'package:flutter_mdokon/features/cashier/pages/sales_on_credit.dart';

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
      return cupertinoPageBuilder(context, state, ChequeDetail(id: id));
    },
  ),
  GoRoute(
    path: '/payment',
    pageBuilder: (context, state) => cupertinoPageBuilder(context, state, PaymentSample()),
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
