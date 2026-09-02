/// Обработка результата поиска товара перед показом кассиру.
///
/// На десктопе то же самое делает локальная база (`findProducts` получает
/// `searchExact` и `productGrouping` параметрами). У мобилки базы нет — она
/// спрашивает сервер, поэтому обе настройки применяются к уже полученному
/// списку. Функции чистые: сеть и Flutter здесь не нужны.
library;

import 'package:flutter_mdokon/core/utils/helper.dart';

/// Точный поиск: оставить только позиции, где запрос совпал целиком — со
/// штрих-кодом, артикулом или названием.
///
/// Сервер ищет подстрокой, и на коротком штрих-коде это даёт десяток похожих
/// карточек. Если точного совпадения нет вовсе, список возвращается как есть:
/// пустой экран вместо найденного товара кассиру не поможет.
List<dynamic> applyExactSearch(List<dynamic> products, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return products;

  final exact = products.where((item) {
    final map = item as Map;
    return [map['barcode'], map['article'], map['productName']]
        .map((value) => '${value ?? ''}'.trim().toLowerCase())
        .any((value) => value.isNotEmpty && value == needle);
  }).toList();

  return exact.isEmpty ? products : exact;
}

/// Группировка: свести партии одного товара в одну строку с общим остатком.
///
/// Сервер отдаёт остатки по партиям (`balanceId`), и один и тот же товар из
/// двух приходов выглядит как два одинаковых пункта. С группировкой кассир
/// видит одну карточку; в чек уходит партия с наибольшим остатком — её хватит
/// на большее количество без ухода в минус.
List<dynamic> applyProductGrouping(List<dynamic> products) {
  final grouped = <String, Map>{};
  final order = <String>[];

  for (final item in products) {
    final map = item as Map;
    final key = '${map['productId'] ?? map['balanceId']}';

    final existing = grouped[key];
    if (existing == null) {
      grouped[key] = Map.from(map);
      order.add(key);
      continue;
    }

    final total = customNumber(existing['balance']) + customNumber(map['balance']);
    // Ведущей делаем партию с большим остатком: её цена и `balanceId` и уедут
    // в чек, а остаток показываем суммарный.
    if (customNumber(map['balance']) > customNumber(existing['balance'])) {
      grouped[key] = Map.from(map);
    }
    grouped[key]!['balance'] = total;
  }

  return [for (final key in order) grouped[key]!];
}
