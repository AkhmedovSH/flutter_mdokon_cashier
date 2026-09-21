import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';

/// Данные боковой колонки быстрого выбора.
///
/// Набор «быстрый подбор» лежит там же, откуда его редактирует экран
/// настроек, — колонка только читает. Витрина у десктопа берётся из локальной
/// базы товаров; у мобилки базы нет, поэтому и карточки, и поиск по ним
/// уходят на сервер тем же запросом по остаткам, что и каталог.
class QuickRailRepository {
  const QuickRailRepository();

  /// Позиции набора, в порядке, заданном на экране «Быстрый подбор».
  Future<List<Map>> items({required dynamic posId, required dynamic cashboxId}) async {
    final response = await get('/services/desktop/api/selected-products-list/$posId/$cashboxId');
    if (response is! List) return const [];

    final items = [for (final item in response) if (item is Map) Map.of(item)];
    items.sort((a, b) => customNumber(a['order']).compareTo(customNumber(b['order'])));
    return items;
  }

  /// Категории набора.
  Future<List<Map>> categories({required dynamic posId, required dynamic cashboxId}) async {
    final response = await get(
      '/services/desktop/api/selected-product-categories-list/$posId/$cashboxId',
    );
    if (response is! List) return const [];
    return [for (final item in response) if (item is Map) Map.of(item)];
  }

  /// Остатки точки: карточки витрины, цены набора и добавление по коду.
  ///
  /// Пустой [query] отдаёт весь остаток — это и есть «все товары» витрины,
  /// то же, что десктоп читает из локальной базы. Строки приходят партиями,
  /// как есть: добавлению по коду важно перебрать их все, а схлопывает их
  /// только витрина ([uniqueByBarcode]).
  Future<List<Map<String, dynamic>>> balance({
    required dynamic posId,
    required dynamic currencyId,
    String query = '',
  }) async {
    final response = await get(
      '/services/desktop/api/get-balance-product-list-mobile/$posId/$currencyId?search=$query',
    );
    if (response is! List) return const [];
    return [for (final row in response) if (row is Map) Map<String, dynamic>.from(row)];
  }

  /// По одной строке на штрих-код — карточки витрины.
  ///
  /// Партий у товара бывает несколько, а плитка нужна одна: у десктопа в
  /// локальной базе на товар тоже одна запись. Оставляем первую — её цену
  /// десктоп и показывает.
  List<Map<String, dynamic>> uniqueByBarcode(List<Map<String, dynamic>> rows) {
    final byBarcode = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final barcode = '${row['barcode'] ?? ''}';
      if (barcode.isEmpty) continue;
      byBarcode.putIfAbsent(barcode, () => row);
    }
    return byBarcode.values.toList();
  }

  /// Цены из остатка: «штрих-код → цена продажи».
  ///
  /// Сам набор цен не отдаёт, а локальной базы, из которой их берёт десктоп,
  /// у мобилки нет — берём их из тех же строк, что и витрина.
  Map<String, dynamic> pricesOf(List<Map<String, dynamic>> rows) => {
        for (final row in uniqueByBarcode(rows)) '${row['barcode']}': row['salePrice'],
      };
}
