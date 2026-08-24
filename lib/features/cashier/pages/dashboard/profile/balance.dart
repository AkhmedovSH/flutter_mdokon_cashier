import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/shared/widgets/custom_app_bar.dart';

/// Порог, ниже которого остаток считается «Мало».
const int _kLowStockThreshold = 5;

/// Фиксированная высота карточки — позволяет ListView считать
/// геометрию списка без layout-прохода по каждому элементу.
/// Значение подобрано под самый высокий вариант карточки: бейдж остатка +
/// цена продажи + оптовая цена (68px было на 1px мало).
const double _kRowExtent = 100;

const List<Color> _kPosColors = [
  Color(0xFF3B82F6),
  Color(0xFFE0564F),
  Color(0xFF22A06B),
  Color(0xFFB7791F),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFFF97316),
];

enum _StockFilter { all, low, out }

/// Строка остатков со всеми предрассчитанными строками и цветами.
///
/// Форматирование денег и приведение к нижнему регистру для поиска
/// выполняются один раз при загрузке, а не на каждой перерисовке —
/// это то, что держит список плавным на 10 000 позиций.
class _BalanceRow {
  final String name;
  final String barcode;
  final String posName;
  final Color posColor;
  final double balance;
  final String balanceText;
  final String salePriceText;
  final String wholesalePriceText;
  final String haystack;

  const _BalanceRow({
    required this.name,
    required this.barcode,
    required this.posName,
    required this.posColor,
    required this.balance,
    required this.balanceText,
    required this.salePriceText,
    required this.wholesalePriceText,
    required this.haystack,
  });

  bool get isNegative => balance < 0;
  bool get isLow => balance > 0 && balance <= _kLowStockThreshold;
  bool get isOut => balance <= 0;
}

class Balance extends StatefulWidget {
  const Balance({super.key});

  @override
  State<Balance> createState() => _BalanceState();
}

class _BalanceState extends State<Balance> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<_BalanceRow> _all = const [];
  List<_BalanceRow> _visible = const [];
  List<String> _poses = const [];

  String _search = '';
  _StockFilter _stockFilter = _StockFilter.all;
  String? _posFilter;

  bool _loading = true;
  bool _failed = false;
  bool _hasQuery = false;

  int _lowCount = 0;
  int _outCount = 0;
  int _negativeCount = 0;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getData() async {
    setState(() {
      _loading = true;
      _failed = false;
    });

    final response = await get('/services/desktop/api/get-all-balance-product-list');
    if (!mounted) return;

    if (response is! List) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

    final posColors = <String, Color>{};
    final rows = <_BalanceRow>[];

    for (final item in response) {
      if (item is! Map) continue;

      final name = '${item['productName'] ?? ''}';
      final barcode = '${item['barcode'] ?? ''}';
      final posName = '${item['posName'] ?? ''}';
      final balance = customNumber(item['balance']);

      final posColor = posColors.putIfAbsent(
        posName,
        () => _kPosColors[posColors.length % _kPosColors.length],
      );

      rows.add(
        _BalanceRow(
          name: name,
          barcode: barcode,
          posName: posName,
          posColor: posColor,
          balance: balance,
          balanceText: formatQuantity(balance),
          salePriceText: formatMoney(item['salePrice']),
          wholesalePriceText: formatMoney(item['wholesalePrice']),
          haystack: '$name $barcode'.toLowerCase(),
        ),
      );
    }

    var low = 0;
    var out = 0;
    var negative = 0;
    for (final row in rows) {
      if (row.isNegative) negative++;
      if (row.isOut) {
        out++;
      } else if (row.isLow) {
        low++;
      }
    }

    setState(() {
      _all = rows;
      _poses = posColors.keys.toList();
      _lowCount = low;
      _outCount = out;
      _negativeCount = negative;
      _loading = false;
    });
    _applyFilters();
  }

  /// Пересчитывает видимый список. Вызывается только при смене фильтра
  /// или поискового запроса, но никак не из build().
  void _applyFilters() {
    final search = _search;
    final stockFilter = _stockFilter;
    final posFilter = _posFilter;

    final result = <_BalanceRow>[];
    for (final row in _all) {
      if (posFilter != null && row.posName != posFilter) continue;
      switch (stockFilter) {
        case _StockFilter.low:
          if (!row.isLow) continue;
        case _StockFilter.out:
          if (!row.isOut) continue;
        case _StockFilter.all:
          break;
      }
      if (search.isNotEmpty && !row.haystack.contains(search)) continue;
      result.add(row);
    }

    setState(() => _visible = result);

    if (_scrollController.hasClients && _scrollController.offset > 0) {
      _scrollController.jumpTo(0);
    }
  }

  void _onSearchChanged(String value) {
    // Кнопку очистки перерисовываем только на переходе «пусто ↔ не пусто»,
    // а не на каждом нажатии клавиши.
    if (_hasQuery != value.isNotEmpty) {
      setState(() => _hasQuery = value.isNotEmpty);
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final search = value.trim().toLowerCase();
      if (search == _search) return;
      _search = search;
      _applyFilters();
    });
  }

  void _setStockFilter(_StockFilter value) {
    if (_stockFilter == value) return;
    _stockFilter = value;
    _applyFilters();
  }

  void _setPosFilter(String? value) {
    if (_posFilter == value) return;
    _posFilter = value;
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: CustomAppBar(
        title: 'residues',
        leading: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppDimens.gap8),
              child: SizedBox(
                height: 36,
                child: TextButton(
                  onPressed: _loading ? null : _getData,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    shape: const RoundedRectangleBorder(borderRadius: AppDimens.pill),
                    side: const BorderSide(color: AppColors.primaryTint),
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap16),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    context.tr('refresh'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: AppDimens.gap12),
          _buildFilterChips(),
          const SizedBox(height: AppDimens.gap12),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.surface,
          hintText: context.tr('search_by_name_or_barcode'),
          hintStyle: const TextStyle(color: AppColors.iconMuted, fontSize: 15),
          prefixIcon: const Icon(Icons.search, color: AppColors.iconMuted, size: 20),
          suffixIcon: !_hasQuery
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: AppColors.iconMuted, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _debounce?.cancel();
                    _search = '';
                    _hasQuery = false;
                    _applyFilters();
                  },
                ),
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

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
        children: [
          _FilterChip(
            label: context.tr('all'),
            count: _all.length,
            selected: _stockFilter == _StockFilter.all,
            onTap: () => _setStockFilter(_StockFilter.all),
          ),
          _FilterChip(
            label: context.tr('low_stock'),
            count: _lowCount,
            selected: _stockFilter == _StockFilter.low,
            onTap: () => _setStockFilter(_StockFilter.low),
          ),
          _FilterChip(
            label: context.tr('out_of_stock'),
            count: _outCount,
            selected: _stockFilter == _StockFilter.out,
            onTap: () => _setStockFilter(_StockFilter.out),
          ),
          if (_poses.length > 1)
            for (final pos in _poses)
              _FilterChip(
                label: pos,
                selected: _posFilter == pos,
                onTap: () => _setPosFilter(_posFilter == pos ? null : pos),
              ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_failed) {
      return _EmptyState(
        title: context.tr('nothing_found'),
        hint: context.tr('report_change_filter'),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _getData,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.gutter,
                0,
                AppDimens.gutter,
                AppDimens.gap12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: context.tr('total_positions'),
                      value: formatMoney(_all.length),
                    ),
                  ),
                  const SizedBox(width: AppDimens.gap12),
                  Expanded(
                    child: _StatCard(
                      label: context.tr('negative_balance'),
                      value: formatMoney(_negativeCount),
                      suffix: context.tr('positions_short'),
                      valueColor: _negativeCount > 0 ? AppColors.dangerText : AppColors.successText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                title: context.tr('nothing_found'),
                hint: context.tr('report_change_filter'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.gutter,
                0,
                AppDimens.gutter,
                AppDimens.gap24,
              ),
              sliver: SliverFixedExtentList(
                itemExtent: _kRowExtent,
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _BalanceCard(row: _visible[index]),
                  childCount: _visible.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final Color valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.suffix,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.gap12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.card,
        boxShadow: AppDimens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimens.gap4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: AppDimens.gap4),
                Text(
                  suffix!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.gap8),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: AppDimens.pill,
        child: InkWell(
          borderRadius: AppDimens.pill,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppDimens.pill,
              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.onPrimary : AppColors.textPrimary,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: AppDimens.gap8),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? AppColors.primaryTint : AppColors.iconMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final _BalanceRow row;

  const _BalanceCard({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gap8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.gap12,
          vertical: AppDimens.gap8,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimens.card,
          boxShadow: AppDimens.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    row.barcode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.iconMuted),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: row.posColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppDimens.gap4),
                      Flexible(
                        child: Text(
                          row.posName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.gap8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StockBadge(row: row),
                Text(
                  row.salePriceText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${context.tr('wholesale_short')} ${row.wholesalePriceText}',
                  style: const TextStyle(fontSize: 12, color: AppColors.warningText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final _BalanceRow row;

  const _StockBadge({required this.row});

  @override
  Widget build(BuildContext context) {
    Color? background;
    var color = AppColors.textPrimary;

    if (row.isNegative) {
      background = AppColors.dangerSoft;
      color = AppColors.dangerText;
    } else if (row.balance <= _kLowStockThreshold) {
      background = AppColors.warningSoft;
      color = AppColors.warningText;
    }

    return Container(
      padding: background == null
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: AppDimens.gap8, vertical: 2),
      decoration: background == null
          ? null
          : BoxDecoration(color: background, borderRadius: AppDimens.pill),
      child: Text(
        row.balanceText,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String hint;

  const _EmptyState({required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.iconMuted),
          const SizedBox(height: AppDimens.gap12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.gap4),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
