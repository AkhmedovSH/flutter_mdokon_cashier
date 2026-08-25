import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mdokon/features/cashier/domain/discount_engine.dart';
import 'package:flutter_mdokon/features/cashier/domain/promotion_engine.dart';

// Порт src/helpers/__tests__/promotionEngine.test.js из desktop-кассы.

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

final DateTime kNow = DateTime(2026, 7, 20, 12, 0); // понедельник, 12:00
final int kIso = kNow.weekday;

num sumBase(List<Map> items) => items.fold<num>(
    0, (s, it) => s + (it['salePrice'] as num) * (it['quantity'] as num));

PromotionResult run(
  List rules,
  List<Map> items, {
  num? chequeSum,
  List clientSegments = const [],
  Iterable? selectedManualRuleIds,
  DateTime? now,
}) =>
    computePromotions(
      rules: rules,
      items: items,
      context: DiscountContext(
        chequeSum: chequeSum ?? sumBase(items),
        clientSegments: clientSegments,
        selectedManualRuleIds: selectedManualRuleIds,
        now: now ?? kNow,
      ),
    );

void main() {
  group('защита от пустых данных', () {
    test('пустой список правил → ничего', () {
      final r = run([], [item({'quantity': 5})]);
      expect(r.gifts, isEmpty);
      expect(r.lineFree, isEmpty);
      expect(r.applied, isEmpty);
    });
    test('rules=null → без исключения', () {
      final r = computePromotions(
          rules: null, items: [item()], context: DiscountContext(now: kNow));
      expect(r.gifts, isEmpty);
    });
    test('пустая корзина → подарков нет', () {
      final rules = [
        {
          'id': 1,
          'type': 'GIFT_ON_AMOUNT',
          'minChequeAmount': 100,
          'gifts': [
            {'productId': 9, 'quantity': 1}
          ]
        }
      ];
      final r = computePromotions(
          rules: rules,
          items: [],
          context: DiscountContext(chequeSum: 0, now: kNow));
      expect(r.gifts, isEmpty);
    });
  });

  group('GIFT_N_M', () {
    Map<String, dynamic> rule([Map<String, dynamic> over = const {}]) => {
          'id': 1,
          'type': 'GIFT_N_M',
          'buyQuantity': 3,
          'giftQuantity': 1,
          'targets': [
            {'targetType': 'PRODUCT', 'targetId': 1}
          ],
          'gifts': [
            {'productId': 812, 'quantity': 1}
          ],
          ...over,
        };

    test('куплено 3 → 1 подарок', () {
      final r = run([rule()], [item({'quantity': 3})]);
      expect(r.gifts, hasLength(1));
      expect(r.gifts[0].productId, 812);
      expect(r.gifts[0].quantity, 1);
      expect(r.gifts[0].ruleId, 1);
      expect(r.gifts[0].giftDiscountPercent, 100);
      expect(r.applied[0].times, 1);
    });
    test('куплено 7 → 2 подарка (кратность вниз)', () {
      final r = run([rule()], [item({'quantity': 7})]);
      expect(r.gifts[0].quantity, 2);
    });
    test('куплено 2 → подарка нет', () {
      expect(run([rule()], [item({'quantity': 2})]).gifts, isEmpty);
    });
    test('maxApply ограничивает кратность', () {
      final r = run([rule({'maxApply': 2})], [item({'quantity': 12})]);
      expect(r.gifts[0].quantity, 2);
    });
    test('количество суммируется по подходящим позициям', () {
      final rules = [
        rule({
          'targets': [
            {'targetType': 'CATEGORY', 'targetId': 10}
          ]
        })
      ];
      final r = run(rules, [
        item({'productId': 1, 'quantity': 2}),
        item({'productId': 2, 'quantity': 1}),
      ]);
      expect(r.gifts[0].quantity, 1);
    });
    test('несколько подарков в одном правиле', () {
      final r = run([
        rule({
          'gifts': [
            {'productId': 5, 'quantity': 1},
            {'productId': 6, 'quantity': 2},
          ]
        })
      ], [
        item({'quantity': 3})
      ]);
      expect(r.gifts.map((g) => [g.productId, g.quantity]).toList(),
          [
            [5, 1],
            [6, 2]
          ]);
    });
    test('giftQuantity используется, если у подарка нет количества', () {
      final r = run([
        rule({
          'giftQuantity': 2,
          'gifts': [
            {'productId': 812}
          ]
        })
      ], [
        item({'quantity': 3})
      ]);
      expect(r.gifts[0].quantity, 2);
    });
    test('правило без gifts пропускается', () {
      final r = run([rule({'gifts': []})], [item({'quantity': 3})]);
      expect(r.gifts, isEmpty);
      expect(r.skipped[0].reason, 'no_gifts');
    });
    test('подарочные позиции не считаются покупкой', () {
      final items = [
        item({'quantity': 2}),
        item({'quantity': 5, 'promotionGift': true}),
      ];
      expect(run([rule()], items).gifts, isEmpty);
    });
    test('legacy-подарок (promotion) не считается покупкой', () {
      final items = [
        item({'quantity': 2}),
        item({'quantity': 5, 'promotion': true}),
      ];
      expect(run([rule()], items).gifts, isEmpty);
    });
  });

  group('BOGO', () {
    test('купи 1 → получи 1', () {
      final rules = [
        {
          'id': 2,
          'type': 'BOGO',
          'targets': [],
          'gifts': [
            {'productId': 3, 'quantity': 1}
          ]
        }
      ];
      expect(run(rules, [item({'quantity': 2})]).gifts[0].quantity, 2);
    });
    test('maxApply=1 → только один подарок', () {
      final rules = [
        {
          'id': 2,
          'type': 'BOGO',
          'maxApply': 1,
          'targets': [],
          'gifts': [
            {'productId': 3, 'quantity': 1}
          ]
        }
      ];
      expect(run(rules, [item({'quantity': 5})]).gifts[0].quantity, 1);
    });
  });

  group('EVERY_NTH_FREE', () {
    Map<String, dynamic> rule([Map<String, dynamic> over = const {}]) => {
          'id': 3,
          'type': 'EVERY_NTH_FREE',
          'buyQuantity': 3,
          'targets': [],
          ...over,
        };

    test('3 шт по 1000 → 1 бесплатная единица внутри позиции', () {
      final r = run([rule()], [item({'quantity': 3})]);
      expect(r.gifts, isEmpty);
      expect(r.lineFree, hasLength(1));
      expect(r.lineFree[0].itemIndex, 0);
      expect(r.lineFree[0].units, 1);
      expect(r.lineFree[0].amount, 1000);
    });
    test('7 шт → 2 бесплатные единицы', () {
      final r = run([rule()], [item({'quantity': 7})]);
      expect(r.lineFree[0].units, 2);
      expect(r.lineFree[0].amount, closeTo(2000, 0.01));
    });
    test('бесплатными становятся самые дешёвые единицы', () {
      final items = [
        item({'productId': 1, 'salePrice': 5000, 'quantity': 2}),
        item({'productId': 2, 'salePrice': 1000, 'quantity': 1}),
      ];
      final r = run([rule()], items); // всего 3 шт → 1 бесплатно
      expect(r.lineFree, hasLength(1));
      expect(r.lineFree[0].itemIndex, 1);
      expect(r.lineFree[0].units, 1);
      expect(r.lineFree[0].amount, 1000);
    });
    test('giftDiscountPercent<100 → подарок со скидкой', () {
      final r =
          run([rule({'giftDiscountPercent': 50})], [item({'quantity': 3})]);
      expect(r.lineFree[0].amount, closeTo(500, 0.01));
    });
    test('меньше N → бесплатных единиц нет', () {
      expect(run([rule()], [item({'quantity': 2})]).lineFree, isEmpty);
    });
    test('без buyQuantity правило пропускается', () {
      final r = run([rule({'buyQuantity': null})], [item({'quantity': 9})]);
      expect(r.lineFree, isEmpty);
      expect(r.skipped[0].reason, 'no_buy_quantity');
    });
    test('цена берётся по active_price (оптовая)', () {
      final r = run([rule()], [item({'active_price': 1, 'quantity': 3})]);
      expect(r.lineFree[0].amount, closeTo(800, 0.01));
    });
  });

  group('GIFT_ON_AMOUNT', () {
    Map<String, dynamic> rule([Map<String, dynamic> over = const {}]) => {
          'id': 4,
          'type': 'GIFT_ON_AMOUNT',
          'minChequeAmount': 5000,
          'gifts': [
            {'productId': 77, 'quantity': 1}
          ],
          ...over,
        };

    test('чек не меньше порога → подарок', () {
      final r = run([rule()], [item({'quantity': 5})]); // 5000
      expect(r.gifts[0].productId, 77);
      expect(r.gifts[0].quantity, 1);
    });
    test('чек ниже порога → подарка нет', () {
      expect(run([rule()], [item({'quantity': 4})]).gifts, isEmpty);
    });
    test('без порога правило считается недонастроенным', () {
      final r = run([rule({'minChequeAmount': null})], [item({'quantity': 5})]);
      expect(r.gifts, isEmpty);
      expect(r.skipped[0].reason, 'no_min_amount');
    });
    test('подарок выдаётся один раз за чек', () {
      expect(run([rule()], [item({'quantity': 50})]).gifts[0].quantity, 1);
    });
  });

  group('GIFT_ON_CATEGORY', () {
    test('покупка из категории → подарок', () {
      final rules = [
        {
          'id': 5,
          'type': 'GIFT_ON_CATEGORY',
          'targets': [
            {'targetType': 'CATEGORY', 'targetId': 10}
          ],
          'gifts': [
            {'productId': 42, 'quantity': 1}
          ],
        }
      ];
      expect(run(rules, [item({'categoryId': 10})]).gifts[0].productId, 42);
    });
    test('другая категория → подарка нет', () {
      final rules = [
        {
          'id': 5,
          'type': 'GIFT_ON_CATEGORY',
          'targets': [
            {'targetType': 'CATEGORY', 'targetId': 99}
          ],
          'gifts': [
            {'productId': 42, 'quantity': 1}
          ],
        }
      ];
      expect(run(rules, [item({'categoryId': 10})]).gifts, isEmpty);
    });
    test('покупка бренда → подарок', () {
      final rules = [
        {
          'id': 5,
          'type': 'GIFT_ON_CATEGORY',
          'targets': [
            {'targetType': 'BRAND', 'targetValue': 'Coca-Cola'}
          ],
          'gifts': [
            {'productId': 42, 'quantity': 1}
          ],
        }
      ];
      expect(run(rules, [item({'brandName': 'Coca-Cola'})]).gifts, hasLength(1));
    });
  });

  group('применимость (общие оси)', () {
    Map<String, dynamic> base([Map<String, dynamic> over = const {}]) => {
          'id': 6,
          'type': 'GIFT_N_M',
          'buyQuantity': 1,
          'targets': [],
          'gifts': [
            {'productId': 1, 'quantity': 1}
          ],
          ...over,
        };

    test('activated=false → правило не работает', () {
      expect(run([base({'activated': false})], [item()]).gifts, isEmpty);
    });
    test('вне периода → не работает', () {
      expect(
          run([base({'validFrom': '2026-08-01T00:00:00'})], [item()]).gifts,
          isEmpty);
    });
    test('другой день недели → не работает', () {
      final other = '${kIso == 7 ? 1 : kIso + 1}';
      expect(run([base({'weekdays': other})], [item()]).gifts, isEmpty);
    });
    test('вне окна часов → не работает', () {
      expect(
          run([
            base({'timeFrom': '18:00:00', 'timeTo': '22:00:00'})
          ], [
            item()
          ]).gifts,
          isEmpty);
    });
    test('в окне часов → работает', () {
      expect(
          run([
            base({'timeFrom': '10:00:00', 'timeTo': '22:00:00'})
          ], [
            item()
          ]).gifts,
          hasLength(1));
    });
    test('00:00:00–00:00:00 → акция работает весь день', () {
      expect(
          run([
            base({'timeFrom': '00:00:00', 'timeTo': '00:00:00'})
          ], [
            item()
          ]).gifts,
          hasLength(1));
    });
    test('реальное правило BOGO из вебки (пт, окно 00:00–00:00)', () {
      final rule = {
        'id': 3,
        'posId': 710,
        'name': 'A2',
        'type': 'BOGO',
        'applyMode': 'AUTO',
        'priority': 0,
        'validFrom': '2026-07-24T00:00:00',
        'validTo': '2026-07-26T00:00:00',
        'weekdays': '5,6,7',
        'timeFrom': '00:00:00',
        'timeTo': '00:00:00',
        'minChequeAmount': null,
        'buyQuantity': null,
        'giftQuantity': null,
        'giftDiscountPercent': 100.0,
        'maxApply': null,
        'clientStatusRuleId': null,
        'targets': [
          {'targetType': 'PRODUCT', 'targetId': 3640855}
        ],
        'gifts': [
          {'productId': 3640854, 'quantity': 1.0}
        ],
      };
      final friday = DateTime(2026, 7, 24, 15, 30); // пятница, ISO 5
      final r = run(
        [rule],
        [item({'productId': 3640855, 'quantity': 3})],
        chequeSum: 3000,
        now: friday,
      );
      expect(r.gifts[0].productId, 3640854);
      expect(r.gifts[0].quantity, 3);
    });
    test('сегмент клиента не совпал → не работает', () {
      final r = run([base({'clientStatusRuleId': 7})], [item()],
          clientSegments: [3]);
      expect(r.gifts, isEmpty);
    });
    test('сегмент клиента совпал → работает', () {
      final r = run([base({'clientStatusRuleId': 7})], [item()],
          clientSegments: [7]);
      expect(r.gifts, hasLength(1));
    });
    test('MANUAL — только после выбора кассиром', () {
      final rule = base({'applyMode': 'MANUAL'});
      expect(run([rule], [item()]).gifts, isEmpty);
      expect(
          run([rule], [item()], selectedManualRuleIds: [6]).gifts, hasLength(1));
    });
    test('причина отказа попадает в skipped', () {
      final other = '${kIso == 7 ? 1 : kIso + 1}';
      final wrongDay =
          run([base({'name': 'A1', 'weekdays': other})], [item()]).skipped[0];
      expect(wrongDay.ruleId, 6);
      expect(wrongDay.name, 'A1');
      expect(wrongDay.reason, 'wrong_weekday');

      expect(
          run([base({'validTo': '2026-07-01T00:00:00'})], [item()])
              .skipped[0]
              .reason,
          'expired');
      expect(
          run([base({'validFrom': '2026-08-01T00:00:00'})], [item()])
              .skipped[0]
              .reason,
          'not_started');
      expect(run([base({'activated': false})], [item()]).skipped[0].reason,
          'not_active');
      expect(
          run([
            base({'timeFrom': '18:00:00', 'timeTo': '22:00:00'})
          ], [
            item()
          ]).skipped[0].reason,
          'out_of_time');
      expect(
          run([base({'clientStatusRuleId': 7})], [item()]).skipped[0].reason,
          'wrong_client_segment');
      expect(run([base({'applyMode': 'MANUAL'})], [item()]).skipped[0].reason,
          'manual_not_selected');
    });
    test('несовпадение товара показывает ожидаемые targets', () {
      final rule = base({
        'targets': [
          {'targetType': 'PRODUCT', 'targetId': 3640855}
        ]
      });
      final r = run([rule], [item({'productId': 3535134})]);
      expect(r.skipped[0].reason, 'no_target_items');
      expect(r.skipped[0].targets, ['PRODUCT:3640855']);
    });
    test('неизвестная механика пропускается', () {
      final r = run([
        {
          'id': 7,
          'type': 'SOMETHING_NEW',
          'gifts': [
            {'productId': 1, 'quantity': 1}
          ]
        }
      ], [
        item()
      ]);
      expect(r.gifts, isEmpty);
      expect(r.skipped[0].reason, 'unknown_type');
    });
  });

  group('giftLineDiscount', () {
    test('100% → скидка равна стоимости позиции', () {
      final line = item(
          {'promotionGift': true, 'giftDiscountPercent': 100, 'quantity': 2});
      expect(giftLineDiscount(line), 2000);
    });
    test('50% → половина стоимости', () {
      final line = item(
          {'promotionGift': true, 'giftDiscountPercent': 50, 'quantity': 2});
      expect(giftLineDiscount(line), 1000);
    });
    test('по умолчанию (percent не задан) — бесплатно', () {
      expect(giftLineDiscount(item({'promotionGift': true, 'quantity': 1})),
          1000);
    });
    test('обычная позиция — нулевая скидка', () {
      expect(giftLineDiscount(item()), 0);
      expect(isPromotionGiftItem(item()), isFalse);
    });
    test('оптовая цена учитывается', () {
      final line =
          item({'promotionGift': true, 'active_price': 1, 'quantity': 1});
      expect(giftLineDiscount(line), 800);
    });
  });

  group('признаки позиции для печатных форм', () {
    test('акция распознаётся и в чеке кассы, и в чеке с сервера', () {
      expect(isPromotionItem(item({'promotionGift': true})), isTrue);
      expect(isPromotionItem(item({'promotionRuleId': 3})), isTrue);
      expect(isPromotionItem(item({'promotionRuleId': 0})), isFalse);
      expect(isPromotionItem(item()), isFalse);
    });
    test('бесплатная позиция = скидка равна стоимости', () {
      expect(
          isFreeByPromotion(item({
            'promotionRuleId': 3,
            'salePrice': 11000,
            'quantity': 1,
            'discountAmount': 11000
          })),
          isTrue);
      expect(
          isFreeByPromotion(item({
            'promotionRuleId': 3,
            'salePrice': 11000,
            'quantity': 1,
            'discountAmount': 5500
          })),
          isFalse);
      expect(
          isFreeByPromotion(item({
            'salePrice': 11000,
            'quantity': 1,
            'discountAmount': 11000
          })),
          isFalse); // обычная скидка
    });
    test('название акции: из чека, из кэша правил, иначе пусто', () {
      final rules = [
        {'id': 3, 'name': 'A2'}
      ];
      expect(getPromotionName(item({'promotionRuleName': '3+1 на кофе'}), rules),
          '3+1 на кофе');
      expect(getPromotionName(item({'promotionRuleId': 3}), rules), 'A2');
      expect(getPromotionName(item({'promotionRuleId': 99}), rules), '');
      expect(getPromotionName(item(), rules), '');
    });
  });

  group('приоритет и порядок', () {
    test('правила применяются по priority, затем по id', () {
      final a = {
        'id': 20,
        'priority': 5,
        'type': 'GIFT_N_M',
        'buyQuantity': 1,
        'targets': [],
        'gifts': [
          {'productId': 1, 'quantity': 1}
        ]
      };
      final b = {
        'id': 10,
        'priority': 1,
        'type': 'GIFT_N_M',
        'buyQuantity': 1,
        'targets': [],
        'gifts': [
          {'productId': 2, 'quantity': 1}
        ]
      };
      final r = run([a, b], [item()]);
      expect(r.gifts.map((g) => g.ruleId).toList(), [10, 20]);
    });
  });
}
