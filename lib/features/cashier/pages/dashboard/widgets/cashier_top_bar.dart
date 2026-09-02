import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_mdokon/features/cashier/pages/dashboard/widgets/cashier_nav_bar.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';
import 'package:flutter_mdokon/core/theme/themes.dart';

/// Верхняя навигация кассы для планшета.
///
/// На телефоне разделы живут в нижней панели ([CashierNavBar]) — там до них
/// достаёт большой палец. На широком экране низ экрана далеко от рук кассира,
/// поэтому разделы переезжают в шапку и встают рядом с тем, кто работает на
/// кассе: имя, точка, номер кассы.
class CashierTopBar extends StatelessWidget {
  final List<CashierNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Кассир и торговая точка — то же, что на телефоне показывает шапка продажи.
  final String name;
  final String meta;

  /// Меню кассы («…»). `null` — кнопку не показываем.
  final VoidCallback? onActionsTap;

  const CashierTopBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.name,
    required this.meta,
    this.onActionsTap,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    return parts.take(2).map((e) => e.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Яркость иконок берём от палитры: прибитая к светлой теме, она делала
      // статус-бар тёмным на тёмном.
      value: systemOverlayStyleFor(AppColors.palette).copyWith(
        statusBarColor: AppColors.surface,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: layout.topNavHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: layout.gutter),
              child: Row(
                children: [
                  _Identity(initials: _initials, name: name, meta: meta),
                  const SizedBox(width: AppDimens.gap16),
                  // Вкладки — центр шапки; при нехватке ширины скроллятся.
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i != 0) const SizedBox(width: AppDimens.gap4),
                            _NavTab(
                              item: items[i],
                              selected: i == currentIndex,
                              height: layout.tapTarget,
                              onTap: () => onTap(i),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (onActionsTap != null) ...[
                    const SizedBox(width: AppDimens.gap8),
                    AppIconButton(
                      icon: Icons.more_horiz,
                      background: AppColors.canvas,
                      foreground: AppColors.textSecondary,
                      size: layout.tapTarget,
                      iconSize: 22,
                      onPressed: onActionsTap,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Кассир и торговая точка слева в шапке.
class _Identity extends StatelessWidget {
  final String initials;
  final String name;
  final String meta;

  const _Identity({required this.initials, required this.name, required this.meta});

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: layout.pick(compact: 200, medium: 220, expanded: 260)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppDimens.control,
            ),
            child: Text(
              initials,
              style: AppText.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.gap8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Вкладка раздела: иконка, подпись и счётчик позиций.
class _NavTab extends StatelessWidget {
  final CashierNavItem item;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.selected,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return Material(
      color: selected ? AppColors.primarySoft : Colors.transparent,
      borderRadius: AppDimens.control,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 20, color: selected ? AppColors.primary : AppColors.iconMuted),
              const SizedBox(width: AppDimens.gap8),
              Text(
                context.tr(item.labelKey),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
              if (item.badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: AppDimens.pill,
                  ),
                  child: Text(
                    item.badge > 99 ? '99+' : '${item.badge}',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                      fontFeatures: AppText.tabularFigures,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
