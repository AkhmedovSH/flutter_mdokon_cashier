import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/domain/scale_barcode.dart';

void main() {
  const format7 = ScaleSettings();
  const format6 = ScaleSettings(format: 6);

  group('parseScaleBarcode — формат 7', () {
    test('весовой префикс: код товара и вес в килограммах', () {
      // 20 | 01234 | 03445 | 7 → товар 1234, 3.445 кг
      final scanned = parseScaleBarcode('2001234034457', format7);

      expect(scanned, isNotNull);
      expect(scanned!.productCode, 1234);
      expect(scanned.quantity, closeTo(3.445, 0.0001));
      expect(scanned.byWeight, isTrue);
    });

    test('штучный префикс: количество из двух цифр перед контрольной', () {
      // 21 | 01234 | 000 | 07 | 7 → товар 1234, 7 штук
      final scanned = parseScaleBarcode('2101234000077', format7);

      expect(scanned!.productCode, 1234);
      expect(scanned.quantity, 7);
      expect(scanned.byWeight, isFalse);
    });
  });

  group('parseScaleBarcode — формат 6', () {
    test('код и вес сдвинуты на цифру вправо', () {
      // 200 | 12345 | 3445 | 7 → товар 12345, 3.445 кг
      final scanned = parseScaleBarcode('2001234534457', format6);

      expect(scanned!.productCode, 12345);
      expect(scanned.quantity, closeTo(3.445, 0.0001));
    });
  });

  group('parseScaleBarcode — не штрих-код весов', () {
    test('чужой префикс', () {
      expect(parseScaleBarcode('4601234034457', format7), isNull);
    });

    test('обычный EAN-8', () {
      expect(parseScaleBarcode('20012347', format7), isNull);
    });

    test('нецифровая строка той же длины', () {
      expect(parseScaleBarcode('20ABCDE034457', format7), isNull);
    });

    test('пустая строка', () {
      expect(parseScaleBarcode('', format7), isNull);
    });

    test('свои префиксы из настроек', () {
      const custom = ScaleSettings(weightPrefix: 26, piecePrefix: 27);

      expect(parseScaleBarcode('2601234034457', custom), isNotNull);
      expect(parseScaleBarcode('2001234034457', custom), isNull);
    });
  });

  group('scaleQuantityFor', () {
    ScaleBarcode weight(double value) =>
        ScaleBarcode(productCode: 1, quantity: value, byWeight: true);

    test('весовой товар получает дробный вес как есть', () {
      expect(scaleQuantityFor(weight(3.445), uomId: 2), closeTo(3.445, 0.0001));
    });

    test('штучный товар округляется вниз до целого', () {
      expect(scaleQuantityFor(weight(3.445), uomId: 1), 3);
    });

    test('нулевой вес превращается в одну единицу', () {
      // Иначе сканирование выглядит как несработавшее: позиция не появится.
      expect(scaleQuantityFor(weight(0), uomId: 2), 1);
      expect(scaleQuantityFor(weight(0.4), uomId: 1), 1);
    });

    test('штучный префикс не округляется по uomId', () {
      const scanned = ScaleBarcode(productCode: 1, quantity: 7, byWeight: false);

      expect(scaleQuantityFor(scanned, uomId: 1), 7);
    });
  });
}
