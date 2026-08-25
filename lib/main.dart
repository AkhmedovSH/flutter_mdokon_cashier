import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mdokon/app/app.dart';
import 'package:flutter_mdokon/app/providers.dart';
import 'package:flutter_mdokon/core/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await EasyLocalization.ensureInitialized();

  final storage = GetStorage();

  // Пользовательский выбор темы важнее системного: системную яркость берём
  // только при самом первом запуске, пока в хранилище ничего нет.
  final bool isDarkTheme = storage.read('isDarkTheme') ??
      SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  AppColors.use(isDarkTheme);

  bool savedLocale = storage.read('language') ?? false;

  Locale locale = const Locale('ru', '');
  if (savedLocale) {
    locale = const Locale('uz', 'Latn');
  }

  const locales = [
    Locale('ru', ''),
    Locale('uz', 'Latn'),
  ];
  if (storage.read('settings') is String) {
    storage.write('settings', jsonDecode(storage.read('settings')));
  }

  runApp(
    EasyLocalization(
      supportedLocales: locales,
      path: 'assets/i18n',
      fallbackLocale: const Locale('ru', ''),
      child: MultiProvider(
        providers: appProviders(storage: storage, isDarkTheme: isDarkTheme, locale: locale),
        child: const App(),
      ),
    ),
  );
}
