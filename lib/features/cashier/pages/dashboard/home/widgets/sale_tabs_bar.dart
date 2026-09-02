import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/domain/sale_tabs.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Панель параллельных чеков — порт `cashbox-sessions-tabs` из `Cashbox.js`.
///
/// Рисуется только на планшете: на телефоне ширины нет ни на вкладки, ни на
/// сценарий «два покупателя у одной кассы».
class SaleTabsBar extends StatelessWidget {
  const SaleTabsBar({
    super.key,
    required this.state,
    required this.currency,
    required this.onSelect,
    required this.onClose,
    required this.onAdd,
  });

  final SaleTabsState state;
  final String currency;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onClose;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;

    return Container(
      height: layout.tapTarget + AppDimens.gap12,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: layout.gutter, vertical: AppDimens.gap8 / 2),
              itemCount: state.tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppDimens.gap8),
              itemBuilder: (context, index) {
                final tab = state.tabs[index];
                return _TabChip(
                  position: index + 1,
                  tab: tab,
                  currency: currency,
                  active: tab.id == state.activeId,
                  // Последнюю вкладку закрыть нельзя: касса без чека — не
                  // состояние. Крестик у неё просто не рисуем.
                  onClose: state.canClose ? () => onClose(tab.id) : null,
                  onTap: () => onSelect(tab.id),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: layout.gutter, left: AppDimens.gap8),
            child: AppIconButton(
              icon: Icons.add,
              background: AppColors.canvas,
              foreground: state.canAdd ? AppColors.textPrimary : AppColors.textSecondary,
              size: layout.tapTarget,
              iconSize: 22,
              tooltip: context.tr('new_cheque'),
              onPressed: state.canAdd ? onAdd : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.position,
    required this.tab,
    required this.currency,
    required this.active,
    required this.onTap,
    required this.onClose,
  });

  final int position;
  final SaleTab tab;
  final String currency;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    // Пустая вкладка показывает только номер: «0 сум» кассир читает как
    // проваленную продажу, а это просто ещё не начатый чек.
    final subtitle = tab.isEmpty
        ? context.tr('cheque_is_empty')
        : '${tab.lineCount} · ${formatMoney(tab.total)} $currency';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusControl),
      child: Container(
        constraints: const BoxConstraints(minWidth: 132, maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12, vertical: AppDimens.gap8 / 2),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryTint : AppColors.canvas,
          borderRadius: BorderRadius.circular(AppDimens.radiusControl),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.tr('cheque')} $position',
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.primary : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: AppText.tabular(AppText.caption),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onClose != null) ...[
              const SizedBox(width: AppDimens.gap8),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(AppDimens.radiusControl),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
