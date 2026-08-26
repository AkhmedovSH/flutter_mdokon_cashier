import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/domain/marking_item.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Строка чека: номер, название, расчёт «цена × количество», степпер и сумма.
///
/// Выбранная строка подсвечивается бордером 1.5px #5B60E8 — быстрые операции
/// применяются именно к ней.
class CartLineTile extends StatelessWidget {
  final int index;
  final Map item;
  final String currency;
  final VoidCallback onTap;
  final ValueChanged<num> onQuantityChanged;

  /// Маркировочная позиция: количество задаётся кодами, а не степпером.
  /// `true` — сканировать новый код, `false` — открыть список кодов.
  final ValueChanged<bool>? onMarkingCodes;

  const CartLineTile({
    super.key,
    required this.index,
    required this.item,
    required this.currency,
    required this.onTap,
    required this.onQuantityChanged,
    this.onMarkingCodes,
  });

  bool get _selected => item['selected'] == true;
  bool get _marking => onMarkingCodes != null && isMarkingItem(item);
  double get _quantity => customNumber(item['quantity']);
  double get _discount => customNumber(item['discount']);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      selected: _selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppDimens.gap12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IndexBadge(index: index + 1, selected: _selected),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${item['productName'] ?? ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap8),
          // Степпер стоит первым и имеет постоянную ширину — растущая сумма
          // больше не сдвигает кнопки «+»/«−» при смене количества.
          Row(
            children: [
              _QuantityStepper(
                value: _quantity,
                onChanged: onQuantityChanged,
                onMarkingCodes: _marking ? onMarkingCodes : null,
              ),
              const SizedBox(width: AppDimens.gap8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${formatMoney(item['totalPrice'])} $currency',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.price.copyWith(fontSize: 16),
                    ),
                    Text(
                      [
                        '${formatMoney(item['salePrice'])} × ${formatMoney(_quantity, decimalDigits: 3)}',
                        if (_discount > 0) '−${formatMoney(_discount, decimalDigits: 0)}%',
                      ].join('  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.tabular(AppText.small),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Порядковый номер позиции.
class _IndexBadge extends StatelessWidget {
  final int index;
  final bool selected;

  const _IndexBadge({required this.index, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.onPrimary : AppColors.primary,
          fontFeatures: AppText.tabularFigures,
        ),
      ),
    );
  }
}

/// Степпер количества. Дробные количества (вес) показываем как есть,
/// шаг всегда единичный; уход в ноль удаляет позицию.
class _QuantityStepper extends StatelessWidget {
  final double value;
  final ValueChanged<num> onChanged;

  /// У маркировочной позиции обе кнопки ведут к кодам: «+» — сканер,
  /// «−» — список, где кассир выбирает, какую именно пачку убрать.
  final ValueChanged<bool>? onMarkingCodes;

  const _QuantityStepper({
    required this.value,
    required this.onChanged,
    this.onMarkingCodes,
  });

  bool get _whole => value == value.roundToDouble();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            onTap: () => onMarkingCodes == null ? onChanged(value - 1) : onMarkingCodes!(false),
          ),
          // Ширина фиксирована: число любой длины не двигает кнопки степпера.
          Container(
            width: 52,
            height: 34,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border.symmetric(vertical: BorderSide(color: AppColors.border)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _whole ? '${value.round()}' : formatMoney(value, decimalDigits: 3),
                style: TextStyle(
                  fontSize: 15,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFeatures: AppText.tabularFigures,
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onTap: () => onMarkingCodes == null ? onChanged(value + 1) : onMarkingCodes!(true),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
