import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/data/marking_repository.dart';
import 'package:flutter_mdokon/features/cashier/domain/marking.dart';

void main() {
  group('parseMarkingCode', () {
    test('обычные штрих-коды кодом маркировки не считаются', () {
      expect(parseMarkingCode('4780068020047'), isNull);
      expect(parseMarkingCode('54491014'), isNull);
      expect(parseMarkingCode('2100123004567'), isNull); // весовой
      expect(parseMarkingCode(''), isNull);
      expect(parseMarkingCode(null), isNull);
    });

    test('GS1 с разделителем групп', () {
      final code = '0104780068020047215Fw1RmMd${kGs}93dGVz';
      final parsed = parseMarkingCode(code)!;
      expect(parsed.format, MarkingFormat.gs1);
      expect(parsed.gtin, '04780068020047');
      expect(parsed.serial, '5Fw1RmMd');
      expect(parsed.code, code);
    });

    test('GS1 без разделителя: серийный режется по началу криптохвоста', () {
      final parsed = parseMarkingCode('010478006802004721qwerty1291EE0692dGVzdA')!;
      expect(parsed.gtin, '04780068020047');
      expect(parsed.serial, 'qwerty12');
    });

    test('AI 02 (групповая упаковка) — GTIN берётся так же', () {
      expect(parseMarkingCode('0204780068020047215Fw1RmMd')!.gtin, '04780068020047');
    });

    test('префикс сканера AIM отбрасывается', () {
      final parsed = parseMarkingCode(']d20104780068020047215Fw1RmMd')!;
      expect(parsed.gtin, '04780068020047');
      expect(parsed.code.startsWith(']d2'), isFalse);
    });

    test('сигареты: ровно 29 символов без AI', () {
      final parsed = parseMarkingCode('04780068020047ABC1234XYZ98765')!;
      expect(parsed.format, MarkingFormat.tobacco);
      expect(parsed.gtin, '04780068020047');
      expect(parsed.serial, 'ABC1234');
    });

    test('29 символов с AI 21 — это GS1, а не сигареты', () {
      final parsed = parseMarkingCode('010478006802004721ABC1234XYZ')!;
      expect(parsed.format, MarkingFormat.gs1);
      expect(parsed.gtin, '04780068020047');
    });

    test('GS присланный текстом и переводы строк не мешают разбору', () {
      final parsed = parseMarkingCode('0104780068020047215Fw1RmMd\\u001d93dGVz\r\n')!;
      expect(parsed.gtin, '04780068020047');
      expect(parsed.serial, '5Fw1RmMd');
      expect(parsed.code.contains(kGs), isTrue);
    });

    test('looksLikeMarkingInput', () {
      expect(looksLikeMarkingInput('4780068020047'), isFalse);
      expect(looksLikeMarkingInput('0104780068020047215Fw1RmMd'), isTrue);
    });
  });

  group('gtinToBarcodeVariants', () {
    test('нули слева срезаются по одному, минимум 8 символов', () {
      expect(gtinToBarcodeVariants('04780068020047'), ['04780068020047', '4780068020047']);
      expect(gtinToBarcodeVariants('00012000051654'), [
        '00012000051654',
        '0012000051654',
        '012000051654',
        '12000051654',
      ]);
      expect(gtinToBarcodeVariants('00000054491014'), [
        '00000054491014',
        '0000054491014',
        '000054491014',
        '00054491014',
        '0054491014',
        '054491014',
        '54491014',
      ]);
    });

    test('пустой GTIN — пустой список', () {
      expect(gtinToBarcodeVariants(''), isEmpty);
      expect(gtinToBarcodeVariants(null), isEmpty);
    });
  });

  group('normalizeMarkingCheck', () {
    test('мусор на входе — UNKNOWN, продажа не блокируется', () {
      expect(normalizeMarkingCheck(null).status, MarkingStatus.unknown);
      expect(normalizeMarkingCheck('oops').status, MarkingStatus.unknown);
      expect(normalizeMarkingCheck(false).status, MarkingStatus.unknown);
    });

    test('success без checked — это ещё не ответ ЦРПТ', () {
      expect(normalizeMarkingCheck({'success': true}).status, MarkingStatus.unknown);
    });

    test('checked без статуса — считаем код в обороте', () {
      expect(normalizeMarkingCheck({'checked': true}).status, MarkingStatus.ok);
    });

    test('обёртка data разворачивается, GTIN чистится от нецифр', () {
      final result = normalizeMarkingCheck({
        'data': {'checked': true, 'status': 'in_circulation', 'gtin': ' 0478-0068020047 '},
      });
      expect(result.status, MarkingStatus.ok);
      expect(result.gtin, '04780068020047');
      expect(result.warningKey, isNull);
    });

    test('registered:false важнее статуса', () {
      final result = normalizeMarkingCheck({'status': 'ok', 'registered': false});
      expect(result.status, MarkingStatus.notRegistered);
      expect(result.warningKey, 'marking_not_registered');
    });

    test('выведенные из оборота статусы', () {
      for (final value in ['withdrawn', 'SOLD', ' written_off ']) {
        expect(normalizeMarkingCheck({'status': value}).status, MarkingStatus.withdrawn);
      }
      expect(normalizeMarkingCheck({'state': 'retired'}).warningKey, 'marking_withdrawn');
    });

    test('незарегистрированные статусы', () {
      for (final value in ['not_found', 'emitted', 'NotRegistered']) {
        expect(normalizeMarkingCheck({'markingStatus': value}).status,
            MarkingStatus.notRegistered);
      }
    });

    test('незнакомый статус без checked — UNKNOWN, а не ошибка', () {
      final result = normalizeMarkingCheck({'status': 'something_new'});
      expect(result.status, MarkingStatus.unknown);
      expect(result.warningKey, 'marking_not_checked');
    });

    test('код идентификации берётся из любого из двух полей', () {
      expect(normalizeMarkingCheck({'markingCode': 'abc'}).identificationCode, 'abc');
      expect(normalizeMarkingCheck({'identificationCode': 'xyz'}).identificationCode, 'xyz');
    });
  });
}
