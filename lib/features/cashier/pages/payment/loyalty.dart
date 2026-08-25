import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/models/cashbox_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/payment/widgets/payment_widgets.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Вкладка «Лояльность»: карта клиента, баллы и плитки способов оплаты.
class Loyalty extends StatelessWidget {
  const Loyalty({super.key});

  /// Лист поиска клиента по QR-коду или телефону.
  Future<void> _openCardSheet(BuildContext context, CashboxModel model) {
    FocusManager.instance.primaryFocus?.unfocus();

    return AppModal.sheet(
      context,
      builder: (ctx) => _LoyaltyCardSheet(model: model),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CashboxModel, PaymentUiState>(
      builder: (context, model, ui, child) {
        final String clientName = '${model.data['loyaltyClientName'] ?? ''}'.trim();
        final bool hasClient = clientName.isNotEmpty;
        final double balance = customNumber(model.data['loyaltyClientBalance']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClientBar(
              label: context.tr('loyalty'),
              title: hasClient ? clientName : context.tr('enter_QR_code_or_phone_number'),
              subtitle: hasClient
                  ? '${formatMoney(balance)} ${context.tr('accumulated_points')}'
                  : null,
              action: hasClient ? context.tr('edit') : context.tr('search'),
              selected: hasClient,
              icon: Icons.qr_code_scanner,
              onTap: () => _openCardSheet(context, model),
            ),
            if (hasClient) ...[
              const SizedBox(height: AppDimens.gap12),
              _BonusCard(model: model),
            ],
            const SizedBox(height: AppDimens.gap12),
            PaymentTypeTiles(model: model, ui: ui),
            if (!hasClient) ...[
              const SizedBox(height: AppDimens.gap12),
              AppBanner(
                title: context.tr('client_not_found'),
                text: context.tr('enter_QR_code_or_phone_number'),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Карточка баллов: накоплено, к списанию, к начислению.
class _BonusCard extends StatelessWidget {
  final CashboxModel model;

  const _BonusCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('accumulated_points'), style: AppText.secondary),
              Text(
                formatMoney(model.data['loyaltyClientBalance']),
                style: AppText.tabular(AppText.secondaryBold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppInput.money(
            label: context.tr('points_to_be_written_off'),
            controller: model.loyaltyPointsController,
            hint: '0',
            height: AppDimens.heightMedium,
            onChanged: model.updateLoyaltyPoints,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              AppButton(
                label: context.tr('max'),
                variant: AppButtonVariant.soft,
                size: AppButtonSize.small,
                expanded: false,
                pill: true,
                onPressed: () {
                  final balance = customNumber(model.data['loyaltyClientBalance']).round().toString();
                  model.loyaltyPointsController.text = balance;
                  model.updateLoyaltyPoints(balance);
                },
              ),
              const SizedBox(width: AppDimens.gap8),
              AppButton(
                label: context.tr('do_not_write_off'),
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                expanded: false,
                pill: true,
                onPressed: () {
                  model.loyaltyPointsController.clear();
                  model.updateLoyaltyPoints('');
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimens.gap8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('points_to_be_awarded'), style: AppText.secondary),
              Text(
                '+${model.loyaltyAwardController.text.isEmpty ? '0' : model.loyaltyAwardController.text}',
                style: AppText.tabular(AppText.secondaryBold).copyWith(color: AppColors.successText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Лист поиска клиента лояльности: код ищется по мере ввода (6 или 12 знаков).
class _LoyaltyCardSheet extends StatelessWidget {
  final CashboxModel model;

  const _LoyaltyCardSheet({required this.model});

  @override
  Widget build(BuildContext context) {
    return Consumer<CashboxModel>(
      builder: (context, model, child) {
        final String clientName = '${model.data['loyaltyClientName'] ?? ''}'.trim();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('loyalty'), style: AppText.h2),
            const SizedBox(height: AppDimens.gap16),
            AppInput(
              label: context.tr('enter_QR_code_or_phone_number'),
              hint: context.tr('enter_QR_code_or_phone_number'),
              controller: model.loyaltyCodeController,
              autofocus: true,
              prefixIcon: Icons.qr_code_scanner,
              onChanged: (value) => model.updateLoyaltyInput(value, 'card'),
            ),
            const SizedBox(height: AppDimens.gap12),
            if (clientName.isEmpty)
              AppBanner(
                title: context.tr('client_not_found'),
                text: context.tr('enter_QR_code_or_phone_number'),
              )
            else
              AppCard(
                selected: true,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: AppDimens.control,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.loyalty_outlined, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppDimens.gap12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientName,
                            style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${formatMoney(model.data['loyaltyClientBalance'])} ${context.tr('accumulated_points')}',
                            style: AppText.tabular(AppText.small),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppDimens.gap16),
            AppButton(
              label: context.tr('choose'),
              onPressed: clientName.isEmpty ? null : () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
