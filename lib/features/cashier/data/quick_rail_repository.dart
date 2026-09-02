import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';

/// Данные боковой колонки быстрого выбора.
///
/// Набор «быстрый подбор» лежит там же, откуда его редактирует экран
/// настроек, — колонка только читает. Витрина у десктопа берётся из локальной
/// базы; у мобилки базы нет, поэтому поиск уходит на сервер тем же запросом,
/// что и каталог.
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

  /// Поиск по остаткам точки — витрина и добавление по коду.
  ///
  /// Список режем по [limit]: колонка узкая, а сервер на коротком запросе
  /// отдаёт сотни партий.
  Future<List<Map>> search({
    required dynamic posId,
    required dynamic currencyId,
    required String query,
    int limit = 50,
  }) async {
    final response = await get(
      '/services/desktop/api/get-balance-product-list-mobile/$posId/$currencyId?search=$query',
    );
    if (response is! List) return const [];

    final rows = [for (final item in response) if (item is Map) Map<String, dynamic>.from(item)];
    return rows.length > limit ? rows.sublist(0, limit) : rows;
  }
}
