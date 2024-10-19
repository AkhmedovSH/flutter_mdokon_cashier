// cheques
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '/pages/cashier/dashboard/cheques/cheq_detail.dart';

import '/pages/cashier/dashboard/return.dart';

// import '/pages/cashier/dashboard/index.dart';
import '/pages/cashier/dashboard/home/search.dart';
import '/pages/cashier/payment/payment_sample.dart';
import '/pages/cashier/dashboard/profile/x_report.dart';
import '/pages/cashier/dashboard/profile/balance.dart';
import '/pages/cashier/dashboard/profile/info.dart';
import '/pages/cashier/dashboard/profile/settings.dart';

import '/pages/cashier/client_debt.dart';
import '/pages/cashier/sales_on_credit.dart';

// Функция для создания страниц с Cupertino анимацией
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
    pageBuilder: (context, state) => cupertinoPageBuilder(context, state, const Search()),
  ),
  GoRoute(
    path: '/cheque/detail/:id',
    pageBuilder: (context, state) {
      final String id = state.pathParameters['id']!;
      return cupertinoPageBuilder(context, state, CheqDetail(id: id));
    },
  ),
];
