import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/shared/widgets/custom_app_bar.dart';

/// Экран поиска товаров для «Быстрого подбора».
///
/// Возвращает через `pop` список выбранных товаров — каждая позиция уже
/// приведена к виду, который ждёт бэкенд (`productId`, `productName`,
/// `productBarcode`, `salePrice`). Экран ничего не сохраняет сам: набор
/// живёт на [QuickSelection], а здесь только выбирают.
class QuickSelectionPicker extends StatefulWidget {
  /// Штрих-коды, которые уже лежат в наборе, — чтобы не добавить дважды.
  final Set<String> addedBarcodes;

  const QuickSelectionPicker({super.key, this.addedBarcodes = const {}});

  @override
  State<QuickSelectionPicker> createState() => _QuickSelectionPickerState();
}

class _QuickSelectionPickerState extends State<QuickSelectionPicker> {
  final GetStorage storage = GetStorage();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  Map cashbox = {};
  List _products = const [];

  /// Штрих-код → выбранный товар. Map, чтобы повторный тап снимал выбор.
  final Map<String, Map> _picked = {};

  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    cashbox = storage.read('cashbox') ?? {};
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- Данные ------------------------------------------------------------

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _products = const [];
        _searched = false;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);

    final response = await get(
      '/services/desktop/api/get-balance-product-list-mobile/'
      '${cashbox['posId']}/${cashbox['defaultCurrency']}?search=$query',
    );
    if (!mounted) return;

    var rows = response is List ? response : const [];
    if (rows.length > 50) rows = rows.sublist(0, 50);

    setState(() {
      _products = rows;
      _loading = false;
      _searched = true;
    });
  }

  // --- Выбор -------------------------------------------------------------

  void _toggle(dynamic item) {
    final barcode = '${item['barcode'] ?? ''}';
    if (widget.addedBarcodes.contains(barcode)) return;

    setState(() {
      if (_picked.containsKey(barcode)) {
        _picked.remove(barcode);
      } else {
        _picked[barcode] = {
          'productId': item['productId'] ?? item['id'],
          'productName': '${item['productName'] ?? ''}',
          'productBarcode': barcode,
          'salePrice': item['salePrice'],
        };
      }
    });
  }

  void _submit() {
    context.pop(_picked.values.toList());
  }

  // --- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: CustomAppBar(title: 'add_products', leading: true),
      body: Column(
        children: [
          _searchField(),
          const SizedBox(height: AppDimens.gap12),
          Expanded(child: _body()),
        ],
      ),
      bottomNavigationBar: _picked.isEmpty ? null : _footer(),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          _debounce?.cancel();
          final query = value.trim();
          if (query.isNotEmpty) _search(query);
        },
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.surface,
          hintText: context.tr('search_by_name_or_barcode'),
          hintStyle: const TextStyle(color: AppColors.iconMuted, fontSize: 15),
          prefixIcon: const Icon(Icons.search, color: AppColors.iconMuted, size: 20),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.gap12,
            vertical: AppDimens.gap12,
          ),
          border: const OutlineInputBorder(
            borderRadius: AppDimens.control,
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppDimens.control,
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppDimens.control,
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (!_searched) {
      return _EmptyHint(
        icon: Icons.search,
        title: context.tr('enter_search_query'),
      );
    }

    if (_products.isEmpty) {
      return _EmptyHint(
        icon: Icons.inbox_outlined,
        title: context.tr('nothing_found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        0,
        AppDimens.gutter,
        AppDimens.gap24,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final item = _products[index];
        final barcode = '${item['barcode'] ?? ''}';
        final added = widget.addedBarcodes.contains(barcode);
        final picked = _picked.containsKey(barcode);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.gap8),
          child: Material(
            color: picked ? AppColors.primarySoft : AppColors.surface,
            borderRadius: AppDimens.card,
            child: InkWell(
              borderRadius: AppDimens.card,
              onTap: added ? null : () => _toggle(item),
              child: Container(
                padding: const EdgeInsets.all(AppDimens.gap12),
                decoration: BoxDecoration(
                  borderRadius: AppDimens.card,
                  border: Border.all(
                    color: picked ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['productName'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: added ? AppColors.textSecondary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppDimens.gap4),
                          Text(
                            added
                                ? '$barcode · ${context.tr('already_in_set')}'
                                : '$barcode · ${formatMoney(item['salePrice'])}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.iconMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimens.gap8),
                    Icon(
                      added
                          ? Icons.check_circle
                          : picked
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                      size: 24,
                      color: added
                          ? AppColors.successText
                          : picked
                              ? AppColors.primary
                              : AppColors.iconMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _footer() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gap8,
        AppDimens.gutter,
        AppDimens.gap12,
      ),
      child: SizedBox(
        height: AppDimens.heightLarge,
        child: FilledButton.icon(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: const RoundedRectangleBorder(borderRadius: AppDimens.control),
          ),
          icon: const Icon(Icons.add, size: 20),
          label: Text(
            '${context.tr('add')} · ${_picked.length}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;

  const _EmptyHint({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: AppColors.iconMuted),
            const SizedBox(height: AppDimens.gap12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
