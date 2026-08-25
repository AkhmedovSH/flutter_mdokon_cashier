import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/theme/app_typography.dart';

/// Карточка дизайн-системы: фон #FFFFFF, бордер 1px #E3E8F3, радиус 16.
/// [selected] — выделение 1.5px #5B60E8 (товар в чеке, выбранный клиент).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool selected;
  final Color? color;
  final bool shadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimens.gap16,
      vertical: 14,
    ),
    this.onTap,
    this.selected = false,
    this.color,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: AppDimens.card,
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.border,
        width: selected ? 1.5 : 1,
      ),
      boxShadow: shadow ? AppDimens.cardShadow : null,
    );

    if (onTap == null) {
      return Container(decoration: decoration, padding: padding, child: child);
    }

    return Material(
      color: color ?? AppColors.surface,
      borderRadius: AppDimens.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: decoration.copyWith(color: Colors.transparent),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Лейбл секции: 11/600 caps 0.06em, цвет #5F6980.
class AppSectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final Widget? trailing;

  const AppSectionLabel(this.text, {super.key, this.color, this.trailing});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: AppText.caption.copyWith(color: color ?? AppColors.textSecondary),
    );

    if (trailing == null) return label;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [label, trailing!],
    );
  }
}

/// Семантика баннера: предупреждение, ошибка, успех.
enum AppBannerTone { warning, danger, success }

/// Информационный баннер (офлайн, превышение лимита долга и т.п.).
class AppBanner extends StatelessWidget {
  final String title;
  final String? text;

  /// Семантика баннера. Цвета выводятся из неё в [build], а не хранятся полями:
  /// константный конструктор запомнил бы цвета одной темы.
  final AppBannerTone tone;

  const AppBanner({
    super.key,
    required this.title,
    this.text,
  }) : tone = AppBannerTone.warning;

  const AppBanner.danger({
    super.key,
    required this.title,
    this.text,
  }) : tone = AppBannerTone.danger;

  const AppBanner.success({
    super.key,
    required this.title,
    this.text,
  }) : tone = AppBannerTone.success;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, dotColor) = switch (tone) {
      AppBannerTone.danger => (AppColors.dangerSoft, AppColors.dangerText, AppColors.danger),
      AppBannerTone.success => (AppColors.successSoft, AppColors.successText, AppColors.success),
      AppBannerTone.warning => (AppColors.warningSoft, AppColors.warningText, AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppDimens.gap12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppDimens.control,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.secondaryBold.copyWith(color: foreground),
                ),
                if (text != null) ...[
                  const SizedBox(height: 2),
                  Text(text!, style: AppText.small.copyWith(color: foreground)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Пустое состояние: иконка, заголовок 18/600, текст 14/400 и опциональное действие.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? text;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.text,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: AppDimens.gap24),
        // Текст и кнопка не растягиваются на всю ширину планшета — читать
        // строку в 1000 px неудобно, а кнопка выглядит полосой.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppColors.iconMuted),
              const SizedBox(height: 10),
              Text(title, style: AppText.h2, textAlign: TextAlign.center),
              if (text != null) ...[
                const SizedBox(height: 10),
                Text(
                  text!,
                  style: AppText.secondary.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppDimens.gap16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
