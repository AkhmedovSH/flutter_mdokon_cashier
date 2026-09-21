import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Быстрый переход: короче стандартных 300мс, но не настолько резкий, чтобы
/// терять плавность на слабых Android-устройствах.
const Duration _kPageTransitionDuration = Duration(milliseconds: 220);

bool get _isCupertinoPlatform =>
    defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

/// Нативный переход под текущую платформу вместо единого Cupertino-стиля
/// для всех: iOS/macOS — горизонтальный slide с параллаксом (как в системе),
/// Android/desktop — fade+scale, как в нативных Material-приложениях.
Page<T> nativePageBuilder<T>(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    name: state.name,
    arguments: state.extra,
    child: child,
    transitionDuration: _kPageTransitionDuration,
    reverseTransitionDuration: _kPageTransitionDuration,
    transitionsBuilder: _isCupertinoPlatform ? _iosTransition : _materialTransition,
  );
}

Widget _iosTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curve = CurveTween(curve: Curves.easeOutCubic);

  final incoming = animation.drive(curve).drive(Tween(begin: const Offset(1, 0), end: Offset.zero));
  // Параллакс: текущий экран слегка уезжает влево, когда сверху открывается новый.
  final outgoing =
      secondaryAnimation.drive(curve).drive(Tween(begin: Offset.zero, end: const Offset(-0.25, 0)));

  return SlideTransition(
    position: outgoing,
    child: SlideTransition(position: incoming, child: child),
  );
}

Widget _materialTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
  final scale = Tween(begin: 0.96, end: 1.0).animate(
    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
  );

  return FadeTransition(
    opacity: fade,
    child: ScaleTransition(scale: scale, child: child),
  );
}
