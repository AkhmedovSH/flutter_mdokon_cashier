import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'package:kassa/pages/director/pos/documents_in/create.dart';
import 'package:kassa/pages/director/pos/documents_in/index.dart';
import 'package:kassa/pages/director/reports/balance.dart';
import 'package:kassa/pages/director/reports/sales.dart';

Page<T> cupertinoPageBuilder<T>(BuildContext context, GoRouterState state, Widget child) {
  return CupertinoPage(
    child: child,
    key: state.pageKey,
    name: state.name,
    arguments: state.extra,
  );
}

List<RouteBase> directors = [
  GoRoute(
    path: '/documents-in',
    pageBuilder: (context, state) => cupertinoPageBuilder(context, state, DocumentsIn()),
    routes: [
      GoRoute(
        path: '/create',
        pageBuilder: (context, state) => cupertinoPageBuilder(context, state, DocumentsInCreate()),
      )
    ],
  ),
  GoRoute(
    path: '/balance',
    pageBuilder: (context, state) => cupertinoPageBuilder(context, state, PosBalance()),
  ),
  GoRoute(
    path: '/sales',
    pageBuilder: (context, state) => cupertinoPageBuilder(context, state, PosSales()),
  ),
];
