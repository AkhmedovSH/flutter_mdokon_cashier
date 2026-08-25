import 'package:flutter_mdokon/features/cashier/domain/marking.dart';

/// Во что превратить отсканированную строку перед поиском товара.
///
/// Код маркировки в поиск отдавать нельзя: в базе такого «штрих-кода» нет.
/// Искать нужно по GTIN из кода, причём GTIN-14 — это тот же штрих-код карточки,
/// дополненный нулями слева, поэтому вариантов может быть несколько
/// ([gtinToBarcodeVariants]). Первый вариант — самый точный.
class ScannedInput {
  const ScannedInput({
    required this.raw,
    required this.searchTerms,
    this.marking,
  });

  /// Нормализованная строка со сканера (без AIM-префикса и переводов строк).
  final String raw;

  /// Что подставлять в поиск, по убыванию точности.
  final List<String> searchTerms;

  /// Разобранный код маркировки; `null` — обычный штрих-код.
  final MarkingCode? marking;

  bool get isMarking => marking != null;

  /// Что показать кассиру в поле поиска.
  String get displayTerm => searchTerms.isEmpty ? raw : searchTerms.first;
}

/// Разобрать строку со сканера (или из поля ввода).
ScannedInput parseScannedInput(dynamic value) {
  final raw = normalizeScannedCode(value);
  final marking = parseMarkingCode(raw);
  if (marking == null) {
    return ScannedInput(raw: raw, searchTerms: raw.isEmpty ? const [] : [raw]);
  }
  final variants = gtinToBarcodeVariants(marking.gtin);
  return ScannedInput(
    raw: raw,
    searchTerms: variants.isEmpty ? [raw] : variants,
    marking: marking,
  );
}
