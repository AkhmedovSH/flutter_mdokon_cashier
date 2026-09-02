import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:unicons/unicons.dart';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/data/quick_rail_repository.dart';
import 'package:flutter_mdokon/features/cashier/domain/quick_rail.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Ширина рельсы с иконками видов.
const double _kRailWidth = 64;

/// Ширина раскрытой панели.
const double _kPanelWidth = 288;

/// Боковая колонка быстрого выбора (`src/components/cashbox/Rightbar.js`).
///
/// Четыре вида: список набора, витрина с картинками, категории набора и
/// цифровая клавиатура. Живёт только на планшете: на телефоне для неё нет ни
/// ширины, ни сценария — там товар ищут через каталог.
///
/// Панель по умолчанию закрыта — видна одна рельса иконок. Повторный тап по
/// активной иконке закрывает панель, как на десктопе: чек на 1024 px важнее
/// витрины, и кассир решает сам, когда её открыть.
class QuickRail extends StatefulWidget {
  /// Добавить товар в чек по штрих-коду.
  final Future<void> Function(String barcode) onAddBarcode;

  /// Нажатие клавиши на экранном цифровом блоке — уходит в тот же разбор
  /// `resolveHotkey`, что и внешняя клавиатура.
  final void Function(String key) onKey;

  /// «Добавить в чек» — товар по набранному коду.
  final VoidCallback onSubmit;

  /// Что уже набрано: клавиатура показывает буфер прямо над клавишами,
  /// иначе на планшете его видно только в строке горячих клавиш сверху.
  final String buffer;

  const QuickRail({
    super.key,
    required this.onAddBarcode,
    required this.onKey,
    required this.onSubmit,
    required this.buffer,
  });

  @override
  State<QuickRail> createState() => _QuickRailState();
}

class _QuickRailState extends State<QuickRail> {
  static const _repository = QuickRailRepository();

  final GetStorage _storage = GetStorage();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  Map _cashbox = {};

  List<Map> _items = const [];
  List<Map> _categories = const [];
  List<Map> _showcase = const [];

  QuickRailView _view = QuickRailView.list;
  String _activeCategoryId = '';
  String _search = '';
  bool _open = false;
  bool _loading = true;
  bool _showcaseLoading = false;

  @override
  void initState() {
    super.initState();
    _cashbox = _storage.read('cashbox') ?? {};
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- Данные ------------------------------------------------------------

  Future<void> _load() async {
    final posId = _cashbox['posId'];
    final cashboxId = _cashbox['cashboxId'];
    final results = await Future.wait([
      _repository.items(posId: posId, cashboxId: cashboxId),
      _repository.categories(posId: posId, cashboxId: cashboxId),
    ]);
    if (!mounted) return;

    setState(() {
      _items = results[0];
      _categories = results[1];
      _loading = false;
    });
  }

  /// Витрина: у мобилки нет локальной базы, поэтому карточки приходят с
  /// сервера по запросу. Пустой запрос показывает сам набор — иначе кассир
  /// открывал бы витрину на пустой экран.
  Future<void> _loadShowcase(String query) async {
    if (query.isEmpty) {
      setState(() {
        _showcase = const [];
        _showcaseLoading = false;
      });
      return;
    }

    setState(() => _showcaseLoading = true);
    final rows = await _repository.search(
      posId: _cashbox['posId'],
      currencyId: _cashbox['defaultCurrency'],
      query: query,
    );
    if (!mounted) return;
    setState(() {
      _showcase = rows;
      _showcaseLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _search = value);
    if (_view != QuickRailView.showcase) return;

    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _loadShowcase(value.trim()),
    );
  }

  // --- Виды ---------------------------------------------------------------

  void _toggleView(QuickRailView view) {
    if (_open && _view == view) {
      setState(() => _open = false);
      return;
    }

    setState(() {
      if (view != _view) {
        _activeCategoryId = '';
        _search = '';
        _searchController.clear();
      }
      _view = view;
      _open = true;
    });
    if (view == QuickRailView.showcase) _loadShowcase(_search.trim());
  }

  void _openCategory(String categoryId) {
    setState(() => _activeCategoryId = categoryId);
  }

  String get _currency =>
      customNumber(_cashbox['defaultCurrency']) == 2 ? 'USD' : context.tr('sum');

  String get _title {
    switch (_view) {
      case QuickRailView.list:
        return context.tr('quick_selection');
      case QuickRailView.showcase:
        return context.tr('rightbar_showcase_title');
      case QuickRailView.keys:
        return context.tr('rightbar_keyboard');
      case QuickRailView.groups:
        if (_activeCategoryId.isEmpty) return context.tr('rightbar_categories_title');
        final active = _categories.where(
          (category) => quickCategoryKey(category) == _activeCategoryId,
        );
        return active.isEmpty
            ? context.tr('regular_category')
            : quickCategoryName(active.first);
    }
  }

  // --- Вёрстка -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_open) SizedBox(width: _kPanelWidth, child: _panel()),
        _rail(),
      ],
    );
  }

  Widget _rail() {
    const views = <(QuickRailView, IconData, String)>[
      (QuickRailView.list, UniconsLine.list_ul, 'rightbar_rail_list'),
      (QuickRailView.showcase, UniconsLine.image_v, 'rightbar_rail_showcase'),
      (QuickRailView.groups, UniconsLine.apps, 'rightbar_rail_groups'),
      (QuickRailView.keys, UniconsLine.keyboard, 'rightbar_rail_keys'),
    ];

    return Container(
      width: _kRailWidth,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppDimens.gap8),
          for (final (view, icon, labelKey) in views)
            _RailButton(
              icon: icon,
              label: context.tr(labelKey),
              active: _open && _view == view,
              onTap: () => _toggleView(view),
            ),
        ],
      ),
    );
  }

  Widget _panel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          if (_view != QuickRailView.keys) _searchField(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _header() {
    final canGoBack = _view == QuickRailView.groups && _activeCategoryId.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gap12,
        AppDimens.gap12,
        AppDimens.gap8,
        AppDimens.gap8,
      ),
      child: Row(
        children: [
          if (canGoBack) ...[
            AppIconButton(
              icon: UniconsLine.arrow_left,
              tooltip: context.tr('rightbar_back'),
              size: 32,
              iconSize: 18,
              background: AppColors.canvas,
              foreground: AppColors.textSecondary,
              onPressed: () => _openCategory(''),
            ),
            const SizedBox(width: AppDimens.gap8),
          ],
          Expanded(
            child: Text(
              _title,
              style: AppText.h2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppIconButton(
            icon: UniconsLine.times,
            tooltip: context.tr('close'),
            size: 32,
            iconSize: 18,
            background: AppColors.canvas,
            foreground: AppColors.textSecondary,
            onPressed: () => setState(() => _open = false),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimens.gap12, 0, AppDimens.gap12, AppDimens.gap8),
      child: AppInput(
        controller: _searchController,
        hint: context.tr('rightbar_search_placeholder'),
        prefixIcon: UniconsLine.search,
        height: AppDimens.heightMedium,
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _body() {
    if (_view == QuickRailView.keys) return _keyboard();
    if (_loading) return const AppLoaderView();

    switch (_view) {
      case QuickRailView.showcase:
        return _showcaseView();
      case QuickRailView.groups:
        return _groupsView();
      case QuickRailView.list:
      case QuickRailView.keys:
        return _listView();
    }
  }

  /// Пустой экран: без запроса подсказываем, где набор пополнить, с запросом —
  /// что его достаточно изменить.
  Widget _empty(String emptyHintKey) {
    return AppEmptyState(
      icon: UniconsLine.search,
      title: context.tr('nothing_found'),
      text: context.tr(
        _search.trim().isEmpty ? emptyHintKey : 'rightbar_search_empty_hint',
      ),
    );
  }

  EdgeInsets get _listPadding => const EdgeInsets.fromLTRB(
        AppDimens.gap12,
        0,
        AppDimens.gap12,
        AppDimens.gap12,
      );

  Widget _productList(List<Map> visible) {
    return ListView.separated(
      padding: _listPadding,
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimens.gap8),
      itemBuilder: (_, index) => _productRow(visible[index]),
    );
  }

  Widget _listView() {
    final visible = filterQuickItems(_items, search: _search, view: QuickRailView.list);
    if (visible.isEmpty) return _empty('rightbar_quick_empty_hint');
    return _productList(visible);
  }

  Widget _groupsView() {
    if (_activeCategoryId.isNotEmpty) {
      final visible = filterQuickItems(
        _items,
        search: _search,
        categoryId: _activeCategoryId,
        view: QuickRailView.groups,
      );
      if (visible.isEmpty) return _empty('rightbar_quick_empty_hint');
      return _productList(visible);
    }

    final categories = filterQuickCategories(
      _categories,
      search: _search,
      activeCategoryId: _activeCategoryId,
    );

    // Товары без категории показываем отдельной папкой «Обычные»: на экране
    // настроек они лежат там же, и иначе из групп до них не добраться.
    final regular = countQuickItems(_items, '');
    final showRegular = regular > 0 && _search.trim().isEmpty;

    if (categories.isEmpty && !showRegular) return _empty('rightbar_quick_empty_hint');

    return ListView(
      padding: _listPadding,
      children: [
        if (showRegular) ...[
          _categoryCard(context.tr('regular_category'), '', regular),
          const SizedBox(height: AppDimens.gap8),
        ],
        for (final category in categories) ...[
          _categoryCard(
            quickCategoryName(category),
            quickCategoryKey(category),
            countQuickItems(_items, quickCategoryKey(category)),
          ),
          const SizedBox(height: AppDimens.gap8),
        ],
      ],
    );
  }

  Widget _showcaseView() {
    if (_showcaseLoading) return const AppLoaderView();

    // Пустой запрос — показываем сам набор карточками: у мобилки нет
    // локальной базы, из которой десктоп берёт «все товары».
    final rows = _search.trim().isEmpty ? _items : _showcase;
    if (rows.isEmpty) return _empty('rightbar_quick_empty_hint');

    return GridView.builder(
      padding: _listPadding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimens.gap8,
        crossAxisSpacing: AppDimens.gap8,
        childAspectRatio: 0.78,
      ),
      itemCount: rows.length,
      itemBuilder: (_, index) => _showcaseCard(rows[index]),
    );
  }

  /// Штрих-код позиции: у набора он `productBarcode`, у остатков — `barcode`.
  String _barcodeOf(Map item) => '${item['productBarcode'] ?? item['barcode'] ?? ''}';

  Widget _productRow(Map item) {
    final barcode = _barcodeOf(item);
    final price = item['salePrice'];

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.gap8),
      onTap: barcode.isEmpty ? null : () => widget.onAddBarcode(barcode),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppDimens.control,
            ),
            child: Icon(UniconsLine.plus, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: AppDimens.gap8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['productName'] ?? ''}',
                  style: AppText.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (barcode.isNotEmpty)
                  Text(
                    barcode,
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (customIf(price))
                  Text(
                    '${formatMoney(price)} $_currency',
                    style: AppText.tabular(AppText.secondaryBold),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(String name, String id, int count) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimens.gap12),
      onTap: () => _openCategory(id),
      child: Row(
        children: [
          Icon(UniconsLine.folder, size: 20, color: AppColors.primary),
          const SizedBox(width: AppDimens.gap8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppText.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  context.tr('rightbar_products_count', namedArgs: {'count': '$count'}),
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          Icon(UniconsLine.angle_right, size: 18, color: AppColors.iconMuted),
        ],
      ),
    );
  }

  Widget _showcaseCard(Map item) {
    final barcode = _barcodeOf(item);
    final image = '${item['productImageUrl'] ?? ''}';

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.gap8),
      onTap: barcode.isEmpty ? null : () => widget.onAddBarcode(barcode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: AppDimens.control,
              child: Container(
                color: AppColors.canvas,
                alignment: Alignment.center,
                child: image.isEmpty
                    ? Icon(UniconsLine.box, size: 28, color: AppColors.iconMuted)
                    : Image.network(
                        '$hostUrl$image',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        // Картинка не обязана доехать: на кассе бывает тонкий
                        // канал, а добавить товар нужно всё равно.
                        errorBuilder: (_, _, _) =>
                            Icon(UniconsLine.box, size: 28, color: AppColors.iconMuted),
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.gap4),
          Text(
            '${item['productName'] ?? ''}',
            style: AppText.secondaryBold,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${formatMoney(item['salePrice'])} $_currency',
            style: AppText.tabular(AppText.caption),
          ),
        ],
      ),
    );
  }

  // --- Клавиатура ----------------------------------------------------------

  Widget _keyboard() {
    const digits = ['7', '8', '9', '4', '5', '6', '1', '2', '3', '.', '0'];
    const shortcuts = ['+', '*', '-', '/', 'F5', 'F6'];

    return SingleChildScrollView(
      padding: _listPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: AppDimens.heightMedium,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: AppDimens.control,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              widget.buffer.isEmpty ? '0' : widget.buffer,
              style: AppText.tabular(AppText.h2).copyWith(
                color: widget.buffer.isEmpty ? AppColors.iconMuted : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.gap8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppDimens.gap8,
            crossAxisSpacing: AppDimens.gap8,
            childAspectRatio: 1.4,
            children: [
              for (final key in digits) _KeyButton(label: key, onTap: () => widget.onKey(key)),
              _KeyButton(
                label: '⌫',
                tone: _KeyTone.danger,
                onTap: () => widget.onKey('Backspace'),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap8),
          // Те же операции, что и на внешней клавиатуре: набранное число плюс
          // клавиша операции, разбор один и тот же — `resolveHotkey`.
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppDimens.gap8,
            crossAxisSpacing: AppDimens.gap8,
            childAspectRatio: 1.4,
            children: [
              for (final key in shortcuts)
                _KeyButton(
                  label: key,
                  tone: _KeyTone.secondary,
                  onTap: () => widget.onKey(key),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.gap8),
          AppButton(
            label: context.tr('rightbar_add_to_cheque'),
            onPressed: widget.buffer.isEmpty ? null : widget.onSubmit,
          ),
        ],
      ),
    );
  }
}

/// Кнопка вида в рельсе иконок.
class _RailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RailButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap4, vertical: 2),
      child: Material(
        color: active ? AppColors.primarySoft : Colors.transparent,
        borderRadius: AppDimens.control,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDimens.control,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.gap8),
            child: Column(
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _KeyTone { normal, secondary, danger }

class _KeyButton extends StatelessWidget {
  final String label;
  final _KeyTone tone;
  final VoidCallback onTap;

  const _KeyButton({required this.label, required this.onTap, this.tone = _KeyTone.normal});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      _KeyTone.normal => (AppColors.canvas, AppColors.textPrimary),
      _KeyTone.secondary => (AppColors.primarySoft, AppColors.primary),
      _KeyTone.danger => (AppColors.dangerSoft, AppColors.dangerText),
    };

    return Material(
      color: background,
      borderRadius: AppDimens.control,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.control,
        child: Center(
          child: Text(
            label,
            style: AppText.tabular(AppText.h2).copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}
