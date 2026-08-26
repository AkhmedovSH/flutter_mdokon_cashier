import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/domain/marking.dart';
import 'package:flutter_mdokon/features/cashier/domain/marking_item.dart';

/// Табачный код: GTIN(14) + серийный(7) + код проверки(8) = 29 знаков.
const tobacco = '04606203070152abc1234defghij4';
const gs1 = '010460600300021521abcdefg$kGs' '93dGVz';

void main() {
  group('isMarkingItem', () {
    test('флаг сервера в любом виде', () {
      expect(isMarkingItem({'marking': true}), isTrue);
      expect(isMarkingItem({'marking': 1}), isTrue);
      expect(isMarkingItem({'marking': '1'}), isTrue);
    });

    test('обычный товар и null', () {
      expect(isMarkingItem({'marking': 0}), isFalse);
      expect(isMarkingItem({}), isFalse);
      expect(isMarkingItem(null), isFalse);
    });

    test('коды на позиции важнее отсутствующего флага', () {
      expect(isMarkingItem({'markingNumbers': ['x']}), isTrue);
      expect(isMarkingItem({'markingNumber': 'x'}), isTrue);
      expect(isMarkingItem({'markingNumbers': []}), isFalse);
      expect(isMarkingItem({'markingNumber': ''}), isFalse);
    });
  });

  group('markingCodes', () {
    test('старое поле markingNumber поддержано', () {
      expect(markingCodes({'markingNumber': 'a'}), ['a']);
    });

    test('список важнее одиночного поля', () {
      expect(markingCodes({'markingNumber': 'a', 'markingNumbers': ['b', 'c']}), ['b', 'c']);
    });

    test('пусто', () {
      expect(markingCodes({}), isEmpty);
      expect(markingCodes(null), isEmpty);
    });
  });

  group('addMarkingCode', () {
    test('первый код задаёт количество 1', () {
      final item = <String, dynamic>{'marking': 1};
      expect(addMarkingCode(item, 'aaa'), MarkingAddResult.added);
      expect(markingCodes(item), ['aaa']);
      expect(item['quantity'], 1);
      expect(item['markingNumber'], 'aaa');
    });

    test('одинаковые коды собираются в одну позицию, количество растёт', () {
      final item = <String, dynamic>{'marking': 1};
      addMarkingCode(item, 'aaa');
      expect(addMarkingCode(item, 'bbb'), MarkingAddResult.added);
      expect(item['quantity'], 2);
      expect(markingCodes(item), ['aaa', 'bbb']);
    });

    test('повторный код не добавляется', () {
      final item = <String, dynamic>{};
      addMarkingCode(item, 'aaa');
      expect(addMarkingCode(item, 'aaa'), MarkingAddResult.duplicate);
      expect(item['quantity'], 1);
    });

    test('код нормализуется — префикс сканера не делает его новым', () {
      final item = <String, dynamic>{};
      addMarkingCode(item, 'aaa');
      expect(addMarkingCode(item, ']d2aaa'), MarkingAddResult.duplicate);
    });

    test('остаток ограничивает число кодов', () {
      final item = <String, dynamic>{};
      expect(addMarkingCode(item, 'aaa', balance: 1), MarkingAddResult.added);
      expect(addMarkingCode(item, 'bbb', balance: 1), MarkingAddResult.limitExceeded);
      expect(item['quantity'], 1);
    });

    test('продажа в минус (balance: null) остаток не проверяет', () {
      final item = <String, dynamic>{};
      addMarkingCode(item, 'aaa');
      expect(addMarkingCode(item, 'bbb'), MarkingAddResult.added);
      expect(item['quantity'], 2);
    });

    test('пустой код игнорируется', () {
      final item = <String, dynamic>{};
      expect(addMarkingCode(item, '  '), MarkingAddResult.duplicate);
      expect(markingCodes(item), isEmpty);
    });
  });

  group('removeMarkingCode', () {
    test('количество уменьшается вслед за кодами', () {
      final item = <String, dynamic>{};
      addMarkingCode(item, 'aaa');
      addMarkingCode(item, 'bbb');
      expect(removeMarkingCode(item, 'aaa'), isTrue);
      expect(markingCodes(item), ['bbb']);
      expect(item['quantity'], 1);
      expect(item['markingNumber'], 'bbb');
    });

    test('удаление последнего кода оставляет позицию пустой', () {
      final item = <String, dynamic>{};
      addMarkingCode(item, 'aaa');
      expect(removeMarkingCode(item, 'aaa'), isTrue);
      expect(markingCodes(item), isEmpty);
      expect(item['quantity'], 0);
    });

    test('чужой код ничего не меняет', () {
      final item = <String, dynamic>{};
      addMarkingCode(item, 'aaa');
      expect(removeMarkingCode(item, 'zzz'), isFalse);
      expect(item['quantity'], 1);
    });
  });

  group('markingLabel', () {
    test('табачный код режется до GTIN + серийного', () {
      expect(tobacco.length, 29);
      expect(markingLabel(tobacco), '04606203070152abc1234');
    });

    test('GS1 режется по разделителю', () {
      expect(markingLabel(gs1), '010460600300021521abcdefg');
    });

    test('режется по «=»', () {
      expect(markingLabel('0104606003000215=tail'), '0104606003000215');
    });

    test('пусто', () {
      expect(markingLabel(null), '');
      expect(markingLabel(''), '');
    });
  });

  test('setMarkingCodes держит количество равным числу кодов', () {
    final item = <String, dynamic>{'quantity': 7};
    setMarkingCodes(item, ['a', 'b', 'c']);
    expect(item['quantity'], 3);
    expect(item['markingNumber'], 'a');
  });
}
