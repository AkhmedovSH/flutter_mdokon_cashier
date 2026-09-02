import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/theme/app_typography.dart';

/// Варианты кнопок дизайн-системы.
enum AppButtonVariant {
  /// Основное действие: заливка #5B60E8, текст caps.
  primary,

  /// Вторичное действие: белый фон + бордер #E3E8F3.
  secondary,

  /// Мягкое действие: фон #EEF0FE, текст #5B60E8.
  soft,

  /// Деструктивное: фон #FDECEC, текст #C4262B.
  danger,

  /// Деструктивное с заливкой: фон #C4262B, белый текст.
  dangerSolid,

  /// Без фона, только текст.
  ghost,
}

/// Размеры: large 56 (основное действие), medium 48, small 40.
enum AppButtonSize { large, medium, small }

/// Единая кнопка приложения.
///
/// ```dart
/// AppButton(
///   label: 'Оплата',
///   onPressed: () => ...,
/// )
/// AppButton(
///   label: 'Очистить',
///   variant: AppButtonVariant.danger,
///   size: AppButtonSize.small,
///   onPressed: () => ...,
/// )
/// ```
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Иконка слева от подписи.
  final IconData? icon;

  /// Иконка справа от подписи.
  final IconData? trailingIcon;

  /// Растянуть на всю доступную ширину.
  final bool expanded;

  /// Показать спиннер вместо содержимого и заблокировать нажатие.
  final bool loading;

  /// Пилюля (radius 999) вместо радиуса 12.
  final bool pill;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.expanded = true,
    this.loading = false,
    this.pill = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.expanded = true,
    this.loading = false,
    this.pill = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.soft({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.small,
    this.icon,
    this.trailingIcon,
    this.expanded = false,
    this.loading = false,
    this.pill = true,
  }) : variant = AppButtonVariant.soft;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.expanded = true,
    this.loading = false,
    this.pill = false,
  }) : variant = AppButtonVariant.danger;

  bool get _disabled => onPressed == null || loading;

  double get _height => switch (size) {
        AppButtonSize.large => AppDimens.heightLarge,
        AppButtonSize.medium => AppDimens.heightMedium,
        AppButtonSize.small => AppDimens.heightSmall,
      };

  double get _fontSize => switch (size) {
        AppButtonSize.large => 15,
        AppButtonSize.medium => 14,
        AppButtonSize.small => 13,
      };

  Color get _background => switch (variant) {
        AppButtonVariant.primary => AppColors.primary,
        AppButtonVariant.secondary => AppColors.surface,
        AppButtonVariant.soft => AppColors.primarySoft,
        AppButtonVariant.danger => AppColors.dangerSoft,
        AppButtonVariant.dangerSolid => AppColors.dangerText,
        AppButtonVariant.ghost => Colors.transparent,
      };

  Color get _foreground => switch (variant) {
        AppButtonVariant.primary => AppColors.onPrimary,
        AppButtonVariant.secondary => AppColors.textPrimary,
        AppButtonVariant.soft => AppColors.primary,
        AppButtonVariant.danger => AppColors.dangerText,
        AppButtonVariant.dangerSolid => AppColors.onPrimary,
        AppButtonVariant.ghost => AppColors.textSecondary,
      };

  /// Заливка primary/dangerSolid — подпись капсом с трекингом 0.04em.
  bool get _uppercase => variant == AppButtonVariant.primary ||
      variant == AppButtonVariant.dangerSolid ||
      variant == AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final radius = pill ? AppDimens.pill : AppDimens.control;
    final background = _disabled ? AppColors.disabledSurface : _background;
    final foreground = _disabled ? AppColors.disabledText : _foreground;

    final textStyle = AppText.button.copyWith(
      fontSize: _fontSize,
      color: foreground,
      letterSpacing: _uppercase ? 0.04 * _fontSize : 0,
    );

    final Widget content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(foreground),
            ),
          )
        : Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: AppDimens.gap8),
              ],
              Flexible(
                child: Text(
                  _uppercase ? label.toUpperCase() : label,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppDimens.gap8),
                Icon(trailingIcon, size: 20, color: foreground),
              ],
            ],
          );

    return SizedBox(
      width: expanded ? double.infinity : null,
      height: _height,
      child: Material(
        color: background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: variant == AppButtonVariant.secondary && !_disabled
              ? BorderSide(color: AppColors.border)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: _disabled ? null : onPressed,
          borderRadius: radius,
          splashColor: variant == AppButtonVariant.primary
              ? AppColors.primaryDark.withValues(alpha: 0.6)
              : foreground.withValues(alpha: 0.08),
          highlightColor: variant == AppButtonVariant.primary
              ? AppColors.primaryDark
              : foreground.withValues(alpha: 0.06),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size == AppButtonSize.small ? AppDimens.gap12 : AppDimens.gap16,
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}

/// Квадратная иконочная кнопка с тач-таргетом 44×44 (или заданным).
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  /// Цвета — необязательные: значения по умолчанию берутся из палитры в
  /// [build], иначе константный конструктор запомнил бы цвета одной темы.
  final Color? background;
  final Color? foreground;
  final double size;
  final double iconSize;
  final bool pill;
  final String? tooltip;

  /// Вариант «плавающая»: свой фон и тень, см. [AppIconButton.floating].
  final bool _floating;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.background,
    this.foreground,
    this.size = AppDimens.tapTarget,
    this.iconSize = 20,
    this.pill = false,
    this.tooltip,
  }) : _floating = false;

  /// Плавающая кнопка сканера: 64×64, брендовая заливка, тень.
  const AppIconButton.floating({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  })  : background = null,
        foreground = null,
        size = 64,
        iconSize = 28,
        pill = true,
        _floating = true;

  @override
  Widget build(BuildContext context) {
    final radius = pill ? AppDimens.pill : AppDimens.control;
    final fill = background ?? (_floating ? AppColors.primary : AppColors.canvas);
    final color = onPressed == null
        ? AppColors.iconMuted
        : (foreground ?? (_floating ? AppColors.onPrimary : AppColors.textPrimary));

    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(boxShadow: _floating ? AppDimens.floatingShadow : null),
      child: Material(
        color: fill,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Center(child: Icon(icon, size: iconSize, color: color)),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Чип-таб: активный — заливка primary, обычный — белый с бордером.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  /// Цвет точки статуса слева (success / warning и т.д.).
  final Color? dotColor;

  /// Мягкий вариант: фон #EEF0FE, текст #5B60E8.
  final bool soft;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.dotColor,
    this.soft = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = selected
        ? AppColors.primary
        : soft
            ? AppColors.primarySoft
            : AppColors.surface;
    final Color foreground = selected
        ? AppColors.onPrimary
        : soft
            ? AppColors.primary
            : AppColors.textPrimary;

    return Material(
      color: background,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppDimens.pill,
        side: !selected && !soft
            ? BorderSide(color: AppColors.border)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.pill,
        child: Container(
          height: AppDimens.heightSmall,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppDimens.gap8),
              ],
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
              ],
              // Подпись ужимаем: чип часто стоит в Expanded (например ряд
              // быстрых сроков), и на узком экране длинное слово выпирало.
              Flexible(
                child: Text(
                  label,
                  style: AppText.secondaryBold.copyWith(color: foreground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
