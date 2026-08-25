import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/theme/responsive.dart';

export 'package:flutter_mdokon/core/theme/responsive.dart';

/// Ограничивает ширину содержимого и центрирует его.
///
/// На телефоне это прозрачная обёртка, на планшете список перестаёт
/// растягиваться на 1280 px и остаётся читаемой колонкой.
class ContentBox extends StatelessWidget {
  final Widget child;

  /// Своя предельная ширина; по умолчанию — [AppLayout.contentMaxWidth].
  final double? maxWidth;

  final Alignment alignment;

  const ContentBox({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final width = maxWidth ?? context.layout.contentMaxWidth;
    if (!width.isFinite) return child;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }
}

/// Раскладка «основная область + боковая колонка».
///
/// Пока экран узкий ([AppLayout.hasSideRail] == false), колонка уезжает вниз
/// обычной панелью — телефонная вёрстка не меняется.
class SideRailLayout extends StatelessWidget {
  final Widget body;

  /// Колонка справа на широком экране.
  final Widget rail;

  /// Панель снизу на узком экране. `null` — колонка просто не показывается.
  final Widget? bottom;

  /// Своя ширина колонки; по умолчанию — [AppLayout.railWidth].
  final double? railWidth;

  const SideRailLayout({
    super.key,
    required this.body,
    required this.rail,
    this.bottom,
    this.railWidth,
  });

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;

    if (!layout.hasSideRail) {
      return Column(
        children: [
          Expanded(child: body),
          ?bottom,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: body),
        Container(
          width: railWidth ?? layout.railWidth,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(left: layout.columnBorder),
          ),
          child: rail,
        ),
      ],
    );
  }
}

/// Раскладка «список слева — карточка справа».
///
/// На узком экране показываем что-то одно: пока [detail] не выбран — список.
class MasterDetailLayout extends StatelessWidget {
  final Widget master;

  /// Правая колонка. `null` — ничего не выбрано.
  final Widget? detail;

  /// Заглушка правой колонки, когда ничего не выбрано.
  final Widget? placeholder;

  /// Ширина списка; по умолчанию — [AppLayout.masterWidth].
  final double? masterWidth;

  const MasterDetailLayout({
    super.key,
    required this.master,
    this.detail,
    this.placeholder,
    this.masterWidth,
  });

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;

    if (!layout.hasMasterDetail) return detail ?? master;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: masterWidth ?? layout.masterWidth, child: master),
        Container(width: 1, color: AppColors.border),
        Expanded(child: detail ?? placeholder ?? const SizedBox.shrink()),
      ],
    );
  }
}
