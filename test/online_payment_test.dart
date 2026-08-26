import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/domain/online_payment.dart';

/// Тесты онлайн-оплаты: Click Pass / Payme / Uzum.
///
/// Эталон — `Tab.js:3082-3220` и `generate-sha1` из `public/electron.js:177`.
void main() {
  group('провайдер по paymentTypeId', () {
    test('5/6/7 — click/payme/uzum, остальное не онлайн', () {
      expect(onlineProviderFromPaymentTypeId(5), OnlineProvider.click);
      expect(onlineProviderFromPaymentTypeId(6), OnlineProvider.payme);
      expect(onlineProviderFromPaymentTypeId(7), OnlineProvider.uzum);
      expect(onlineProviderFromPaymentTypeId(1), isNull);
      expect(onlineProviderFromPaymentTypeId(null), isNull);
    });

    test('строка тоже разбирается — справочник приходит с сервера', () {
      expect(onlineProviderFromPaymentTypeId('5'), OnlineProvider.click);
    });

    test('id и ключ кассы совпадают с десктопом', () {
      expect(onlineProviderPaymentTypeId(OnlineProvider.click), 5);
      expect(onlineProviderCashboxKey(OnlineProvider.click), 'clickPay');
      expect(onlineProviderCashboxKey(OnlineProvider.payme), 'paymePay');
      expect(onlineProviderCashboxKey(OnlineProvider.uzum), 'uzumPay');
    });
  });

  group('detectOnlinePayment', () {
    test('без онлайн-способов — null', () {
      final result = detectOnlinePayment([
        {'paymentTypeId': 1, 'amount': 5000},
        {'paymentTypeId': 2, 'amount': 3000},
      ]);
      expect(result, isNull);
    });

    test('нулевая сумма онлайн-способа не считается выбором', () {
      expect(
        detectOnlinePayment([
          {'paymentTypeId': 5, 'amount': ''},
          {'paymentTypeId': 1, 'amount': 5000},
        ]),
        isNull,
      );
    });

    test('сумма и customPaymentTypeId выбранного способа', () {
      final result = detectOnlinePayment([
        {'paymentTypeId': 1, 'amount': 1000},
        {'paymentTypeId': 7, 'amount': '25000', 'customPaymentTypeId': 42},
      ]);
      expect(result!.provider, OnlineProvider.uzum);
      expect(result.amount, 25000);
      expect(result.customPaymentTypeId, 42);
    });

    test('пустой список и null не роняют разбор', () {
      expect(detectOnlinePayment(null), isNull);
      expect(detectOnlinePayment([]), isNull);
    });
  });

  group('подпись запроса', () {
    // Эталон: sha1('1700000000000secret') — тот же код, что считает electron.js.
    test('формат id:sha1:timestamp', () {
      final token = onlineAuthToken(userId: '3952', secret: 'secret', timestampMs: 1700000000000);
      final parts = token.split(':');
      expect(parts.length, 3);
      expect(parts[0], '3952');
      expect(parts[1].length, 40);
      expect(parts[2], '1700000000000');
    });

    test('подпись зависит от времени — два вызова подряд разные', () {
      final a = onlineAuthToken(userId: '1', secret: 's', timestampMs: 1);
      final b = onlineAuthToken(userId: '1', secret: 's', timestampMs: 2);
      expect(a, isNot(b));
    });

    test('Click подписывается merchant_service_user_id, Uzum — merchant_id', () {
      const merchant = {
        'merchant_id': 'M1',
        'merchant_service_user_id': 'U9',
        'merchant_secret_key': 'k',
      };
      expect(
        onlineAuthFromCashbox(OnlineProvider.click, merchant, 100)!.startsWith('U9:'),
        isTrue,
      );
      expect(
        onlineAuthFromCashbox(OnlineProvider.uzum, merchant, 100)!.startsWith('M1:'),
        isTrue,
      );
    });

    test('Payme — пара merchant_id:secret без хеша', () {
      final auth = onlineAuthFromCashbox(
        OnlineProvider.payme,
        {'merchant_id': 'M1', 'merchant_secret_key': 'k'},
        100,
      );
      expect(auth, 'M1:k');
    });

    test('без секрета точки подписи нет — оплату дальше не пускаем', () {
      expect(onlineAuthFromCashbox(OnlineProvider.click, {'merchant_service_user_id': 'U9'}, 1), isNull);
      expect(onlineAuthFromCashbox(OnlineProvider.uzum, null, 1), isNull);
    });
  });

  group('payload', () {
    test('Click — сумма в сумах, Uzum — в тийинах', () {
      final click = clickPayload(
        amount: 25000,
        cashboxCode: 'c',
        otpCode: '123',
        transactionId: 't',
        serviceId: 9,
      );
      final uzum = uzumPayload(
        amount: 25000,
        cashboxCode: 'c',
        otpCode: '123',
        transactionId: 't',
        serviceId: 9,
      );
      expect(click['amount'], 25000);
      expect(uzum['amount'], 2500000);
      expect(click['otp_data'], '123');
      expect(uzum['transaction_id'], 't');
    });

    test('cashbox_code собирается как на десктопе', () {
      expect(
        onlineCashboxCode(posId: 3, cashboxId: 12, shiftId: 555),
        'posId3cashboxId12shiftId555',
      );
    });

    test('Payme create — тийины и состав чека позициями', () {
      final payload = paymeCreatePayload(
        chequeNumber: 77,
        amount: 12000,
        itemsList: [
          {
            'productName': 'Хлеб',
            'salePrice': 5000,
            'quantity': 2,
            'gtin': '123',
            'vat': 12,
            'packageCode': 'p1',
          },
        ],
      );
      expect(payload['method'], 'receipts.create');
      final params = payload['params'] as Map;
      expect(params['amount'], 1200000);
      expect((params['account'] as Map)['order_id'], 77);
      final items = (params['detail'] as Map)['items'] as List;
      expect(items.first['price'], 500000);
      expect(items.first['title'], 'Хлеб');
    });

    test('Payme pay — по _id чека из шага 1', () {
      final created = {
        'id': 77,
        'result': {
          'receipt': {'_id': 'abc'}
        }
      };
      expect(paymeReceiptId(created), 'abc');
      final pay = paymePayPayload(requestId: 77, receiptId: 'abc', otpCode: 'code');
      expect(pay['method'], 'receipts.pay');
      expect((pay['params'] as Map)['token'], 'code');
    });

    test('битый ответ Payme не даёт _id', () {
      expect(paymeReceiptId(null), isNull);
      expect(paymeReceiptId({'error': {}}), isNull);
    });
  });

  group('ответы провайдеров', () {
    test('Click: error_code — ошибка с текстом error_note', () {
      final result = parseClickResponse({'error_code': -5, 'error_note': 'Неверный код'});
      expect(result.ok, isFalse);
      expect(result.error, 'Неверный код');
    });

    test('Click: успех отдаёт payment_id и телефон покупателя', () {
      final result = parseClickResponse({
        'error_code': 0,
        'payment_id': 12345,
        'phone_number': '998901234567',
      });
      expect(result.ok, isTrue);
      expect(result.paymentId, '12345');
      expect(result.clientPhone, '998901234567');
    });

    test('Uzum: ошибка только при error_code > 0', () {
      expect(parseUzumResponse({'error_code': 0, 'payment_id': 1}).ok, isTrue);
      final failed = parseUzumResponse({'error_code': 3, 'error_message': 'Нет средств'});
      expect(failed.ok, isFalse);
      expect(failed.error, 'Нет средств');
    });

    test('Uzum: телефон покупателя лежит в client_phone_number', () {
      final result = parseUzumResponse({'payment_id': 'p', 'client_phone_number': '998900000000'});
      expect(result.clientPhone, '998900000000');
    });

    test('Payme: error склеивает message и data', () {
      final result = parsePaymeResponse({
        'error': {'code': -31610, 'message': 'Ошибка', 'data': 'token'}
      });
      expect(result.ok, isFalse);
      expect(result.error, 'Ошибка token');
    });

    test('Payme: успех отдаёт _id чека и телефон плательщика', () {
      final result = parsePaymeResponse({
        'result': {
          'receipt': {
            '_id': 'r1',
            'payer': {'phone': '998911111111'}
          }
        }
      });
      expect(result.ok, isTrue);
      expect(result.paymentId, 'r1');
      expect(result.clientPhone, '998911111111');
    });

    test('не-Map ответ — оплата не прошла, а не «прошла молча»', () {
      expect(parseClickResponse(null).ok, isFalse);
      expect(parseUzumResponse('<html>').ok, isFalse);
      expect(parsePaymeResponse(false).ok, isFalse);
    });
  });
}
