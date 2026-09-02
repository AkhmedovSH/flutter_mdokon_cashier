import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/theme/themes.dart';

/// Активная тема приложения.
///
/// Хранит не `ThemeData`, а один флаг: тема — это в первую очередь палитра
/// ([AppColors]), а `ThemeData` из неё выводится. Модель — единственное место,
/// где палитра переключается, поэтому виджеты, читающие токены напрямую, и
/// виджеты, читающие `Theme.of(context)`, всегда показывают одно и то же.
class ThemeModel with ChangeNotifier {
  final GetStorage storage = GetStorage();

  bool _isDark;

  ThemeModel(bool isDark) : _isDark = isDark {
    AppColors.use(isDark);
  }

  bool get isDark => _isDark;

  ThemeData get themeData => buildAppTheme(AppColors.palette);

  /// Всегда явный режим, не [ThemeMode.system]: палитра статическая, и «пусть
  /// решит система» означало бы, что Flutter выбрал одну тему, а токены в
  /// экранах остались от другой. Системную яркость учитываем один раз при
  /// первом запуске — в `main()`, пока пользователь не выбрал сам.
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void setDark(bool value) {
    if (_isDark == value) return;
    _isDark = value;
    AppColors.use(value);
    applySystemOverlayStyle();
    storage.write('isDarkTheme', value);
    notifyListeners();
  }

  /// Перекрасить системные панели под активную палитру. Экраны без `AppBar`
  /// свой стиль не задают, поэтому без этого вызова статус-бар и панель
  /// навигации оставались от прежней темы.
  static void applySystemOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(systemOverlayStyleFor(AppColors.palette));
  }
}
