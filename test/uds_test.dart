import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/domain/uds.dart';

/// Ответ `uds-calc` в том виде, в каком его отдаёт сервер.
Map<String, dynamic> _response({
  double points = 0,
  double maxPoints = 0,
  double cash = 0,
  double total = 0,
  double discount = 0,
  double cashBack = 0,
  double balance = 0,
  String uid = 'uid-1',
  String phone = '',
}) =>
    {
      'user': {
        'uid': uid,
        'displayName': 'Иван',
        'phone': phone,
        'participant': {
          'points': balance,
          'membershipTier': {'name': 'Серебряный'},
        },
      },
      'purchase': {
        'maxPoints': maxPoints,
        'discountAmount': discount,
        'points': points,
        'cash': cash,
        'cashBack': cashBack,
        'total': total,
      },
    };

void main() {
  group('parseUdsCalc', () {
    test('раскладывает ответ сервера в плоскую карточку', () {
      final calc = parseUdsCalc(_response(
        points: 500,
        maxPoints: 1200,
        cash: 9500,
        total: 10000,
        discount: 300,
        cashBack: 45,
        balance: 1500,
      ));

      expect(calc.uid, 'uid-1');
      expect(calc.displayName, 'Иван');
      expect(calc.tier, 'Серебряный');
      expect(calc.balance, 1500);
      expect(calc.maxPoints, 1200);
      expect(calc.points, 500);
      expect(calc.cash, 9500);
      expect(calc.cashBack, 45);
      expect(calc.discountAmount, 300);
      expect(calc.total, 10000);
    });

    test('пустой и битый ответ — нулевая карточка, а не исключение', () {
      expect(parseUdsCalc(null).cash, 0);
      expect(parseUdsCalc('нет').displayName, '');
      expect(parseUdsCalc({'user': 'нет', 'purchase': 5}).uid, '');
    });

    test('строковые суммы приводятся к числам', () {
      final calc = parseUdsCalc({
        'purchase': {'cash': '9500.5', 'points': '100'},
      });
      expect(calc.cash, 9500.5);
      expect(calc.points, 100);
    });
  });

  group('ошибки', () {
    test('ключ ошибки читается из errorKey, key, code и message', () {
      expect(udsErrorKeyOf({'errorKey': 'error.uds.not_found'}), 'error.uds.not_found');
      expect(udsErrorKeyOf({'key': 'error.uds.disabled'}), 'error.uds.disabled');
      expect(udsErrorKeyOf({'code': 'error.uds.two_loyalty'}), 'error.uds.two_loyalty');
      expect(udsErrorKeyOf({'message': 'error.uds.discount_limit'}), 'error.uds.discount_limit');
    });

    test('чужой текст ключом не считается', () {
      expect(udsErrorKeyOf({'message': 'Внутренняя ошибка'}), null);
      expect(udsErrorKeyOf('строка'), null);
      expect(udsErrorKeyOf(null), null);
    });

    test('известный ключ переводится, неизвестный — нет', () {
      expect(
        const UdsError(errorKey: 'error.uds.insufficient_funds').i18nKey,
        'uds_error_insufficient_funds',
      );
      expect(const UdsError(errorKey: 'error.uds.wat').i18nKey, null);
      expect(const UdsError(message: 'Ошибка сервера').i18nKey, null);
    });

    test('недоступность: обрыв связи, 503 и явный ключ', () {
      expect(const UdsError(networkFailure: true).unavailable, true);
      expect(const UdsError(status: 503).unavailable, true);
      expect(const UdsError(errorKey: udsUnavailableKey).unavailable, true);
    });

    test('отказ по существу недоступностью не считается: кассир может исправить', () {
      expect(const UdsError(errorKey: 'error.uds.not_found', status: 400).unavailable, false);
    });
  });

  group('calcUdsSkipLoyaltyTotal', () {
    test('скидка на весь чек выводит из лояльности чек целиком', () {
      final total = calcUdsSkipLoyaltyTotal({
        'discountAmount': 500,
        'totalPrice': 12000,
        'itemsList': [
          {'totalPrice': 12000},
        ],
      });
      expect(total, 12000);
    });

    test('позиции со скидкой и подарки по акции', () {
      final total = calcUdsSkipLoyaltyTotal({
        'discountAmount': 0,
        'totalPrice': 30000,
        'itemsList': [
          {'totalPrice': 10000, 'discountAmount': 1000},
          {'totalPrice': 5000, 'promotionGift': true},
          {'totalPrice': 15000},
        ],
      });
      expect(total, 15000);
    });

    test('чек без скидок — ноль', () {
      expect(
        calcUdsSkipLoyaltyTotal({
          'totalPrice': 30000,
          'itemsList': [
            {'totalPrice': 30000},
          ],
        }),
        0,
      );
      expect(calcUdsSkipLoyaltyTotal(null), 0);
      expect(calcUdsSkipLoyaltyTotal({'itemsList': 'нет'}), 0);
    });
  });

  group('udsIdentifierPayload', () {
    test('идентификатор ровно один, в порядке код → телефон → uid', () {
      expect(udsIdentifierPayload(code: ' 123 ', phone: '998900000000'), {'code': '123'});
      expect(udsIdentifierPayload(phone: ' 998900000000 ', uid: 'u'), {'phone': '998900000000'});
      expect(udsIdentifierPayload(uid: 'u'), {'uid': 'u'});
      expect(udsIdentifierPayload(code: '  '), {});
      expect(udsIdentifierPayload(), {});
    });
  });

  group('UdsState', () {
    const calc = UdsCalc(maxPoints: 1000, points: 200, cash: 9000, total: 10000, cashBack: 30);
    const state = UdsState(found: true, calculated: true, calc: calc, pointsInput: '200');

    test('расчёт устаревает при изменении корзины', () {
      expect(state.isStale(10000), false);
      expect(state.isStale(11000), true);
      // До первого расчёта устаревать нечему.
      expect(const UdsState().isStale(500), false);
    });

    test('пробить можно только когда внесена ровно сумма из расчёта', () {
      expect(state.isValidated(9000, 10000), true);
      expect(state.isValidated(8000, 10000), false);
      // Корзину правили после расчёта — цифры UDS уже чужие.
      expect(state.isValidated(9000, 11000), false);
      expect(const UdsState().isValidated(0, 0), false);
    });

    test('копейки в пределах округления сумму не ломают', () {
      expect(state.isValidated(9000.004, 10000.001), true);
    });

    test('списание запрещено по телефону и без доступных баллов', () {
      expect(state.pointsDisabled, false);
      expect(state.copyWith(mode: UdsMode.phone).pointsDisabled, true);
      expect(state.copyWith(calc: const UdsCalc()).pointsDisabled, true);
      expect(const UdsState().pointsDisabled, true);
    });

    test('поле баллов чистится от букв и режется по максимуму', () {
      expect(state.clampPoints('12a3'), '123');
      expect(state.clampPoints('5000'), '1000');
      expect(state.clampPoints(''), '');
    });

    test('пересчёт нужен, только если ввод разошёлся с зачтённым', () {
      expect(state.needsRecalc, false);
      expect(state.copyWith(pointsInput: '300').needsRecalc, true);
      // Клиента ещё не нашли — пересчитывать нечего.
      expect(const UdsState(pointsInput: '300').needsRecalc, false);
    });
  });

  group('udsChequeFields', () {
    test('по QR уходит код, суммы — из расчёта как есть', () {
      final fields = udsChequeFields(const UdsState(
        search: ' promo-1 ',
        found: true,
        calculated: true,
        skipLoyaltyTotal: 4000,
        calc: UdsCalc(
          uid: 'uid-1',
          displayName: 'Иван',
          balance: 1500,
          points: 200,
          cash: 9000,
          discountAmount: 300,
          cashBack: 30,
        ),
      ));

      expect(fields['udsCode'], 'promo-1');
      expect(fields.containsKey('udsPhone'), false);
      expect(fields['udsPoints'], 200);
      expect(fields['udsCash'], 9000);
      expect(fields['udsDiscount'], 300);
      expect(fields['udsCashback'], 30);
      expect(fields['udsBalance'], 1500);
      expect(fields['udsSkipLoyaltyTotal'], 4000);
      expect(fields['udsCustomerUid'], 'uid-1');
      expect(fields['udsCustomerName'], 'Иван');
      // Сдачи в чеке UDS нет: платят ровно сумму из расчёта.
      expect(fields['change'], 0);
    });

    test('по телефону уходит номер из ответа, а не набранный', () {
      final fields = udsChequeFields(const UdsState(
        mode: UdsMode.phone,
        search: '998900000000',
        found: true,
        calculated: true,
        calc: UdsCalc(phone: '+998900000000'),
      ));

      expect(fields['udsPhone'], '+998900000000');
      expect(fields.containsKey('udsCode'), false);
    });

    test('телефона в ответе нет — уходит набранный кассиром', () {
      final fields = udsChequeFields(const UdsState(mode: UdsMode.phone, search: ' 998900000000 '));
      expect(fields['udsPhone'], '998900000000');
    });
  });

  group('udsPointsText', () {
    test('целое — без хвоста «.0»', () {
      expect(udsPointsText(1000), '1000');
      expect(udsPointsText(12.5), '12.5');
    });
  });
}
