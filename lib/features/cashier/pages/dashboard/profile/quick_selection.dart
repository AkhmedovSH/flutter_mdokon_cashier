import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/shared/widgets/custom_app_bar.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

const String _kProductsUrl = '/services/desktop/api/selected-products';
const String _kProductsListUrl = '/services/desktop/api/selected-products-list';
const String _kCategoriesUrl = '/services/desktop/api/selected-product-categories';
const String _kCategoriesListUrl = '/services/desktop/api/selected-product-categories-list';

/// Категория набора. Пустой [id] — «Обычные», псевдокатегория без записи
/// на бэкенде: туда попадают товары, у которых `categoryId` не задан.
class _Category {
  final String id;
  final String name;

  const _Category({required this.id, required this.name});

  bool get isDefault => id.isEmpty;

  factory _Category.fromJson(Map item, {String fallbackName = ''}) {
    return _Category(
      id: '${item['id'] ?? item['categoryId'] ?? ''}',
      name: '${item['categoryName'] ?? item['name'] ?? fallbackName}',
    );
  }
}

/// «Быстрый подбор» — набор товаров, которые касса показывает под рукой.
///
/// Экран держит весь набор в памяти: добавленные позиции живут локально
/// до нажатия «Сохранить набор», удаление сохранённой позиции уходит на
/// бэкенд сразу. Такой компромисс повторяет десктопную кассу: набирать
/// удобно пачкой, а удаление должно быть окончательным без лишнего шага.
class QuickSelection extends StatefulWidget {
  const QuickSelection({super.key});

  @override
  State<QuickSelection> createState() => _QuickSelectionState();
}

class _QuickSelectionState extends State<QuickSelection> {
  final GetStorage storage = GetStorage();

  /// Живёт вместе с экраном, а не с модалкой: лист успевает перерисоваться
  /// на анимации закрытия, и контроллер, убитый сразу после await, падает.
  final TextEditingController _categoryController = TextEditingController();

  Map cashbox = {};

  List<_Category> _categories = const [];
  List<Map> _items = [];

  String _activeCategoryId = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    cashbox = storage.read('cashbox') ?? {};
    _load();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  String get _posId => '${cashbox['posId']}';
  String get _cashboxId => '${cashbox['cashboxId']}';

  /// Позиции активной категории — единственный список, который видно на экране.
  List<Map> get _visible =>
      _items.where((item) => _categoryIdOf(item) == _activeCategoryId).toList();

  String _categoryIdOf(Map item) =>
      '${item['categoryId'] ?? item['selectedProductCategoryId'] ?? ''}';

  _Category get _activeCategory => _categories.firstWhere(
        (category) => category.id == _activeCategoryId,
        orElse: () => _Category(id: '', name: context.tr('regular_category')),
      );

  int _countIn(String categoryId) =>
      _items.where((item) => _categoryIdOf(item) == categoryId).length;

  // --- Данные ------------------------------------------------------------

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.wait([_loadCategories(), _loadItems()]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadCategories() async {
    final response = await get('$_kCategoriesListUrl/$_posId/$_cashboxId');
    if (!mounted || response is! List) return;

    final categories = <_Category>[];
    for (final item in response) {
      if (item is! Map) continue;
      final category = _Category.fromJson(item);
      if (category.id.isNotEmpty) categories.add(category);
    }

    setState(() {
      _categories = categories;
      // Категорию могли удалить в другом месте — не оставляем экран пустым.
      if (_activeCategoryId.isNotEmpty &&
          !categories.any((category) => category.id == _activeCategoryId)) {
        _activeCategoryId = '';
      }
    });
  }

  Future<void> _loadItems() async {
    final response = await get('$_kProductsListUrl/$_posId/$_cashboxId');
    if (!mounted || response is! List) return;

    final items = <Map>[];
    for (final item in response) {
      if (item is Map) items.add(Map.of(item));
    }
    items.sort((a, b) => customNumber(a['order']).compareTo(customNumber(b['order'])));

    setState(() => _items = items);
  }

  // --- Категории ---------------------------------------------------------

  Future<void> _addCategory() async {
    _categoryController.clear();
    final name = await AppModal.sheet<String>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('new_category'), style: AppText.h2),
          const SizedBox(height: AppDimens.gap16),
          AppInput(
            label: context.tr('category_name'),
            controller: _categoryController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              final text = value.trim();
              // Закрываем лист следующим кадром: pop прямо из обработчика
              // клавиши сносит InkWell'ы листа, пока фокус-менеджер ещё
              // разбирает то же нажатие, и тот лезет в мёртвое поддерево.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ctx.mounted) Navigator.of(ctx).pop(text);
              });
            },
          ),
          const SizedBox(height: AppDimens.gap16),
          AppButton(
            label: context.tr('add'),
            onPressed: () => Navigator.of(ctx).pop(_categoryController.text.trim()),
          ),
        ],
      ),
    );

    if (!mounted || name == null || name.isEmpty) return;

    final exists = _categories.any(
      (category) => category.name.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      showWarningToast(context.tr('category_exists'));
      return;
    }

    final response = await post(_kCategoriesUrl, {
      'posId': cashbox['posId'],
      'cashboxId': cashbox['cashboxId'],
      'categoryName': name,
    });
    if (!mounted || !httpOk(response)) return;

    if (response is Map) {
      final created = _Category.fromJson(response, fallbackName: name);
      if (created.id.isNotEmpty) {
        setState(() {
          _categories = [..._categories, created];
          _activeCategoryId = created.id;
        });
        return;
      }
    }

    // Бэкенд не вернул созданную запись — перечитываем список и находим её.
    await _loadCategories();
    if (!mounted) return;
    final created = _categories.where(
      (category) => category.name.toLowerCase() == name.toLowerCase(),
    );
    if (created.isNotEmpty) {
      setState(() => _activeCategoryId = created.first.id);
    }
  }

  Future<void> _deleteCategory(_Category category) async {
    final confirmed = await AppModal.confirm(
      context,
      title: context.tr('delete_category_question'),
      text: context.tr('delete_category_text'),
      note: category.name,
      confirmLabel: context.tr('delete'),
      cancelLabel: context.tr('cancel'),
      tone: AppModalTone.danger,
    );
    if (!mounted || !confirmed) return;

    final response = await del('$_kCategoriesUrl/${category.id}');
    if (!mounted || !httpOk(response)) return;

    // Сохранённые позиции категории удаляем поштучно: бэкенд не каскадит.
    final saved = _items
        .where((item) => _categoryIdOf(item) == category.id && item['id'] != null)
        .toList();
    for (final item in saved) {
      await del('$_kProductsUrl/${item['id']}');
    }
    if (!mounted) return;

    setState(() {
      _categories = _categories.where((row) => row.id != category.id).toList();
      _items = _items.where((item) => _categoryIdOf(item) != category.id).toList();
      if (_activeCategoryId == category.id) _activeCategoryId = '';
    });
  }

  // --- Позиции набора ----------------------------------------------------

  Future<void> _openPicker() async {
    final added = _items.map((item) => '${item['productBarcode'] ?? ''}').toSet();

    final picked = await context.push<List>(
      '/cashier/profile/quick-selection/picker',
      extra: added,
    );
    if (!mounted || picked == null || picked.isEmpty) return;

    setState(() {
      for (final row in picked) {
        if (row is! Map) continue;
        _items.add({
          'posId': cashbox['posId'],
          'cashboxId': cashbox['cashboxId'],
          'categoryId': _activeCategoryId.isEmpty ? null : _activeCategoryId,
          'order': _countIn(_activeCategoryId),
          'productId': row['productId'],
          'productName': row['productName'],
          'productBarcode': row['productBarcode'],
          'salePrice': row['salePrice'],
        });
      }
    });
  }

  Future<void> _deleteItem(Map item) async {
    if (item['id'] != null) {
      final response = await del('$_kProductsUrl/${item['id']}');
      if (!mounted || !httpOk(response)) return;
    }
    setState(() => _items.remove(item));
  }

  /// Поднимает позицию на строку выше внутри своей категории.
  void _moveUp(Map item) {
    final visible = _visible;
    final index = visible.indexOf(item);
    if (index <= 0) return;

    final previous = visible[index - 1];
    final from = _items.indexOf(item);
    final to = _items.indexOf(previous);

    setState(() {
      _items[from] = previous;
      _items[to] = item;
      // Порядок пересчитываем по всей категории, иначе новые позиции
      // с одинаковым order перемешаются после перезагрузки.
      final reordered = _visible;
      for (var i = 0; i < reordered.length; i++) {
        reordered[i]['order'] = i;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final created = _items.where((item) => item['id'] == null).toList();
    final existing = _items.where((item) => item['id'] != null).toList();

    var ok = true;
    if (created.isNotEmpty) {
      ok = httpOk(await post(_kProductsUrl, created));
    }
    // Порядок сохранённых позиций мог измениться стрелкой «вверх».
    for (final item in existing) {
      await put(_kProductsUrl, item);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (!ok) return;
    showSuccessToast(context.tr('saved_successfully'));
    await _loadItems();
  }

  // --- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: CustomAppBar(
        title: 'quick_selection',
        leading: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppDimens.gutter),
              child: Text(
                '${_visible.length} ${context.tr('in_set')}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _chipsRow(),
                const SizedBox(height: AppDimens.gap12),
                _searchButton(),
                const SizedBox(height: AppDimens.gap16),
                _sectionHeader(),
                const SizedBox(height: AppDimens.gap8),
                Expanded(child: _list()),
              ],
            ),
      bottomNavigationBar: _loading ? null : _footer(),
    );
  }

  Widget _chipsRow() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
        children: [
          _CategoryChip(
            label: context.tr('regular_category'),
            count: _countIn(''),
            selected: _activeCategoryId.isEmpty,
            onTap: () => setState(() => _activeCategoryId = ''),
          ),
          for (final category in _categories)
            _CategoryChip(
              label: category.name,
              count: _countIn(category.id),
              selected: _activeCategoryId == category.id,
              onTap: () => setState(() => _activeCategoryId = category.id),
            ),
          Material(
            color: AppColors.primarySoft,
            borderRadius: AppDimens.pill,
            child: InkWell(
              borderRadius: AppDimens.pill,
              onTap: _addCategory,
              child: const SizedBox(
                width: 44,
                child: Icon(Icons.add, size: 20, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Поиск на этом экране — вход в отдельный экран подбора, а не фильтр:
  /// товары ищутся на сервере, и держать их список рядом с набором незачем.
  Widget _searchButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppDimens.control,
        child: InkWell(
          borderRadius: AppDimens.control,
          onTap: _openPicker,
          child: Container(
            height: AppDimens.heightMedium,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12),
            decoration: BoxDecoration(
              borderRadius: AppDimens.control,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.iconMuted),
                const SizedBox(width: AppDimens.gap8),
                Expanded(
                  child: Text(
                    context.tr('search_by_name_or_barcode'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, color: AppColors.iconMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader() {
    final category = _activeCategory;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${context.tr('in_set_of')} «${category.name.toUpperCase()}»',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (!category.isDefault)
            AppButton(
              label: context.tr('delete_category'),
              variant: AppButtonVariant.danger,
              size: AppButtonSize.small,
              expanded: false,
              onPressed: () => _deleteCategory(category),
            ),
        ],
      ),
    );
  }

  Widget _list() {
    final visible = _visible;

    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.iconMuted),
              const SizedBox(height: AppDimens.gap12),
              Text(
                context.tr('set_empty_title'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimens.gap4),
              Text(
                context.tr('set_empty_text'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        0,
        AppDimens.gutter,
        AppDimens.gap24,
      ),
      itemCount: visible.length,
      itemBuilder: (context, index) => _SetRow(
        item: visible[index],
        position: index + 1,
        canMoveUp: index > 0,
        onMoveUp: () => _moveUp(visible[index]),
        onDelete: () => _deleteItem(visible[index]),
      ),
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
      child: AppButton(
        label: context.tr('save_set'),
        icon: Icons.save_outlined,
        loading: _saving,
        onPressed: _saving ? null : _save,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
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
            child: Text(
              count > 0 ? '$label · $count' : label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final Map item;
  final int position;
  final bool canMoveUp;
  final VoidCallback onMoveUp;
  final VoidCallback onDelete;

  const _SetRow({
    required this.item,
    required this.position,
    required this.canMoveUp,
    required this.onMoveUp,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final price = item['salePrice'];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gap8),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.gap12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimens.card,
          boxShadow: AppDimens.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppDimens.control,
              ),
              child: Text(
                '$position',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.gap12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['productName'] ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimens.gap4),
                  Text(
                    price == null
                        ? '${item['productBarcode'] ?? ''}'
                        : '${item['productBarcode'] ?? ''} · ${formatMoney(price)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.iconMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.gap8),
            _IconAction(
              icon: Icons.arrow_upward,
              color: AppColors.primary,
              background: AppColors.primarySoft,
              tooltip: context.tr('move_up'),
              onTap: canMoveUp ? onMoveUp : null,
            ),
            const SizedBox(width: AppDimens.gap8),
            _IconAction(
              icon: Icons.close,
              color: AppColors.dangerText,
              background: AppColors.dangerSoft,
              tooltip: context.tr('delete'),
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String tooltip;
  final VoidCallback? onTap;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.background,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? background : AppColors.divider,
        borderRadius: AppDimens.control,
        child: InkWell(
          borderRadius: AppDimens.control,
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 18,
              color: enabled ? color : AppColors.iconMuted,
            ),
          ),
        ),
      ),
    );
  }
}
