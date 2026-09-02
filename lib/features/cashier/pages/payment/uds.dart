import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/domain/uds.dart';
import 'package:flutter_mdokon/features/cashier/models/cashbox_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/payment/widgets/payment_widgets.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Вкладка «UDS» — вторая программа лояльности, параллельная uGet.
///
/// Порядок работы: корзина собрана → клиент показывает QR-промокод (или
/// называет телефон) → расчёт отдаёт скидку, баллы и сумму к оплате деньгами →
/// кассир разносит эту сумму по способам оплаты → чек уходит на сервер, и он
/// сам проводит операцию в UDS.
///
/// Суммы здесь не считаются: всё берётся из ответа `uds-calc`, иначе сервер
/// отобьёт чек как `error.uds.invalid_checksum`.
class Uds extends StatelessWidget {
  const Uds({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CashboxModel, PaymentUiState>(
      builder: (context, model, ui, child) {
        final uds = model.uds;
        final calc = uds.calc;
        final stale = model.udsStale;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeSwitch(model: model),
            const SizedBox(height: AppDimens.gap12),
            _SearchField(model: model),
            if (uds.found) ...[
              const SizedBox(height: AppDimens.gap12),
              _ClientCard(model: model),
            ],
            if (uds.found && uds.mode == UdsMode.phone) ...[
              const SizedBox(height: AppDimens.gap12),
              AppBanner(title: context.tr('uds_points_qr_only')),
            ],
            if (uds.found && uds.mode == UdsMode.code && calc.maxPoints <= 0) ...[
              const SizedBox(height: AppDimens.gap12),
              AppBanner(title: context.tr('uds_no_points_available')),
            ],
            if (uds.skipLoyaltyTotal > 0) ...[
              const SizedBox(height: AppDimens.gap12),
              AppBanner(
                title: context.tr('uds_skip_loyalty_total'),
                text: formatMoney(uds.skipLoyaltyTotal),
              ),
            ],
            if (uds.calculated) ...[
              const SizedBox(height: AppDimens.gap12),
              _Summary(model: model),
            ],
            if (stale) ...[
              const SizedBox(height: AppDimens.gap12),
              AppBanner.danger(title: context.tr('uds_recalculate_needed')),
            ],
            const SizedBox(height: AppDimens.gap12),
            // Способы оплаты открыты только после расчёта: до него неизвестно,
            // сколько вообще надо внести деньгами.
            if (uds.calculated && !stale)
              PaymentTypeTiles(model: model, ui: ui)
            else
              AppBanner(
                title: context.tr('client_not_found'),
                text: context.tr('scan_or_enter_qr_code'),
              ),
          ],
        );
      },
    );
  }
}

/// «По QR» / «Телефон». Переключение сбрасывает расчёт: идентификатор другой.
class _ModeSwitch extends StatelessWidget {
  final CashboxModel model;

  const _ModeSwitch({required this.model});

  @override
  Widget build(BuildContext context) {
    Widget button(UdsMode mode, String label) => Expanded(
          child: AppButton(
            label: label,
            variant: model.uds.mode == mode ? AppButtonVariant.primary : AppButtonVariant.secondary,
            size: AppButtonSize.small,
            pill: true,
            onPressed: () => model.setUdsMode(mode),
          ),
        );

    return Row(
      children: [
        button(UdsMode.code, context.tr('uds_by_qr')),
        const SizedBox(width: AppDimens.gap8),
        button(UdsMode.phone, context.tr('phone')),
      ],
    );
  }
}

/// Поле кода или телефона. Ищем по кнопке и по Enter, а не по каждому символу:
/// сканер отдаёт код посимвольно, а промокод одноразовый.
class _SearchField extends StatelessWidget {
  final CashboxModel model;

  const _SearchField({required this.model});

  @override
  Widget build(BuildContext context) {
    final bool byCode = model.uds.mode == UdsMode.code;
    final String label = byCode ? context.tr('scan_or_enter_qr_code') : context.tr('phone');

    return AppInput(
      label: label,
      hint: label,
      controller: model.udsSearchController,
      autofocus: true,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.search,
      prefixIcon: byCode ? Icons.qr_code_scanner : Icons.phone_outlined,
      onChanged: model.udsSearchChanged,
      onSubmitted: (_) => model.udsSearch(),
      suffix: AppIconButton(
        icon: Icons.search,
        size: 32,
        iconSize: 18,
        background: AppColors.primarySoft,
        foreground: AppColors.primary,
        onPressed: model.udsCalculating ? null : () => model.udsSearch(),
      ),
    );
  }
}

/// Карточка клиента: имя, уровень, баллы и поле списания.
class _ClientCard extends StatelessWidget {
  final CashboxModel model;

  const _ClientCard({required this.model});

  @override
  Widget build(BuildContext context) {
    final calc = model.uds.calc;
    final bool disabled = model.uds.pointsDisabled;

    return AppCard(
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppDimens.control,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.person_outline, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppDimens.gap12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      calc.displayName.isEmpty ? context.tr('client') : calc.displayName,
                      style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (calc.tier.isNotEmpty) Text(calc.tier, style: AppText.small),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap12),
          _Row(
            label: context.tr('accumulated_points'),
            value: formatMoney(calc.balance),
          ),
          const SizedBox(height: AppDimens.gap8),
          _Row(
            label: context.tr('uds_max_points'),
            value: formatMoney(calc.maxPoints),
          ),
          const SizedBox(height: AppDimens.gap12),
          AppInput.money(
            label: context.tr('points_to_be_written_off'),
            controller: model.udsPointsController,
            hint: '0',
            enabled: !disabled,
            height: AppDimens.heightMedium,
            onChanged: model.udsPointsChanged,
          ),
          if (!disabled) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                AppButton(
                  label: context.tr('max'),
                  variant: AppButtonVariant.soft,
                  size: AppButtonSize.small,
                  expanded: false,
                  pill: true,
                  onPressed: model.udsMaxPoints,
                ),
                const SizedBox(width: AppDimens.gap8),
                AppButton(
                  label: context.tr('do_not_write_off'),
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.small,
                  expanded: false,
                  pill: true,
                  onPressed: () {
                    model.udsPointsController.clear();
                    model.udsPointsChanged('');
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Итог расчёта: что UDS скинул, списал и начислит, и сколько платить деньгами.
class _Summary extends StatelessWidget {
  final CashboxModel model;

  const _Summary({required this.model});

  @override
  Widget build(BuildContext context) {
    final calc = model.uds.calc;

    return AppCard(
      child: Column(
        children: [
          _Row(label: '${context.tr('discount')} UDS', value: formatMoney(calc.discountAmount)),
          const SizedBox(height: AppDimens.gap8),
          _Row(
            label: context.tr('points_to_be_written_off'),
            value: formatMoney(calc.points),
          ),
          const SizedBox(height: AppDimens.gap8),
          _Row(
            label: context.tr('points_to_be_awarded'),
            value: '+${formatMoney(calc.cashBack)}',
            valueColor: AppColors.successText,
          ),
          const SizedBox(height: AppDimens.gap8),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimens.gap8),
          _Row(
            label: context.tr('uds_cash_to_pay'),
            value: formatMoney(calc.cash),
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;

  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppText.tabular(strong ? AppText.bodyMedium : AppText.secondaryBold);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.secondary),
        Text(
          value,
          style: strong
              ? style.copyWith(fontWeight: FontWeight.w700, color: valueColor)
              : style.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
