import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/state/data_model.dart';
import 'package:flutter_mdokon/core/state/loading_model.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/domain/scanned_input.dart';
import 'package:flutter_mdokon/features/cashier/models/sale_model.dart';
import 'package:flutter_mdokon/shared/widgets/scanner/barcode_scanner_page.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Каталог товаров: поиск по названию/штрих-коду и добавление позиций в чек.
///
/// Кнопка «Добавить» на карточке кладёт в чек одну единицу — это основной
/// сценарий кассы. Тап по самой карточке открывает лист с количеством, когда
/// нужно больше одной штуки. Набранное уходит в [DataModel]; экран продажи
/// забирает список после возврата.
class Search extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const Search({
    super.key,
    required this.arguments,
  });

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final GetStorage storage = GetStorage();
  final TextEditingController textEditingController = TextEditingController();
  Timer? _debounce;

  List products = [];
  List<Map<String, dynamic>> productsList = [];

  Map cashbox = {};

  /// Количества, уже лежащие в чеке на момент открытия каталога, по balanceId.
  /// Каталог показывает их в степпере, чтобы товар не выглядел «не добавленным».
  final Map<dynamic, double> _inCheque = {};

  /// Сумма чека на момент открытия — база для подписи нижней кнопки.
  double _chequeTotal = 0;

  @override
  void initState() {
    super.initState();
    cashbox = (storage.read('cashbox')!);

    final sale = Provider.of<SaleModel>(context, listen: false);
    for (final item in sale.items) {
      _inCheque[item['balanceId']] = customNumber(item['quantity']);
    }
    _chequeTotal = sale.totalPrice;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    textEditingController.dispose();
    super.dispose();
  }

  // --- Данные ------------------------------------------------------------

  void searchProducts(dynamic value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
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
            '/services/desktop/api/get-balance-product-list-mobile/${cashbox['posId']}/${widget.arguments!['currencyId']}?search=$term',
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
            // Остаток режем уже после фильтра: позиция из чека не должна
            // пропасть из выдачи только потому, что её всю набрали.
            _restoreCartState(response[i]);
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

  /// Итоговое количество позиции: набранное здесь либо уже лежащее в чеке.
  double _inCart(dynamic item) {
    final index = productsList.indexWhere((e) => e['balanceId'] == item['balanceId']);
    if (index >= 0) return customNumber(productsList[index]['quantity']);
    return _inCheque[item['balanceId']] ?? 0;
  }

  /// Найденный товар может уже лежать в чеке — показываем его как добавленный
  /// и сразу вычитаем это количество из остатка.
  void _restoreCartState(dynamic item) {
    final quantity = _inCart(item);
    if (quantity <= 0) return;
    item['originalBalance'] = item['balance'];
    item['balance'] = customNumber(item['balance']) - quantity;
    item['quantity'] = quantity;
  }

  /// Выставляет итоговое количество позиции (чек + набранное здесь).
  ///
  /// Буфер [productsList] всегда хранит абсолютное количество: экран продажи
  /// заменяет им количество строки чека, а не прибавляет к нему.
  bool _applyQuantity(int i, num quantity) {
    final product = products[i];
    final original = customNumber(product['originalBalance'] ?? product['balance']);
    product['originalBalance'] = original;

    if (quantity > original) {
      if (cashbox['saleMinus'] == null || !cashbox['saleMinus']) {
        showDangerToast('${product['productName']} превышает остаток');
        return false;
      }
    }

    final index = productsList.indexWhere((item) => item['balanceId'] == product['balanceId']);
    if (quantity <= 0) {
      if (index >= 0) productsList.removeAt(index);
      product['quantity'] = 1;
      product['balance'] = original;
    } else {
      product['selected'] = false;
      product['quantity'] = quantity;
      product['balance'] = original - quantity;
      if (index >= 0) {
        productsList[index]['quantity'] = quantity;
      } else {
        productsList.add(Map<String, dynamic>.from(product));
      }
    }

    Vibration.vibrate(amplitude: 10, duration: 30);
    Provider.of<DataModel>(context, listen: false).setProductList(productsList);
    setState(() {});
    return true;
  }

  void addProductToList(dynamic i, {num quantity = 1}) {
    if (!_applyQuantity(i, _inCart(products[i]) + quantity)) return;

    // «Убрать» откатывает ровно то количество, что добавили этим действием.
    final label = quantity > 1
        ? '${products[i]['productName']} × ${formatMoney(quantity)} · ${context.tr('added')}'
        : '${products[i]['productName']} · ${context.tr('added')}';
    final balanceId = products[i]['balanceId'];
    showActionToast(
      context,
      label,
      actionLabel: context.tr('remove'),
      onAction: () => _undoAdd(balanceId, quantity),
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
        balance: customNumber(item['balance']),
      ),
    );
    if (quantity != null && quantity > 0) addProductToList(i, quantity: quantity);
  }

  // --- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            _searchRow(),
            const SizedBox(height: AppDimens.gap12),
            Expanded(child: _content()),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimens.gap8, AppDimens.gap8, AppDimens.gutter, AppDimens.gap4),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.arrow_back,
            background: Colors.transparent,
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              context.tr('catalog'),
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
              autofocus: true,
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

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.gutter,
            AppDimens.gap4,
            AppDimens.gutter,
            AppDimens.gap24,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: products.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppDimens.gap8),
          itemBuilder: (context, i) => _ProductTile(
            item: products[i],
            price: _price(products[i]),
            currency: '${widget.arguments!['currencyName']}',
            inCart: _inCart(products[i]),
            // Позицию, пришедшую из чека, отсюда не убираем — только правим.
            minQuantity: _inCheque.containsKey(products[i]['balanceId']) ? 1 : 0,
            onAdd: () => addProductToList(i),
            onQuantityChanged: (value) => _applyQuantity(i, value),
            onTap: () => _openQuantitySheet(i),
          ),
        );
      },
    );
  }

  /// Цена по активному режиму: 1 — оптовая, 2 — банковская, иначе розничная.
  dynamic _price(dynamic item) {
    return switch (widget.arguments!['activePrice']) {
      1 => item['wholesalePrice'],
      2 => item['bankPrice'],
      _ => item['salePrice'],
    };
  }

  /// Сумма чека с учётом набранного здесь: к сумме на входе прибавляем
  /// только разницу по изменённым позициям.
  double _cartTotal() {
    var total = _chequeTotal;
    for (final item in productsList) {
      final delta = customNumber(item['quantity']) - (_inCheque[item['balanceId']] ?? 0);
      total += customNumber(_price(item)) * delta;
    }
    return total;
  }

  /// Панель видна, пока в чеке что-то есть, — и когда поиск пуст тоже.
  Widget? _bottomBar() {
    if (productsList.isEmpty && _inCheque.isEmpty) return null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.gap12),
          child: AppButton(
            label: '${context.tr('to_receipt')} · ${formatMoney(_cartTotal())} ${widget.arguments!['currencyName']}',
            onPressed: () => context.pop(),
          ),
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
  final double inCart;
  final int minQuantity;
  final VoidCallback onAdd;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onTap;

  const _ProductTile({
    required this.item,
    required this.price,
    required this.currency,
    required this.inCart,
    required this.minQuantity,
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
                    _BalanceBadge(balance: customNumber(item['balance'])),
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
                    min: minQuantity,
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
