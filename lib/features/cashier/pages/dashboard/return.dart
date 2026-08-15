import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/models/dashboard_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/cheques/cheque_preview_sheet.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Возврат — вкладка нижней навигации.
///
/// Экран двухшаговый. Сначала кассир выбирает чек: вводит номер или берёт его
/// из списка последних продаж смены. Затем в одном списке проставляет
/// количество к возврату по каждой позиции — вместо двух таблиц «чек» и
/// «возврат», которые на телефоне не помещаются рядом. Итог и кнопка закреплены
/// снизу: сумма к выплате видна, до какой бы позиции ни доскроллили.
class Return extends StatefulWidget {
  const Return({super.key});

  @override
  State<Return> createState() => _ReturnState();
}

class _ReturnState extends State<Return> {
  /// Сколько дней продаж показываем в списке для выбора чека.
  static const int recentPeriodDays = 10;

  final GetStorage storage = GetStorage();
  final TextEditingController searchController = TextEditingController();

  Map cashbox = {};
  Map shift = {};

  /// Открытый чек и его позиции.
  Map cheque = {};
  List items = [];

  /// Количество к возврату по индексу позиции чека.
  /// Позиции, которых здесь нет, в возврат не попадут.
  final Map<int, double> retQty = {};

  /// Последние чеки смены — список для выбора, когда номер вводить не хочется.
  List recent = [];

  bool loading = false;
  bool loadingRecent = false;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    final storedCashbox = storage.read('cashbox');
    cashbox = storedCashbox is Map ? storedCashbox : {};
    final storedShift = storage.read('shift');
    shift = storedShift is Map ? storedShift : {};

    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Чек мог прийти из списка чеков — тогда сразу открываем его и забываем,
  /// чтобы при следующем заходе на вкладку он не подставлялся повторно.
  void _start() {
    if (!mounted) return;

    final dashboard = Provider.of<DashboardModel>(context, listen: false);
    final incoming = dashboard.returnCheque;
    final number = '${incoming['chequeNumber'] ?? ''}'.trim();

    if (number.isNotEmpty) {
      dashboard.setCurrentCheque({});
      _loadCheque(number);
      return;
    }
    _loadRecent();
  }

  // --- Данные ------------------------------------------------------------

  Future<void> _loadCheque(String number) async {
    final query = number.trim();
    if (query.isEmpty || loading) return;

    setState(() => loading = true);
    final response = await get('/services/desktop/api/cheque-byNumber/$query/${cashbox['posId']}');
    if (!mounted) return;

    final found = httpOk(response) && response is Map && response['id'] != null;
    setState(() {
      loading = false;
      if (found) {
        cheque = response;
        items = response['itemsList'] ?? [];
        retQty.clear();
        searchController.clear();
      }
    });

    if (!found) showDangerToast(context.tr('cheque_not_found'));
  }

  Future<void> _loadRecent() async {
    if (loadingRecent) return;

    setState(() => loadingRecent = true);
    final now = DateTime.now();
    final response = await get(
      '/services/desktop/api/cashier-cheque-pageList',
      payload: {
        'posId': cashbox['posId'],
        'startDate': DateTime(now.year, now.month, now.day).subtract(const Duration(days: recentPeriodDays)).toUtc().millisecondsSinceEpoch,
        'endDate': DateTime(now.year, now.month, now.day, 23, 59).toUtc().millisecondsSinceEpoch,
        'fromPaid': '',
        'toPaid': '',
        'outType': false,
        'search': '',
        'size': 50,
      },
    );
    if (!mounted) return;

    setState(() {
      loadingRecent = false;
      // Полностью возвращённый чек второй раз вернуть нельзя — не предлагаем.
      recent = httpOk(response) && response is List ? response.where((item) => customNumber(item['returned']).round() != 2).toList() : [];
    });
  }

  void _reset() {
    setState(() {
      cheque = {};
      items = [];
      retQty.clear();
    });
    _loadRecent();
  }

  // --- Расчёты -----------------------------------------------------------

  bool get _hasCheque => cheque.isNotEmpty;

  String get _number => '${cheque['chequeNumber'] ?? cheque['id'] ?? ''}';

  String get _currency => customNumber(cheque['saleCurrencyId']) == 2 ? 'USD' : context.tr('sum');

  /// Цена единицы с учётом скидки: v2 отдаёт скидку суммой на единицу,
  /// v1 — процентом на позицию. Поддерживаем оба формата.
  double _unitPrice(dynamic item) {
    final price = customNumber(item['salePrice']);
    final discountOne = customNumber(item['discountOne']);
    if (discountOne > 0) return price - discountOne;

    final percent = customNumber(item['discount']);
    if (percent > 0) return price - price * percent / 100;
    return price;
  }

  /// Сколько ещё можно вернуть по позиции: продано минус уже возвращённое.
  double _available(dynamic item) {
    if (customNumber(item['returned']).round() == 2) return 0;
    final quantity = customNumber(item['quantity']);
    final returned = customNumber(item['returnedQuantity']);
    return (quantity - returned) > 0 ? quantity - returned : 0;
  }

  double get _refundAmount {
    double total = 0;
    retQty.forEach((index, quantity) {
      if (index < items.length) total += _unitPrice(items[index]) * quantity;
    });
    return total;
  }

  double get _refundCount => retQty.values.fold(0, (sum, quantity) => sum + quantity);

  /// Есть ли вообще что возвращать — если нет, экран не предлагает действий.
  bool get _hasReturnable => items.any((item) => _available(item) > 0);

  void _setQty(int index, double quantity) {
    final available = _available(items[index]);
    final next = quantity.clamp(0, available).toDouble();

    setState(() {
      if (next <= 0) {
        retQty.remove(index);
      } else {
        retQty[index] = next;
      }
    });
  }

  void _returnAll() {
    setState(() {
      retQty.clear();
      for (var i = 0; i < items.length; i++) {
        final available = _available(items[i]);
        if (available > 0) retQty[i] = available;
      }
    });
  }

  // --- Оформление возврата -----------------------------------------------

  Future<void> _submit() async {
    if (sending) return;
    if (_refundAmount <= 0) {
      showDangerToast(context.tr('check_quantity'));
      return;
    }

    final confirmed = await AppModal.confirm(
      context,
      title: '${context.tr('return')} · ${context.tr('cheque')} №$_number',
      text: context.tr('return_confirm_text', args: ['${formatMoney(_refundAmount)} $_currency']),
      note: context.tr('return_confirm_note'),
      confirmLabel: context.tr('make_return'),
      cancelLabel: context.tr('cancel'),
      tone: AppModalTone.danger,
    );
    if (!confirmed || !mounted) return;

    setState(() => sending = true);
    final response = await post('/services/desktop/api/cheque-returned', _payload());
    if (!mounted) return;

    setState(() => sending = false);

    // Сетевую ошибку `post` уже показал тостом и вернул false.
    final ok = httpOk(response) && (response is! Map || response['success'] != false);
    if (!ok) return;

    showSuccessToast(context.tr('return_completed_successfully'));
    _reset();
  }

  /// Штучное количество отправляем целым числом — таким его ждёт бэкенд
  /// для товара с uomId = 1; дробный вес уходит как есть.
  num _whole(double value) => value == value.roundToDouble() ? value.round() : value;

  /// Тело запроса возврата. Состав полей — как у десктопной кассы:
  /// позиции с урезанным количеством и одна расходная транзакция наличными.
  Map<String, dynamic> _payload() {
    final lines = <Map<String, dynamic>>[];

    retQty.forEach((index, quantity) {
      if (index >= items.length) return;

      final source = items[index];
      final line = Map<String, dynamic>.from(source as Map);
      line['initialQuantity'] = source['quantity'];
      line['oldQuantity'] = _whole(_available(source));
      line['quantity'] = _whole(quantity);
      line['totalPrice'] = _unitPrice(source) * quantity;
      lines.add(line);
    });

    final total = _refundAmount;

    return {
      'actionDate': getUnixTime(),
      'cashboxId': cashbox['cashboxId'],
      'posId': cashbox['posId'],
      'shiftId': cashbox['id'] ?? shift['id'],
      'chequeId': cheque['id'],
      'chequeNumber': cheque['chequeNumber'],
      'clientId': cheque['clientId'],
      'clientAmount': cheque['clientAmount'],
      'currencyId': cheque['currencyId'],
      'saleCurrencyId': cheque['saleCurrencyId'],
      'note': '',
      'offline': false,
      'itemsList': lines,
      'totalAmount': total,
      'transactionId': generateTransactionId(
        cashbox['posId'],
        cashbox['cashboxId'],
        cashbox['id'] ?? shift['id'],
      ),
      'transactionsList': [
        {'amountIn': 0, 'amountOut': total, 'paymentTypeId': 1, 'paymentPurposeId': 3},
      ],
    };
  }

  /// Ввод точного количества — для весового товара, где шага в единицу мало.
  Future<void> _editQuantity(int index) async {
    final item = items[index];
    final available = _available(item);
    if (available <= 0) return;

    final result = await AppModal.sheet<double>(
      context,
      builder: (ctx) => _QuantitySheet(
        title: '${item['productName'] ?? ''}',
        available: available,
        value: retQty[index] ?? 0,
        wholeOnly: customNumber(item['uomId']).round() == 1,
      ),
    );
    if (result == null || !mounted) return;
    _setQty(index, result);
  }

  // --- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          _header(),
          Expanded(child: _content()),
        ],
      ),
      bottomNavigationBar: _hasCheque && _hasReturnable ? _bottomBar() : null,
    );
  }

  /// Шапка на белой подложке: пока чек не выбран — заголовок и поиск по номеру,
  /// после выбора — стрелка назад к списку и реквизиты открытого чека.
  Widget _header() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: _hasCheque ? _chequeHeader() : _searchHeader(),
        ),
      ),
    );
  }

  Widget _searchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gap12,
        AppDimens.gutter,
        AppDimens.gap12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('return'),
            style: AppText.h1.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDimens.gap12),
          Row(
            children: [
              Expanded(
                child: AppInput(
                  controller: searchController,
                  hint: context.tr('check_number'),
                  height: AppDimens.heightMedium,
                  prefixIcon: Icons.search,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _loadCheque,
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
              AppIconButton(
                icon: Icons.arrow_forward,
                background: AppColors.primarySoft,
                foreground: AppColors.primary,
                size: AppDimens.heightMedium,
                iconSize: 22,
                onPressed: () => _loadCheque(searchController.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chequeHeader() {
    final meta = [
      if (cheque['chequeDate'] != null) formatUnixTime(cheque['chequeDate']),
      '${cheque['cashierName'] ?? ''}'.trim(),
    ].where((element) => element.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gap8,
        AppDimens.gap8,
        AppDimens.gutter,
        AppDimens.gap12,
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.arrow_back,
            background: Colors.transparent,
            foreground: AppColors.textPrimary,
            onPressed: _reset,
          ),
          const SizedBox(width: AppDimens.gap4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${context.tr('return')} · ${context.tr('cheque')} №$_number',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tabular(AppText.h1).copyWith(fontWeight: FontWeight.w700),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.tabular(AppText.small),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    if (loading) return const Center(child: AppLoader());
    return _hasCheque ? _chequeContent() : _pickContent();
  }

  /// Шаг 1 — выбор чека.
  Widget _pickContent() {
    if (loadingRecent) return const Center(child: AppLoader());

    if (recent.isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long,
        title: context.tr('EMPTY_LIST'),
        text: context.tr('return_find_cheque_hint'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecent,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          AppDimens.gap12,
          AppDimens.gutter,
          AppDimens.gap24,
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: recent.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: AppDimens.gap8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.gap4),
              child: Text(
                context.tr('return_select_cheque_hint'),
                style: AppText.secondary,
              ),
            );
          }

          final item = recent[index - 1];
          return _RecentChequeTile(
            cheque: item,
            onTap: () => _loadCheque('${item['chequeNumber'] ?? item['id'] ?? ''}'),
          );
        },
      ),
    );
  }

  /// Шаг 2 — количество к возврату по позициям и итог.
  Widget _chequeContent() {
    if (items.isEmpty) {
      return AppEmptyState(
        icon: Icons.remove_shopping_cart_outlined,
        title: context.tr('cheque_is_empty'),
        text: context.tr('return_find_cheque_hint'),
      );
    }

    if (!_hasReturnable) {
      return AppEmptyState(
        icon: Icons.assignment_turned_in_outlined,
        title: context.tr('item_returned'),
        text: context.tr('return_nothing_left_hint'),
        action: AppButton.soft(
          label: context.tr('return_select_other_cheque'),
          onPressed: _reset,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gap12,
        AppDimens.gutter,
        AppDimens.gap24,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text(context.tr('return_qty_hint'), style: AppText.secondary),
        const SizedBox(height: AppDimens.gap12),
        AppSectionLabel(
          '${context.tr('products')} · ${items.length} ${context.tr('positions_short')}',
          trailing: retQty.isEmpty
              ? AppButton.soft(label: context.tr('return_all_items'), onPressed: _returnAll)
              : AppButton.soft(
                  label: context.tr('reset'),
                  onPressed: () => setState(retQty.clear),
                ),
        ),
        const SizedBox(height: AppDimens.gap8),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppDimens.gap8),
          _ReturnLine(
            item: items[i],
            unitPrice: _unitPrice(items[i]),
            available: _available(items[i]),
            quantity: retQty[i] ?? 0,
            currency: _currency,
            onChanged: (value) => _setQty(i, value),
            onEdit: () => _editQuantity(i),
          ),
        ],
        const SizedBox(height: AppDimens.gap16),
        _summary(),
      ],
    );
  }

  /// Итог возврата: сколько единиц уходит обратно и сколько денег из кассы.
  Widget _summary() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap16, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(context.tr('return_positions'), style: AppText.secondary)),
              const SizedBox(width: AppDimens.gap8),
              Text(formatQuantity(_refundCount), style: AppText.tabular(AppText.bodyMedium)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimens.gap8),
            child: Divider(height: 1, thickness: 1, color: AppColors.divider),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppSectionLabel(
                  context.tr('TO_RETURN'),
                  color: AppColors.dangerText,
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
              Flexible(
                child: Text(
                  '${formatMoney(_refundAmount)} $_currency',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.amount.copyWith(color: AppColors.dangerText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.gutter,
            AppDimens.gap12,
            AppDimens.gutter,
            AppDimens.gap12,
          ),
          child: AppButton(
            label: context.tr('make_return'),
            variant: AppButtonVariant.dangerSolid,
            loading: sending,
            onPressed: _refundAmount > 0 ? _submit : null,
          ),
        ),
      ),
    );
  }
}

/// Чек в списке выбора: номер и сумма сверху, время с кассиром и статус — снизу.
class _RecentChequeTile extends StatelessWidget {
  final Map cheque;
  final VoidCallback onTap;

  const _RecentChequeTile({required this.cheque, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = customNumber(cheque['totalPrice']) - customNumber(cheque['discountAmount']);
    final currency = customNumber(cheque['saleCurrencyId']) == 2 ? 'USD' : context.tr('sum');
    final (background, foreground, status) = chequeStatusStyle(context, cheque);

    final meta = [
      if (cheque['chequeDate'] != null) DateFormat('dd.MM HH:mm').format(DateTime.fromMillisecondsSinceEpoch(cheque['chequeDate'])),
      '${cheque['cashierName'] ?? ''}'.trim(),
    ].where((element) => element.isNotEmpty).join(' · ');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppDimens.gap12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${context.tr('cheque')} №${cheque['chequeNumber'] ?? cheque['id'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tabular(AppText.bodyMedium).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
              Text('${formatMoney(total)} $currency', style: AppText.price),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tabular(AppText.small),
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: background, borderRadius: AppDimens.pill),
                child: Text(
                  status,
                  maxLines: 1,
                  style: AppText.small.copyWith(color: foreground, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Позиция чека со степпером количества к возврату.
///
/// Пока количество нулевое, строка выглядит обычной карточкой; как только
/// кассир что-то вернул — подсвечивается красным, и по списку сразу видно,
/// что уходит в возврат. Полностью возвращённая позиция степпер не показывает.
class _ReturnLine extends StatelessWidget {
  final Map item;
  final double unitPrice;
  final double available;
  final double quantity;
  final String currency;
  final ValueChanged<double> onChanged;
  final VoidCallback onEdit;

  const _ReturnLine({
    required this.item,
    required this.unitPrice,
    required this.available,
    required this.quantity,
    required this.currency,
    required this.onChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final active = quantity > 0;
    final returned = available <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppDimens.gap12),
      decoration: BoxDecoration(
        color: active ? AppColors.dangerSoft : AppColors.surface,
        borderRadius: AppDimens.card,
        border: Border.all(
          color: active ? AppColors.danger.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item['productName'] ?? ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMedium.copyWith(
                    color: returned ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: returned ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  returned
                      ? '${formatMoney(unitPrice)} $currency'
                      : '${formatMoney(unitPrice)} × ${formatQuantity(available)} ${context.tr('available')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tabular(AppText.small),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.gap12),
          if (returned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: AppDimens.pill,
              ),
              child: Text(
                context.tr('returned'),
                style: AppText.small.copyWith(
                  color: AppColors.dangerText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            _QtyStepper(
              value: quantity,
              max: available,
              onChanged: onChanged,
              onTapValue: onEdit,
            ),
        ],
      ),
    );
  }
}

/// Степпер количества, понимающий дробные остатки весового товара:
/// шаг — единица, но «+» на последнем шаге добирает ровно остаток (2 → 2,5).
/// Тап по числу открывает ввод точного количества.
class _QtyStepper extends StatelessWidget {
  final double value;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback onTapValue;

  const _QtyStepper({
    required this.value,
    required this.max,
    required this.onChanged,
    required this.onTapValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimens.tapTarget,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.control,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            enabled: value > 0,
            onTap: () => onChanged(value - 1 > 0 ? value - 1 : 0),
          ),
          InkWell(
            onTap: onTapValue,
            child: Container(
              constraints: const BoxConstraints(minWidth: 38),
              height: AppDimens.tapTarget,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                border: Border.symmetric(vertical: BorderSide(color: AppColors.border)),
              ),
              child: Text(
                formatQuantity(value),
                style: AppText.price.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            enabled: value < max,
            onTap: () => onChanged(value + 1 < max ? value + 1 : max),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 38,
        height: AppDimens.tapTarget,
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.primary : AppColors.iconMuted,
        ),
      ),
    );
  }
}

/// Ввод точного количества к возврату — быстрее степпера, когда позиций много,
/// и единственный способ вернуть дробный вес.
class _QuantitySheet extends StatefulWidget {
  final String title;
  final double available;
  final double value;

  /// Штучный товар (uomId = 1) дробным быть не может.
  final bool wholeOnly;

  const _QuantitySheet({
    required this.title,
    required this.available,
    required this.value,
    required this.wholeOnly,
  });

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late final TextEditingController controller = TextEditingController(
    text: widget.value > 0 ? formatQuantity(widget.value) : '',
  );
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = controller.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(raw);

    if (raw.isEmpty || parsed == null || parsed < 0) {
      setState(() => error = context.tr('wrong_quantity'));
      return;
    }
    if (widget.wholeOnly && parsed != parsed.roundToDouble()) {
      setState(() => error = context.tr('wrong_quantity'));
      return;
    }
    if (parsed > widget.available) {
      setState(() => error = context.tr('not_more', args: [formatQuantity(widget.available)]));
      return;
    }

    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: AppText.h2, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: AppDimens.gap4),
        Text(
          '${context.tr('available')}: ${formatQuantity(widget.available)}',
          style: AppText.tabular(AppText.secondary),
        ),
        const SizedBox(height: AppDimens.gap16),
        AppInput.money(
          label: context.tr('return_quantity'),
          controller: controller,
          autofocus: true,
          errorText: error,
          onChanged: (_) {
            if (error != null) setState(() => error = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppDimens.gap16),
        AppButton(
          label: context.tr('confirm'),
          onPressed: _submit,
        ),
        const SizedBox(height: AppDimens.gap8),
        AppButton(
          label: context.tr('cancel'),
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.medium,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
