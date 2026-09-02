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

  /// `null` — меню «…» недоступно (например, в чеке нет позиций).
  final VoidCallback? onMore;

  const SaleSummaryBar({
    super.key,
    required this.lineCount,
    required this.subtotal,
    required this.discountPercent,
    required this.discountSum,
    required this.total,
    required this.currency,
    required this.payLabel,
    this.busy = false,
    this.onPay,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
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
          Divider(height: 1, color: AppColors.border),
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

/// Правая колонка итогов и оплаты для планшета.
///
/// Те же данные, что в [SaleSummaryBar], но развёрнутые по вертикали: сумма
/// к оплате крупнее, кнопка оплаты выше, меню чека вынесено
/// отдельной кнопкой — на широком экране прятать действия в «…» незачем.
class SaleSummaryPanel extends StatelessWidget {
  final int lineCount;
  final double subtotal;
  final double discountPercent;
  final double discountSum;
  final double total;
  final String currency;
  final String payLabel;
  final bool busy;
  final VoidCallback? onPay;
  final VoidCallback? onMore;

  /// Меню кассы («…» из шапки продажи): режим цены, валюта, долг, расходы.
  final VoidCallback? onCashierActions;

  const SaleSummaryPanel({
    super.key,
    required this.lineCount,
    required this.subtotal,
    required this.discountPercent,
    required this.discountSum,
    required this.total,
    required this.currency,
    required this.payLabel,
    this.busy = false,
    this.onPay,
    this.onMore,
    this.onCashierActions,
  });

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;

    return SafeArea(
      top: false,
      left: false,
      child: Padding(
        padding: EdgeInsets.all(layout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionLabel(context.tr('to_pay')),
            const SizedBox(height: AppDimens.gap12),
            _Row(
              label: '${context.tr('total')} · $lineCount ${context.tr('pieces_short')}',
              value: '${formatMoney(subtotal)} $currency',
            ),
            const SizedBox(height: AppDimens.gap8),
            _Row(
              label: '${context.tr('discount')} ${formatMoney(discountPercent, decimalDigits: 0)}%',
              value: '−${formatMoney(discountSum)} $currency',
            ),
            const SizedBox(height: AppDimens.gap12),
            Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppDimens.gap12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${formatMoney(total)} $currency',
                style: AppText.display.copyWith(
                  fontSize: layout.scaled(AppText.display.fontSize!),
                  color: AppColors.primary,
                ),
              ),
            ),
            // Свободное место отдаём чеку: кнопки прижаты к низу колонки.
            const Spacer(),
            SizedBox(
              height: layout.primaryButtonHeight,
              child: AppButton(
                label: payLabel,
                loading: busy,
                onPressed: onPay,
              ),
            ),
            const SizedBox(height: AppDimens.gap8),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: context.tr('cheque'),
                    icon: Icons.more_horiz,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.medium,
                    onPressed: onMore,
                  ),
                ),
                if (onCashierActions != null) ...[
                  const SizedBox(width: AppDimens.gap8),
                  AppIconButton(
                    icon: Icons.tune,
                    background: AppColors.canvas,
                    foreground: AppColors.textSecondary,
                    size: AppDimens.heightMedium,
                    iconSize: 20,
                    onPressed: onCashierActions,
                  ),
                ],
              ],
            ),
          ],
        ),
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
