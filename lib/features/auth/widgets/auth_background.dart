import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';

/// Фирменный фон экранов авторизации: заливка primary и два мягких круга.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  /// Круги — та же заливка, осветлённая: отдельного токена не заводим,
  /// декорация читается только рядом с [AppColors.brandSurface].
  static Color get _circle => Color.lerp(AppColors.brandSurface, Colors.white, 0.08)!;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brandSurface,
      child: Stack(
        children: [
          const Positioned(top: -130, left: -140, child: _Circle(size: 300)),
          const Positioned(bottom: -100, right: -110, child: _Circle(size: 240)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;

  const _Circle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AuthBackground._circle,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Логотип и название продукта над карточкой формы.
class AuthLogoHeader extends StatelessWidget {
  final String subtitle;

  const AuthLogoHeader({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.onBrandSurface.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            'm',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.onBrandSurface,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.gap12),
        Text(
          'mDokon POS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onBrandSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.onBrandSurface.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
