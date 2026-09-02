/// Разбор штрих-кода, напечатанного магазинными весами.
///
/// Порт `src/components/cashbox/Tab.js:665-750` десктопной кассы. Весы печатают
/// 13-значный EAN, где первые две цифры — префикс, заданный в настройках
/// (`weightPrefix` для веса, `piecePrefix` для штук), дальше идёт код товара, а
/// перед контрольной цифрой — вес в граммах либо количество штук.
///
/// Раскладка зависит от формата весов:
///
/// ```
/// формат 7 (значение 5):  PP CCCCC WWWWW K   код 2..7, вес 7..12
/// формат 6 (значение 6):  PPP CCCCC WWWW K   код 3..8, вес 8..12
/// ```
///
/// Вес приходит в граммах — делим на 1000. Штучный префикс кладёт количество в
/// две цифры перед контрольной (позиции 10..12) в обоих форматах.
library;

/// Что весы зашили в штрих-код.
class ScaleBarcode {
  const ScaleBarcode({
    required this.productCode,
    required this.quantity,
    required this.byWeight,
  });

  /// Код товара из середины штрих-кода — по нему ищут карточку.
  final int productCode;

  /// Вес в килограммах (весовой префикс) либо число штук (штучный).
  final double quantity;

  /// `true` — весовой префикс, `false` — штучный.
  final bool byWeight;
}

/// Настройки весов. Отдельный класс, чтобы разбор не тянул за собой
/// `SettingsModel` и оставался проверяемым без Flutter.
class ScaleSettings {
  const ScaleSettings({
    this.format = 5,
    this.weightPrefix = 20,
    this.piecePrefix = 21,
  });

  /// 5 — формат 7, 6 — формат 6 (нумерация десктопа, менять нельзя).
  final int format;
  final int weightPrefix;
  final int piecePrefix;
}

/// Разобрать штрих-код весов или вернуть `null`, если это обычный штрих-код.
ScaleBarcode? parseScaleBarcode(String barcode, ScaleSettings settings) {
  if (barcode.length != 13) return null;
  if (int.tryParse(barcode) == null) return null;

  final prefix = int.parse(barcode.substring(0, 2));
  final byWeight = prefix == settings.weightPrefix;
  final byPiece = prefix == settings.piecePrefix;
  if (!byWeight && !byPiece) return null;

  // Префиксы можно задать одинаковыми — тогда весовой имеет приоритет, как и
  // на десктопе (его проверяют первым).
  final format6 = settings.format == 6;
  final code = int.parse(barcode.substring(format6 ? 3 : 2, format6 ? 8 : 7));

  final double quantity;
  if (byWeight) {
    final grams = int.parse(barcode.substring(format6 ? 8 : 7, 12));
    quantity = grams / 1000;
  } else {
    quantity = int.parse(barcode.substring(10, 12)).toDouble();
  }

  return ScaleBarcode(productCode: code, quantity: quantity, byWeight: byWeight);
}

/// Количество, которое реально нужно поставить в чек.
///
/// Штучный товар (`uomId == 1`) продаётся целыми единицами, даже если весы
/// прислали граммы; при нулевом количестве в чек идёт одна штука — иначе
/// сканирование выглядит как несработавшее.
double scaleQuantityFor(ScaleBarcode scanned, {dynamic uomId}) {
  var quantity = scanned.quantity;
  if (scanned.byWeight && '$uomId' == '1') {
    quantity = quantity.truncateToDouble();
  }
  return quantity <= 0 ? 1 : quantity;
}
