// Коды маркировки на позиции чека — порт `isMarkingItem` / `getMarkingCodes` /
// `formatUniversalMarkingNumber` из `src/helpers/helpers.js` desktop-кассы.
//
// Правило: одинаковые товары собираются в ОДНУ позицию, а количество равно числу
// отсканированных кодов. Поэтому количество маркировочной позиции нельзя менять
// степпером «на глаз» — только сканированием кода (`+`) и удалением кода (`−`).

import 'package:flutter_mdokon/features/cashier/domain/marking.dart';

/// Позиция маркировочная: либо так сказал сервер (`marking`), либо на ней уже есть коды.
bool isMarkingItem(Map? item) {
  if (item == null) return false;
  final flag = item['marking'];
  if (flag == true || flag == 1 || flag == '1') return true;
  return markingCodes(item).isNotEmpty;
}

/// Полные коды позиции. Старое поле `markingNumber` поддерживается для чеков,
/// сохранённых до агрегации.
List<String> markingCodes(Map? item) {
  final list = item?['markingNumbers'];
  if (list is List && list.isNotEmpty) {
    return list.map((e) => '$e').where((e) => e.isNotEmpty).toList();
  }
  final single = item?['markingNumber'];
  if (single != null && '$single'.isNotEmpty) return ['$single'];
  return const [];
}

/// Записать коды на позицию: количество всегда равно их числу.
void setMarkingCodes(Map item, List<String> codes) {
  item['markingNumbers'] = List<String>.from(codes);
  item['markingNumber'] = codes.isEmpty ? '' : codes.first;
  item['quantity'] = codes.length;
}

/// Что произошло при попытке добавить код к позиции.
enum MarkingAddResult {
  /// Код добавлен, количество увеличено на единицу.
  added,

  /// Такой код на позиции уже есть — кассир сканировал одну пачку дважды.
  duplicate,

  /// Кодов уже столько же, сколько товара на остатке.
  limitExceeded,
}

/// Добавить код к позиции. [balance] — остаток; `null` снимает проверку
/// (`saleMinus`, продажа в минус разрешена настройками кассы).
MarkingAddResult addMarkingCode(Map item, String code, {num? balance}) {
  final normalized = normalizeScannedCode(code);
  if (normalized.isEmpty) return MarkingAddResult.duplicate;

  final codes = markingCodes(item);
  if (codes.contains(normalized)) return MarkingAddResult.duplicate;
  if (balance != null && codes.length + 1 > balance) return MarkingAddResult.limitExceeded;

  setMarkingCodes(item, [...codes, normalized]);
  return MarkingAddResult.added;
}

/// Убрать код с позиции. Возвращает `false`, если такого кода на ней не было.
/// Удаление последнего кода оставляет позицию пустой — строку удаляет вызывающий код.
bool removeMarkingCode(Map item, String code) {
  final codes = markingCodes(item);
  if (!codes.remove(code)) return false;
  setMarkingCodes(item, codes);
  return true;
}

/// Короткий вид кода для кассира и для поля `Label` (порт `formatUniversalMarkingNumber`).
///
/// Табачный код (29 знаков без разделителей) режется до GTIN + серийного,
/// GS1 — до первого разделителя или `=`.
String markingLabel(dynamic raw) {
  if (raw == null) return '';
  var label = '$raw';
  if (label.isEmpty) return '';

  final hasSeparators = label.contains(kGs) || label.contains(String.fromCharCode(232));
  if (label.length == _tobaccoCodeLength && !hasSeparators) {
    return label.substring(0, 21).trim();
  }

  final gs = label.indexOf(kGs);
  if (gs != -1) label = label.substring(0, gs);

  final unicode = label.indexOf(r'\u');
  if (unicode != -1) label = label.substring(0, unicode);

  final equals = label.indexOf('=');
  if (equals != -1) label = label.substring(0, equals);

  return label.trim();
}

const int _tobaccoCodeLength = 29;
