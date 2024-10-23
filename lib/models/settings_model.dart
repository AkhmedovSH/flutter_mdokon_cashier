import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class SettingsModel with ChangeNotifier {
  final GetStorage _box = GetStorage();

  bool _theme = false;
  bool _showChequeProducts = false;
  bool _searchGroupProducts = false;
  bool _printAfterSale = false;
  bool _selectUserAftersale = false;
  bool _offlineDeferment = false;
  bool _additionalInfo = false;
  bool _language = false;
  double _decimalDigits = 0;

  SettingsModel() {
    _theme = _box.read('theme') ?? false;
    _showChequeProducts = _box.read('showChequeProducts') ?? false;
    _searchGroupProducts = _box.read('searchGroupProducts') ?? false;
    _printAfterSale = _box.read('printAfterSale') ?? false;
    _selectUserAftersale = _box.read('selectUserAftersale') ?? false;
    _offlineDeferment = _box.read('offlineDeferment') ?? false;
    _additionalInfo = _box.read('additionalInfo') ?? false;
    _language = _box.read('language') ?? false;
    _decimalDigits = _box.read('decimalDigits') ?? 0;
  }

  bool get theme => _theme;
  bool get showChequeProducts => _showChequeProducts;
  bool get searchGroupProducts => _searchGroupProducts;
  bool get printAfterSale => _printAfterSale;
  bool get selectUserAftersale => _selectUserAftersale;
  bool get offlineDeferment => _offlineDeferment;
  bool get additionalInfo => _additionalInfo;
  bool get language => _language;
  double get decimalDigits => _decimalDigits;

  void updateSetting(String key, dynamic value) {
    switch (key) {
      case 'theme':
        _theme = value;
        break;
      case 'showChequeProducts':
        _showChequeProducts = value;
        break;
      case 'searchGroupProducts':
        _searchGroupProducts = value;
        break;
      case 'printAfterSale':
        _printAfterSale = value;
        break;
      case 'selectUserAftersale':
        _selectUserAftersale = value;
        break;
      case 'offlineDeferment':
        _offlineDeferment = value;
        break;
      case 'additionalInfo':
        _additionalInfo = value;
        break;
      case 'language':
        _language = value;
        break;
      case 'decimalDigits':
        _decimalDigits = value;
        break;
    }
    _box.write(key, value);
    notifyListeners();
  }
}
