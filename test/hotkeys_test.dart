import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/domain/hotkeys.dart';
import 'package:flutter_mdokon/features/cashier/models/sale_model.dart';

void main() {
  group('resolveHotkey', () {
    test('цифра копится в буфере', () {
      final command = resolveHotkey('2', buffer: '');
      expect(command.action, HotkeyAction.append);
      expect(command.symbol, '2');
    });

    test('буквы и прочие клавиши касса не перехватывает', () {
      expect(resolveHotkey('a').handled, isFalse);
      expect(resolveHotkey('F1').handled, isFalse);
      expect(resolveHotkey('').handled, isFalse);
    });

    test('запятая приходит в буфер точкой', () {
      final command = resolveHotkey(',', buffer: '3');
      expect(command.action, HotkeyAction.append);
      expect(command.symbol, '.');
    });

    test('вторая точка и точка в пустом буфере игнорируются', () {
      expect(resolveHotkey('.', buffer: '3.4').handled, isFalse);
      expect(resolveHotkey('.', buffer: '').handled, isFalse);
    });

    test('операции разбираются в свои быстрые действия', () {
      expect(resolveHotkey('+', buffer: '2').shortcut, SaleShortcut.quantity);
      expect(resolveHotkey('*', buffer: '2000').shortcut, SaleShortcut.price);
      expect(resolveHotkey('-', buffer: '5000').shortcut, SaleShortcut.lineTotal);
      expect(resolveHotkey('F5', buffer: '10').shortcut, SaleShortcut.discountPercent);
      expect(resolveHotkey('F6', buffer: '3000').shortcut, SaleShortcut.discountAmount);
      expect(resolveHotkey('F7', buffer: '3000').shortcut, SaleShortcut.discountLine);
    });

    test('операция с пустым буфером не выполняется', () {
      expect(resolveHotkey('+', buffer: '').handled, isFalse);
      expect(resolveHotkey('F5', buffer: '   ').handled, isFalse);
    });

    test('упаковке число не нужно', () {
      final command = resolveHotkey('/', buffer: '');
      expect(command.action, HotkeyAction.shortcut);
      expect(command.shortcut, SaleShortcut.unit);
    });

    test('F9 очищает чек независимо от буфера', () {
      expect(resolveHotkey('F9', buffer: '').action, HotkeyAction.clearCheque);
      expect(resolveHotkey('F9', buffer: '12').action, HotkeyAction.clearCheque);
    });

    test('Backspace и Escape работают только по набранному', () {
      expect(resolveHotkey('Backspace', buffer: '12').action, HotkeyAction.backspace);
      expect(resolveHotkey('Backspace', buffer: '').handled, isFalse);
      expect(resolveHotkey('Escape', buffer: '12').action, HotkeyAction.clearInput);
      expect(resolveHotkey('Escape', buffer: '').handled, isFalse);
    });
  });

  group('appendToHotkeyBuffer', () {
    test('ведущий ноль заменяется цифрой', () {
      expect(appendToHotkeyBuffer('0', '5'), '5');
    });

    test('после ноля точка остаётся на месте', () {
      expect(appendToHotkeyBuffer('0', '.'), '0.');
    });

    test('обычное дописывание', () {
      expect(appendToHotkeyBuffer('12', '3'), '123');
      expect(appendToHotkeyBuffer('', '7'), '7');
    });
  });

  test('подсказки покрывают все клавиши операций и F9', () {
    final keys = hotkeyHints.expand((h) => h.keys).toSet();
    for (final key in hotkeyShortcuts.keys) {
      expect(keys, contains(key));
    }
    expect(keys, contains('F9'));
  });
}
