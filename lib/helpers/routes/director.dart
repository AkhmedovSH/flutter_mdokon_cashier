import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'package:kassa/pages/director/pos/documents_in/create.dart';
import 'package:kassa/pages/director/pos/documents_in/index.dart';

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
];
