// Разбор кода маркировки DataMatrix («Asl Belgisi») — порт `src/helpers/marking.js`
// из desktop-кассы.
//
// Касса разбирает код сама только для того, чтобы (1) не слать на сервер каждый обычный
// штрих-код и (2) найти товар в локальной базе, когда сервера нет — продажа обязана
// работать офлайн. Источник правды — бэкенд (`MarkingCodeParser`), его GTIN важнее нашего.

/// Разделитель групп данных GS1 (ASCII 29). Часть сканеров его не передаёт вовсе.
const String kGs = '';

/// Префикс символики, который некоторые сканеры добавляют перед данными (AIM ID).
final RegExp _aimPrefixRe = RegExp(r'^\](?:d2|d1|C1|e0|Q3|Q1)', caseSensitive: false);

/// Экранированный вид разделителя групп: часть сканеров и терминалов присылает его текстом.
final RegExp _escapedGsRe = RegExp(r'\\u001d|<GS>', caseSensitive: false);

final RegExp _newlinesRe = RegExp(r'[\r\n]+');

/// Короче этого код маркировки не бывает (ограничение Open API xTrace) —
/// обычные EAN-13/EAN-8/UPC сюда не попадают.
const int _minMarkingLength = 20;

/// Длина кода сигарет: GTIN(14) + серийный(7) + код проверки(8).
const int _tobaccoLength = 29;

/// Формат разобранного кода.
enum MarkingFormat { gs1, tobacco }

/// Разобранный код маркировки.
class MarkingCode {
  const MarkingCode({
    required this.code,
    required this.gtin,
    required this.serial,
    required this.format,
  });

  /// Нормализованная строка кода — именно её отправляем на проверку.
  final String code;
  final String gtin;
  final String serial;
  final MarkingFormat format;

  @override
  String toString() => 'MarkingCode($format, gtin: $gtin, serial: $serial)';
}

/// Убрать префикс сканера, переводы строк и экранированный вид GS.
String normalizeScannedCode(dynamic raw) {
  if (raw == null) return '';
  var code = '$raw'.replaceAll(_escapedGsRe, kGs).replaceAll(_newlinesRe, '');
  code = code.replaceFirst(_aimPrefixRe, '');
  return code.trim();
}

/// Отрезать серийный номер, когда сканер не передал GS: криптохвост начинается с 91/92/93.
String _cutSerialWithoutGs(String rest) {
  final gsIndex = rest.indexOf(kGs);
  if (gsIndex >= 0) return rest.substring(0, gsIndex);
  final cryptoIndex = rest.indexOf(RegExp(r'9[123]'));
  return cryptoIndex > 0 ? rest.substring(0, cryptoIndex) : rest;
}

/// Разобрать отсканированную строку.
///
/// `null` — это не код маркировки (обычный штрих-код, поиск по названию и т.п.).
MarkingCode? parseMarkingCode(dynamic raw) {
  final code = normalizeScannedCode(raw);
  if (code.length < _minMarkingLength) return null;

  // Сигареты: ровно 29 символов без AI и без разделителей.
  // Проверяем раньше GS1, потому что GTIN сигарет тоже может начинаться на «01»;
  // от GS1 отличаем по AI серийного номера (`21`), который у сигарет на этом месте не стоит.
  final looksLikeGs1 = RegExp(r'^0[12]\d{14}21').hasMatch(code);
  if (code.length == _tobaccoLength &&
      !code.contains(kGs) &&
      RegExp(r'^\d{14}').hasMatch(code) &&
      !looksLikeGs1) {
    return MarkingCode(
      code: code,
      gtin: code.substring(0, 14),
      serial: code.substring(14, 21),
      format: MarkingFormat.tobacco,
    );
  }

  // GS1: 01<GTIN 14>21<серийный>[GS 91…][GS 92…]. AI 02 — групповая упаковка, GTIN там же.
  final gs1 = RegExp(r'^0[12](\d{14})').firstMatch(code);
  if (gs1 != null) {
    var serial = '';
    final rest = code.substring(16);
    if (rest.startsWith('21')) {
      serial = _cutSerialWithoutGs(rest.substring(2));
    }
    return MarkingCode(
      code: code,
      gtin: gs1.group(1)!,
      serial: serial,
      format: MarkingFormat.gs1,
    );
  }

  return null;
}

/// Дешёвая проверка «похоже на код маркировки» — без разбора полей.
bool looksLikeMarkingInput(dynamic raw) => parseMarkingCode(raw) != null;

/// Варианты штрих-кода карточки для GTIN-14: это тот же штрих-код, дополненный
/// нулями слева. Порядок = приоритет поиска, от самого точного к самому короткому.
List<String> gtinToBarcodeVariants(dynamic gtin) {
  final clean = '${gtin ?? ''}'.replaceAll(RegExp(r'\D'), '');
  if (clean.isEmpty) return const [];
  final variants = <String>[clean];
  var current = clean;
  while (current.length > 8 && current.startsWith('0')) {
    current = current.substring(1);
    variants.add(current);
  }
  return variants;
}
