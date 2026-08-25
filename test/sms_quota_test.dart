import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mdokon/features/cashier/domain/sms_quota.dart';

// Порт src/helpers/__tests__/smsQuota.test.js из desktop-кассы.

Map<String, dynamic> dto([Map<String, dynamic> over = const {}]) => {
      'paidActive': true,
      'paidFrom': '2026-09-01',
      'freeLimit': 500,
      'usedCount': 100,
      'freeLeft': 400,
      'price': 150,
      'balance': 4500,
      'canSend': true,
      ...over,
    };

void main() {
  group('normalizeSmsQuota', () {
    test('пустой ответ — null, касса ничего не показывает', () {
      expect(normalizeSmsQuota(null), isNull);
      expect(normalizeSmsQuota(''), isNull);
    });

    test('остаток считается сам, если freeLeft не пришёл', () {
      final q = normalizeSmsQuota(
          {'paidActive': true, 'freeLimit': 500, 'usedCount': 612});
      expect(q!.freeLeft, 0);
    });

    test('пустая цена — 150 сум, как на бэкенде', () {
      expect(normalizeSmsQuota(dto({'price': 0}))!.price, kSmsDefaultPrice);
      expect(normalizeSmsQuota(dto({'price': null}))!.price, kSmsDefaultPrice);
    });

    test('canSend без поля считается по формуле сервера', () {
      expect(
          normalizeSmsQuota({
            'paidActive': true,
            'freeLeft': 0,
            'price': 150,
            'balance': 100
          })!.canSend,
          isFalse);
      expect(
          normalizeSmsQuota({
            'paidActive': true,
            'freeLeft': 0,
            'price': 150,
            'balance': 150
          })!.canSend,
          isTrue);
      expect(
          normalizeSmsQuota({
            'paidActive': false,
            'freeLeft': 0,
            'price': 150,
            'balance': 0
          })!.canSend,
          isTrue);
    });

    test('на сколько платных SMS хватит баланса', () {
      expect(normalizeSmsQuota(dto({'balance': 4500, 'price': 150}))!.affordable,
          30);
      expect(normalizeSmsQuota(dto({'balance': -500}))!.affordable, 0);
    });
  });

  group('smsQuotaLevel', () {
    test('платность не включена — молчим', () {
      expect(
          smsQuotaLevel(
              normalizeSmsQuota(dto({'paidActive': false, 'freeLeft': 0}))),
          SmsQuotaLevel.none);
      expect(smsQuotaLevel(null), SmsQuotaLevel.none);
    });

    test('бесплатных много', () {
      expect(smsQuotaLevel(normalizeSmsQuota(dto())), SmsQuotaLevel.ok);
    });

    test('бесплатные заканчиваются', () {
      expect(smsQuotaLevel(normalizeSmsQuota(dto({'freeLeft': 50}))),
          SmsQuotaLevel.low);
      expect(smsQuotaLevel(normalizeSmsQuota(dto({'freeLeft': 51}))),
          SmsQuotaLevel.ok);
    });

    test('бесплатные кончились, платим с баланса', () {
      expect(smsQuotaLevel(normalizeSmsQuota(dto({'freeLeft': 0}))),
          SmsQuotaLevel.paid);
    });

    test('денег нет — SMS не уходят', () {
      expect(
          smsQuotaLevel(normalizeSmsQuota(
              dto({'freeLeft': 0, 'balance': 0, 'canSend': false}))),
          SmsQuotaLevel.blocked);
    });
  });

  group('isSmsQuotaAlert', () {
    test('предупреждаем при открытии смены только о том, что важно', () {
      expect(
          [SmsQuotaLevel.low, SmsQuotaLevel.paid, SmsQuotaLevel.blocked]
              .every(isSmsQuotaAlert),
          isTrue);
      expect(isSmsQuotaAlert(SmsQuotaLevel.ok), isFalse);
      expect(isSmsQuotaAlert(SmsQuotaLevel.none), isFalse);
    });
  });

  group('smsQuotaMessage', () {
    test('пока платность не включена — сообщения нет', () {
      expect(smsQuotaMessage(normalizeSmsQuota(dto({'paidActive': false}))),
          isNull);
    });

    test('в остатке — сколько бесплатных и из скольких', () {
      final m = smsQuotaMessage(normalizeSmsQuota(dto({'freeLeft': 10})))!;
      expect(m.key, 'sms_quota_low');
      expect(m.args, {'left': '10', 'limit': '500'});
    });

    test('сверх лимита — цена и на сколько хватит баланса', () {
      final m = smsQuotaMessage(
          normalizeSmsQuota(dto({'freeLeft': 0, 'balance': 4500})))!;
      expect(m.key, 'sms_quota_paid');
      expect(m.args, {'price': '150', 'count': '30'});
    });

    test('баланс пуст — прямое указание пополнить', () {
      final m = smsQuotaMessage(normalizeSmsQuota(
          dto({'freeLeft': 0, 'balance': 0, 'canSend': false})))!;
      expect(m.key, 'sms_quota_blocked');
    });
  });
}
