import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class LocaleModel with ChangeNotifier {
  Locale _locale;
  String _id;
  final GetStorage storage = GetStorage();

  LocaleModel(this._locale, this._id);

  Locale get locale => _locale;
  String get localeName => _locale.languageCode;
  String get id => _id;

  void setLocale(Locale locale, String newId) {
    _locale = locale;
    _id = newId;
    storage.write('locale_id', newId);
    storage.write('locale', locale.languageCode);
    notifyListeners();
  }
}
