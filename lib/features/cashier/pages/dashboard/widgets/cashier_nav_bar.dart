import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Вкладка нижней навигации.
class CashierNavItem {
  final IconData icon;
  final String labelKey;

  /// Счётчик поверх иконки (позиции в чеке).
  final int badge;

  const CashierNavItem({
    required this.icon,
    required this.labelKey,
    this.badge = 0,
  });
}

/// Нижняя навигация кассы.
///
/// Фон #FFFFFF, верхний бордер 1px #E3E8F3, высота 52 + жест-бар.
/// Активная вкладка — 11/600 #5B60E8, обычная — 11/400 #5F6980
/// (иконка #8A93A8).
class CashierNavBar extends StatelessWidget {
  final List<CashierNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CashierNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final CashierNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    final iconColor = selected ? AppColors.primary : AppColors.iconMuted;

    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Badged(count: item.badge, child: Icon(item.icon, size: 22, color: iconColor)),
          const SizedBox(height: AppDimens.gap4),
          Text(
            context.tr(item.labelKey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Красный счётчик в правом верхнем углу иконки.
class _Badged extends StatelessWidget {
  final int count;
  final Widget child;

  const _Badged({required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -6,
          right: -10,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16),
            height: 16,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: AppDimens.pill,
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: TextStyle(
                fontSize: 10,
                height: 1,
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimary,
                fontFeatures: AppText.tabularFigures,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
