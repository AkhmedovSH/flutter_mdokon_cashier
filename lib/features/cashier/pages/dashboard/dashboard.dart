import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mdokon/features/cashier/models/dashboard_model.dart';
import 'package:flutter_mdokon/features/cashier/models/sale_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/profile/profile.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/return.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/widgets/cashier_nav_bar.dart';
import 'package:provider/provider.dart';

import 'package:unicons/unicons.dart';

import 'package:flutter_mdokon/features/cashier/pages/dashboard/home/home.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/cheques/cheques.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({
    super.key,
  });

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showSecondModalConfirm();
      },
      child: Consumer<DashboardModel>(
        builder: (context, dashboardModel, child) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: SizedBox.expand(
              child: IndexedStack(
                index: dashboardModel.currentIndex,
                children: [
                  CashierHome(),
                  dashboardModel.currentIndex == 1 ? Cheques() : SizedBox(),
                  dashboardModel.currentIndex == 2 ? Return() : SizedBox(),
                  Profile(),
                ],
              ),
            ),
            bottomNavigationBar: CashierNavBar(
              currentIndex: dashboardModel.currentIndex,
              onTap: dashboardModel.setCurrentIndex,
              items: [
                CashierNavItem(
                  icon: UniconsLine.shopping_cart,
                  labelKey: 'sale',
                  badge: context.watch<SaleModel>().lineCount,
                ),
                const CashierNavItem(icon: UniconsLine.receipt, labelKey: 'checks'),
                const CashierNavItem(icon: UniconsLine.backward, labelKey: 'return'),
                const CashierNavItem(icon: UniconsLine.user, labelKey: 'profile'),
              ],
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
