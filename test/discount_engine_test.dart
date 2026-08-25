import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mdokon/features/cashier/domain/discount_engine.dart';

// Порт src/helpers/__tests__/discountEngine.test.js из desktop-кассы.

Map<String, dynamic> item([Map<String, dynamic> over = const {}]) => {
      'productId': 1,
      'categoryId': 10,
      'salePrice': 1000,
      'wholesalePrice': 800,
      'bankPrice': 700,
      'active_price': 0,
      'quantity': 1,
      'vat': 0,
      ...over,
    };

final DateTime kNow = DateTime(2026, 7, 20, 12, 0); // 20 июля 2026, 12:00
final int kIso = kNow.weekday;

num sumBase(List<Map> items) =>
    items.fold<num>(0, (s, it) => s + itemBase(it));

DiscountResult run(
  List rules,
  List<Map> items, {
  num? chequeSum,
  List clientSegments = const [],
  dynamic paymentTypeId,
  String? promocode,
  Iterable? selectedManualRuleIds,
  DateTime? now,
}) =>
    computeDiscounts(
      rules: rules,
      items: items,
      context: DiscountContext(
        chequeSum: chequeSum ?? sumBase(items),
        clientSegments: clientSegments,
        paymentTypeId: paymentTypeId,
        promocode: promocode,
        selectedManualRuleIds: selectedManualRuleIds,
        now: now ?? kNow,
      ),
    );

void main() {
  group('unitPrice / itemBase', () {
    test('active_price выбирает розницу/опт/банк', () {
      expect(unitPrice(item({'active_price': 0})), 1000);
      expect(unitPrice(item({'active_price': 1})), 800);
      expect(unitPrice(item({'active_price': 2})), 700);
    });
    test('itemBase = unitPrice * quantity', () {
      expect(itemBase(item({'quantity': 3})), 3000);
    });
  });

  group('защита от пустых данных', () {
    test('пустые правила → нули', () {
      final r = run([], [item({'quantity': 2})]);
      expect(r.itemDiscounts, [0]);
      expect(r.chequeDiscount, 0);
      expect(r.totalDiscount, 0);
    });
    test('null правила → нули без исключения', () {
      final r = computeDiscounts(
          rules: null, items: [item()], context: DiscountContext(now: kNow));
      expect(r.totalDiscount, 0);
    });
  });

  group('PERCENT', () {
    test('процент на позицию при targets = ALL', () {
      final rules = [
        {'id': 1, 'type': 'PERCENT', 'valueType': 'PERCENT', 'value': 10}
      ];
      final r = run(rules, [item({'quantity': 2})]); // база 2000
      expect(r.itemDiscounts[0], closeTo(200, 0.01));
      expect(r.totalDiscount, closeTo(200, 0.01));
    });
    test('процент от оптовой цены при active_price=1', () {
      final rules = [
        {'id': 1, 'type': 'PERCENT', 'valueType': 'PERCENT', 'value': 10}
      ];
      final r = run(rules, [
        item({'active_price': 1, 'quantity': 2})
      ]); // база 1600
      expect(r.itemDiscounts[0], closeTo(160, 0.01));
    });
  });

  group('FIXED', () {
    test('AMOUNT за единицу × qty', () {
      final rules = [
        {'id': 1, 'type': 'FIXED', 'valueType': 'AMOUNT', 'value': 100}
      ];
      final r = run(rules, [item({'quantity': 3})]);
      expect(r.itemDiscounts[0], closeTo(300, 0.01));
    });
    test('обрезается по базе позиции', () {
      final rules = [
        {'id': 1, 'type': 'FIXED', 'valueType': 'AMOUNT', 'value': 5000}
      ];
      final r = run(rules, [item({'quantity': 1})]); // база 1000
      expect(r.itemDiscounts[0], 1000);
    });
  });

  group('QUANTITY_PRICE', () {
    final rules = [
      {
        'id': 1,
        'type': 'QUANTITY_PRICE',
        'tiers': [
          {'threshold': 1, 'value': 1000, 'valueType': 'PRICE'},
          {'threshold': 3, 'value': 900, 'valueType': 'PRICE'},
        ],
      }
    ];
    test('qty=3 берёт ступень 900 → (1000-900)*3 = 300', () {
      final r = run(rules, [item({'quantity': 3})]);
      expect(r.itemDiscounts[0], closeTo(300, 0.01));
    });
    test('qty=1 берёт ступень 1000 → скидки нет', () {
      final r = run(rules, [item({'quantity': 1})]);
      expect(r.itemDiscounts[0], 0);
    });
    test('нет ступени ниже qty → скидки нет', () {
      final r = run([
        {
          'id': 1,
          'type': 'QUANTITY_PRICE',
          'tiers': [
            {'threshold': 5, 'value': 900, 'valueType': 'PRICE'}
          ],
        }
      ], [
        item({'quantity': 2})
      ]);
      expect(r.itemDiscounts[0], 0);
    });
  });

  group('CHEQUE_THRESHOLD', () {
    test('процентная ступень на весь чек', () {
      final rules = [
        {
          'id': 1,
          'type': 'CHEQUE_THRESHOLD',
          'tiers': [
            {'threshold': 100000, 'value': 5, 'valueType': 'PERCENT'},
            {'threshold': 500000, 'value': 10, 'valueType': 'PERCENT'},
          ],
        }
      ];
      final r = run(rules, [
        item({'salePrice': 300000, 'quantity': 1})
      ]); // chequeSum 300000 → 5%
      expect(r.chequeDiscount, closeTo(15000, 0.01));
      expect(r.itemDiscounts[0], 0);
    });
  });

  group('SECOND_ITEM', () {
    test('каждая вторая единица -50%', () {
      final rules = [
        {'id': 1, 'type': 'SECOND_ITEM', 'valueType': 'PERCENT', 'value': 50}
      ];
      final r = run(rules, [item({'quantity': 2})]);
      expect(r.itemDiscounts[0], closeTo(500, 0.01));
    });
    test('3 единицы → скидка только на одну вторую', () {
      final rules = [
        {'id': 1, 'type': 'SECOND_ITEM', 'valueType': 'AMOUNT', 'value': 100}
      ];
      final r = run(rules, [item({'quantity': 3})]);
      expect(r.itemDiscounts[0], closeTo(100, 0.01));
    });
  });

  group('BUNDLE', () {
    final rules = [
      {
        'id': 1,
        'type': 'BUNDLE',
        'value': 1200,
        'targets': [
          {'targetType': 'PRODUCT', 'targetId': 1},
          {'targetType': 'PRODUCT', 'targetId': 2},
        ],
      }
    ];
    test('набор из двух, скидка пропорционально цене', () {
      final items = [
        item({'productId': 1, 'salePrice': 1000}),
        item({'productId': 2, 'salePrice': 500}),
      ];
      final r = run(rules, items); // 1500 - 1200 = 300; 200/100
      expect(r.itemDiscounts[0], closeTo(200, 0.01));
      expect(r.itemDiscounts[1], closeTo(100, 0.01));
    });
    test('неполный набор → скидки нет + причина', () {
      final r = run(rules, [item({'productId': 1})]);
      expect(r.totalDiscount, 0);
      expect(r.skipped.any((s) => s.reason == 'bundle_incomplete'), isTrue);
    });
  });

  group('TIME', () {
    test('внутри окна дня и времени работает как процент', () {
      final rules = [
        {
          'id': 1,
          'type': 'TIME',
          'valueType': 'PERCENT',
          'value': 10,
          'weekdays': '$kIso',
          'timeFrom': '09:00',
          'timeTo': '18:00',
        }
      ];
      final r = run(rules, [item({'quantity': 1})]);
      expect(r.itemDiscounts[0], closeTo(100, 0.01));
    });
    test('вне окна времени → скидки нет', () {
      final rules = [
        {
          'id': 1,
          'type': 'TIME',
          'valueType': 'PERCENT',
          'value': 10,
          'timeFrom': '13:00',
          'timeTo': '18:00'
        }
      ];
      expect(run(rules, [item()]).totalDiscount, 0); // сейчас 12:00
    });
    test('другой день недели → скидки нет', () {
      final other = kIso == 7 ? 1 : kIso + 1;
      final rules = [
        {
          'id': 1,
          'type': 'TIME',
          'valueType': 'PERCENT',
          'value': 10,
          'weekdays': '$other'
        }
      ];
      expect(run(rules, [item()]).totalDiscount, 0);
    });
    test('00:00:00–00:00:00 → окно не ограничивает', () {
      final rules = [
        {
          'id': 1,
          'type': 'TIME',
          'valueType': 'PERCENT',
          'value': 10,
          'timeFrom': '00:00:00',
          'timeTo': '00:00:00'
        }
      ];
      expect(run(rules, [item()]).itemDiscounts[0], closeTo(100, 0.01));
    });
    test('формат HH:MM:SS понимается', () {
      final inside = [
        {
          'id': 1,
          'type': 'TIME',
          'valueType': 'PERCENT',
          'value': 10,
          'timeFrom': '09:00:00',
          'timeTo': '18:00:00'
        }
      ];
      final outside = [
        {
          'id': 1,
          'type': 'TIME',
          'valueType': 'PERCENT',
          'value': 10,
          'timeFrom': '13:00:00',
          'timeTo': '18:00:00'
        }
      ];
      expect(run(inside, [item()]).itemDiscounts[0], closeTo(100, 0.01));
      expect(run(outside, [item()]).totalDiscount, 0);
    });
    test('граница окна включительна', () {
      final rules = [
        {
          'id': 1,
          'type': 'TIME',
          'valueType': 'PERCENT',
          'value': 10,
          'timeFrom': '12:00:00',
          'timeTo': '18:00:00'
        }
      ];
      expect(run(rules, [item()]).itemDiscounts[0], closeTo(100, 0.01));
    });
    test('окно через полночь', () {
      final rules = [
        {
          'id': 1,
          'type': 'TIME',
          'valueType': 'PERCENT',
          'value': 10,
          'timeFrom': '22:00:00',
          'timeTo': '13:00:00'
        }
      ];
      expect(run(rules, [item()]).itemDiscounts[0], closeTo(100, 0.01));
    });
  });

  group('CLIENT_SEGMENT', () {
    final rules = [
      {
        'id': 1,
        'type': 'CLIENT_SEGMENT',
        'valueType': 'PERCENT',
        'value': 10,
        'clientStatusRuleId': 5
      }
    ];
    test('применяется, если клиент в сегменте', () {
      final r = run(rules, [item()], clientSegments: [5, 8]);
      expect(r.itemDiscounts[0], closeTo(100, 0.01));
    });
    test('пропускается, если клиент не в сегменте', () {
      expect(run(rules, [item()], clientSegments: [3]).totalDiscount, 0);
    });
  });

  group('PAYMENT_TYPE', () {
    final rules = [
      {
        'id': 1,
        'type': 'PAYMENT_TYPE',
        'valueType': 'PERCENT',
        'value': 5,
        'paymentTypeId': 2
      }
    ];
    test('применяется при совпадении типа оплаты', () {
      final r = run(rules, [item({'salePrice': 10000})], paymentTypeId: 2);
      expect(r.chequeDiscount, closeTo(500, 0.01));
    });
    test('другой тип оплаты → скидки нет', () {
      final r = run(rules, [item({'salePrice': 10000})], paymentTypeId: 1);
      expect(r.totalDiscount, 0);
    });
  });

  group('EXPIRY', () {
    final rules = [
      {
        'id': 1,
        'type': 'EXPIRY',
        'valueType': 'PERCENT',
        'value': 20,
        'expiryDays': 7
      }
    ];
    test('применяется у истекающего срока', () {
      final r = run(rules, [
        item({'expDate': DateTime(2026, 7, 23)})
      ]);
      expect(r.itemDiscounts[0], closeTo(200, 0.01));
    });
    test('пропускается, если срок далеко', () {
      final r = run(rules, [
        item({'expDate': DateTime(2026, 9, 1)})
      ]);
      expect(r.totalDiscount, 0);
    });
    test('пропускается при пустом expDate', () {
      expect(run(rules, [item({'expDate': ''})]).totalDiscount, 0);
    });
  });

  group('PROMOCODE', () {
    final rules = [
      {
        'id': 1,
        'type': 'PROMOCODE',
        'valueType': 'PERCENT',
        'value': 10,
        'promocode': 'SALE'
      }
    ];
    test('применяется при совпавшем коде', () {
      final r = run(rules, [item()], promocode: 'SALE');
      expect(r.itemDiscounts[0], closeTo(100, 0.01));
    });
    test('без кода скидки нет', () {
      expect(run(rules, [item()]).totalDiscount, 0);
    });
    test('промокод на весь чек', () {
      final chequeRules = [
        {
          'id': 1,
          'type': 'PROMOCODE',
          'valueType': 'AMOUNT',
          'value': 300,
          'promocode': 'X',
          'limitScope': 'CHEQUE'
        }
      ];
      final r =
          run(chequeRules, [item({'salePrice': 10000})], promocode: 'X');
      expect(r.chequeDiscount, closeTo(300, 0.01));
    });
  });

  group('ручной режим применения', () {
    final rules = [
      {
        'id': 7,
        'type': 'PERCENT',
        'applyMode': 'MANUAL',
        'valueType': 'PERCENT',
        'value': 10
      }
    ];
    test('не применяется, пока не выбрано кассиром', () {
      expect(run(rules, [item()]).totalDiscount, 0);
    });
    test('применяется при выборе кассиром', () {
      final r = run(rules, [item()], selectedManualRuleIds: [7]);
      expect(r.itemDiscounts[0], closeTo(100, 0.01));
    });
  });

  group('стек и приоритет', () {
    test('нестекируемое второе правило пропускает позицию со скидкой', () {
      final rules = [
        {
          'id': 1,
          'priority': 1,
          'type': 'PERCENT',
          'valueType': 'PERCENT',
          'value': 10,
          'stackable': true
        },
        {
          'id': 2,
          'priority': 2,
          'type': 'PERCENT',
          'valueType': 'PERCENT',
          'value': 10,
          'stackable': false
        },
      ];
      expect(run(rules, [item()]).itemDiscounts[0], closeTo(100, 0.01));
    });
    test('стекируемые правила складываются', () {
      final rules = [
        {
          'id': 1,
          'priority': 1,
          'type': 'PERCENT',
          'valueType': 'PERCENT',
          'value': 10,
          'stackable': true
        },
        {
          'id': 2,
          'priority': 2,
          'type': 'PERCENT',
          'valueType': 'PERCENT',
          'value': 10,
          'stackable': true
        },
      ];
      expect(run(rules, [item()]).itemDiscounts[0], closeTo(200, 0.01));
    });
    test('меньший приоритет применяется первым', () {
      final rules = [
        {
          'id': 1,
          'priority': 2,
          'type': 'FIXED',
          'valueType': 'AMOUNT',
          'value': 50,
          'stackable': false
        },
        {
          'id': 2,
          'priority': 1,
          'type': 'FIXED',
          'valueType': 'AMOUNT',
          'value': 100,
          'stackable': false
        },
      ];
      expect(run(rules, [item()]).itemDiscounts[0], closeTo(100, 0.01));
    });
  });

  group('вердикт CASHIER_LIMIT', () {
    test('ITEM: превышен процент по позиции', () {
      final rules = [
        {
          'id': 1,
          'priority': 1,
          'type': 'PERCENT',
          'valueType': 'PERCENT',
          'value': 20
        },
        {
          'id': 2,
          'type': 'CASHIER_LIMIT',
          'limitScope': 'ITEM',
          'maxDiscountPercent': 10
        },
      ];
      final r = run(rules, [item()]);
      expect(r.limit, isNotNull);
      expect(r.limit!.scope, 'ITEM');
      expect(r.limit!.itemIndex, 0);
    });
    test('CHEQUE: превышена сумма по чеку', () {
      final rules = [
        {
          'id': 1,
          'priority': 1,
          'type': 'FIXED',
          'valueType': 'AMOUNT',
          'value': 500
        },
        {
          'id': 2,
          'type': 'CASHIER_LIMIT',
          'limitScope': 'CHEQUE',
          'maxDiscountAmount': 300
        },
      ];
      final r = run(rules, [item()]);
      expect(r.limit, isNotNull);
      expect(r.limit!.scope, 'CHEQUE');
    });
    test('в пределах лимита нарушения нет', () {
      final rules = [
        {
          'id': 1,
          'priority': 1,
          'type': 'PERCENT',
          'valueType': 'PERCENT',
          'value': 5
        },
        {
          'id': 2,
          'type': 'CASHIER_LIMIT',
          'limitScope': 'ITEM',
          'maxDiscountPercent': 10
        },
      ];
      expect(run(rules, [item()]).limit, isNull);
    });
  });

  group('сопоставление targets', () {
    test('CATEGORY точное совпадение', () {
      expect(
          matchesTarget(item({'categoryId': 2}),
              [{'targetType': 'CATEGORY', 'targetId': 2}]),
          isTrue);
      expect(
          matchesTarget(item({'categoryId': 3}),
              [{'targetType': 'CATEGORY', 'targetId': 2}]),
          isFalse);
    });
    test('CATEGORY через categoryPath (подкатегории)', () {
      expect(
          matchesTarget(
              item({'categoryId': 9, 'categoryPath': [1, 5, 9]}),
              [{'targetType': 'CATEGORY', 'targetId': 5}]),
          isTrue);
      expect(
          matchesTarget(item({'categoryId': 9, 'categoryPath': '1,5,9'}),
              [{'targetType': 'CATEGORY', 'targetId': 5}]),
          isTrue);
    });
    test('BRAND пропускается без brandName', () {
      expect(
          matchesTarget(
              item(), [{'targetType': 'BRAND', 'targetValue': 'Coca'}]),
          isFalse);
      expect(
          matchesTarget(item({'brandName': 'Coca'}),
              [{'targetType': 'BRAND', 'targetValue': 'Coca'}]),
          isTrue);
    });
    test('пустые targets = ALL', () {
      expect(matchesTarget(item(), []), isTrue);
      expect(matchesTarget(item(), null), isTrue);
    });
  });

  group('реальное правило бэкенда (posId 710 "Test skidka")', () {
    final realRule = {
      'id': 2,
      'posId': 710,
      'name': 'Test skidka',
      'type': 'QUANTITY_PRICE',
      'valueType': null,
      'value': null,
      'applyMode': 'AUTO',
      'priority': 1,
      'stackable': false,
      'validFrom': '2026-07-21T00:00:00',
      'validTo': '2026-07-26T00:00:00',
      'weekdays': null,
      'timeFrom': null,
      'timeTo': null,
      'minChequeAmount': 50000.000,
      'maxDiscountAmount': null,
      'maxDiscountPercent': null,
      'limitScope': null,
      'clientStatusRuleId': null,
      'paymentTypeId': null,
      'promocode': null,
      'expiryDays': null,
      'tiers': [
        {'id': 4, 'threshold': 3.000, 'value': 1000.000, 'valueType': 'PRICE'}
      ],
      'targets': [],
    };
    final inWindow = DateTime(2026, 7, 22, 12, 0);

    test('qty>=3 и чек>=50000 → цена падает до 1000/шт', () {
      final r = run(
        [realRule],
        [item({'salePrice': 5000, 'quantity': 10})],
        chequeSum: 50000,
        now: inWindow,
      );
      expect(r.itemDiscounts[0], closeTo(40000, 0.01)); // (5000-1000)*10
    });
    test('чек < 50000 → скидки нет (minChequeAmount)', () {
      final r = run(
        [realRule],
        [item({'salePrice': 5000, 'quantity': 3})],
        chequeSum: 15000,
        now: inWindow,
      );
      expect(r.totalDiscount, 0);
    });
    test('qty < 3 → нет подходящей ступени', () {
      final r = run(
        [realRule],
        [item({'salePrice': 30000, 'quantity': 2})],
        chequeSum: 60000,
        now: inWindow,
      );
      expect(r.totalDiscount, 0);
    });
    test('вне периода действия → скидки нет', () {
      final r = run(
        [realRule],
        [item({'salePrice': 5000, 'quantity': 10})],
        chequeSum: 50000,
        now: DateTime(2026, 7, 28),
      );
      expect(r.totalDiscount, 0);
    });
  });

  group('clearEngineDiscounts', () {
    test('обнуляет поля скидок', () {
      final data = {
        'itemsList': [
          {'discountAmount': 100},
          {'discountAmount': 50}
        ],
        'discountAmount': 150,
        'totalPriceBeforeDiscount': 5000,
        'discountSource': 'ENGINE',
      };
      clearEngineDiscounts(data);
      expect((data['itemsList'] as List)[0]['discountAmount'], 0);
      expect((data['itemsList'] as List)[1]['discountAmount'], 0);
      expect(data['discountAmount'], 0);
      expect(data['totalPriceBeforeDiscount'], 0);
      expect(data['discountSource'], '');
    });
  });
}
