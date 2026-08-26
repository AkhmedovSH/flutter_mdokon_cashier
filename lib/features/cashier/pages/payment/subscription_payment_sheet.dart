import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/data/subscription_payment_repository.dart';
import 'package:flutter_mdokon/features/cashier/domain/subscription_payment.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Оплата абонентской платы картой (Multicard / Rahmat).
///
/// Платит не касса: страница банка с 3-D Secure открывается во внешнем браузере.
/// Касса создаёт счёт и опрашивает его статус — баланс точки пополняет callback
/// Multicard на сервере, поэтому «оплачено» мы узнаём только от него.
///
/// Шаги: выбор точки и суммы → ожидание оплаты → оплачено / не прошло.
class SubscriptionPaymentSheet extends StatefulWidget {
  const SubscriptionPaymentSheet({super.key, this.repository = const SubscriptionPaymentRepository()});

  final SubscriptionPaymentRepository repository;

  /// Открыть лист. `true` — абонплата прошла (вызывающему стоит обновить баланс).
  static Future<bool> open(BuildContext context) async {
    final paid = await AppModal.sheet<bool>(
      context,
      builder: (_) => const SubscriptionPaymentSheet(),
    );
    return paid == true;
  }

  @override
  State<SubscriptionPaymentSheet> createState() => _SubscriptionPaymentSheetState();
}

enum _Step { select, waiting, paid, failed }

class _SubscriptionPaymentSheetState extends State<SubscriptionPaymentSheet> {
  final TextEditingController _amount = TextEditingController();

  _Step _step = _Step.select;
  bool _loading = true;
  bool _busy = false;
  List<SubscriptionPoint> _points = const [];
  int? _posId;
  SubscriptionInvoice? _invoice;
  String? _error;

  Timer? _poll;
  DateTime? _pollStartedAt;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _amount.dispose();
    super.dispose();
  }

  /// Список точек грузим при каждом открытии: баланс мог измениться.
  Future<void> _loadPoints() async {
    final points = await widget.repository.points();
    if (!mounted) return;

    setState(() {
      _points = points;
      _loading = false;
      // Одна точка — выбирать не из чего.
      if (points.length == 1) _select(points.first, notify: false);
    });
  }

  void _select(SubscriptionPoint point, {bool notify = true}) {
    _posId = point.posId;
    _amount.text = point.defaultAmount > 0 ? '${point.defaultAmount}' : '';
    _error = null;
    if (notify) setState(() {});
  }

  int get _amountValue => int.tryParse(_amount.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  Future<void> _createInvoice() async {
    final formError = subscriptionFormError(posId: _posId, amount: _amountValue);
    if (formError != null) {
      setState(() => _error = context.tr(formError));
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final invoice = await widget.repository.createInvoice(posId: _posId!, amount: _amountValue);
    if (!mounted) return;

    if (!invoice.usable) {
      setState(() {
        _busy = false;
        _error = invoice.message ?? context.tr('subscription_pay_error');
      });
      return;
    }

    setState(() {
      _busy = false;
      _invoice = invoice;
      _step = _Step.waiting;
      _pollStartedAt = DateTime.now();
    });
    await _openLink();
    _startPolling();
  }

  Future<void> _openLink() async {
    final link = _invoice?.shortLink;
    if (link == null) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      showDangerToast(context.tr('error'));
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(subscriptionPollInterval, (timer) {
      final started = _pollStartedAt;
      if (started != null && DateTime.now().difference(started) > subscriptionPollLimit) {
        timer.cancel();
        return;
      }
      _checkStatus();
    });
  }

  /// `manual` — кассир нажал «Проверить»: только тогда молчаливое «ещё платят»
  /// стоит показать текстом.
  Future<void> _checkStatus({bool manual = false}) async {
    final invoiceId = _invoice?.invoiceId;
    if (invoiceId == null) return;

    if (manual) setState(() => _busy = true);
    final status = await widget.repository.status(invoiceId);
    if (!mounted) return;
    if (manual) setState(() => _busy = false);
    if (status == null) return;

    switch (status) {
      case InvoiceStatus.paid:
        _poll?.cancel();
        setState(() => _step = _Step.paid);
      case InvoiceStatus.canceled:
      case InvoiceStatus.failed:
        _poll?.cancel();
        setState(() {
          _step = _Step.failed;
          _error = context.tr(invoiceStatusMessageKey(status)!);
        });
      case InvoiceStatus.pending:
        if (manual) setState(() => _error = context.tr('subscription_pay_still_pending'));
    }
  }

  void _backToSelect() {
    _poll?.cancel();
    setState(() {
      _invoice = null;
      _error = null;
      _step = _Step.select;
    });
  }

  // --- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.tr('subscription_pay_title'), style: AppText.h1.copyWith(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(context.tr('subscription_pay_subtitle'), style: AppText.small),
                ],
              ),
            ),
            AppIconButton(
              icon: Icons.close,
              background: AppColors.canvas,
              foreground: AppColors.textPrimary,
              size: 36,
              iconSize: 19,
              onPressed: () => Navigator.pop(context, _step == _Step.paid),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.gap16),
        switch (_step) {
          _Step.select => _selectStep(),
          _Step.waiting => _waitingStep(),
          _Step.paid => _resultStep(paid: true),
          _Step.failed => _resultStep(paid: false),
        },
      ],
    );
  }

  Widget _selectStep() {
    if (_loading) return const Padding(padding: EdgeInsets.all(AppDimens.gap24), child: AppLoader());
    if (_points.isEmpty) {
      return AppEmptyState(
        icon: Icons.credit_card_outlined,
        title: context.tr('subscription_pay_no_points'),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_points.length > 1) ...[
          AppSectionLabel(context.tr('pos')),
          const SizedBox(height: AppDimens.gap8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _points.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppDimens.gap8),
              itemBuilder: (context, index) => _pointTile(_points[index]),
            ),
          ),
          const SizedBox(height: AppDimens.gap16),
        ] else
          _pointTile(_points.first),
        const SizedBox(height: AppDimens.gap12),
        AppInput.money(
          label: context.tr('amount'),
          controller: _amount,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppDimens.gap12),
          AppBanner.danger(title: context.tr('error'), text: _error!),
        ],
        const SizedBox(height: AppDimens.gap16),
        AppButton(
          label: context.tr('subscription_pay_open'),
          loading: _busy,
          onPressed: _busy ? null : _createInvoice,
        ),
      ],
    );
  }

  Widget _pointTile(SubscriptionPoint point) {
    final selected = point.posId == _posId;
    final debt = point.balance < 0;

    return Material(
      color: selected ? AppColors.primarySoft : AppColors.canvas,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _select(point),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12, vertical: AppDimens.gap12),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(point.name, style: AppText.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${context.tr('balance')}: ${formatMoney(point.balance)}',
                      style: AppText.small.copyWith(
                        color: debt ? AppColors.danger : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _waitingStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBanner(
          title: context.tr('subscription_pay_waiting'),
          text: context.tr('subscription_pay_waiting_hint'),
        ),
        const SizedBox(height: AppDimens.gap12),
        Text(
          '${context.tr('amount')}: ${formatMoney(_invoice?.amount ?? 0)}',
          style: AppText.price,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppDimens.gap12),
          AppBanner(title: context.tr('attention'), text: _error!),
        ],
        const SizedBox(height: AppDimens.gap16),
        AppButton(
          label: context.tr('subscription_pay_open_again'),
          variant: AppButtonVariant.secondary,
          onPressed: _openLink,
        ),
        const SizedBox(height: AppDimens.gap8),
        AppButton(
          label: context.tr('subscription_pay_check'),
          loading: _busy,
          onPressed: _busy ? null : () => _checkStatus(manual: true),
        ),
      ],
    );
  }

  Widget _resultStep({required bool paid}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (paid)
          AppBanner.success(
            title: context.tr('subscription_pay_paid'),
            text: '${context.tr('amount')}: ${formatMoney(_invoice?.amount ?? 0)}',
          )
        else
          AppBanner.danger(
            title: context.tr('subscription_pay_error'),
            text: _error ?? context.tr('subscription_pay_failed'),
          ),
        const SizedBox(height: AppDimens.gap16),
        if (!paid) ...[
          AppButton(
            label: context.tr('back'),
            variant: AppButtonVariant.secondary,
            onPressed: _backToSelect,
          ),
          const SizedBox(height: AppDimens.gap8),
        ],
        AppButton(
          label: context.tr('close'),
          onPressed: () => Navigator.pop(context, paid),
        ),
      ],
    );
  }
}
