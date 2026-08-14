import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '/pages/director/pos/documents_in/create.dart';
import '/pages/director/pos/documents_in/index.dart';
import '/pages/director/pos/documents_in/complete.dart';
import '/pages/director/pos/inventory/complete.dart';
import '/pages/director/pos/inventory/create.dart';
import '/pages/director/pos/inventory/index.dart';

import '/pages/director/reports/balance.dart';
import '/pages/director/reports/sales.dart';

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
        routes: [
          GoRoute(
            path: '/complete',
            pageBuilder: (context, state) => cupertinoPageBuilder(context, state, DocumentsInComplete()),
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: '/inventory',
    pageBuilder: (context, state) => cupertinoPageBuilder(context, state, Inventory()),
    routes: [
      GoRoute(
        path: '/create',
        pageBuilder: (context, state) => cupertinoPageBuilder(context, state, InventoryCreate()),
        routes: [
          GoRoute(
            path: '/complete',
            pageBuilder: (context, state) => cupertinoPageBuilder(context, state, InventoryComplete()),
          ),
        ],
      ),
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
