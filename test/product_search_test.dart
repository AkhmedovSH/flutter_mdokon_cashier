import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/domain/product_search.dart';

void main() {
  List<Map<String, dynamic>> catalog() => [
        {'balanceId': 1, 'productId': 10, 'productName': 'Кола 0.5', 'barcode': '4780001', 'balance': 3},
        {'balanceId': 2, 'productId': 10, 'productName': 'Кола 0.5', 'barcode': '4780001', 'balance': 7},
        {'balanceId': 3, 'productId': 11, 'productName': 'Кола 1.5', 'barcode': '47800012', 'balance': 2},
      ];

  group('applyExactSearch', () {
    test('оставляет только полное совпадение штрих-кода', () {
      final found = applyExactSearch(catalog(), '4780001');

      expect(found.length, 2);
      expect(found.every((item) => item['productId'] == 10), isTrue);
    });

    test('совпадение по названию не зависит от регистра и пробелов', () {
      final found = applyExactSearch(catalog(), '  кола 1.5 ');

      expect(found.length, 1);
      expect(found.single['balanceId'], 3);
    });

    test('без точного совпадения возвращает исходный список', () {
      // Пустой экран вместо похожих товаров кассиру не помогает.
      final found = applyExactSearch(catalog(), '478');

      expect(found.length, 3);
    });

    test('пустой запрос ничего не фильтрует', () {
      expect(applyExactSearch(catalog(), '   ').length, 3);
    });
  });

  group('applyProductGrouping', () {
    test('партии одного товара сходятся в строку с общим остатком', () {
      final grouped = applyProductGrouping(catalog());

      expect(grouped.length, 2);
      expect(grouped.first['productId'], 10);
      expect(grouped.first['balance'], 10);
    });

    test('ведущей становится партия с большим остатком', () {
      final grouped = applyProductGrouping(catalog());

      expect(grouped.first['balanceId'], 2);
    });

    test('порядок товаров сохраняется', () {
      final grouped = applyProductGrouping(catalog());

      expect(grouped.map((item) => item['productId']).toList(), [10, 11]);
    });

    test('без productId группируем по партии — строки не склеиваются', () {
      final grouped = applyProductGrouping([
        {'balanceId': 1, 'balance': 1},
        {'balanceId': 2, 'balance': 1},
      ]);

      expect(grouped.length, 2);
    });

    test('пустой список остаётся пустым', () {
      expect(applyProductGrouping([]), isEmpty);
    });
  });
}
