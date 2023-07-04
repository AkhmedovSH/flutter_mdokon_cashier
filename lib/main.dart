import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'helpers/globals.dart';

import 'pages/splash.dart';

// auth
import 'pages/auth/login.dart';
import 'pages/auth/cashboxes.dart';

// cheques
import 'pages/cashier/cheques/cheques.dart';
import 'pages/cashier/cheques/cheq_detail.dart';

import 'pages/cashier/return/return.dart';

import 'pages/cashier/index.dart';
import 'pages/cashier/search.dart';
import 'pages/cashier/payment/payment_sample.dart';
import 'package:kassa/pages/cashier/x_report.dart';

import 'pages/cashier/client_debt.dart';
import 'pages/cashier/sales_on_credit.dart';
import 'pages/cashier/calculator.dart';

import 'pages/agent/index.dart';
import 'pages/agent/search.dart';
import 'pages/agent/cheques.dart';

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
            backgroundColor: blue,
          ),
        ),
      ),
      initialRoute: '/splash',
      getPages: [
        // Cashier
        GetPage(name: '/', page: () => const Index()),
        GetPage(name: '/splash', page: () => const Splash()),
        // Auth
        GetPage(name: '/login', page: () => const Login()),
        GetPage(name: '/cashboxes', page: () => const CashBoxes()),
        // Cheques
        GetPage(name: '/cheques', page: () => const Cheques()),
        GetPage(name: '/cheq-detail', page: () => const CheqDetail()),

        GetPage(name: '/return', page: () => const Return()),

        GetPage(name: '/search', page: () => const Search()),
        GetPage(name: '/payment', page: () => const PaymentSample()),
        GetPage(name: '/x-report', page: () => const XReport()),

        GetPage(name: '/client-debt', page: () => const ClientDebt()),
        GetPage(name: '/sales-on-credit', page: () => const SalesOnCredit()),
        GetPage(name: '/calculator', page: () => const Calculator()),

        // Agent
        GetPage(name: '/agent', page: () => const AgentIndex()),
        GetPage(name: '/agent/search', page: () => const AgentSearch()),
        GetPage(name: '/agent/history', page: () => const AgentHistory()),
      ],
    );
  }
}
