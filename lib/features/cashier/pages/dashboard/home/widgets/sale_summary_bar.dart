import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Нижний блок итогов: «Итого», «Скидка», «К оплате» и действия.
///
/// Палец не покидает нижнюю треть экрана: оплата и меню «…» стоят рядом
/// с суммой к оплате.
class SaleSummaryBar extends StatelessWidget {
  final int lineCount;
  final double subtotal;
  final double discountPercent;
  final double discountSum;
  final double total;
  final String currency;

  /// Подпись основной кнопки: «Продать» либо «Отправить на кассу» у агента.
  final String payLabel;
  final bool busy;
  final VoidCallback? onPay;
  final VoidCallback onMore;

  const SaleSummaryBar({
    super.key,
    required this.lineCount,
    required this.subtotal,
    required this.discountPercent,
    required this.discountSum,
    required this.total,
    required this.currency,
    required this.payLabel,
    required this.onMore,
    this.busy = false,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gap12,
        AppDimens.gutter,
        AppDimens.gap12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Row(
            label: '${context.tr('total')} · $lineCount ${context.tr('pieces_short')}',
            value: '${formatMoney(subtotal)} $currency',
          ),
          const SizedBox(height: AppDimens.gap8),
          _Row(
            label: '${context.tr('discount')} ${formatMoney(discountPercent, decimalDigits: 0)}%',
            value: '−${formatMoney(discountSum)} $currency',
          ),
          const SizedBox(height: AppDimens.gap8),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimens.gap8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('to_pay').toUpperCase(),
                style: AppText.caption.copyWith(
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${formatMoney(total)} $currency',
                    style: AppText.amount.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: payLabel,
                  loading: busy,
                  onPressed: onPay,
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
              AppIconButton(
                icon: Icons.more_horiz,
                background: AppColors.surface,
                foreground: AppColors.textSecondary,
                size: AppDimens.heightLarge,
                iconSize: 22,
                onPressed: onMore,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Строка «подпись — сумма» блока итогов.
class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(width: AppDimens.gap8),
        Text(value, style: AppText.tabular(AppText.secondaryBold)),
      ],
    );
  }
}
