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

/// Ключ псевдокатегории «Обычные» — товаров набора без категории.
///
/// У самих таких товаров `categoryId` пустой, но пустым же обозначается «ни
/// одна категория не открыта»: с одним значением на два смысла папка не
/// открывалась вовсе. Наружу, в фильтр, ключ уходит обратно пустым.
const String _kRegularCategoryId = 'regular';

/// Ширина рельсы с иконками видов.
const double _kRailWidth = 64;

/// Ширина раскрытой панели.
const double _kPanelWidth = 288;

/// Виды колонки: иконка и подпись. Порядок один и для рельсы планшета, и для
/// сегментов телефонного листа.
const List<(QuickRailView, IconData, String)> _kViews = [
  (QuickRailView.list, UniconsLine.list_ul, 'rightbar_rail_list'),
  (QuickRailView.showcase, UniconsLine.image_v, 'rightbar_rail_showcase'),
  (QuickRailView.groups, UniconsLine.apps, 'rightbar_rail_groups'),
];

/// Боковая колонка быстрого выбора (`src/components/cashbox/Rightbar.js`).
///
/// Три вида: список набора, витрина с картинками и категории набора.
/// Цифрового блока здесь нет: код товара на телефоне набирают не пальцем, а
/// сканером, и клавиши только занимали место.
///
/// Две раскладки одного и того же набора. На планшете — колонка справа от
/// чека: панель по умолчанию закрыта, видна одна рельса иконок, и повторный
/// тап по активной иконке её закрывает (чек на 1024 px важнее витрины).
/// На телефоне ([compact]) колонке нет места, поэтому тот же набор
/// открывается листом снизу — [QuickRail.show]: рельсы нет, вид переключают
/// сегменты в шапке, панель всегда раскрыта.
class QuickRail extends StatefulWidget {
  /// Добавить товар в чек по штрих-коду.
  final Future<void> Function(String barcode) onAddBarcode;

  /// Чек меняется — колонка перерисовывает счётчики.
  ///
  /// Слушаем модель, а не получаем цифры разом: телефонный лист живёт в своём
  /// маршруте, и `setState` страницы продажи его не перестраивает.
  final Listenable cart;

  /// Сколько штук этого штрих-кода уже в чеке — цифра на карточке товара.
  final double Function(String barcode) quantityOf;

  /// Телефонная раскладка листом. См. описание класса.
  final bool compact;

  const QuickRail({
    super.key,
    required this.onAddBarcode,
    required this.cart,
    required this.quantityOf,
    this.compact = false,
  });

  /// Открыть быстрый выбор листом снизу — вход с телефона.
  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(String barcode) onAddBarcode,
    required Listenable cart,
    required double Function(String barcode) quantityOf,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        // Лист высокий: витрина карточками должна помещаться целиком.
        // Экранную клавиатуру поиска пропускаем вперёд — иначе список
        // уезжает под неё.
        final insets = media.viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: insets),
          child: SafeArea(
            top: false,
            child: Container(
              height: (media.size.height - insets) * 0.9,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppDimens.sheet,
              ),
              clipBehavior: Clip.antiAlias,
              child: QuickRail(
                compact: true,
                cart: cart,
                quantityOf: quantityOf,
                onAddBarcode: onAddBarcode,
              ),
            ),
          ),
        );
      },
    );
  }

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

  /// Строки остатка точки — карточки витрины. Это «все товары», а не набор:
  /// у десктопа витрина тоже идёт мимо быстрого подбора.
  List<Map<String, dynamic>> _showcase = const [];

  /// Запрос, которым набран `_showcase`. Открытие витрины поверх уже
  /// загруженного списка не должно снова тянуть весь остаток.
  String? _showcaseQuery;

  /// «Штрих-код → цена продажи»: сам набор цен не отдаёт, их приносит остаток.
  Map<String, dynamic> _prices = const {};

  QuickRailView _view = QuickRailView.list;
  String _activeCategoryId = '';
  String _search = '';
  late bool _open = widget.compact;
  bool _loading = true;
  bool _showcaseLoading = false;

  /// Набор быстрого подбора живёт на кассе. У агента кассы нет, и запросы за
  /// набором уходили с пустым `cashboxId` — сервер отвечал на них 400. Ему
  /// оставляем витрину: она считается от точки, а не от кассы.
  bool get _hasSet => customIf(_cashbox['cashboxId']);

  /// Виды, которые видно на этой сессии. См. [_hasSet].
  List<(QuickRailView, IconData, String)> get _views => _hasSet
      ? _kViews
      : [for (final view in _kViews) if (view.$1 == QuickRailView.showcase) view];

  @override
  void initState() {
    super.initState();
    _cashbox = _storage.read('cashbox') ?? {};
    if (!_hasSet) _view = QuickRailView.showcase;
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
    // Остаток тянем одним запросом на двоих: из него и карточки витрины, и
    // цены набора — цен сам набор не отдаёт. Запрос уходит вместе с набором,
    // а не после него: ждать его дважды колонке незачем.
    final balanceRequest = _repository.balance(
      posId: posId,
      currencyId: _cashbox['defaultCurrency'],
    );
    final results = _hasSet
        ? await Future.wait([
            _repository.items(posId: posId, cashboxId: cashboxId),
            _repository.categories(posId: posId, cashboxId: cashboxId),
          ])
        : const [<Map>[], <Map>[]];
    final balance = await balanceRequest;
    if (!mounted) return;

    setState(() {
      _items = results[0];
      _categories = results[1];
      _showcase = _repository.uniqueByBarcode(balance);
      _showcaseQuery = '';
      _prices = _repository.pricesOf(balance);
      _loading = false;
    });
  }

  /// Витрина: карточки — это остаток точки, как у десктопа «все товары».
  /// Локальной базы у мобилки нет, поэтому и полный список, и поиск по нему
  /// приходят с сервера одним и тем же запросом.
  Future<void> _loadShowcase(String query) async {
    if (_showcaseQuery == query) return;

    setState(() => _showcaseLoading = true);
    final rows = await _repository.balance(
      posId: _cashbox['posId'],
      currencyId: _cashbox['defaultCurrency'],
      query: query,
    );
    if (!mounted) return;
    setState(() {
      _showcase = _repository.uniqueByBarcode(rows);
      _showcaseQuery = query;
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
      // В листе закрывать нечего: панель — и есть весь лист.
      if (!widget.compact) setState(() => _open = false);
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
    // Пока идёт первая загрузка, остаток уже едет — второй раз не просим.
    if (view == QuickRailView.showcase && !_loading) _loadShowcase(_search.trim());
  }

  void _openCategory(String categoryId) {
    setState(() => _activeCategoryId = categoryId);
  }

  /// Категория позиций для фильтра: «Обычные» — это пустой `categoryId`.
  String get _filterCategoryId =>
      _activeCategoryId == _kRegularCategoryId ? '' : _activeCategoryId;

  String get _currency =>
      customNumber(_cashbox['defaultCurrency']) == 2 ? 'USD' : context.tr('sum');

  String get _title {
    switch (_view) {
      case QuickRailView.list:
        return context.tr('quick_selection');
      case QuickRailView.showcase:
        return context.tr('rightbar_showcase_title');
      case QuickRailView.groups:
        if (_activeCategoryId.isEmpty) return context.tr('rightbar_categories_title');
        if (_activeCategoryId == _kRegularCategoryId) return context.tr('regular_category');
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
    if (widget.compact) return _sheet();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_open) SizedBox(width: _kPanelWidth, child: _panel()),
        _rail(),
      ],
    );
  }

  /// Телефонная раскладка: та же панель без рельсы, виды — сегментами сверху.
  Widget _sheet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        _viewTabs(),
        _searchField(),
        Expanded(child: _body()),
      ],
    );
  }

  /// Переключатель видов для листа — те же четыре кнопки, что и в рельсе,
  /// только в строку.
  Widget _viewTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gap8,
        0,
        AppDimens.gap8,
        AppDimens.gap8,
      ),
      child: Row(
        children: [
          for (final (view, icon, labelKey) in _views)
            Expanded(
              child: _RailButton(
                icon: icon,
                label: context.tr(labelKey),
                active: _view == view,
                onTap: () => _toggleView(view),
              ),
            ),
        ],
      ),
    );
  }

  /// Закрыть быстрый выбор: на планшете сворачивается панель, на телефоне
  /// уходит весь лист.
  void _close() {
    if (widget.compact) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _open = false);
  }

  Widget _rail() {
    return Container(
      width: _kRailWidth,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppDimens.gap8),
          for (final (view, icon, labelKey) in _views)
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
          _searchField(),
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
            onPressed: _close,
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
    if (_loading) return const AppLoaderView();

    // Счётчики добавленного живут в чеке: он меняется без ведома колонки,
    // поэтому перерисовку тянем от модели, а не от `setState` страницы.
    return ListenableBuilder(
      listenable: widget.cart,
      builder: (_, _) {
        switch (_view) {
          case QuickRailView.showcase:
            return _showcaseView();
          case QuickRailView.groups:
            return _groupsView();
          case QuickRailView.list:
            return _listView();
        }
      },
    );
  }

  /// Пустой экран: без запроса подсказываем, где набор пополнить, с запросом —
  /// что его достаточно изменить. У витрины подсказки без запроса нет: пустой
  /// там не набор, а остаток точки, и кассир его из кассы не пополнит.
  Widget _empty(String? emptyHintKey) {
    final hint = _search.trim().isEmpty ? emptyHintKey : 'rightbar_search_empty_hint';
    return AppEmptyState(
      icon: UniconsLine.search,
      title: context.tr('nothing_found'),
      text: hint == null ? null : context.tr(hint),
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
        categoryId: _filterCategoryId,
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
          _categoryCard(context.tr('regular_category'), _kRegularCategoryId, regular),
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

    final rows = _showcase;
    if (rows.isEmpty) return _empty(null);

    return GridView.builder(
      padding: _listPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // Лист во всю ширину телефона держит третью карточку, узкая
        // колонка планшета — нет.
        crossAxisCount: widget.compact ? 3 : 2,
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

  /// Цена позиции. У строки остатка она своя, у позиции набора её нет —
  /// подставляем из карты цен по штрих-коду.
  dynamic _priceOf(Map item) =>
      customIf(item['salePrice']) ? item['salePrice'] : _prices[_barcodeOf(item)];

  /// Цена подписью, или пусто — цену без остатка показывать нечем.
  Widget _priceLabel(Map item, TextStyle style) {
    final price = _priceOf(item);
    if (!customIf(price)) return const SizedBox.shrink();
    return Text('${formatMoney(price)} $_currency', style: AppText.tabular(style));
  }

  Widget _productRow(Map item) {
    final barcode = _barcodeOf(item);
    final quantity = widget.quantityOf(barcode);

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
                _priceLabel(item, AppText.secondaryBold),
              ],
            ),
          ),
          if (quantity > 0) ...[
            const SizedBox(width: AppDimens.gap8),
            _QtyBadge(quantity: quantity),
          ],
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

  /// Адрес картинки товара. Сервер отдаёт путь от корня, но встречается и
  /// готовая ссылка — тогда хост приписывать не нужно.
  String _imageOf(Map item) {
    final path = '${item['productImageUrl'] ?? item['imageUrl'] ?? ''}'.trim();
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return path.startsWith('/') ? '$hostUrl$path' : '$hostUrl/$path';
  }

  Widget _showcaseCard(Map item) {
    final barcode = _barcodeOf(item);
    final image = _imageOf(item);
    final quantity = widget.quantityOf(barcode);

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.gap8),
      onTap: barcode.isEmpty ? null : () => widget.onAddBarcode(barcode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: AppDimens.control,
                  child: Container(
                    color: AppColors.canvas,
                    alignment: Alignment.center,
                    child: image.isEmpty
                        ? Icon(UniconsLine.box, size: 28, color: AppColors.iconMuted)
                        : Image.network(
                            image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            // Картинка не обязана доехать: на кассе бывает
                            // тонкий канал, а добавить товар нужно всё равно.
                            errorBuilder: (_, _, _) =>
                                Icon(UniconsLine.box, size: 28, color: AppColors.iconMuted),
                          ),
                  ),
                ),
                if (quantity > 0)
                  Positioned(
                    top: AppDimens.gap4,
                    right: AppDimens.gap4,
                    child: _QtyBadge(quantity: quantity),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.gap4),
          Text(
            '${item['productName'] ?? ''}',
            style: AppText.secondaryBold,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          _priceLabel(item, AppText.secondaryBold),
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

/// Счётчик уже добавленного в чек: без него повторный тап по карточке
/// выглядит как «не сработало».
class _QtyBadge extends StatelessWidget {
  final double quantity;

  const _QtyBadge({required this.quantity});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        formatQuantity(quantity),
        style: AppText.tabular(AppText.caption).copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
