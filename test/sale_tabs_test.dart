import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/domain/sale_tabs.dart';

Map cheque(List items) => {'itemsList': items};

Map line(num total) => {'totalPrice': total, 'markingNumbers': <String>[]};

void main() {
  group('добавление вкладок', () {
    test('первая вкладка — текущий чек', () {
      final state = initialSaleTabs(cheque([line(100)]));
      expect(state.tabs, hasLength(1));
      expect(state.activeId, 1);
      expect(state.active.total, 100);
      expect(state.canClose, isFalse);
    });

    test('новая вкладка становится активной, старая сохраняет чек', () {
      var state = initialSaleTabs(cheque([]));
      state = addSaleTab(state, cheque([line(500)]), cheque([]));

      expect(state.tabs, hasLength(2));
      expect(state.activeId, 2);
      expect(state.tabs.first.total, 500);
      expect(state.active.isEmpty, isTrue);
    });

    test('больше maxSaleTabs не добавляется', () {
      var state = initialSaleTabs(cheque([]));
      for (var i = 0; i < maxSaleTabs + 3; i++) {
        state = addSaleTab(state, cheque([]), cheque([]));
      }
      expect(state.tabs, hasLength(maxSaleTabs));
      expect(state.canAdd, isFalse);
    });

    test('id не повторяется после закрытия средней вкладки', () {
      var state = initialSaleTabs(cheque([]));
      state = addSaleTab(state, cheque([]), cheque([]));
      state = addSaleTab(state, cheque([]), cheque([]));
      state = closeSaleTab(state, 2, cheque([]));
      state = addSaleTab(state, cheque([]), cheque([]));

      final ids = state.tabs.map((e) => e.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, contains(4));
    });
  });

  group('переключение', () {
    test('текущий чек уходит в покидаемую вкладку', () {
      var state = initialSaleTabs(cheque([]));
      state = addSaleTab(state, cheque([]), cheque([]));
      state = switchSaleTab(state, 1, cheque([line(300)]));

      expect(state.activeId, 1);
      expect(state.tabs.last.total, 300);
    });

    test('неизвестный id ничего не меняет', () {
      final state = initialSaleTabs(cheque([]));
      expect(identical(switchSaleTab(state, 99, cheque([])), state), isTrue);
    });

    test('снимок глубокий — правка корзины не трогает соседнюю вкладку', () {
      final current = cheque([line(100)]);
      var state = initialSaleTabs(cheque([]));
      state = addSaleTab(state, current, cheque([]));

      (current['itemsList'] as List).add(line(50));
      ((current['itemsList'] as List).first as Map)['totalPrice'] = 999;

      expect(state.tabs.first.lineCount, 1);
      expect(state.tabs.first.total, 100);
    });
  });

  group('закрытие', () {
    test('единственную вкладку закрыть нельзя', () {
      final state = initialSaleTabs(cheque([]));
      expect(identical(closeSaleTab(state, 1, cheque([])), state), isTrue);
    });

    test('активной становится соседняя справа', () {
      var state = initialSaleTabs(cheque([]));
      state = addSaleTab(state, cheque([]), cheque([]));
      state = addSaleTab(state, cheque([]), cheque([]));
      state = switchSaleTab(state, 2, cheque([]));
      state = closeSaleTab(state, 2, cheque([]));

      expect(state.tabs.map((e) => e.id), [1, 3]);
      expect(state.activeId, 3);
    });

    test('у последней в списке — соседняя слева', () {
      var state = initialSaleTabs(cheque([]));
      state = addSaleTab(state, cheque([]), cheque([]));
      state = closeSaleTab(state, 2, cheque([]));

      expect(state.activeId, 1);
    });

    test('закрытие неактивной сохраняет текущий чек и активную вкладку', () {
      var state = initialSaleTabs(cheque([]));
      state = addSaleTab(state, cheque([]), cheque([]));
      state = closeSaleTab(state, 1, cheque([line(700)]));

      expect(state.activeId, 2);
      expect(state.active.total, 700);
    });
  });

  test('подпись вкладки — порядковый номер, а не id', () {
    var state = initialSaleTabs(cheque([]));
    state = addSaleTab(state, cheque([]), cheque([]));
    state = addSaleTab(state, cheque([]), cheque([]));
    state = closeSaleTab(state, 2, cheque([]));

    expect(saleTabPosition(state, 3), 2);
  });
}
