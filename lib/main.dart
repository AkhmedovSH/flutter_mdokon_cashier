import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mdokon/app/app.dart';
import 'package:flutter_mdokon/app/providers.dart';
import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/theme/theme_model.dart';
import 'package:flutter_mdokon/core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await EasyLocalization.ensureInitialized();

  final storage = GetStorage();

  // Файловый лог поднимаем до первого экрана: падение на старте тоже должно
  // попасть в файл (см. lib/core/utils/logger.dart).
  await appLog.init();
  appLog.refreshVerbose();
  appLog.installGlobalErrorHandlers();
  appLog.info('app.start');

  // Пользовательский выбор темы важнее системного: системную яркость берём
  // только при самом первом запуске, пока в хранилище ничего нет.
  final bool isDarkTheme = storage.read('isDarkTheme') ?? SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  AppColors.use(isDarkTheme);

  // Рисуем под системными панелями: иначе Android заливает их своим чёрным
  // (`windowDrawsSystemBarBackgrounds` был выключен), и статус-бар оставался
  // тёмным в любой теме. Шапки экранов красят эту область сами — они уже
  // обёрнуты в `SafeArea` поверх цветного контейнера.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  ThemeModel.applySystemOverlayStyle();

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
