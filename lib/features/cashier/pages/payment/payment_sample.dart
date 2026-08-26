import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mdokon/features/cashier/domain/cheque_format.dart';
import 'package:flutter_mdokon/core/state/loading_model.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/models/cashbox_model.dart';
import 'package:flutter_mdokon/features/cashier/models/printer_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/payment/loyalty.dart';
import 'package:flutter_mdokon/features/cashier/pages/payment/on_credit.dart';
import 'package:flutter_mdokon/features/cashier/pages/payment/payment.dart';
import 'package:flutter_mdokon/features/cashier/pages/payment/widgets/payment_widgets.dart';
import 'package:flutter_mdokon/shared/widgets/loading_layout.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Экран оплаты чека.
///
/// Сверху узкая белая шапка и фиолетовый блок с главной суммой: кассир видит,
/// сколько ещё осталось внести (или какая сдача), не отрываясь от ввода.
/// Способы оплаты — плитками, сумма активного способа набирается в нижней
/// панели своей клавиатурой: системная клавиатура перекрывала итог и кнопку.
class PaymentSample extends StatefulWidget {
  const PaymentSample({super.key});

  @override
  State<PaymentSample> createState() => _PaymentSampleState();
}

class _PaymentSampleState extends State<PaymentSample> {
  final GetStorage storage = GetStorage();
  final PaymentUiState _ui = PaymentUiState();

  @override
  void dispose() {
    _ui.dispose();
    super.dispose();
  }

  /// Вкладка «В долг» доступна только с ролью CASHBOX_DEBT.
  bool _tabAllowed(int index) => index != 1 || checkRole('CASHBOX_DEBT');

  void _setTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    Provider.of<CashboxModel>(context, listen: false).setIndex(index);
    _ui.reset();
  }

  Future<void> _accept(CashboxModel model) async {
    final loadingModel = Provider.of<LoadingModel>(context, listen: false);
    final printerModel = Provider.of<PrinterModel>(context, listen: false);

    FocusManager.instance.primaryFocus?.unfocus();
    loadingModel.showLoader(num: 2);
    final result = await model.createCheque();
    loadingModel.hideLoader();

    if (!customIf(result)) return;
    if (customIf(storage.read('settings')['printAfterSale'])) {
      // Печатаем чек в серверном формате (БРУТТО + скидка отдельной суммой):
      // printFullCheque сам вычитает discountAmount.
      final printable = toGrossCheque(model.data);
      await printerModel.printFullCheque(printable, printable['itemsList']);
    }
    if (mounted) Navigator.pop(context, result);
  }

  // --- Тексты шапки и кнопки ---------------------------------------------

  /// Сколько ещё нужно внести: положительное — недобор, отрицательное — сдача.
  double _rest(CashboxModel model) => -customNumber(model.data['change']);

  String _heroLabel(CashboxModel model) {
    final rest = _rest(model);
    if (rest > 0) {
      return model.currentIndex == 1 ? context.tr('AMOUNT_OF_DEBT') : context.tr('remainder');
    }
    return rest < 0 ? context.tr('change') : context.tr('paid');
  }

  double _heroValue(CashboxModel model) {
    final rest = _rest(model);
    if (rest > 0) return rest;
    return rest < 0 ? -rest : customNumber(model.data['totalPrice']);
  }

  String _acceptLabel(CashboxModel model) {
    final rest = _rest(model);
    final currency = '${model.data['currencyName'] ?? ''}';

    if (model.currentIndex == 1) {
      return '${context.tr('on_credit')} ${formatMoney(rest > 0 ? rest : 0)} $currency';
    }
    if (rest > 0) {
      return '${context.tr('accept')} · ${context.tr('remainder')} ${formatMoney(rest)}';
    }
    if (rest < 0) {
      return '${context.tr('accept')} · ${context.tr('change')} ${formatMoney(-rest)}';
    }
    return '${context.tr('accept')} ${formatMoney(model.data['totalPrice'])} $currency';
  }

  // --- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentUiState>.value(
      value: _ui,
      child: LoadingLayout(
        body: Scaffold(
          backgroundColor: AppColors.canvas,
          resizeToAvoidBottomInset: true,
          body: Consumer<CashboxModel>(
            builder: (context, model, child) {
              final layout = context.layout;
              final online = model.onlinePayment;

              final body = GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    layout.gutter,
                    AppDimens.gap12,
                    layout.gutter,
                    AppDimens.gap16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      switch (model.currentIndex) {
                        1 => const OnCredit(),
                        2 => const Loyalty(),
                        _ => const Payment(),
                      },
                      // Код с телефона покупателя нужен на любой вкладке:
                      // онлайн-способом можно закрыть и долг, и лояльность.
                      if (online != null) OtpCodeField(model: model, selection: online),
                    ],
                  ),
                ),
              );

              Widget amountBar({bool vertical = false}) => Consumer<PaymentUiState>(
                    builder: (context, ui, child) {
                      return PaymentAmountBar(
                        model: model,
                        ui: ui,
                        vertical: vertical,
                        acceptLabel: _acceptLabel(model),
                        // isSubmitDisabled — исторически «можно принимать»:
                        // null здесь блокирует кнопку.
                        onAccept: model.isSubmitDisabled ? () => _accept(model) : null,
                      );
                    },
                  );

              return _window(
                context,
                Column(
                  children: [
                    _header(model),
                    _hero(model),
                    Expanded(
                      // На широком экране способы оплаты и клавиатура стоят
                      // рядом: в столбик они не помещаются по высоте.
                      child: layout.hasSideRail
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: body),
                                SizedBox(width: layout.paymentPadWidth, child: amountBar(vertical: true)),
                              ],
                            )
                          : body,
                    ),
                    if (!layout.hasSideRail) amountBar(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Оплата на планшете — окно по центру, а не экран во всю ширину: чек
  /// остаётся виден по краям, и кассир не теряет контекст.
  Widget _window(BuildContext context, Widget content) {
    final layout = context.layout;
    if (!layout.isTablet) return content;

    // Свободная высота экрана: окно не должно залезать ни под статус-бар,
    // ни под клавиатуру, даже если по дизайну оно выше.
    final media = MediaQuery.of(context);
    final free = media.size.height - media.padding.vertical - media.viewInsets.bottom - layout.gutter * 2;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(layout.gutter),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: layout.paymentWindowWidth,
              maxHeight: math.min(layout.paymentWindowHeight, free),
            ),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.all(Radius.circular(layout.radiusPanel)),
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              // Внутри окна системные отступы уже не нужны: шапка не подпирает
              // статус-бар, а нижняя панель — жест-бар.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeBottom: true,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Узкая белая шапка: назад, заголовок и количество позиций в чеке.
  Widget _header(CashboxModel model) {
    final int lineCount = (model.data['itemsList'] as List?)?.length ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, AppDimens.gutter, AppDimens.gap8),
            child: Row(
              children: [
                AppIconButton(
                  icon: Icons.arrow_back,
                  background: AppColors.canvas,
                  foreground: AppColors.textPrimary,
                  size: 36,
                  iconSize: 19,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('payment'),
                    style: AppText.h1.copyWith(fontSize: 17),
                  ),
                ),
                if (lineCount > 0)
                  Text(
                    '$lineCount ${context.tr('pieces_short')}',
                    style: AppText.tabular(AppText.small),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Фиолетовый блок с главной суммой и переключателем вкладок.
  Widget _hero(CashboxModel model) {
    final double total = customNumber(model.data['totalPrice']);
    final double paid = customNumber(model.data['paid']);
    final double rest = _rest(model);
    final bool done = rest <= 0;
    final String currency = '${model.data['currencyName'] ?? ''}';

    return PaymentHero(
      label: _heroLabel(model),
      value: _heroValue(model),
      currency: currency,
      subtitle: '${context.tr('total')} ${formatMoney(total)} · ${context.tr('entered')} ${formatMoney(paid)}',
      badge: done ? '✓' : '${((paid / (total <= 0 ? 1 : total)) * 100).round()}%',
      done: done,
      tabs: Row(
        children: [
          for (var i = 0; i < 3; i++)
            if (_tabAllowed(i)) ...[
              if (i != 0) const SizedBox(width: 6),
              Expanded(
                child: PaymentHeroTab(
                  label: switch (i) {
                    0 => context.tr('payment'),
                    1 => context.tr('on_credit'),
                    _ => context.tr('loyalty'),
                  },
                  selected: model.currentIndex == i,
                  onTap: () => _setTab(i),
                ),
              ),
            ],
        ],
      ),
    );
  }
}
