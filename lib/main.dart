import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:get_storage/get_storage.dart';
import 'package:toastification/toastification.dart';
import 'package:provider/provider.dart';

import 'models/locale_model.dart';
import 'models/theme_model.dart';
import 'models/loading_model.dart';
import 'models/settings_model.dart';
import 'models/user_model.dart';
import 'models/data_model.dart';
import 'models/filter_model.dart';

import 'helpers/routes/index.dart';
import 'helpers/themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await EasyLocalization.ensureInitialized();

  const locales = [
    Locale('ru', ''),
    Locale('uz', 'Latn'),
    Locale('uz', 'Cyrl'),
  ];

  final storage = GetStorage();

  var isDarkTheme = storage.read('isDarkTheme') ?? SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  final theme = isDarkTheme ? darkTheme : lightTheme;

  String savedLocaleId = storage.read('locale_id') ?? '1';

  Locale locale = const Locale('ru', '');
  if (savedLocaleId == '2') {
    locale = const Locale('uz', 'Cyrl');
  } else if (savedLocaleId == '3') {
    locale = const Locale('uz', 'Latn');
  }

  runApp(
    EasyLocalization(
      supportedLocales: locales,
      path: 'assets/i18n',
      fallbackLocale: const Locale('ru', ''),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeModel(theme)),
          ChangeNotifierProvider(create: (_) => LocaleModel(locale, savedLocaleId)),
          ChangeNotifierProvider(create: (_) => LoaderModel()),
          ChangeNotifierProvider(create: (_) => SettingsModel()),
          ChangeNotifierProvider(create: (_) => UserModel(storage.read('user') ?? {})),
          ChangeNotifierProvider(create: (_) => DataModel()),
          ChangeNotifierProvider(create: (_) => FilterModel()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: Consumer2<ThemeModel, LocaleModel>(
        builder: (context, themeModel, localeModel, child) {
          context.setLocale(localeModel.locale);
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: localeModel.locale,
            themeMode: ThemeMode.system,
            theme: themeModel.themeData,
            routerConfig: globalRouter,
          );
        },
      ),
    );
  }
}
