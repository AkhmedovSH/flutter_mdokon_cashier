import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import 'package:flutter_mdokon/app/router/app_router.dart';
import 'package:flutter_mdokon/core/localization/locale_model.dart';
import 'package:flutter_mdokon/core/theme/theme_model.dart';
import 'package:flutter_mdokon/features/cashier/models/printer_model.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  Future<void> setInitData() async {
    // initializeNotifications(context);
    Provider.of<PrinterModel>(context, listen: false).autoConnectSavedPrinter();
  }

  @override
  void initState() {
    super.initState();
    setInitData();
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
