import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kassa/helpers/theme.dart';

import 'helpers/translations.dart';

import 'pages/splash.dart';

// auth
import 'pages/auth/login.dart';
import 'pages/auth/cashboxes.dart';

// cheques
import 'pages/cashier/dashboard/cheques/cheques.dart';
import 'pages/cashier/dashboard/cheques/cheq_detail.dart';

import 'pages/cashier/dashboard/return.dart';

import 'pages/cashier/dashboard/dashboard.dart';
// import 'pages/cashier/dashboard/index.dart';
import 'pages/cashier/dashboard/home/search.dart';
import 'pages/cashier/payment/payment_sample.dart';
import 'pages/cashier/dashboard/profile/x_report.dart';
import 'pages/cashier/dashboard/profile/settings.dart';

import 'pages/cashier/client_debt.dart';
import 'pages/cashier/sales_on_credit.dart';
import 'pages/cashier/calculator.dart';

import 'pages/agent/index.dart';
import 'pages/agent/cheques.dart';

void main() async {
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final storage = GetStorage();
  // ThemeController controller = Get.put(ThemeController());

  Locale locale = const Locale('ru', '');
  ThemeMode defaultThemeMode = ThemeMode.light;

  getLocale() async {
    if (storage.read('settings') != null) {
      var settings = jsonDecode(storage.read('settings'));
      if (settings['language']) {
        Get.updateLocale(const Locale('uz-Latn-UZ', ''));
        locale = const Locale('uz-Latn-UZ', '');
      }
      setState(() {});
    }
  }

  getTheme() async {
    if (storage.read('settings') != null) {
      var settings = jsonDecode(storage.read('settings'));
      if (settings['theme']) {
        defaultThemeMode = ThemeMode.dark;
      }
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    getLocale();
    getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      translations: Messages(),
      locale: locale,
      fallbackLocale: const Locale('ru', ''),
      debugShowCheckedModeBanner: false,
      themeMode: defaultThemeMode,
      theme: defaultThemeMode == ThemeMode.dark ? Themes.dark : Themes.light,
      initialRoute: '/splash',
      getPages: [
        // Auth
        GetPage(name: '/login', page: () => const Login()),
        GetPage(name: '/cashboxes', page: () => const CashBoxes()),
        // Welcome
        GetPage(name: '/splash', page: () => const Splash()),
        // Cashier
        GetPage(name: '/', page: () => const Dashboard()),
        GetPage(name: '/x-report', page: () => const XReport()),
        GetPage(name: '/settings', page: () => const Settings()),

        // Cheques
        GetPage(name: '/cheques', page: () => const Cheques()),
        GetPage(name: '/cheq-detail', page: () => const CheqDetail()),

        GetPage(name: '/return', page: () => const Return()),

        GetPage(name: '/search', page: () => const Search()),
        GetPage(name: '/payment', page: () => const PaymentSample()),

        GetPage(name: '/client-debt', page: () => const ClientDebt()),
        GetPage(name: '/sales-on-credit', page: () => const SalesOnCredit()),
        GetPage(name: '/calculator', page: () => const Calculator()),

        // Agent
        GetPage(name: '/agent', page: () => const AgentIndex()),
        GetPage(name: '/agent/history', page: () => const AgentHistory()),
      ],
    );
  }
}
