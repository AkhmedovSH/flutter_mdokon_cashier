// Возврат маркировочной позиции — порт `submitReturnMarking` / `prepareReturnItem`
// из `src/components/return/Return.js` desktop-кассы.
//
// Возвращается не «количество», а конкретные коды: покупатель принёс те самые
// пачки. Поэтому код должен быть в этом чеке, повторно его не берём, и больше,
// чем ещё не возвращено по позиции, взять нельзя.

import 'package:flutter_mdokon/features/cashier/domain/marking.dart';
import 'package:flutter_mdokon/features/cashier/domain/marking_item.dart';

/// Что произошло при попытке добавить код в возврат.
enum ReturnCodeResult {
  /// Код принят, количество к возврату выросло на единицу.
  added,

  /// Такого кода в чеке нет — принесли товар из другой продажи.
  notFound,

  /// Код уже отмечен к возврату.
  duplicate,

  /// Отмечено столько кодов, сколько по позиции ещё можно вернуть.
  limitExceeded,
}

/// Результат разбора: сам код и что с ним делать.
class ReturnCodeSelection {
  const ReturnCodeSelection(this.result, this.codes);

  final ReturnCodeResult result;

  /// Новый список отмеченных кодов. При любой ошибке — прежний, без изменений.
  final List<String> codes;

  bool get isAdded => result == ReturnCodeResult.added;
}

/// Отметить код к возврату.
///
/// [available] — коды позиции из чека, [selected] — уже отмеченные,
/// [limit] — сколько единиц по позиции ещё можно вернуть (`null` — все коды чека).
ReturnCodeSelection selectReturnCode({
  required List<String> available,
  required List<String> selected,
  required String code,
  num? limit,
}) {
  final normalized = normalizeScannedCode(code);
  if (normalized.isEmpty || !available.contains(normalized)) {
    return ReturnCodeSelection(ReturnCodeResult.notFound, selected);
  }
  if (selected.contains(normalized)) {
    return ReturnCodeSelection(ReturnCodeResult.duplicate, selected);
  }

  final cap = (limit != null && limit > 0) ? limit : available.length;
  if (selected.length + 1 > cap) {
    return ReturnCodeSelection(ReturnCodeResult.limitExceeded, selected);
  }

  return ReturnCodeSelection(ReturnCodeResult.added, [...selected, normalized]);
}

/// Коды позиции, которые ещё можно вернуть, — по ним работает «вернуть всё».
/// Частично возвращённая позиция отдаёт первые `limit` кодов: какие именно
/// пачки ушли в прошлый возврат, сервер не сообщает.
List<String> returnableMarkingCodes(Map? item, {num? limit}) {
  final codes = markingCodes(item);
  if (limit == null || limit <= 0 || limit >= codes.length) return codes;
  return codes.sublist(0, limit.toInt());
}
