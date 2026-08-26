import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/domain/cheque_format.dart';

/// Чек в том виде, в каком его держит касса во время продажи:
/// `totalPrice` — НЕТТО (к оплате), скидка уже вычтена.
Map<String, dynamic> netCheque() => {
      'totalPrice': 90000,
      'totalPriceBeforeDiscount': 100000,
      'discountAmount': 10000,
      'discount': 10,
      'itemsList': [
        {
          'productName': 'A',
          'totalPrice': 54000,
          'totalPriceBeforeDiscount': 60000,
          'discountAmount': 6000,
        },
        {
          'productName': 'B',
          'totalPrice': 36000,
          'totalPriceBeforeDiscount': 40000,
          'discountAmount': 4000,
        },
      ],
    };

void main() {
  group('toGrossCheque', () {
    test('чек переводится в БРУТТО, скидка остаётся отдельной суммой', () {
      final gross = toGrossCheque(netCheque());

      expect(gross['totalPrice'], 100000);
      expect(gross['discountAmount'], 10000);
    });

    test('позиции тоже переводятся в БРУТТО', () {
      final gross = toGrossCheque(netCheque());
      final items = gross['itemsList'] as List;

      expect(items[0]['totalPrice'], 60000);
      expect(items[1]['totalPrice'], 40000);
    });

    test('печать не вычитает скидку дважды', () {
      final gross = toGrossCheque(netCheque());

      // Так считает `К оплате` printer_model.dart.
      final toPay = (gross['totalPrice'] as num) - (gross['discountAmount'] as num);
      expect(toPay, 90000, reason: 'должно совпасть с НЕТТО исходного чека');
    });

    test('чек без скидки не меняет сумму', () {
      final gross = toGrossCheque({
        'totalPrice': 50000,
        'totalPriceBeforeDiscount': 0,
        'itemsList': [
          {'totalPrice': 50000, 'totalPriceBeforeDiscount': 0},
        ],
      });

      expect(gross['totalPrice'], 50000);
      expect(gross['discountAmount'], 0);
      expect((gross['itemsList'] as List)[0]['totalPrice'], 50000);
    });

    test('исходный чек не мутируется', () {
      final source = netCheque();
      toGrossCheque(source);

      expect(source['totalPrice'], 90000);
      expect((source['itemsList'] as List)[0]['totalPrice'], 54000);
    });

    test('пустой чек переживает конвертацию', () {
      final gross = toGrossCheque({'totalPrice': 0, 'itemsList': []});

      expect(gross['totalPrice'], 0);
      expect(gross['itemsList'], isEmpty);
    });
  });
}
