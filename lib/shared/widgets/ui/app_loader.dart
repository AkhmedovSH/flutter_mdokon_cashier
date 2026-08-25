import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/theme/app_typography.dart';

/// Спиннер дизайн-системы: кольцо #EEF0FE с дугой #5B60E8.
class AppLoader extends StatelessWidget {
  final double size;
  final double strokeWidth;

  /// `null` — брендовый цвет активной палитры.
  final Color? color;

  const AppLoader({
    super.key,
    this.size = 32,
    this.strokeWidth = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? AppColors.primary,
        backgroundColor: AppColors.primarySoft,
      ),
    );
  }
}

/// Центрированный лоадер с подписью — для пустой области экрана.
class AppLoaderView extends StatelessWidget {
  final String? label;

  const AppLoaderView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoader(),
          if (label != null) ...[
            const SizedBox(height: AppDimens.gap12),
            Text(label!, style: AppText.secondary),
          ],
        ],
      ),
    );
  }
}

/// Карточка лоадера поверх затемнения (как в прототипе: белая плашка 16px,
/// спиннер 32 и подпись 14/400).
class AppLoaderCard extends StatelessWidget {
  final String label;

  const AppLoaderCard({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(minWidth: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.gap24,
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimens.card,
          boxShadow: AppDimens.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoader(),
            const SizedBox(height: AppDimens.gap12),
            Text(
              label,
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Блокирующий оверлей поверх контента.
///
/// ```dart
/// AppLoadingOverlay(
///   loading: model.isLoading,
///   label: 'Проведение оплаты…',
///   child: Scaffold(...),
/// )
/// ```
class AppLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool loading;
  final String? label;

  const AppLoadingOverlay({
    super.key,
    required this.child,
    required this.loading,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (loading)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: AppColors.scrim.withValues(alpha: 0.35),
                child: label == null ? const Center(child: AppLoader()) : AppLoaderCard(label: label!),
              ),
            ),
          ),
      ],
    );
  }
}

/// Модальный лоадер: `final close = await showAppLoader(context, 'Печать чека…');`
/// затем `close();`.
Future<VoidCallback> showAppLoader(BuildContext context, [String? label]) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.scrim.withValues(alpha: 0.35),
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: label == null ? const Center(child: AppLoader()) : AppLoaderCard(label: label),
    ),
  );
  return () {
    if (navigator.canPop()) navigator.pop();
  };
}

/// Скелетон-плашка для списков в состоянии загрузки.
class AppSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const AppSkeleton({
    super.key,
    this.height = 64,
    this.width,
    this.borderRadius = AppDimens.card,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: widget.borderRadius,
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
  }
}
