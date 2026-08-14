import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import '/helpers/themes.dart';

class ThemeModel with ChangeNotifier {
  ThemeData _themeData;
  final GetStorage storage = GetStorage();

  ThemeModel(this._themeData);

  ThemeData get themeData => _themeData;

  void setTheme(ThemeData theme) {
    _themeData = theme;
    storage.write('isDarkTheme', theme == darkTheme);
    notifyListeners();
  }
}
