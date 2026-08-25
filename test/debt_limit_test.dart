import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mdokon/features/cashier/domain/debt_limit.dart';

// Порт src/helpers/__tests__/debtLimit.test.js из desktop-кассы.

const num kRate = 12000; // курс точки: 1 USD = 12 000 сум

// Долг хранится отрицательным балансом.
Map<String, dynamic> client([Map<String, dynamic> over = const {}]) => {
      'clientId': 1,
      'name': 'Клиент',
      'debtLimit': 0,
      'balanceList': [],
      ...over,
    };

void main() {
  group('amountToUzs', () {
    test('сумы возвращаются как есть', () {
      expect(amountToUzs(5000, currencyUzs, kRate), 5000);
    });
    test('доллары пересчитываются по курсу', () {
      expect(amountToUzs(10, currencyUsd, kRate), 120000);
    });
    test('нет курса → null (пересчёт невозможен)', () {
      expect(amountToUzs(10, currencyUsd, 0), isNull);
      expect(amountToUzs(10, currencyUsd, null), isNull);
    });
    test('мусор вместо суммы → 0', () {
      expect(amountToUzs(null, currencyUzs, kRate), 0);
      expect(amountToUzs('abc', currencyUzs, kRate), 0);
    });
  });

  group('readDebtLimit', () {
    test('camelCase из спеки', () {
      expect(readDebtLimit({'debtLimit': 50000}), 50000);
    });
    test('snake_case тоже принимаем', () {
      expect(readDebtLimit({'debt_limit': 50000}), 50000);
    });
    test('строка из локальной БД', () {
      expect(readDebtLimit({'debtLimit': '50000'}), 50000);
    });
    test('поля нет → 0 (без ограничения)', () {
      expect(readDebtLimit({}), 0);
      expect(readDebtLimit(null), 0);
    });
    test('лимит доезжает до проверки при snake_case', () {
      final r = checkClientDebtLimit(
        client: {'debt_limit': 50000, 'balanceList': []},
        addAmount: 60000,
        addCurrencyId: currencyUzs,
        currencyRate: kRate,
      );
      expect(r.exceeded, isTrue);
    });
  });

  group('resolveCurrencyId', () {
    test('явный currencyId в приоритете', () {
      expect(resolveCurrencyId({'currencyId': 2, 'currencyName': 'Сум'}),
          currencyUsd);
    });
    test('валюта по названию, если id нет', () {
      expect(resolveCurrencyId({'currencyName': 'USD'}), currencyUsd);
      expect(resolveCurrencyId({'currencyName': 'Доллар'}), currencyUsd);
      expect(resolveCurrencyId({'currencyName': 'Сум'}), currencyUzs);
    });
    test('пусто → сумы', () {
      expect(resolveCurrencyId({}), currencyUzs);
      expect(resolveCurrencyId(null), currencyUzs);
    });
  });

  group('clientDebtUzs', () {
    test('долг в сумах', () {
      final r = clientDebtUzs(
          client({
            'balanceList': [
              {'totalAmount': -500000, 'currencyId': 1}
            ]
          }),
          kRate);
      expect(r.debt, 500000);
      expect(r.unknown, isFalse);
    });
    test('долг в долларах пересчитывается', () {
      final r = clientDebtUzs(
          client({
            'balanceList': [
              {'totalAmount': -10, 'currencyId': 2}
            ]
          }),
          kRate);
      expect(r.debt, 120000);
    });
    test('несколько валют складываются', () {
      final r = clientDebtUzs(
          client({
            'balanceList': [
              {'totalAmount': -500000, 'currencyId': 1},
              {'totalAmount': -10, 'currencyId': 2},
            ]
          }),
          kRate);
      expect(r.debt, 620000);
    });
    test('переплата (положительный баланс) — не долг', () {
      final r = clientDebtUzs(
          client({
            'balanceList': [
              {'totalAmount': 300000, 'currencyId': 1}
            ]
          }),
          kRate);
      expect(r.debt, 0);
    });
    test('переплата гасит долг в другой валюте', () {
      final r = clientDebtUzs(
          client({
            'balanceList': [
              {'totalAmount': -500000, 'currencyId': 1},
              {'totalAmount': 100, 'currencyId': 2},
            ]
          }),
          kRate);
      expect(r.debt, 0);
    });
    test('нет курса при долларовом балансе → unknown', () {
      final r = clientDebtUzs(
          client({
            'balanceList': [
              {'totalAmount': -10, 'currencyId': 2}
            ]
          }),
          0);
      expect(r.unknown, isTrue);
    });
    test('скалярный balance, если balanceList пуст (офлайн)', () {
      final r = clientDebtUzs({'balance': -700000, 'balanceList': []}, kRate);
      expect(r.debt, 700000);
    });
    test('нет данных о балансе → 0', () {
      expect(clientDebtUzs({}, kRate).debt, 0);
      expect(clientDebtUzs({}, kRate).unknown, isFalse);
      expect(clientDebtUzs(null, kRate).debt, 0);
    });
  });

  group('debtLimitInfo', () {
    test('debtLimit = 0 → без ограничения', () {
      final info = debtLimitInfo(client({'debtLimit': 0}), kRate);
      expect(info.unlimited, isTrue);
      expect(info.available, double.infinity);
    });
    test('доступная сумма = лимит − текущий долг', () {
      final info = debtLimitInfo(
          client({
            'debtLimit': 5000000,
            'balanceList': [
              {'totalAmount': -2000000, 'currencyId': 1}
            ]
          }),
          kRate);
      expect(info.currentDebt, 2000000);
      expect(info.available, 3000000);
    });
    test('долг больше лимита → доступно 0, а не отрицательное', () {
      final info = debtLimitInfo(
          client({
            'debtLimit': 1000000,
            'balanceList': [
              {'totalAmount': -2000000, 'currencyId': 1}
            ]
          }),
          kRate);
      expect(info.available, 0);
    });
    test('локальные чеки добавляются к текущему долгу', () {
      final info = debtLimitInfo(
          client({
            'debtLimit': 5000000,
            'balanceList': [
              {'totalAmount': -2000000, 'currencyId': 1}
            ]
          }),
          kRate,
          1000000);
      expect(info.currentDebt, 3000000);
      expect(info.available, 2000000);
    });
  });

  group('checkClientDebtLimit', () {
    DebtLimitCheck run({
      Map? clientOverride,
      dynamic addAmount = 1000000,
      dynamic addCurrencyId = currencyUzs,
      dynamic currencyRate = kRate,
      dynamic pending = 0,
    }) =>
        checkClientDebtLimit(
          client: clientOverride ??
              client({
                'debtLimit': 5000000,
                'balanceList': [
                  {'totalAmount': -3000000, 'currencyId': 1}
                ]
              }),
          addAmount: addAmount,
          addCurrencyId: addCurrencyId,
          currencyRate: currencyRate,
          pendingDebtUzsAmount: pending,
        );

    test('в пределах лимита → продажа разрешена', () {
      final r = run();
      expect(r.checked, isTrue);
      expect(r.exceeded, isFalse);
      expect(r.total, 4000000);
    });
    test('превышение лимита → продажа запрещена', () {
      final r = run(addAmount: 2500000);
      expect(r.exceeded, isTrue);
      expect(r.total, 5500000);
    });
    test('ровно в лимит → разрешено', () {
      expect(run(addAmount: 2000000).exceeded, isFalse);
    });
    test('сумма долга приходит отрицательной (сдача) → берём модуль', () {
      expect(run(addAmount: -2500000).exceeded, isTrue);
    });
    test('debtLimit = 0 → проверка не проводится', () {
      final r = run(
          clientOverride: client({
        'debtLimit': 0,
        'balanceList': [
          {'totalAmount': -90000000, 'currencyId': 1}
        ]
      }));
      expect(r.checked, isFalse);
      expect(r.exceeded, isFalse);
    });
    test('нет курса при долларовом долге → не блокируем, решает сервер', () {
      final r = checkClientDebtLimit(
        client: client({
          'debtLimit': 1000000,
          'balanceList': [
            {'totalAmount': -100, 'currencyId': 2}
          ]
        }),
        addAmount: 500000,
        addCurrencyId: currencyUzs,
        currencyRate: 0,
      );
      expect(r.checked, isFalse);
      expect(r.exceeded, isFalse);
    });
    test('новый долг в долларах пересчитывается по курсу', () {
      final r = run(addAmount: 200, addCurrencyId: currencyUsd);
      expect(r.newDebt, 2400000);
      expect(r.exceeded, isTrue);
    });
    test('локальные несинхронизированные чеки учитываются', () {
      final r = run(addAmount: 1500000, pending: 1000000);
      expect(r.currentDebt, 4000000);
      expect(r.exceeded, isTrue);
    });
    test('клиент без долга и с лимитом → разрешено', () {
      final r = run(
          clientOverride: client({'debtLimit': 5000000}),
          addAmount: 4999999);
      expect(r.exceeded, isFalse);
    });
  });

  // Реальный случай из лога кассы (клиент 53818, точка 710): лимит 50 000,
  // balance -177 500 = -132 500 сум + -3.75 USD, курс точки в кассе НЕ задан.
  group('регресс: нет курса валюты', () {
    final realClient = {
      'debtLimit': 50000,
      'balance': -177500,
      'balanceList': [
        {'currencyId': 1, 'currencyName': "So'm", 'totalAmount': -132500},
        {'currencyId': 2, 'currencyName': 'USD', 'totalAmount': -3.75},
      ],
    };

    test('скалярный balance даёт полный долг без курса', () {
      final r = clientDebtUzs(realClient, null);
      expect(r.debt, 177500);
      expect(r.unknown, isFalse);
    });

    test('продажа в долг блокируется без курса валюты', () {
      final r = checkClientDebtLimit(
        client: realClient,
        addAmount: -51750,
        addCurrencyId: currencyUzs,
        currencyRate: null,
      );
      expect(r.checked, isTrue);
      expect(r.exceeded, isTrue);
    });

    test('только balanceList и нет курса: известной части хватает → блокируем',
        () {
      final r = checkClientDebtLimit(
        client: {
          'debtLimit': 50000,
          'balanceList': realClient['balanceList'],
        },
        addAmount: 10000,
        addCurrencyId: currencyUzs,
        currencyRate: 0,
      );
      expect(r.exceeded, isTrue);
      expect(r.unknownPart, isTrue);
    });

    test('известной части не хватает, часть неизвестна → решает сервер', () {
      final r = checkClientDebtLimit(
        client: {
          'debtLimit': 5000000,
          'balanceList': realClient['balanceList'],
        },
        addAmount: 10000,
        addCurrencyId: currencyUzs,
        currencyRate: 0,
      );
      expect(r.checked, isFalse);
      expect(r.exceeded, isFalse);
    });

    test('balance всегда в сумах — валюта точки на него не влияет', () {
      final r = clientDebtUzs({'balance': -47500}, kRate);
      expect(r.debt, 47500);
      expect(r.unknown, isFalse);
    });
  });

  // Реальный случай 18.08.2026 (клиент 53818, точка 710 в долларах):
  // лимит 50 000 сум, usedDebt 47 500, balance -47 500, курс точки неизвестен.
  group('регресс: долларовая точка без курса', () {
    final realClient = {
      'debtLimit': 50000,
      'usedDebt': 47500,
      'balance': -47500,
      'balanceList': [
        {'currencyId': 1, 'currencyName': "So'm", 'totalAmount': -32500},
        {'currencyId': 2, 'currencyName': 'USD', 'totalAmount': -1.25},
      ],
    };

    test('usedDebt с сервера — весь долг в сумах', () {
      expect(readUsedDebt(realClient), 47500);
      final r = clientDebtUzs(realClient, null);
      expect(r.debt, 47500);
      expect(r.unknown, isFalse);
    });

    test('курс выводится из баланса клиента', () {
      expect(deriveCurrencyRate(realClient), 12000);
      expect(
          deriveCurrencyRate({
            'balance': -32500,
            'balanceList': [
              {'currencyId': 1, 'totalAmount': -32500}
            ]
          }),
          0);
      expect(deriveCurrencyRate(null), 0);
    });

    test('доступно в долг считается по usedDebt, а не по сумовой части', () {
      final info = debtLimitInfo(realClient, null);
      expect(info.currentDebt, 47500);
      expect(info.available, 2500);
    });

    test('продажа 30 USD в долг блокируется без курса точки', () {
      final r = checkClientDebtLimit(
        client: realClient,
        addAmount: -30,
        addCurrencyId: currencyUsd,
        currencyRate: null,
      );
      expect(r.checked, isTrue);
      expect(r.newDebt, 360000);
      expect(r.exceeded, isTrue);
    });

    test('продажа в пределах лимита проходит', () {
      final r = checkClientDebtLimit(
        client: realClient,
        addAmount: -2000,
        addCurrencyId: currencyUzs,
        currencyRate: null,
      );
      expect(r.exceeded, isFalse);
    });

    test('курс вывести не из чего → решает сервер, кассу не блокируем', () {
      final r = checkClientDebtLimit(
        client: {
          'debtLimit': 50000,
          'usedDebt': 0,
          'balance': 0,
          'balanceList': []
        },
        addAmount: -30,
        addCurrencyId: currencyUsd,
        currencyRate: 0,
      );
      expect(r.checked, isFalse);
      expect(r.exceeded, isFalse);
    });
  });

  group('pendingDebtUzs', () {
    test('суммирует локальные чеки по валютам', () {
      final total = pendingDebtUzs([
        {'clientCurrencyId': 1, 'amount': 500000},
        {'clientCurrencyId': 2, 'amount': 10},
      ], kRate);
      expect(total, 620000);
    });
    test('строки без курса пропускаются', () {
      expect(
          pendingDebtUzs([
            {'clientCurrencyId': 2, 'amount': 10}
          ], 0),
          0);
    });
    test('мусор на входе → 0', () {
      expect(pendingDebtUzs(null, kRate), 0);
      expect(pendingDebtUzs([], kRate), 0);
    });
  });
}
