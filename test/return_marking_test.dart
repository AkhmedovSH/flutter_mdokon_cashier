import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/domain/return_marking.dart';

const a = '01046060030002152100000000000001';
const b = '01046060030002152100000000000002';
const c = '01046060030002152100000000000003';

void main() {
  group('selectReturnCode', () {
    test('код из чека принимается', () {
      final result = selectReturnCode(available: [a, b], selected: [], code: a);
      expect(result.result, ReturnCodeResult.added);
      expect(result.codes, [a]);
    });

    test('чужой код не принимается', () {
      final result = selectReturnCode(available: [a, b], selected: [], code: c);
      expect(result.result, ReturnCodeResult.notFound);
      expect(result.codes, isEmpty);
    });

    test('пустой код — тоже «нет такого»', () {
      expect(selectReturnCode(available: [a], selected: [], code: '   ').result,
          ReturnCodeResult.notFound);
    });

    test('префикс сканера снимается перед сравнением', () {
      final result = selectReturnCode(available: [a], selected: [], code: ']d2$a');
      expect(result.result, ReturnCodeResult.added);
      expect(result.codes, [a]);
    });

    test('повторное сканирование одной пачки отбивается', () {
      final result = selectReturnCode(available: [a, b], selected: [a], code: a);
      expect(result.result, ReturnCodeResult.duplicate);
      expect(result.codes, [a]);
    });

    test('нельзя вернуть больше, чем осталось по позиции', () {
      final result = selectReturnCode(available: [a, b], selected: [a], code: b, limit: 1);
      expect(result.result, ReturnCodeResult.limitExceeded);
      expect(result.codes, [a]);
    });

    test('без лимита потолок — число кодов чека', () {
      final first = selectReturnCode(available: [a, b], selected: [a], code: b);
      expect(first.result, ReturnCodeResult.added);
      expect(first.codes, [a, b]);
    });

    test('лимит 0 трактуем как «все коды»', () {
      final result = selectReturnCode(available: [a, b], selected: [], code: a, limit: 0);
      expect(result.result, ReturnCodeResult.added);
    });
  });

  group('returnableMarkingCodes', () {
    test('целая позиция отдаёт все коды', () {
      expect(returnableMarkingCodes({'markingNumbers': [a, b]}), [a, b]);
    });

    test('частично возвращённая — первые limit кодов', () {
      expect(returnableMarkingCodes({'markingNumbers': [a, b, c]}, limit: 2), [a, b]);
    });

    test('лимит больше числа кодов ничего не режет', () {
      expect(returnableMarkingCodes({'markingNumbers': [a]}, limit: 5), [a]);
    });

    test('старое поле markingNumber тоже читается', () {
      expect(returnableMarkingCodes({'markingNumber': a}), [a]);
    });

    test('немаркировочная позиция — пусто', () {
      expect(returnableMarkingCodes({'productName': 'хлеб'}), isEmpty);
    });
  });
}
