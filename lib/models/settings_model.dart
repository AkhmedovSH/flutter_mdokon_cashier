import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class SettingsModel with ChangeNotifier {
  final GetStorage _box = GetStorage();

  bool _showAnswer = false;
  bool _darkTheme = false;
  bool _automaticCheck = false;

  SettingsModel() {
    _showAnswer = _box.read('showAnswer') ?? false;
    _darkTheme = _box.read('darkTheme') ?? false;
    _automaticCheck = _box.read('automaticCheck') ?? false;
  }

  bool get showAnswer => _showAnswer;
  bool get darkTheme => _darkTheme;
  bool get automaticCheck => _automaticCheck;

  void updateSetting(String key, bool value) {
    switch (key) {
      case 'showAnswer':
        _showAnswer = value;
        break;
      case 'darkTheme':
        _darkTheme = value;
        break;
      case 'automaticCheck':
        _automaticCheck = value;
        break;
    }
    _box.write(key, value);
    notifyListeners();
  }
}
