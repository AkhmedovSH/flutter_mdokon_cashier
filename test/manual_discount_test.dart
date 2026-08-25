import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mdokon/features/cashier/domain/manual_discount.dart';

// Порт src/helpers/__tests__/manualDiscount.test.js из desktop-кассы.

num sum(List<num> list) => list.fold<num>(0, (s, v) => s + v);

void main() {
  group('manualDiscountAmounts', () {
    group('F5 — процент на чек', () {
      test('считает процент от стоимости каждой позиции', () {
        expect(
            manualDiscountAmounts([50000, 15000], [],
                const ManualDiscount(ManualDiscountKey.f5, 10)),
            [5000, 1500]);
      });

      test('процент держится после смены количества', () {
        const md = ManualDiscount(ManualDiscountKey.f5, 10);
        final before = manualDiscountAmounts([50000, 15000], [], md);
        final after =
            manualDiscountAmounts([75000, 15000], [], md); // количество 2 → 3
        expect(sum(before) / 65000, closeTo(0.1, 1e-10));
        expect(sum(after) / 90000, closeTo(0.1, 1e-10));
      });

      test('процент больше 100 срезается до 100 — позиция не уходит в минус',
          () {
        expect(
            manualDiscountAmounts(
                [10000], [], const ManualDiscount(ManualDiscountKey.f5, 250)),
            [10000]);
      });
    });

    group('F6 — сумма на чек', () {
      test('раскидывает сумму пропорционально стоимости позиций', () {
        final amounts = manualDiscountAmounts([50000, 15000], [],
            const ManualDiscount(ManualDiscountKey.f6, 6500));
        expect(amounts[0], closeTo(5000, 1e-6));
        expect(amounts[1], closeTo(1500, 1e-6));
      });

      test('Σ по позициям равна введённой сумме даже при неделимом остатке', () {
        final amounts = manualDiscountAmounts([33333, 33333, 33334], [],
            const ManualDiscount(ManualDiscountKey.f6, 10000));
        expect(sum(amounts), closeTo(10000, 1e-10));
      });

      test('сумма скидки держится после добавления товара в чек', () {
        const md = ManualDiscount(ManualDiscountKey.f6, 10000);
        expect(sum(manualDiscountAmounts([50000, 15000], [], md)),
            closeTo(10000, 1e-10));
        expect(sum(manualDiscountAmounts([50000, 15000, 40000], [], md)),
            closeTo(10000, 1e-10));
      });

      test('сумма больше стоимости чека срезается до неё', () {
        expect(
            sum(manualDiscountAmounts([10000, 5000], [],
                const ManualDiscount(ManualDiscountKey.f6, 99000))),
            closeTo(15000, 1e-10));
      });
    });

    group('F7 — сумма на позицию', () {
      test('держит фиксированную сумму по своим позициям', () {
        expect(manualDiscountAmounts([50000, 15000], [1000, 1000], null),
            [1000, 1000]);
      });

      test('позиции без своей суммы остаются без скидки', () {
        expect(manualDiscountAmounts([50000, 15000], [1000, null], null),
            [1000, 0]);
      });

      test('перекрывает процент чека по своей позиции', () {
        expect(
            manualDiscountAmounts([50000, 15000], [null, 1000],
                const ManualDiscount(ManualDiscountKey.f5, 10)),
            [5000, 1000]);
      });

      test('срезается до стоимости позиции, когда количество уменьшили', () {
        expect(manualDiscountAmounts([12000], [20000], null), [12000]);
      });
    });

    test('без параметров скидки не начисляет ничего', () {
      expect(manualDiscountAmounts([50000, 15000], [], null), [0, 0]);
    });

    test('на пустом чеке возвращает пустой список', () {
      expect(
          manualDiscountAmounts(
              [], [], const ManualDiscount(ManualDiscountKey.f5, 10)),
          isEmpty);
    });
  });
}
