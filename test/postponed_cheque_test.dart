import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/domain/postponed_cheque.dart';

void main() {
  Map cheque() => {
        'chequeNumber': '0001',
        'currencyId': 1,
        'clientId': 7,
        'clientName': 'Иванов',
        'cashboxId': 'OLD-CASHBOX',
        'posId': 'OLD-POS',
        'shiftId': 'OLD-SHIFT',
        'cashierName': 'Старый кассир',
        'chequeDate': 1700000000000,
        'transactionId': 'OLD-TX',
        'paid': 5000,
        'itemsList': [
          {'productId': 1, 'quantity': 2, 'totalPrice': 3000, 'selected': true},
          {'productId': 2, 'quantity': 1, 'totalPrice': 2000, 'selected': false},
        ],
      };

  Map cashbox() => {
        'cashboxId': 'NEW-CASHBOX',
        'posId': 'NEW-POS',
        'posName': 'Точка',
        'id': 'NEW-SHIFT',
        'defaultCurrency': 1,
      };

  Map user() => {'login': 'kassir', 'firstName': 'Пётр'};

  group('canPostpone', () {
    test('пустой чек откладывать нечего', () {
      expect(canPostpone({'itemsList': []}), isFalse);
      expect(canPostpone({}), isFalse);
    });

    test('чек с позициями отложить можно', () {
      expect(canPostpone(cheque()), isTrue);
    });
  });

  group('postponedSnapshot', () {
    test('снимает выделение со строк и проставляет дату', () {
      final snapshot = postponedSnapshot(cheque(), createdDate: 111);

      expect(snapshot['createdDate'], 111);
      expect(snapshot['selected'], isFalse);
      expect((snapshot['itemsList'] as List).every((e) => e['selected'] == false), isTrue);
    });

    test('исходный чек не меняется — кассир продолжает работать с той же корзиной', () {
      final source = cheque();
      postponedSnapshot(source, createdDate: 111);

      expect((source['itemsList'] as List).first['selected'], isTrue);
      expect(source.containsKey('createdDate'), isFalse);
    });
  });

  group('postponedTotal', () {
    test('считает по позициям — у агентского чека верхнего итога нет', () {
      expect(postponedTotal(cheque()), 5000);
    });

    test('чек без позиций — ноль, а не падение', () {
      expect(postponedTotal({}), 0);
    });
  });

  group('parsePostponedList', () {
    test('разбирает чек из строки JSON и берёт реквизиты из строки списка', () {
      final list = parsePostponedList([
        {
          'id': 42,
          'createdDate': 1700000000000,
          'clientId': 9,
          'clientName': 'Петров',
          'agentLogin': 'agent1',
          'agentName': 'Агент',
          'cheque': jsonEncode(cheque()),
        },
      ]);

      expect(list.length, 1);
      expect(list.single.id, 42);
      expect(list.single.clientId, 9);
      // Строка списка перебивает то, что лежит внутри чека.
      expect(list.single.clientName, 'Петров');
      expect(list.single.agentName, 'Агент');
      expect(list.single.lineCount, 2);
    });

    test('битый JSON пропускается — остальные чеки остаются в списке', () {
      final list = parsePostponedList([
        {'id': 1, 'cheque': '{не json'},
        {'id': 2, 'cheque': jsonEncode(cheque())},
      ]);

      expect(list.length, 1);
      expect(list.single.id, 2);
    });

    test('не список — пустой результат', () {
      expect(parsePostponedList(false), isEmpty);
      expect(parsePostponedList(null), isEmpty);
    });
  });

  group('parseStoredList', () {
    test('офлайновый чек лежит без обёртки', () {
      final list = parseStoredList([cheque()..['createdDate'] = 555]);

      expect(list.single.id, isNull);
      expect(list.single.createdDate, 555);
      expect(list.single.total, 5000);
    });
  });

  group('subtitle', () {
    test('берёт первое непустое имя: клиент, организация, агент', () {
      const withAgent = PostponedCheque(cheque: {}, agentName: 'Агент');
      expect(withAgent.subtitle, 'Агент');

      const withClient = PostponedCheque(cheque: {}, clientName: 'Клиент', agentName: 'Агент');
      expect(withClient.subtitle, 'Клиент');
    });

    test('имя внутри чека годится, если рядом со строкой его нет', () {
      const fromCheque = PostponedCheque(cheque: {'organizationName': 'ООО'});
      expect(fromCheque.subtitle, 'ООО');
    });

    test('никого не выбрали — пусто', () {
      expect(const PostponedCheque(cheque: {}).subtitle, '');
    });
  });

  group('currencyMatches', () {
    test('валюты совпадают', () {
      expect(currencyMatches({'currencyId': 1}, 1), isTrue);
    });

    test('долларовый чек на сумовой кассе не открывается', () {
      expect(currencyMatches({'currencyId': 2}, 1), isFalse);
    });

    test('валюта не проставлена — чек пропускаем: у старых чеков её не было', () {
      expect(currencyMatches({}, 1), isTrue);
      expect(currencyMatches({'currencyId': 1}, null), isTrue);
    });
  });

  group('restorePostponed', () {
    test('чек переезжает на текущую кассу, смену и кассира', () {
      final restored = restorePostponed(
        cheque(),
        cashbox: cashbox(),
        user: user(),
        shiftId: 'ACTIVE-SHIFT',
      );

      expect(restored['cashboxId'], 'NEW-CASHBOX');
      expect(restored['posId'], 'NEW-POS');
      expect(restored['shiftId'], 'ACTIVE-SHIFT');
      expect(restored['cashierName'], 'Пётр');
      expect(restored['cashierLogin'], 'kassir');
      expect(restored['currencyId'], 1);
      expect(restored['saleCurrencyId'], 1);
    });

    test('номер, время и транзакция обнуляются — их выдаст оплата заново', () {
      final restored = restorePostponed(cheque(), cashbox: cashbox(), user: user());

      for (final key in ['chequeNumber', 'chequeDate', 'transactionId', 'paid', 'createdDate']) {
        expect(restored.containsKey(key), isFalse, reason: key);
      }
    });

    test('корзина переносится целиком, выделена последняя строка', () {
      final restored = restorePostponed(cheque(), cashbox: cashbox(), user: user());
      final items = restored['itemsList'] as List;

      expect(items.length, 2);
      expect(items.first['selected'], isFalse);
      expect(items.last['selected'], isTrue);
    });

    test('правки корзины не меняют чек, оставшийся в списке', () {
      final source = cheque();
      final restored = restorePostponed(source, cashbox: cashbox(), user: user());

      (restored['itemsList'] as List).first['quantity'] = 99;

      expect((source['itemsList'] as List).first['quantity'], 2);
    });

    test('серверный чек уносит chequeOnlineId — продажа закроет исходную строку', () {
      final row = parsePostponedList([
        {'id': 77, 'agentName': 'Агент', 'cheque': jsonEncode(cheque())},
      ]).single;

      final restored = restorePostponed(
        row.cheque,
        cashbox: cashbox(),
        user: user(),
        source: row,
      );

      expect(restored['chequeOnlineId'], 77);
      expect(restored['agentName'], 'Агент');
    });

    test('офлайновый чек chequeOnlineId не получает — иначе продажа удалит чужую строку', () {
      final restored = restorePostponed(cheque(), cashbox: cashbox(), user: user());

      expect(restored.containsKey('chequeOnlineId'), isFalse);
    });

    test('долларовая касса проставляет чеку свою валюту и название', () {
      final restored = restorePostponed(
        cheque(),
        cashbox: cashbox()..['defaultCurrency'] = 2,
        user: user(),
      );

      expect(restored['currencyId'], 2);
      expect(restored['currencyName'], 'USD');
    });
  });

  group('postponedDateLabel', () {
    test('миллисекунды офлайнового чека', () {
      final millis = DateTime(2026, 3, 14, 9, 5).millisecondsSinceEpoch;
      expect(postponedDateLabel(millis), '14.03 09:05');
    });

    test('строка с сервера', () {
      expect(postponedDateLabel('2026-03-14T09:05:00'), '14.03 09:05');
    });

    test('разобрать не удалось — пусто, а не исключение', () {
      expect(postponedDateLabel('не дата'), '');
      expect(postponedDateLabel(null), '');
      expect(postponedDateLabel(''), '');
    });
  });
}
