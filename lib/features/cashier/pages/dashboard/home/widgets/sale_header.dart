import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Фиолетовая шапка экрана продажи: кассир, торговая точка и меню кассы.
///
/// По дизайну такая шапка живёт только там, где видно кассира и статус смены —
/// на самом экране продажи. Остальные экраны кассы используют белую шапку.
/// В меню «…» здесь — то, что не относится к текущему чеку (режим цены,
/// валюта, погашение долга, расходы); операции над чеком — в блоке итогов.
class SaleHeader extends StatelessWidget {
  final String name;
  final String meta;
  final VoidCallback onActionsTap;

  const SaleHeader({
    super.key,
    required this.name,
    required this.meta,
    required this.onActionsTap,
  });

  /// Инициалы для аватара: до двух букв.
  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    return parts.take(2).map((e) => e.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        color: AppColors.primary,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              AppDimens.gap8,
              AppDimens.gap8,
              AppDimens.gap12,
            ),
            child: Row(
              children: [
                _Avatar(initials: _initials),
                const SizedBox(width: AppDimens.gap12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMedium.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (meta.isNotEmpty)
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: AppColors.onPrimary,
                            fontFeatures: AppText.tabularFigures,
                          ).copyWith(color: AppColors.onPrimary.withValues(alpha: 0.8)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.gap8),
                _HeaderIcon(icon: Icons.more_horiz, onTap: onActionsTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Кнопка меню кассы в шапке.
class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppDimens.control,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: AppDimens.tapTarget,
          height: AppDimens.tapTarget,
          child: Icon(icon, size: 22, color: AppColors.onPrimary),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;

  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.18),
        borderRadius: AppDimens.control,
      ),
      child: Text(
        initials,
        style: AppText.bodyMedium.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
