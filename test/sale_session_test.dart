import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/domain/sale_session.dart';
import 'package:flutter_mdokon/features/cashier/domain/sale_tabs.dart';

const owner = SaleSessionOwner(posId: 7, cashboxId: 71, shiftId: 900, login: 'kassir');

Map cheque(List items, {num total = 0, num discount = 0}) => {
      'itemsList': items,
      'totalPrice': total,
      'discount': discount,
    };

Map line(String name, {num quantity = 1, num total = 100}) => {
      'name': name,
      'quantity': quantity,
      'totalPrice': total,
      'markingNumbers': <String>[],
    };

final int now = DateTime.now().millisecondsSinceEpoch;

String encode(SaleTabsState tabs, {int? savedAt, SaleSessionOwner from = owner}) =>
    encodeSaleSession(tabs: tabs, owner: from, savedAt: savedAt ?? now)!;

void main() {
  group('восстановление сессии', () {
    test('чек возвращается с позициями, скидкой и итогом', () {
      final state = initialSaleTabs(cheque([line('olma', quantity: 2, total: 940)], total: 940, discount: 5));

      final restored = decodeSaleSession(encode(state), owner: owner, now: now);

      expect(restored, isNotNull);
      expect(restored!.tabs, hasLength(1));
      expect(restored.active.lineCount, 1);
      expect(restored.active.cheque['discount'], 5);
      expect(restored.active.cheque['totalPrice'], 940);
      expect(restored.active.cheque['itemsList'].first['quantity'], 2);
    });

    test('вкладки и активная переживают перезапуск', () {
      var state = initialSaleTabs(cheque([line('olma')]));
      state = addSaleTab(state, state.active.cheque, cheque([line('non')]));

      final restored = decodeSaleSession(encode(state), owner: owner, now: now);

      expect(restored!.tabs, hasLength(2));
      expect(restored.activeId, state.activeId);
      expect(restored.active.cheque['itemsList'].first['name'], 'non');
    });

    test('снимок не делит структуры с исходным чеком', () {
      final state = initialSaleTabs(cheque([line('olma')]));
      final restored = decodeSaleSession(encode(state), owner: owner, now: now)!;

      (restored.active.cheque['itemsList'] as List).clear();

      expect(state.active.lineCount, 1);
    });
  });

  group('чужая сессия не поднимается', () {
    test('другая смена', () {
      final state = initialSaleTabs(cheque([line('olma')]));
      const other = SaleSessionOwner(posId: 7, cashboxId: 71, shiftId: 901, login: 'kassir');

      expect(decodeSaleSession(encode(state), owner: other, now: now), isNull);
    });

    test('другой кассир', () {
      final state = initialSaleTabs(cheque([line('olma')]));
      const other = SaleSessionOwner(posId: 7, cashboxId: 71, shiftId: 900, login: 'kassir2');

      expect(decodeSaleSession(encode(state), owner: other, now: now), isNull);
    });

    test('другая касса', () {
      final state = initialSaleTabs(cheque([line('olma')]));
      const other = SaleSessionOwner(posId: 7, cashboxId: 72, shiftId: 900, login: 'kassir');

      expect(decodeSaleSession(encode(state), owner: other, now: now), isNull);
    });

    test('снимок старше суток', () {
      final state = initialSaleTabs(cheque([line('olma')]));
      final old = encode(state, savedAt: now - const Duration(hours: 13).inMilliseconds);

      expect(decodeSaleSession(old, owner: owner, now: now), isNull);
    });

    test('снимок из будущего — переведённые часы', () {
      final state = initialSaleTabs(cheque([line('olma')]));
      final ahead = encode(state, savedAt: now + const Duration(hours: 2).inMilliseconds);

      expect(decodeSaleSession(ahead, owner: owner, now: now), isNull);
    });
  });

  group('поднимать нечего', () {
    test('пустая корзина', () {
      final state = initialSaleTabs(cheque([]));

      expect(decodeSaleSession(encode(state), owner: owner, now: now), isNull);
    });

    test('в хранилище пусто', () {
      expect(decodeSaleSession(null, owner: owner, now: now), isNull);
      expect(decodeSaleSession('', owner: owner, now: now), isNull);
    });

    test('битый снимок', () {
      expect(decodeSaleSession('{not json', owner: owner, now: now), isNull);
      expect(decodeSaleSession('{"tabs":[]}', owner: owner, now: now), isNull);
    });

    test('активной вкладки в снимке нет — открывается первая', () {
      final state = initialSaleTabs(cheque([line('olma')]));
      final broken = encode(state).replaceFirst('"activeId":1', '"activeId":42');

      final restored = decodeSaleSession(broken, owner: owner, now: now);

      expect(restored!.activeId, 1);
    });
  });
}
