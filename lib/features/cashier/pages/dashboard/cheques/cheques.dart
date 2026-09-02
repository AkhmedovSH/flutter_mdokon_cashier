import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/state/loading_model.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/core/theme/themes.dart';
import 'package:flutter_mdokon/features/cashier/models/dashboard_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/cheques/cheque_preview_sheet.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Чеки смены — вкладка нижней навигации.
///
/// Список карточек вместо таблицы: номер и сумма читаются с одного взгляда,
/// время, кассир и статус уходят во вторую строку. Поиск в шапке фильтрует уже
/// загруженный список локально — без похода на сервер; всё остальное (период,
/// сумма, фискализация, возврат, кассир, смена, uGet) уходит в запрос через
/// лист фильтров и возвращается чипами под поиском — видно, что сузило выдачу.
class Cheques extends StatefulWidget {
  const Cheques({super.key});

  @override
  State<Cheques> createState() => _ChequesState();
}

class _ChequesState extends State<Cheques> {
  final GetStorage storage = GetStorage();
  final TextEditingController searchController = TextEditingController();

  _ChequeFilter filter = _ChequeFilter.initial();

  /// Всё, что вернул сервер, и то, что осталось после локального поиска.
  /// Второй список пересчитываем на ввод и на загрузку — не на каждый кадр.
  List cheques = [];
  List visible = [];

  /// Чек, открытый в правой колонке (планшет).
  Map? selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => getCheques());
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // --- Данные ------------------------------------------------------------

  Map get _payload {
    final data = <String, dynamic>{
      'posId': (storage.read('cashbox') ?? {})['posId'],
      'startDate': filter.startDate.toUtc().millisecondsSinceEpoch,
      'endDate': filter.endDate.toUtc().millisecondsSinceEpoch,
      'fromPaid': filter.fromPaid,
      'toPaid': filter.toPaid,
      'outType': false,
      'search': '',
      'size': 2000,
    };

    // Доп. фильтры кладём в запрос только когда заданы: пустые значения бэкенд
    // считает условием и возвращает пустую выдачу.
    if (filter.cashierLogin.isNotEmpty) data['cashierLogin'] = filter.cashierLogin;
    if (filter.shiftNumber.isNotEmpty) data['shiftNumber'] = filter.shiftNumber;
    if (filter.uget) data['uget'] = true;
    if (filter.fiscal != _Tri.any) data['fiscal'] = filter.fiscal == _Tri.yes;
    if (filter.returned != _Tri.any) data['returned'] = filter.returned == _Tri.yes;

    return data;
  }

  Future<void> getCheques() async {
    Provider.of<LoadingModel>(context, listen: false).showLoader(num: 1);

    final response = await get('/services/desktop/api/cashier-cheque-pageList', payload: _payload);
    if (!mounted) return;

    setState(() {
      cheques = httpOk(response) && response is List ? response : [];
      visible = _search();
    });
    Provider.of<LoadingModel>(context, listen: false).hideLoader();
  }

  /// Локальный поиск по номеру чека, кассиру, клиенту и сумме.
  List _search() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return cheques;

    return cheques.where((cheque) {
      final haystack = [
        _number(cheque),
        '${cheque['cashierName'] ?? ''}',
        '${cheque['clientName'] ?? ''}',
        formatMoney(_chequeTotal(cheque)),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  String _number(dynamic cheque) => '${cheque['chequeNumber'] ?? cheque['id'] ?? ''}';

  /// К оплате: сумма чека за вычетом скидки — так же считает касса на десктопе.
  double _chequeTotal(dynamic cheque) => customNumber(cheque['totalPrice']) - customNumber(cheque['discountAmount']);

  double get _visibleTotal => visible.fold(0, (sum, cheque) => sum + _chequeTotal(cheque));

  void _apply(_ChequeFilter next) {
    setState(() => filter = next);
    getCheques();
  }

  /// Тап по чеку открывает превью: позиции и итог видно, не уходя со списка.
  /// Полный дубликат и возврат — отдельными экранами уже из превью.
  ///
  /// На планшете превью не всплывает листом, а занимает колонку справа —
  /// список и чек видно одновременно.
  Future<void> _openPreview(dynamic cheque) async {
    if (context.layout.hasMasterDetail) {
      setState(() => selected = cheque);
      return;
    }

    final action = await AppModal.sheet<ChequePreviewAction>(
      context,
      builder: (ctx) => ChequePreviewSheet(
        cheque: cheque,
        number: _number(cheque),
        total: _chequeTotal(cheque),
      ),
    );
    if (!mounted) return;
    _runPreviewAction(action, cheque);
  }

  void _runPreviewAction(ChequePreviewAction? action, dynamic cheque) {
    if (action == null) {
      setState(() => selected = null);
      return;
    }

    switch (action) {
      case ChequePreviewAction.details:
        context.go('/cashier/cheque/detail/${cheque['id']}');
      case ChequePreviewAction.refund:
        Provider.of<DashboardModel>(context, listen: false).setCurrentCheque(cheque);
        // 3 — вкладка «Возврат»: она подхватит переданный чек и откроет его позиции.
        Provider.of<DashboardModel>(context, listen: false).setCurrentIndex(3);
        context.go('/cashier');
    }
  }

  Future<void> _openFilters() async {
    final result = await AppModal.sheet<_ChequeFilter>(
      context,
      builder: (ctx) => _FilterSheet(initial: filter),
    );
    if (result == null || !mounted) return;
    _apply(result);
  }

  /// Активные фильтры — по чипу на условие, каждый снимается отдельно.
  List<_FilterChipData> get _chips {
    final chips = <_FilterChipData>[];

    if (filter.periodChanged) {
      chips.add(
        _FilterChipData(
          label: '${_date(filter.startDate)} — ${_date(filter.endDate)}',
          cleared: filter.withDefaultPeriod(),
        ),
      );
    }
    if (filter.amountChanged) {
      final from = filter.fromPaid.isEmpty ? '0' : formatMoney(filter.fromPaid);
      final to = filter.toPaid.isEmpty ? '∞' : formatMoney(filter.toPaid);
      chips.add(
        _FilterChipData(
          label: '$from — $to',
          cleared: filter.copyWith(fromPaid: '', toPaid: ''),
        ),
      );
    }
    if (filter.fiscal != _Tri.any) {
      chips.add(
        _FilterChipData(
          label: context.tr(filter.fiscal == _Tri.yes ? 'fiscal' : 'not_fiscal'),
          cleared: filter.copyWith(fiscal: _Tri.any),
        ),
      );
    }
    if (filter.returned != _Tri.any) {
      chips.add(
        _FilterChipData(
          label: context.tr(filter.returned == _Tri.yes ? 'returned' : 'without_return'),
          cleared: filter.copyWith(returned: _Tri.any),
        ),
      );
    }
    if (filter.cashierLogin.isNotEmpty) {
      chips.add(
        _FilterChipData(
          label: '${context.tr('cashier')}: ${filter.cashierLogin}',
          cleared: filter.copyWith(cashierLogin: ''),
        ),
      );
    }
    if (filter.shiftNumber.isNotEmpty) {
      chips.add(
        _FilterChipData(
          label: '${context.tr('shift_number')}: ${filter.shiftNumber}',
          cleared: filter.copyWith(shiftNumber: ''),
        ),
      );
    }
    if (filter.uget) {
      chips.add(
        _FilterChipData(
          label: context.tr('uget'),
          cleared: filter.copyWith(uget: false),
        ),
      );
    }

    return chips;
  }

  String _date(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

  // --- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          _topBar(),
          Expanded(
            child: MasterDetailLayout(
              master: _content(),
              detail: selected == null ? null : _preview(selected!),
              placeholder: AppEmptyState(
                icon: Icons.receipt_long,
                title: context.tr('checks'),
                text: context.tr('select_cheque_to_preview'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Превью выбранного чека в правой колонке.
  Widget _preview(Map cheque) {
    return Padding(
      key: ValueKey('preview_${cheque['id']}'),
      padding: EdgeInsets.all(context.layout.gutter),
      child: ChequePreviewSheet(
        key: ValueKey('cheque_${cheque['id']}'),
        cheque: cheque,
        number: _number(cheque),
        total: _chequeTotal(cheque),
        embedded: true,
        onResult: (action) => _runPreviewAction(action, cheque),
      ),
    );
  }

  /// Шапка на белой подложке: заголовок с итогом, поиск и фильтр.
  Widget _topBar() {
    final chips = _chips;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Яркость иконок берём от палитры: прибитая к светлой теме, она делала
      // статус-бар тёмным на тёмном.
      value: systemOverlayStyleFor(AppColors.palette).copyWith(
        statusBarColor: AppColors.surface,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(),
              _searchRow(chips.length),
              _filterChips(chips),
              const SizedBox(height: AppDimens.gap12),
            ],
          ),
        ),
      ),
    );
  }

  /// Итог справа от заголовка: сколько чеков показано и на какую сумму.
  /// Когда поиск сузил список — «показано / всего».
  Widget _header() {
    final shown = visible.length;
    final summary = shown == cheques.length ? '$shown' : '$shown / ${cheques.length}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimens.gutter, AppDimens.gap12, AppDimens.gutter, AppDimens.gap4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              context.tr('checks'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.h1.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          if (cheques.isNotEmpty)
            Text(
              '$summary · ${formatMoney(_visibleTotal)} ${context.tr('sum')}',
              style: AppText.tabular(AppText.secondary),
            ),
        ],
      ),
    );
  }

  Widget _searchRow(int activeFilters) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimens.gutter, AppDimens.gap8, AppDimens.gutter, 0),
      child: Row(
        children: [
          Expanded(
            child: AppSearchField(
              controller: searchController,
              hint: '${context.tr('cheque')}, ${context.tr('client')}',
              onChanged: (_) => setState(() => visible = _search()),
            ),
          ),
          const SizedBox(width: AppDimens.gap8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppIconButton(
                icon: Icons.tune,
                background: activeFilters > 0 ? AppColors.primarySoft : AppColors.canvas,
                foreground: activeFilters > 0 ? AppColors.primary : AppColors.textSecondary,
                size: AppDimens.heightMedium,
                iconSize: 22,
                onPressed: _openFilters,
              ),
              if (activeFilters > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: Text(
                      '$activeFilters',
                      style: AppText.tabular(AppText.caption).copyWith(
                        color: AppColors.onPrimary,
                        fontSize: 11,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Лента активных фильтров: по чипу на условие плюс сброс всех разом.
  Widget _filterChips(List<_FilterChipData> chips) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: AppDimens.heightSmall,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
          itemCount: chips.length + 1,
          separatorBuilder: (context, index) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            if (i == chips.length) {
              return _ResetAllChip(onTap: () => _apply(_ChequeFilter.initial()));
            }
            return _RemovableChip(
              label: chips[i].label,
              onRemove: () => _apply(chips[i].cleared),
            );
          },
        ),
      ),
    );
  }

  Widget _content() {
    return Consumer<LoadingModel>(
      builder: (context, loadingModel, child) {
        if (loadingModel.currentLoading == 1) {
          return const Center(child: AppLoader());
        }

        final items = visible;
        if (items.isEmpty) return _empty();

        return RefreshIndicator(
          onRefresh: getCheques,
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
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppDimens.gap8),
            itemBuilder: (context, i) => _ChequeTile(
              number: _number(items[i]),
              cheque: items[i],
              total: _chequeTotal(items[i]),
              selected: selected != null && selected!['id'] == items[i]['id'],
              onTap: () => _openPreview(items[i]),
            ),
          ),
        );
      },
    );
  }

  /// Пустых состояний три: не нашёл поиск, не нашли фильтры, чеков ещё не было.
  Widget _empty() {
    final query = searchController.text.trim();
    if (query.isNotEmpty) {
      return AppEmptyState(
        icon: Icons.search_off,
        title: context.tr('NOT_FOUND'),
        text: context.tr('nothing_found_for', args: [query]),
      );
    }

    if (_chips.isNotEmpty) {
      return AppEmptyState(
        icon: Icons.filter_alt_off,
        title: context.tr('NOT_FOUND'),
        text: context.tr('no_cheques_for_filters'),
        action: AppButton.soft(
          label: context.tr('clear_all'),
          onPressed: () => _apply(_ChequeFilter.initial()),
        ),
      );
    }

    return AppEmptyState(
      icon: Icons.receipt_long,
      title: context.tr('EMPTY_LIST'),
      text: context.tr('no_cheques_yet'),
    );
  }
}

/// Карточка чека: номер и сумма сверху, время с кассиром и статус — снизу.
class _ChequeTile extends StatelessWidget {
  final String number;
  final Map cheque;
  final double total;
  final VoidCallback onTap;

  /// Открытый в правой колонке чек — подсвечен, как выбранная строка чека.
  final bool selected;

  const _ChequeTile({
    required this.number,
    required this.cheque,
    required this.total,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [
      _time(cheque['chequeDate']),
      '${cheque['cashierName'] ?? ''}'.trim(),
    ].where((e) => e.isNotEmpty).join(' · ');

    final currency = customNumber(cheque['saleCurrencyId']) == 2 ? 'USD' : context.tr('sum');

    return AppCard(
      onTap: onTap,
      selected: selected,
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
                  '${context.tr('cheque')} №$number',
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
              _StatusBadge(cheque: cheque),
            ],
          ),
        ],
      ),
    );
  }

  /// Дата чека приходит unix-миллисекундами. Сегодняшним хватает времени,
  /// остальным добавляем день и месяц — год в списке смены не нужен.
  String _time(dynamic unixTime) {
    if (unixTime == null) return '';

    final date = DateTime.fromMillisecondsSinceEpoch(unixTime);
    final now = DateTime.now();
    final today = date.year == now.year && date.month == now.month && date.day == now.day;
    return DateFormat(today ? 'HH:mm' : 'dd.MM HH:mm').format(date);
  }
}

/// Статус чека: возврат, частичный возврат, продажа в долг или оплачен.
class _StatusBadge extends StatelessWidget {
  final Map cheque;

  const _StatusBadge({required this.cheque});

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = chequeStatusStyle(context, cheque);

    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: AppDimens.pill),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.small.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Чип активного фильтра с крестиком.
class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _RemovableChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: AppDimens.pill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onRemove,
        child: Padding(
          padding: const EdgeInsets.only(left: AppDimens.gap12, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppText.tabular(AppText.secondaryBold).copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 6),
              Icon(Icons.close, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Сброс всех фильтров разом — последний чип в ленте.
class _ResetAllChip extends StatelessWidget {
  final VoidCallback onTap;

  const _ResetAllChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dangerSoft,
      borderRadius: AppDimens.pill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12),
          alignment: Alignment.center,
          child: Text(
            context.tr('clear_all'),
            style: AppText.secondaryBold.copyWith(color: AppColors.dangerText),
          ),
        ),
      ),
    );
  }
}

/// Чип активного фильтра: подпись и фильтр без этого условия.
class _FilterChipData {
  final String label;
  final _ChequeFilter cleared;

  const _FilterChipData({required this.label, required this.cleared});
}

/// Тумблер на три положения: не задано / да / нет.
enum _Tri { any, yes, no }

/// Значения фильтра чеков.
///
/// Период всегда задан, остальное — пустое, пока кассир не сузил выдачу.
/// Иммутабельный: снятие чипа — это [copyWith] без одного условия.
class _ChequeFilter {
  /// Период по умолчанию — последние 10 дней.
  static const int defaultPeriodDays = 10;

  final DateTime startDate;
  final DateTime endDate;
  final String fromPaid;
  final String toPaid;
  final String cashierLogin;
  final String shiftNumber;
  final bool uget;
  final _Tri fiscal;
  final _Tri returned;

  const _ChequeFilter({
    required this.startDate,
    required this.endDate,
    this.fromPaid = '',
    this.toPaid = '',
    this.cashierLogin = '',
    this.shiftNumber = '',
    this.uget = false,
    this.fiscal = _Tri.any,
    this.returned = _Tri.any,
  });

  factory _ChequeFilter.initial() => _ChequeFilter(
    startDate: startOfDay(DateTime.now().subtract(const Duration(days: defaultPeriodDays))),
    endDate: endOfDay(DateTime.now()),
  );

  static DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) => DateTime(date.year, date.month, date.day, 23, 59);

  _ChequeFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? fromPaid,
    String? toPaid,
    String? cashierLogin,
    String? shiftNumber,
    bool? uget,
    _Tri? fiscal,
    _Tri? returned,
  }) {
    return _ChequeFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      fromPaid: fromPaid ?? this.fromPaid,
      toPaid: toPaid ?? this.toPaid,
      cashierLogin: cashierLogin ?? this.cashierLogin,
      shiftNumber: shiftNumber ?? this.shiftNumber,
      uget: uget ?? this.uget,
      fiscal: fiscal ?? this.fiscal,
      returned: returned ?? this.returned,
    );
  }

  _ChequeFilter withDefaultPeriod() => copyWith(
    startDate: startOfDay(DateTime.now().subtract(const Duration(days: defaultPeriodDays))),
    endDate: endOfDay(DateTime.now()),
  );

  /// Пресет периода: последние [days] дней, включая сегодня.
  _ChequeFilter withPeriod(int days) => copyWith(
    startDate: startOfDay(DateTime.now().subtract(Duration(days: days))),
    endDate: endOfDay(DateTime.now()),
  );

  bool isPeriod(int days) {
    final now = DateTime.now();
    return _sameDay(endDate, now) && _sameDay(startDate, now.subtract(Duration(days: days)));
  }

  bool get periodChanged => !isPeriod(defaultPeriodDays);

  bool get amountChanged => fromPaid.isNotEmpty || toPaid.isNotEmpty;

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Лист фильтров: период, сумма, фискализация, возврат, кассир и смена, uGet.
class _FilterSheet extends StatefulWidget {
  final _ChequeFilter initial;

  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _ChequeFilter _draft = widget.initial;

  late final TextEditingController _from = TextEditingController(text: widget.initial.fromPaid);
  late final TextEditingController _to = TextEditingController(text: widget.initial.toPaid);
  late final TextEditingController _cashier = TextEditingController(text: widget.initial.cashierLogin);
  late final TextEditingController _shift = TextEditingController(text: widget.initial.shiftNumber);

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _cashier.dispose();
    _shift.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _draft.startDate : _draft.endDate,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        final start = _ChequeFilter.startOfDay(picked);
        _draft = _draft.copyWith(
          startDate: start,
          endDate: _draft.endDate.isBefore(start) ? _ChequeFilter.endOfDay(picked) : _draft.endDate,
        );
      } else {
        final end = _ChequeFilter.endOfDay(picked);
        _draft = _draft.copyWith(
          endDate: end,
          startDate: _draft.startDate.isAfter(end) ? _ChequeFilter.startOfDay(picked) : _draft.startDate,
        );
      }
    });
  }

  /// Поля ввода живут в контроллерах — собираем их в фильтр только на выходе.
  _ChequeFilter get _result => _draft.copyWith(
    fromPaid: _from.text.trim(),
    toPaid: _to.text.trim(),
    cashierLogin: _cashier.text.trim(),
    shiftNumber: _shift.text.trim(),
  );

  void _reset() {
    _from.clear();
    _to.clear();
    _cashier.clear();
    _shift.clear();
    setState(() => _draft = _ChequeFilter.initial());
  }

  @override
  Widget build(BuildContext context) {
    // Лист длинный — ограничиваем высоту и скроллим тело. Клавиатура забирает
    // высоту у листа, поэтому считаем предел от свободной части экрана.
    final media = MediaQuery.of(context);
    final maxHeight = (media.size.height - media.viewInsets.bottom) * 0.82;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(context.tr('filter'), style: AppText.h2)),
              AppIconButton(
                icon: Icons.close,
                foreground: AppColors.textSecondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSectionLabel(context.tr('period')),
                  const SizedBox(height: AppDimens.gap8),
                  _periodPresets(),
                  const SizedBox(height: AppDimens.gap12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          value: _draft.startDate,
                          onTap: () => _pick(true),
                        ),
                      ),
                      const SizedBox(width: AppDimens.gap8),
                      Expanded(
                        child: _DateField(
                          value: _draft.endDate,
                          onTap: () => _pick(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.gap16),
                  AppSectionLabel(context.tr('check_amount')),
                  const SizedBox(height: AppDimens.gap8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppInput.money(
                          hint: context.tr('amount_from'),
                          controller: _from,
                          height: AppDimens.heightMedium,
                        ),
                      ),
                      const SizedBox(width: AppDimens.gap8),
                      Expanded(
                        child: AppInput.money(
                          hint: context.tr('amount_to'),
                          controller: _to,
                          height: AppDimens.heightMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.gap16),
                  _SegmentedField(
                    label: context.tr('fiscalization'),
                    labels: [context.tr('all'), context.tr('fiscal'), context.tr('not_fiscal')],
                    value: _draft.fiscal,
                    onChanged: (value) => setState(() => _draft = _draft.copyWith(fiscal: value)),
                  ),
                  const SizedBox(height: AppDimens.gap16),
                  _SegmentedField(
                    label: context.tr('return'),
                    labels: [context.tr('all'), context.tr('returned'), context.tr('without_return')],
                    value: _draft.returned,
                    onChanged: (value) => setState(() => _draft = _draft.copyWith(returned: value)),
                  ),
                  const SizedBox(height: AppDimens.gap16),
                  AppSectionLabel(context.tr('cashier_and_shift')),
                  const SizedBox(height: AppDimens.gap8),
                  AppInput(
                    controller: _cashier,
                    hint: context.tr('cashier'),
                    height: AppDimens.heightMedium,
                  ),
                  const SizedBox(height: AppDimens.gap8),
                  AppInput(
                    controller: _shift,
                    hint: context.tr('shift_number'),
                    height: AppDimens.heightMedium,
                  ),
                  const SizedBox(height: AppDimens.gap12),
                  _CheckRow(
                    label: context.tr('only_uget'),
                    value: _draft.uget,
                    onChanged: (value) => setState(() => _draft = _draft.copyWith(uget: value)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.gap16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: context.tr('clear'),
                  variant: AppButtonVariant.secondary,
                  onPressed: _reset,
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: context.tr('apply'),
                  onPressed: () => Navigator.of(context).pop(_result),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodPresets() {
    const presets = [0, 7, _ChequeFilter.defaultPeriodDays, 30];

    return Row(
      children: [
        for (final days in presets) ...[
          if (days != presets.first) const SizedBox(width: 6),
          Expanded(
            child: _SegmentButton(
              label: days == 0 ? context.tr('today') : '$days ${context.tr('days_short')}',
              selected: _draft.isPeriod(days),
              onTap: () => setState(() => _draft = _draft.withPeriod(days)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Дата периода: поле-кнопка с календарём, открывает системный пикер.
class _DateField extends StatelessWidget {
  final DateTime value;
  final VoidCallback onTap;

  const _DateField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      borderRadius: AppDimens.control,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppDimens.heightMedium,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12),
          decoration: BoxDecoration(
            borderRadius: AppDimens.control,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: AppColors.iconMuted),
              const SizedBox(width: AppDimens.gap8),
              Expanded(
                child: Text(
                  DateFormat('dd.MM.yyyy').format(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tabular(AppText.body),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Переключатель на три положения: «Все» и два взаимоисключающих условия.
class _SegmentedField extends StatelessWidget {
  final String label;
  final List<String> labels;
  final _Tri value;
  final ValueChanged<_Tri> onChanged;

  const _SegmentedField({
    required this.label,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSectionLabel(label),
        const SizedBox(height: AppDimens.gap8),
        Row(
          children: [
            for (final option in _Tri.values) ...[
              if (option != _Tri.values.first) const SizedBox(width: 6),
              Expanded(
                child: _SegmentButton(
                  label: labels[option.index],
                  selected: option == value,
                  onTap: () => onChanged(option),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.canvas,
      borderRadius: AppDimens.control,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppDimens.tapTarget,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap8),
          decoration: BoxDecoration(
            borderRadius: AppDimens.control,
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppText.secondaryBold.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Строка-флажок фильтра (uGet).
class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      borderRadius: AppDimens.control,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: value ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: value ? AppColors.primary : AppColors.border,
                    width: value ? 1 : 1.5,
                  ),
                ),
                child: value ? Icon(Icons.check, size: 15, color: AppColors.onPrimary) : null,
              ),
              const SizedBox(width: AppDimens.gap12),
              Expanded(child: Text(label, style: AppText.body)),
            ],
          ),
        ),
      ),
    );
  }
}
