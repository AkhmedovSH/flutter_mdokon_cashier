import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class SettingsModel with ChangeNotifier {
  final GetStorage box = GetStorage();

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
    _theme = box.read('theme') ?? false;
    _showChequeProducts = box.read('showChequeProducts') ?? false;
    _searchGroupProducts = box.read('searchGroupProducts') ?? false;
    _printAfterSale = box.read('printAfterSale') ?? false;
    _selectUserAftersale = box.read('selectUserAftersale') ?? false;
    _offlineDeferment = box.read('offlineDeferment') ?? false;
    _additionalInfo = box.read('additionalInfo') ?? false;
    _language = box.read('language') ?? false;
    _decimalDigits = box.read('decimalDigits') ?? 0;
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
    box.write(key, value);
    notifyListeners();
  }
}
