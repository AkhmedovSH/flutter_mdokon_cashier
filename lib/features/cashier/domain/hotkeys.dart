/// Горячие клавиши кассы для планшета с физической клавиатурой или сканером,
/// работающим в режиме «клавиатура».
///
/// Порт раскладки из desktop-кассы (`src/components/cashbox/Tab.js`,
/// `handleShortcut`): кассир набирает число, а клавиша операции говорит, что с
/// этим числом сделать — `2+` количество, `2000*` цена, `5000-` сумма позиции,
/// `/` упаковка, F5/F6/F7 скидки, F9 очистить чек.
///
/// Слой чистый: клавиша и накопленный буфер на входе, команда на выходе. Ни
/// `SaleModel`, ни виджеты сюда не заглядывают — за счёт этого раскладка
/// проверяется тестами без запуска UI.
library;

import 'package:flutter_mdokon/features/cashier/models/sale_model.dart';

/// Что делать по нажатой клавише.
enum HotkeyAction {
  /// Дописать символ в буфер (цифра или разделитель дробной части).
  append,

  /// Стереть последний символ буфера.
  backspace,

  /// Сбросить набранное, чек не трогать.
  clearInput,

  /// Выполнить быструю операцию над буфером.
  shortcut,

  /// Очистить чек целиком (F9).
  clearCheque,

  /// Клавиша к кассе отношения не имеет — отдать её дальше по дереву.
  none,
}

/// Разобранное нажатие.
class HotkeyCommand {
  const HotkeyCommand(this.action, {this.symbol, this.shortcut});

  final HotkeyAction action;

  /// Что дописать в буфер при [HotkeyAction.append].
  final String? symbol;

  /// Операция при [HotkeyAction.shortcut].
  final SaleShortcut? shortcut;

  /// Обработала ли касса нажатие — если нет, клавиша уходит дальше.
  bool get handled => action != HotkeyAction.none;

  static const _ignored = HotkeyCommand(HotkeyAction.none);
}

/// Клавиши операций. Разделены с [SaleShortcut] намеренно: символ операции в
/// меню («%», «%-») не совпадает с клавишей на клавиатуре (F5, F6).
const Map<String, SaleShortcut> hotkeyShortcuts = {
  '+': SaleShortcut.quantity,
  '*': SaleShortcut.price,
  '-': SaleShortcut.lineTotal,
  '/': SaleShortcut.unit,
  'F5': SaleShortcut.discountPercent,
  'F6': SaleShortcut.discountAmount,
  'F7': SaleShortcut.discountLine,
};

/// Разобрать нажатие клавиши.
///
/// [key] — символ или имя функциональной клавиши (`F5`, `Backspace`, `Escape`).
/// [buffer] — уже набранное число.
///
/// Операция с пустым буфером не выполняется — иначе `+` без числа обнулил бы
/// количество позиции. Исключение — упаковка (`/`): ей число не нужно, она
/// открывает диалог по выбранной позиции.
HotkeyCommand resolveHotkey(String key, {String buffer = ''}) {
  if (key.isEmpty) return HotkeyCommand._ignored;

  if (key == 'Backspace') {
    return buffer.isEmpty
        ? HotkeyCommand._ignored
        : const HotkeyCommand(HotkeyAction.backspace);
  }
  if (key == 'Escape') {
    return buffer.isEmpty
        ? HotkeyCommand._ignored
        : const HotkeyCommand(HotkeyAction.clearInput);
  }
  if (key == 'F9') return const HotkeyCommand(HotkeyAction.clearCheque);

  final shortcut = hotkeyShortcuts[key];
  if (shortcut != null) {
    if (buffer.trim().isEmpty && shortcut != SaleShortcut.unit) {
      return HotkeyCommand._ignored;
    }
    return HotkeyCommand(HotkeyAction.shortcut, shortcut: shortcut);
  }

  if (key.length == 1 && key.codeUnitAt(0) >= 0x30 && key.codeUnitAt(0) <= 0x39) {
    return HotkeyCommand(HotkeyAction.append, symbol: key);
  }
  // Дробное количество кассир набирает и точкой, и запятой — на цифровом блоке
  // клавиатуры и на сканере это разные клавиши. В буфер кладём точку: числа
  // дальше разбирает `customNumber`, а он запятую не понимает.
  if (key == '.' || key == ',') {
    if (buffer.isEmpty || buffer.contains('.')) return HotkeyCommand._ignored;
    return const HotkeyCommand(HotkeyAction.append, symbol: '.');
  }

  return HotkeyCommand._ignored;
}

/// Дописать символ в буфер.
String appendToHotkeyBuffer(String buffer, String symbol) {
  // Ведущие нули кассиру только мешают: «02» и «2» — одно количество.
  if (buffer == '0' && symbol != '.') return symbol;
  return buffer + symbol;
}

/// Строка панели-подсказки: какие клавиши нажать и что это даёт.
class HotkeyHint {
  const HotkeyHint(this.keys, this.labelKey);

  /// Клавиши по порядку нажатия; число показываем примером («2», «3000»).
  final List<String> keys;

  /// Ключ перевода описания.
  final String labelKey;
}

/// Подсказки для панели горячих клавиш — в том же порядке, что у десктопа.
const List<HotkeyHint> hotkeyHints = [
  HotkeyHint(['2', '+'], 'quantity'),
  HotkeyHint(['2000', '*'], 'sale_price'),
  HotkeyHint(['5000', '-'], 'line_amount'),
  HotkeyHint(['/'], 'packaging'),
  HotkeyHint(['10', 'F5'], 'discount_percent_on_cheque'),
  HotkeyHint(['3000', 'F6'], 'discount_sum_on_cheque'),
  HotkeyHint(['3000', 'F7'], 'discount_sum_on_item'),
  HotkeyHint(['F9'], 'clear'),
];
