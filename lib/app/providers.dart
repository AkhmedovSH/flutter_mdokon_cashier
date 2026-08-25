import 'package:flutter/material.dart';

import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:flutter_mdokon/core/localization/locale_model.dart';
import 'package:flutter_mdokon/core/state/data_model.dart';
import 'package:flutter_mdokon/core/state/filter_model.dart';
import 'package:flutter_mdokon/core/state/loading_model.dart';
import 'package:flutter_mdokon/core/state/settings_model.dart';
import 'package:flutter_mdokon/core/theme/theme_model.dart';
import 'package:flutter_mdokon/features/auth/data/auth_repository.dart';
import 'package:flutter_mdokon/features/auth/models/auth_model.dart';
import 'package:flutter_mdokon/features/auth/models/user_model.dart';
import 'package:flutter_mdokon/features/cashier/models/cashbox_model.dart';
import 'package:flutter_mdokon/features/cashier/models/dashboard_model.dart';
import 'package:flutter_mdokon/features/cashier/models/payment_model.dart';
import 'package:flutter_mdokon/features/cashier/models/printer_model.dart';
import 'package:flutter_mdokon/features/cashier/models/sale_model.dart';
import 'package:flutter_mdokon/features/director/models/documents_in_model.dart';
import 'package:flutter_mdokon/features/director/models/inventory_model.dart';

/// Глобальные провайдеры приложения.
List<SingleChildWidget> appProviders({
  required GetStorage storage,
  required bool isDarkTheme,
  required Locale locale,
}) {
  return [
    ChangeNotifierProvider(create: (_) => ThemeModel(isDarkTheme)),
    ChangeNotifierProvider(create: (_) => LocaleModel(locale)),
    ChangeNotifierProvider(create: (_) => LoadingModel()),
    ChangeNotifierProvider(create: (_) => SettingsModel()),
    ChangeNotifierProvider(
      create: (_) => UserModel(
        storage.read('user') ?? {},
        storage.read('cashbox') ?? {},
        storage.read('paymentTypes') ?? [],
      ),
    ),
    // Форма и сценарий входа. Живёт поверх UserModel: пишет в него профиль
    // и открытую смену, но сам ничего не знает про UI и навигацию.
    ChangeNotifierProxyProvider<UserModel, AuthModel>(
      create: (context) => AuthModel(
        userModel: context.read<UserModel>(),
        repository: AuthRepository(storage: storage),
        storage: storage,
      ),
      update: (_, userModel, previous) =>
          previous ??
          AuthModel(
            userModel: userModel,
            repository: AuthRepository(storage: storage),
            storage: storage,
          ),
    ),
    ChangeNotifierProvider(create: (_) => DataModel()),
    ChangeNotifierProvider(create: (_) => FilterModel()),
    ChangeNotifierProvider(create: (_) => DocumentsInModel()),
    ChangeNotifierProvider(create: (_) => InventoryModel()),
    ChangeNotifierProvider(create: (_) => DashboardModel()),
    ChangeNotifierProvider(create: (_) => CashboxModel()),
    // Экран продажи: корзина, скидки, быстрые операции, расходы и долги.
    ChangeNotifierProvider(create: (_) => SaleModel(storage: storage)),
    ChangeNotifierProvider(create: (_) => PaymentModel()),
    ChangeNotifierProvider(create: (_) => PrinterModel()),
  ];
}
