import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kassa/models/cashier/dashboard_model.dart';

import 'package:toastification/toastification.dart';
import 'package:provider/provider.dart';

import 'models/locale_model.dart';
import 'models/theme_model.dart';
import 'models/loading_model.dart';
import 'models/settings_model.dart';
import 'models/user_model.dart';
import 'models/data_model.dart';
import 'models/filter_model.dart';

import 'package:kassa/models/director/documents_in_model.dart';
import 'package:kassa/models/director/inventory_model.dart';

import 'helpers/routes/index.dart';
import 'helpers/themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await GetStorage.init();
  await EasyLocalization.ensureInitialized();

  final storage = GetStorage();

  var isDarkTheme = storage.read('isDarkTheme') ?? SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  final theme = isDarkTheme ? darkTheme : lightTheme;

  bool savedLocale = storage.read('language') ?? false;

  Locale locale = const Locale('ru', '');
  if (savedLocale) {
    locale = const Locale('uz', 'Latn');
  }

  const locales = [
    Locale('ru', ''),
    Locale('uz', 'Latn'),
  ];

  runApp(
    EasyLocalization(
      supportedLocales: locales,
      path: 'assets/i18n',
      fallbackLocale: const Locale('ru', ''),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeModel(theme)),
          ChangeNotifierProvider(create: (_) => LocaleModel(locale)),
          ChangeNotifierProvider(create: (_) => LoadingModel()),
          ChangeNotifierProvider(create: (_) => SettingsModel()),
          ChangeNotifierProvider(
            create: (_) => UserModel(
              storage.read('user') ?? {},
              storage.read('cashbox') ?? {},
            ),
          ),
          ChangeNotifierProvider(create: (_) => DataModel()),
          ChangeNotifierProvider(create: (_) => FilterModel()),
          ChangeNotifierProvider(create: (_) => DocumentsInModel()),
          ChangeNotifierProvider(create: (_) => InventoryModel()),
          ChangeNotifierProvider(create: (_) => DashboardModel()),
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
