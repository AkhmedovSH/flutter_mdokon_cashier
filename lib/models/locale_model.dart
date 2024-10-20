import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class LocaleModel with ChangeNotifier {
  Locale _locale;
  final GetStorage storage = GetStorage();

  LocaleModel(this._locale);

  Locale get locale => _locale;
  String get localeName => _locale.languageCode;

  void setLocale(Locale locale) {
    _locale = locale;
    storage.write('locale', locale.languageCode);
    notifyListeners();
  }
}
