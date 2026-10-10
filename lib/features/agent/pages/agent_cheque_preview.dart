import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Просмотр отправленного агентом чека: позиции, клиент и итог.
///
/// Только чтение — в корзину чек попадает лишь по «Редактировать». Лист
/// возвращает `true`, если агент выбрал правку, и `null`, если просто закрыл.
class AgentChequePreview extends StatelessWidget {
  /// Распакованный JSON чека из строки `cheque-online-list`.
  final Map cheque;

  const AgentChequePreview({super.key, required this.cheque});

  static Future<bool> open(BuildContext context, Map cheque) async {
    final result = await AppModal.sheet<bool>(
      context,
      builder: (_) => AgentChequePreview(cheque: cheque),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final items = cheque['itemsList'] is List ? cheque['itemsList'] as List : const [];
    final currency = '${cheque['currencyName'] ?? "So'm"}';
    final client = '${cheque['clientName'] ?? ''}'.trim();
    final media = MediaQuery.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: (media.size.height - media.viewInsets.bottom) * 0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.tr('cheque'), style: AppText.h2),
          if (client.isNotEmpty) ...[
            const SizedBox(height: AppDimens.gap4),
            Text('${context.tr('client')}: $client', style: AppText.secondary),
          ],
          const SizedBox(height: AppDimens.gap12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, i) {
                final item = items[i] as Map;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.gap8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item['productName'] ?? ''}', style: AppText.bodyMedium),
                            const SizedBox(height: 2),
                            Text(
                              '${formatMoney(item['salePrice'])} × ${formatQuantity(customNumber(item['quantity']))}',
                              style: AppText.small.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimens.gap8),
                      Text(
                        '${formatMoney(item['totalPrice'])} $currency',
                        style: AppText.tabular(AppText.bodyMedium),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(height: AppDimens.gap16, color: AppColors.border),
          Row(
            children: [
              Expanded(child: Text(context.tr('total'), style: AppText.bodyMedium)),
              Text(
                '${formatMoney(cheque['totalPrice'])} $currency',
                style: AppText.tabular(AppText.h2),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap16),
          AppButton(
            label: context.tr('edit'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppDimens.gap8),
          AppButton.secondary(
            label: context.tr('close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
