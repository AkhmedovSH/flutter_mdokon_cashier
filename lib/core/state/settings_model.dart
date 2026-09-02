import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

/// Настройки кассы.
///
/// Раньше на каждый ключ было поле, геттер и ветка `switch` — три правки на
/// одну настройку и молчаливая потеря значения, если про ветку забыли. Теперь
/// источник правды один: [defaults]. Добавить настройку — дописать сюда строку
/// (и, если удобно, именованный геттер ниже).
///
/// Значения лежат в двух местах `GetStorage`: плоским ключом (так их читали
/// исторически) и внутри карты `settings` — её целиком отправляют на сервер и
/// читает [PrinterModel]. Пишем в оба, чтобы расхождения не возникало.
class SettingsModel with ChangeNotifier {
  SettingsModel() {
    final stored = storage.read('settings');
    for (final entry in defaults.entries) {
      final key = entry.key;
      final value = storage.read(key) ??
          (stored is Map ? stored[key] : null) ??
          entry.value;
      _values[key] = value;
    }
  }

  final GetStorage storage = GetStorage();

  /// Все известные настройки и их значения по умолчанию.
  ///
  /// Нумерация разделов повторяет десктопную кассу: 1 — касса, 2 — весы,
  /// 3 — печать, 4 — отложенные чеки.
  static const Map<String, dynamic> defaults = {
    // Общие
    'theme': false,

    // Расширенный лог: пишет уровень `debug` в файл на устройстве.
    // Device-local, как тема, — на сервер не влияет (см. core/utils/logger.dart).
    'verboseLog': false,

    // 1. Касса
    'changeCurrencyOnSale': false,
    'decimalDigits': 0.0,
    'showConfirmModalDeleteItem': false,
    'showConfirmModalDeleteAllItems': true,
    'showLastScannedProduct': false,
    'productGrouping': false,
    'showProductOutOfStock': false,
    'searchExact': false,
    'amountExceedsLimit': false,
    'accountingBalance': false,

    // 2. Весы
    'barcodeFormat': '5',
    'weightPrefix': 20.0,
    'piecePrefix': 21.0,
    'finalPrefix': 25.0,

    // 3. Печать
    'printAfterSale': false,
    'chequeCopy': false,
    'showBarcode': false,
    'showQrCode': false,
    'printReturnCheque': false,
    'print2cheques': false,
    'printerBroken': false,

    // 4. Отложенные чеки
    'postponeOnline': false,
    'postponeOffline': false,
  };

  /// Настройки, которые нельзя включить одновременно: включение одной гасит
  /// другую (как `exclusive` в десктопной схеме).
  static const Map<String, String> exclusive = {
    'postponeOnline': 'postponeOffline',
    'postponeOffline': 'postponeOnline',
  };

  final Map<String, dynamic> _values = {};

  /// Снимок всех настроек — для экрана настроек и отправки на сервер.
  Map<String, dynamic> get values => Map.unmodifiable(_values);

  dynamic operator [](String key) => _values[key] ?? defaults[key];

  bool flag(String key) => _values[key] == true;

  double number(String key) {
    final value = _values[key];
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  String text(String key) => '${_values[key] ?? ''}';

  // Часто используемые настройки — именованными геттерами, чтобы не сыпать
  // строковыми ключами по всему коду.
  bool get theme => flag('theme');
  bool get verboseLog => flag('verboseLog');
  bool get changeCurrencyOnSale => flag('changeCurrencyOnSale');
  double get decimalDigits => number('decimalDigits');
  bool get printAfterSale => flag('printAfterSale');
  bool get showConfirmModalDeleteItem => flag('showConfirmModalDeleteItem');
  bool get showConfirmModalDeleteAllItems => flag('showConfirmModalDeleteAllItems');
  bool get showLastScannedProduct => flag('showLastScannedProduct');
  bool get productGrouping => flag('productGrouping');
  bool get showProductOutOfStock => flag('showProductOutOfStock');
  bool get searchExact => flag('searchExact');
  bool get amountExceedsLimit => flag('amountExceedsLimit');
  bool get accountingBalance => flag('accountingBalance');
  int get barcodeFormat => int.tryParse(text('barcodeFormat')) ?? 5;
  int get weightPrefix => number('weightPrefix').round();
  int get piecePrefix => number('piecePrefix').round();
  int get finalPrefix => number('finalPrefix').round();
  bool get chequeCopy => flag('chequeCopy');
  bool get showBarcode => flag('showBarcode');
  bool get showQrCode => flag('showQrCode');
  bool get printReturnCheque => flag('printReturnCheque');
  bool get print2cheques => flag('print2cheques');
  bool get printerBroken => flag('printerBroken');
  bool get postponeOnline => flag('postponeOnline');
  bool get postponeOffline => flag('postponeOffline');

  void updateSetting(String key, dynamic value) {
    if (!defaults.containsKey(key)) return;

    _values[key] = value;
    _persist(key, value);

    // Взаимоисключающие пары гасим здесь, а не в UI: настройку меняет и экран
    // настроек, и восстановление с сервера.
    final other = exclusive[key];
    if (other != null && value == true && _values[other] == true) {
      _values[other] = false;
      _persist(other, false);
    }

    notifyListeners();
  }

  /// Записать сразу несколько настроек — один `notifyListeners()` на всё
  /// сохранение, а не по перестроению экрана на каждый переключатель.
  void updateAll(Map<String, dynamic> changes) {
    var changed = false;
    for (final entry in changes.entries) {
      if (!defaults.containsKey(entry.key)) continue;
      if (_values[entry.key] == entry.value) continue;
      _values[entry.key] = entry.value;
      _persist(entry.key, entry.value);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void _persist(String key, dynamic value) {
    storage.write(key, value);

    final stored = storage.read('settings');
    final settings = stored is Map ? Map<String, dynamic>.from(stored) : <String, dynamic>{};
    settings[key] = value;
    storage.write('settings', settings);
  }
}
