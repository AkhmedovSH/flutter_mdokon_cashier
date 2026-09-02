/// Боковая колонка быстрого выбора (`src/components/cashbox/Rightbar.js`).
///
/// Здесь только фильтрация набора «быстрый подбор»: какой список товаров и
/// какие категории видны при заданном поиске и открытой категории. Сеть и
/// виджеты сюда не заглядывают — раскладку проверяют тесты без запуска UI.
library;

/// Вид колонки. Порядок совпадает с рельсой иконок у десктопа.
enum QuickRailView {
  /// Плоский список набора «быстрый подбор».
  list,

  /// Витрина карточками с картинками.
  showcase,

  /// Категории набора с переходом внутрь.
  groups,

  /// Цифровая клавиатура: набрать код товара пальцем.
  keys,
}

/// Категория позиции набора. Пустая строка — псевдокатегория «Обычные»:
/// на бэкенде записи нет, туда попадает всё без `categoryId`.
String quickCategoryId(Map item) =>
    '${item['categoryId'] ?? item['selectedProductCategoryId'] ?? ''}';

/// Имя категории — ключ у списка категорий и у самой записи разный.
String quickCategoryName(Map category) =>
    '${category['categoryName'] ?? category['name'] ?? ''}';

/// Идентификатор категории из справочника.
String quickCategoryKey(Map category) =>
    '${category['id'] ?? category['categoryId'] ?? ''}';

/// Позиции набора под текущий вид, поиск и открытую категорию.
///
/// В списке ([QuickRailView.list]) категория не при чём: кассир видит весь
/// набор сразу. В группах — только содержимое открытой категории, а пока
/// категория не выбрана, товаров не показываем вовсе: там стоят папки.
List<Map> filterQuickItems(
  List<Map> items, {
  String search = '',
  String categoryId = '',
  QuickRailView view = QuickRailView.list,
}) {
  final needle = search.trim().toLowerCase();

  return items.where((item) {
    final matchesCategory =
        view == QuickRailView.list || quickCategoryId(item) == categoryId;
    if (!matchesCategory) return false;
    if (needle.isEmpty) return true;

    final name = '${item['productName'] ?? ''}'.toLowerCase();
    final barcode = '${item['productBarcode'] ?? ''}'.toLowerCase();
    return name.contains(needle) || barcode.contains(needle);
  }).toList();
}

/// Категории, которые видно на экране групп.
///
/// Внутри открытой категории список папок не нужен — там уже товары.
List<Map> filterQuickCategories(
  List<Map> categories, {
  String search = '',
  String activeCategoryId = '',
}) {
  if (activeCategoryId.isNotEmpty) return const [];

  final needle = search.trim().toLowerCase();
  if (needle.isEmpty) return List.of(categories);

  return categories
      .where((category) => quickCategoryName(category).toLowerCase().contains(needle))
      .toList();
}

/// Сколько позиций набора лежит в категории — подпись на карточке папки.
int countQuickItems(List<Map> items, String categoryId) =>
    items.where((item) => quickCategoryId(item) == categoryId).length;
