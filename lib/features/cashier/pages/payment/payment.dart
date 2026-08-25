import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/models/cashbox_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/payment/widgets/payment_widgets.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Вкладка «Оплата»: плитки способов оплаты, суммы вводятся в нижней панели.
class Payment extends StatelessWidget {
  const Payment({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CashboxModel, PaymentUiState>(
      builder: (context, model, ui, child) {
        final double change = customNumber(model.data['change']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaymentTypeTiles(model: model, ui: ui),
            if (change > 0) ...[
              const SizedBox(height: AppDimens.gap12),
              AppBanner.success(
                title: context.tr('change'),
                text: '${formatMoney(change)} ${model.data['currencyName'] ?? ''}',
              ),
            ],
          ],
        );
      },
    );
  }
}
