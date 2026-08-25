import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/state/loading_model.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/domain/scanned_input.dart';
import 'package:flutter_mdokon/features/cashier/models/dashboard_model.dart';
import 'package:flutter_mdokon/features/cashier/models/sale_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/sale_sheets.dart';
import 'package:flutter_mdokon/shared/widgets/scanner/barcode_scanner_page.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Каталог товаров — вкладка нижней навигации.
///
/// Поиск по названию/штрих-коду и добавление позиций в чек. Кнопка «Добавить»
/// кладёт одну единицу — это основной сценарий кассы; тап по карточке открывает
/// лист с количеством, когда нужно больше одной штуки.
///
/// Вкладка не держит собственный буфер: количество читается и пишется прямо в
/// [SaleModel], поэтому чек и каталог всегда показывают одно и то же.
class Catalog extends StatefulWidget {
  const Catalog({super.key});

  @override
  State<Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<Catalog> {
  final GetStorage storage = GetStorage();
  final TextEditingController textEditingController = TextEditingController();
  Timer? _debounce;

  List products = [];

  Map cashbox = {};

  @override
  void initState() {
    super.initState();
    cashbox = storage.read('cashbox') ?? {};
  }

  @override
  void dispose() {
    _debounce?.cancel();
    textEditingController.dispose();
    super.dispose();
  }

  SaleModel get _sale => context.read<SaleModel>();

  // --- Данные ------------------------------------------------------------

  void searchProducts(dynamic value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() {
        products = [];
      });
      Provider.of<LoadingModel>(context, listen: false).showLoader(num: 1);
      // Код маркировки ищем не как есть, а по GTIN: у карточки товара может
      // стоять как GTIN-14, так и он же без ведущих нулей — пробуем по порядку.
      final terms = parseScannedInput(value).searchTerms;
      if (terms.isNotEmpty) {
        var arr = [];
        dynamic response;
        for (final term in terms) {
          response = await get(
            '/services/desktop/api/get-balance-product-list-mobile/${cashbox['posId']}/${_sale.data['currencyId']}?search=$term',
          );
          if (response != null && response.length > 0) break;
        }
        if (response != null && response.length > 0) {
          if (response.length > 50) {
            response = response.sublist(0, 50);
          }
          for (var i = 0; i < response.length; i++) {
            response[i]['quantity'] = 1;
            if (response[i]['balance'] == null || double.parse(response[i]['balance'].toString()) <= 0) {
              if (cashbox['saleMinus'] != null && cashbox['saleMinus']) {
                arr.add(response[i]);
              }
            } else {
              arr.add(response[i]);
            }
          }
          products = arr;
        } else if (response != null && response.length == 0) {
          products = [];
        }
        setState(() {});
      } else {
        setState(() {
          products = [];
        });
      }
      if (mounted) Provider.of<LoadingModel>(context, listen: false).hideLoader();
    });
  }

  Future<void> getQrCode() async {
    final result = await BarcodeScannerPage.scan(context);
    if (result == null || !mounted) return;

    final scanned = parseScannedInput(result);
    if (scanned.raw.isEmpty) return;
    setState(() {
      searchProducts(scanned.raw);
      textEditingController.text = scanned.displayTerm;
    });
  }

  // --- Чек ---------------------------------------------------------------

  /// Индекс позиции в чеке или -1.
  int _lineIndex(dynamic item) {
    return _sale.items.indexWhere((e) => e['balanceId'] == item['balanceId']);
  }

  /// Сколько этого товара уже лежит в чеке.
  double _inCart(dynamic item) {
    final index = _lineIndex(item);
    return index < 0 ? 0 : customNumber(_sale.items[index]['quantity']);
  }

  /// Скидка на чек блокирует добавление позиций — иначе итог пересчитается мимо неё.
  bool _blockedByDiscount() {
    if (_sale.discountPercent <= 0) return false;
    showDangerToast(context.tr('discount_has_been_applied'));
    return true;
  }

  /// Выставляет итоговое количество позиции (абсолютное, а не прибавку).
  Future<void> _applyQuantity(int i, num quantity) async {
    if (_blockedByDiscount()) return;

    final model = _sale;
    final index = _lineIndex(products[i]);

    if (index >= 0) {
      model.setQuantity(index, quantity);
    } else {
      if (quantity <= 0) return;
      final product = Map<String, dynamic>.from(products[i] as Map);
      product['quantity'] = quantity;
      final needsUnitDialog = model.addScannedProducts([product]);
      if (needsUnitDialog && mounted) await SaleSheets.unit(context, model);
    }

    Vibration.vibrate(amplitude: 10, duration: 30);
    if (mounted) setState(() {});
  }

  Future<void> addProductToList(int i, {num quantity = 1}) async {
    final before = _inCart(products[i]);
    await _applyQuantity(i, before + quantity);
    if (!mounted) return;

    // Показываем тост только если количество действительно изменилось.
    final added = _inCart(products[i]) - before;
    if (added <= 0) return;

    final label = added > 1
        ? '${products[i]['productName']} × ${formatMoney(added)} · ${context.tr('added')}'
        : '${products[i]['productName']} · ${context.tr('added')}';
    final balanceId = products[i]['balanceId'];
    showActionToast(
      context,
      label,
      actionLabel: context.tr('remove'),
      onAction: () => _undoAdd(balanceId, added),
    );
  }

  /// Откат добавления: вычитает количество, пропавшую позицию убирает из чека.
  void _undoAdd(dynamic balanceId, num quantity) {
    if (!mounted) return;
    final i = products.indexWhere((e) => e['balanceId'] == balanceId);
    if (i < 0) return;
    _applyQuantity(i, _inCart(products[i]) - quantity);
  }

  /// Лист количества — для случаев, когда одной штуки мало.
  Future<void> _openQuantitySheet(int i) async {
    final item = products[i];
    final quantity = await AppModal.sheet<int>(
      context,
      builder: (ctx) => _QuantitySheet(
        title: '${item['productName'] ?? ''}',
        balance: _balance(item),
      ),
    );
    if (quantity != null && quantity > 0) addProductToList(i, quantity: quantity);
  }

  // --- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Количества в карточках зависят от чека — перерисовываемся вместе с ним.
    context.watch<SaleModel>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          _topBar(),
          const SizedBox(height: AppDimens.gap12),
          Expanded(
            child: SideRailLayout(
              body: _content(),
              // На широком экране каталог не уводит кассира от чека:
              // чек виден справа и пополняется прямо здесь.
              rail: _cartRail(),
              bottom: _cartBar(),
            ),
          ),
        ],
      ),
    );
  }

  /// Колонка чека справа: позиции, итог и переход к оплате.
  Widget _cartRail() {
    final model = _sale;
    final layout = context.layout;

    if (model.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(layout.gutter),
        child: AppEmptyState(
          icon: Icons.shopping_cart_outlined,
          title: context.tr('cheque_is_empty'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(layout.gutter, layout.gutter, layout.gutter, AppDimens.gap8),
          child: AppSectionLabel(
            '${context.tr('cheque')} · ${model.lineCount} ${context.tr('pieces_short')}',
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(layout.gutter, 0, layout.gutter, AppDimens.gap12),
            itemCount: model.lineCount,
            separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, position) {
              // Свежая позиция — первой, как и в чеке на вкладке продажи.
              final item = model.items[model.lineCount - 1 - position] as Map;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.gap8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['productName'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body,
                          ),
                          Text(
                            '${formatMoney(item['salePrice'])} × ${formatMoney(customNumber(item['quantity']), decimalDigits: 3)}',
                            style: AppText.tabular(AppText.small),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimens.gap8),
                    Text(
                      formatMoney(item['totalPrice']),
                      style: AppText.tabular(AppText.secondaryBold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Divider(height: 1, color: AppColors.border),
        Padding(
          padding: EdgeInsets.all(layout.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('to_pay').toUpperCase(), style: AppText.caption),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${formatMoney(model.totalPrice)} ${model.currencyName}',
                        style: AppText.amount.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.gap12),
              SizedBox(
                height: layout.primaryButtonHeight,
                child: AppButton(
                  label: context.tr('to_receipt'),
                  onPressed: () => context.read<DashboardModel>().setCurrentIndex(0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Шапка каталога: заголовок и поиск на белой подложке.
  ///
  /// Подложка тянется под статус-бар и отделена от списка бордером — так поиск
  /// читается как закреплённая панель, а не как первый элемент ленты.
  Widget _topBar() {
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
          child: Column(
            children: [
              _header(),
              _searchRow(),
              const SizedBox(height: AppDimens.gap12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimens.gutter, AppDimens.gap12, AppDimens.gutter, AppDimens.gap4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr('products'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.h1.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          if (products.isNotEmpty)
            Text(
              '${context.tr('total')}: ${products.length}',
              style: AppText.tabular(AppText.secondary),
            ),
        ],
      ),
    );
  }

  Widget _searchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimens.gutter, AppDimens.gap8, AppDimens.gutter, 0),
      child: Row(
        children: [
          Expanded(
            child: AppSearchField(
              controller: textEditingController,
              hint: '${context.tr('search_by_name')}, ${context.tr('barcode')}',
              onChanged: searchProducts,
            ),
          ),
          const SizedBox(width: AppDimens.gap8),
          AppIconButton(
            icon: Icons.qr_code_scanner,
            background: AppColors.primarySoft,
            foreground: AppColors.primary,
            size: AppDimens.heightMedium,
            iconSize: 22,
            onPressed: getQrCode,
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return Consumer<LoadingModel>(
      builder: (context, loadingModel, child) {
        if (loadingModel.currentLoading == 1) {
          return const Center(child: AppLoader());
        }
        if (products.isEmpty) {
          final query = textEditingController.text;
          if (query.isEmpty) {
            return AppEmptyState(
              icon: Icons.search,
              title: context.tr('EMPTY_LIST'),
              text: context.tr('enter_name_to_search_for_products'),
            );
          }
          return AppEmptyState(
            icon: Icons.search_off,
            title: context.tr('NOT_FOUND'),
            text: context.tr('nothing_found_for', args: [query]),
          );
        }

        final layout = context.layout;
        final padding = EdgeInsets.fromLTRB(
          layout.gutter,
          AppDimens.gap4,
          layout.gutter,
          AppDimens.gap24,
        );

        Widget tile(int i) => _ProductTile(
              item: products[i],
              price: _price(products[i]),
              currency: _sale.currencyName,
              balance: _balance(products[i]),
              inCart: _inCart(products[i]),
              onAdd: () => addProductToList(i),
              onQuantityChanged: (value) => _applyQuantity(i, value),
              onTap: () => _openQuantitySheet(i),
            );

        // На планшете карточки встают сеткой: одна колонка на 1000 px
        // оставляла бы половину экрана пустой.
        if (layout.isTablet) {
          return GridView.builder(
            padding: padding,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: layout.productTileMaxWidth,
              mainAxisSpacing: AppDimens.gap8,
              crossAxisSpacing: AppDimens.gap8,
              mainAxisExtent: layout.productTileHeight,
            ),
            itemCount: products.length,
            itemBuilder: (context, i) => tile(i),
          );
        }

        return ListView.separated(
          padding: padding,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: products.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppDimens.gap8),
          itemBuilder: (context, i) => tile(i),
        );
      },
    );
  }

  /// Цена по активному режиму: 1 — оптовая, 2 — банковская, иначе розничная.
  dynamic _price(dynamic item) {
    return switch (_sale.data['activePrice']) {
      1 => item['wholesalePrice'],
      2 => item['bankPrice'],
      _ => item['salePrice'],
    };
  }

  /// Свободный остаток: со склада вычитаем то, что уже набрано в чек.
  double _balance(dynamic item) => customNumber(item['balance']) - _inCart(item);

  /// Переход к чеку — пока в нём что-то есть.
  Widget _cartBar() {
    final model = _sale;
    if (model.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.gap12),
        child: AppButton(
          label: '${context.tr('to_receipt')} · ${formatMoney(model.totalPrice)} ${model.currencyName}',
          onPressed: () => context.read<DashboardModel>().setCurrentIndex(0),
        ),
      ),
    );
  }
}

/// Карточка товара: название, цена, остаток и штрих-код + кнопка добавления.
class _ProductTile extends StatelessWidget {
  final Map item;
  final dynamic price;
  final String currency;
  final double balance;
  final double inCart;
  final VoidCallback onAdd;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onTap;

  const _ProductTile({
    required this.item,
    required this.price,
    required this.currency,
    required this.balance,
    required this.inCart,
    required this.onAdd,
    required this.onQuantityChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final barcode = '${item['barcode'] ?? ''}';
    final added = inCart > 0;

    return AppCard(
      onTap: onTap,
      selected: added,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppDimens.gap12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                  style: AppText.bodyMedium,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${formatMoney(price)} $currency',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.price,
                      ),
                    ),
                    const SizedBox(width: AppDimens.gap8),
                    _BalanceBadge(balance: balance),
                  ],
                ),
                if (barcode.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    barcode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.tabular(AppText.small),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimens.gap12),
          // Кнопка и степпер одной высоты — карточка не «прыгает» при добавлении.
          SizedBox(
            height: AppDimens.heightSmall,
            child: added && inCart == inCart.roundToDouble()
                ? AppStepper(
                    value: inCart.round(),
                    min: 0,
                    height: AppDimens.heightSmall,
                    onChanged: onQuantityChanged,
                  )
                : AppButton.soft(
                    label: context.tr('add'),
                    icon: Icons.add,
                    onPressed: onAdd,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Остаток на складе: мало — предупреждение, ноль и минус — ошибка.
class _BalanceBadge extends StatelessWidget {
  final double balance;

  const _BalanceBadge({required this.balance});

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (balance) {
      <= 0 => (AppColors.dangerSoft, AppColors.dangerText),
      < 5 => (AppColors.warningSoft, AppColors.warningText),
      _ => (AppColors.successSoft, AppColors.successText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap8, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: AppDimens.pill),
      child: Text(
        '${context.tr('residue_short')} ${formatMoney(balance)}',
        maxLines: 1,
        style: AppText.tabular(AppText.small).copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Лист выбора количества перед добавлением в чек.
class _QuantitySheet extends StatefulWidget {
  final String title;
  final double balance;

  const _QuantitySheet({required this.title, required this.balance});

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: AppText.h2, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: AppDimens.gap4),
        Text(
          '${context.tr('residue')}: ${formatMoney(widget.balance)}',
          style: AppText.tabular(AppText.secondary),
        ),
        const SizedBox(height: AppDimens.gap16),
        AppSectionLabel(context.tr('quantity')),
        const SizedBox(height: AppDimens.gap8),
        Row(
          children: [
            AppStepper(
              value: _quantity,
              min: 1,
              onChanged: (value) => setState(() => _quantity = value),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.gap16),
        AppButton(
          label: context.tr('add'),
          onPressed: () => Navigator.of(context).pop(_quantity),
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
