import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'helpers/globals.dart';

import 'pages/splash.dart';

// auth
import 'pages/auth/login.dart';
import 'pages/auth/cashboxes.dart';

import 'pages/index.dart';
import 'pages/search.dart';
import 'pages/payment/payment.dart';

import 'pages/client_debt.dart';
import 'pages/sales_on_credit.dart';
import 'pages/calculator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        brightness: Brightness.light,
        primaryColor: const Color(0xFFFF5453),
        platform: TargetPlatform.android,
        textTheme: Theme.of(context).textTheme.apply(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: blue,
          ),
        ),
      ),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const Splash()),
        // Auth
        GetPage(name: '/login', page: () => const Login()),
        GetPage(name: '/cashboxes', page: () => const CashBoxes ()),


        GetPage(name: '/', page: () => const Index()),
        GetPage(name: '/search', page: () => const Search()),
        GetPage(name: '/payment', page: () => const Payment()),
        
        GetPage(name: '/client-debt', page: () => const ClientDebt()),
        GetPage(name: '/sales-on-credit', page: () => const SalesOnCredit()),
        GetPage(name: '/calculator', page: () => const Calculator()),
      ],
    );
  }
}
