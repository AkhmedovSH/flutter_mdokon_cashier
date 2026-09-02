import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mdokon/features/cashier/models/dashboard_model.dart';
import 'package:flutter_mdokon/features/cashier/models/sale_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/catalog.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/profile/profile.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/return.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/widgets/cashier_nav_bar.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/widgets/cashier_top_bar.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

import 'package:unicons/unicons.dart';

import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/home.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/cheques/cheques.dart';

import 'package:go_router/go_router.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/profile/whats_new.dart';

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({
    super.key,
  });

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> {
  final GetStorage _storage = GetStorage();

  @override
  void initState() {
    super.initState();
    // «Что нового» показывается один раз на версию и только после того, как
    // касса уже открылась: перебивать вход кассира списком изменений нельзя.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWhatsNew());
  }

  Future<void> _showWhatsNew() async {
    if (!await shouldShowWhatsNew()) return;
    if (!mounted) return;
    context.push('/cashier/profile/whats-new');
  }

  /// Кассир для верхней навигации: имя и фамилия, иначе логин.
  String get _cashierName {
    final user = _storage.read('user') ?? {};
    final full = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    return full.isEmpty ? '${user['login'] ?? ''}' : full;
  }

  /// Торговая точка и касса — то же, что на телефоне пишет шапка продажи.
  String _cashierMeta(BuildContext context) {
    final cashbox = context.read<SaleModel>().cashbox;
    return [
      if (customIf(cashbox['posName'])) '${cashbox['posName']}',
      if (customIf(cashbox['cashboxName'])) '${cashbox['cashboxName']}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // С любой вкладки «назад» возвращает к продаже, и только с неё — выход.
        final dashboard = context.read<DashboardModel>();
        if (dashboard.currentIndex != 0) {
          dashboard.setCurrentIndex(0);
          return;
        }
        showSecondModalConfirm();
      },
      child: Consumer<DashboardModel>(
        builder: (context, dashboardModel, child) {
          final items = [
            CashierNavItem(
              icon: UniconsLine.shopping_cart,
              labelKey: 'sale',
              badge: context.watch<SaleModel>().lineCount,
            ),
            const CashierNavItem(icon: UniconsLine.search, labelKey: 'products'),
            const CashierNavItem(icon: UniconsLine.receipt, labelKey: 'checks'),
            const CashierNavItem(icon: UniconsLine.backward, labelKey: 'return'),
            const CashierNavItem(icon: UniconsLine.user, labelKey: 'profile'),
          ];

          // На широком экране разделы переезжают в шапку: низ планшета и
          // планшета кассир руками не достаёт.
          final topNav = context.layout.useTopNav;

          // Статус-бар уже закрыла шапка навигации: если оставить отступ
          // страницам, каждая из них добавит его второй раз.
          final pages = MediaQuery.removePadding(
            context: context,
            removeTop: topNav,
            child: SizedBox.expand(
              child: IndexedStack(
                index: dashboardModel.currentIndex,
                children: [
                  CashierHome(hasShellHeader: topNav),
                  Catalog(),
                  dashboardModel.currentIndex == 2 ? Cheques() : SizedBox(),
                  dashboardModel.currentIndex == 3 ? Return() : SizedBox(),
                  Profile(),
                ],
              ),
            ),
          );

          return Scaffold(
            backgroundColor: AppColors.canvas,
            resizeToAvoidBottomInset: false,
            body: topNav
                ? Column(
                    children: [
                      CashierTopBar(
                        items: items,
                        currentIndex: dashboardModel.currentIndex,
                        onTap: dashboardModel.setCurrentIndex,
                        name: _cashierName,
                        meta: _cashierMeta(context),
                      ),
                      Expanded(child: pages),
                    ],
                  )
                : pages,
            bottomNavigationBar: topNav
                ? null
                : CashierNavBar(
                    currentIndex: dashboardModel.currentIndex,
                    onTap: dashboardModel.setCurrentIndex,
                    items: items,
                  ),
          );
        },
      ),
    );
  }

  void showSecondModalConfirm() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: bgColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        scrollable: true,
        content: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Center(
                  child: Text(
                    context.tr('are_you_sure_you_want_to_go_out'),
                    style: TextStyle(
                      color: black,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: MediaQuery.of(context).size.width,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: white,
                      ),
                      child: Text(
                        context.tr('cancel'),
                        style: TextStyle(color: black),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Provider.of<DashboardModel>(context, listen: false).closeApp();
                      },
                      child: Text(
                        context.tr('confirm'),
                        style: TextStyle(color: white),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
