import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/domain/subscription_payment.dart';

/// Тесты абонплаты картой (Multicard / Rahmat) — порт `apiMulticard.js`
/// и `SubscriptionPaymentModal.js`.
void main() {
  group('статус счёта', () {
    test('PAID и флаг paid — оплачено', () {
      expect(parseInvoiceStatus({'status': 'PAID'}), InvoiceStatus.paid);
      expect(parseInvoiceStatus({'paid': true, 'status': 'PENDING'}), InvoiceStatus.paid);
    });

    test('CANCELED и FAILED различаются — у них разные сообщения', () {
      expect(parseInvoiceStatus({'status': 'CANCELED'}), InvoiceStatus.canceled);
      expect(parseInvoiceStatus({'status': 'FAILED'}), InvoiceStatus.failed);
      expect(invoiceStatusMessageKey(InvoiceStatus.canceled), 'subscription_pay_canceled');
      expect(invoiceStatusMessageKey(InvoiceStatus.failed), 'subscription_pay_failed');
    });

    test('NOT_FOUND и мусор — всё ещё ждём оплату, а не ошибка', () {
      expect(parseInvoiceStatus({'status': 'NOT_FOUND'}), InvoiceStatus.pending);
      expect(parseInvoiceStatus({}), InvoiceStatus.pending);
      expect(parseInvoiceStatus(null), InvoiceStatus.pending);
    });

    test('у ожидания сообщения нет', () {
      expect(invoiceStatusMessageKey(InvoiceStatus.pending), isNull);
      expect(invoiceStatusMessageKey(InvoiceStatus.paid), isNull);
    });
  });

  group('точки', () {
    test('разбираются со всеми полями, минусовой баланс — долг', () {
      final points = parseSubscriptionPoints([
        {'posId': 3, 'name': 'Точка 1', 'balance': -120000, 'suggestedAmount': 150000, 'activated': true},
      ]);
      expect(points.length, 1);
      expect(points.first.posId, 3);
      expect(points.first.balance, -120000);
      expect(points.first.defaultAmount, 150000);
      expect(points.first.activated, isTrue);
    });

    test('запись без posId пропускается, а не роняет список', () {
      final points = parseSubscriptionPoints([
        {'name': 'без id'},
        {'posId': '7', 'name': 'Точка 7'},
      ]);
      expect(points.length, 1);
      expect(points.first.posId, 7);
    });

    test('не список — пустой результат («нет доступных точек»)', () {
      expect(parseSubscriptionPoints(null), isEmpty);
      expect(parseSubscriptionPoints({'error': 403}), isEmpty);
    });

    test('без рекомендованной суммы поле остаётся пустым', () {
      final points = parseSubscriptionPoints([
        {'posId': 1, 'suggestedAmount': 0},
      ]);
      expect(points.first.defaultAmount, 0);
    });
  });

  group('счёт', () {
    test('годен только со ссылкой на страницу банка', () {
      final ok = SubscriptionInvoice.fromJson(
        {'success': true, 'invoiceId': 55, 'shortLink': 'https://pay/x'},
        amount: 150000,
      );
      expect(ok.usable, isTrue);
      expect(ok.invoiceId, '55');
      expect(ok.amount, 150000);

      final noLink = SubscriptionInvoice.fromJson({'success': true});
      expect(noLink.usable, isFalse);
    });

    test('отказ сервиса приходит текстом — его и показываем', () {
      final failed = SubscriptionInvoice.fromJson({'success': false, 'message': 'Нет доступа к точке'});
      expect(failed.usable, isFalse);
      expect(failed.message, 'Нет доступа к точке');
    });

    test('не-Map ответ — счёт не создан', () {
      expect(SubscriptionInvoice.fromJson(null).usable, isFalse);
    });
  });

  group('форма', () {
    test('без точки и без суммы счёт не создаётся', () {
      expect(subscriptionFormError(posId: null, amount: 1000), 'subscription_pay_no_point_selected');
      expect(subscriptionFormError(posId: 3, amount: 0), 'subscription_pay_amount_invalid');
      expect(subscriptionFormError(posId: 3, amount: -5), 'subscription_pay_amount_invalid');
    });

    test('точка и положительная сумма — ошибок нет', () {
      expect(subscriptionFormError(posId: 3, amount: 150000), isNull);
    });
  });
}
