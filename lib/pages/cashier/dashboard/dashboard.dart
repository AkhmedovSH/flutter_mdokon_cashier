import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:kassa/models/cashier/dashboard_model.dart';
import 'package:kassa/pages/cashier/dashboard/profile/profile.dart';
import 'package:kassa/pages/cashier/dashboard/return.dart';
import 'package:provider/provider.dart';

import 'package:unicons/unicons.dart';

import 'home/index.dart';
import 'cheques/cheques.dart';

import '../../../helpers/helper.dart';

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({
    Key? key,
  }) : super(key: key);

  @override
  State<CashierDashboard> createState() => _DashboardState();
}

class _DashboardState extends State<CashierDashboard> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showSecondModalConfirm();
        return false;
      },
      child: Consumer<DashboardModel>(
        builder: (context, dashboardModel, child) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: SizedBox.expand(
              child: IndexedStack(
                index: dashboardModel.currentIndex,
                children: [
                  Index(),
                  dashboardModel.currentIndex == 1 ? Cheques() : SizedBox(),
                  dashboardModel.currentIndex == 2 ? Return() : SizedBox(),
                  Profile(),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: black.withOpacity(0.3),
                    width: 0.33,
                  ),
                ),
              ),
              child: BottomAppBar(
                padding: const EdgeInsets.all(0),
                elevation: 0,
                color: Colors.transparent,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: BottomNavigationBar(
                    onTap: (index) => dashboardModel.setCurrentIndex(index),
                    backgroundColor: Colors.transparent,
                    selectedItemColor: mainColor,
                    currentIndex: dashboardModel.currentIndex,
                    type: BottomNavigationBarType.fixed,
                    selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: TextStyle(
                      color: grey,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    elevation: 0,
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(UniconsLine.monitor),
                        label: context.tr('sale'),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(UniconsLine.receipt),
                        label: context.tr('checks'),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(UniconsLine.backward),
                        label: context.tr('return'),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(UniconsLine.user),
                        label: context.tr('profile'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // bottomNavigationBar: Container(
            //   decoration: BoxDecoration(
            //     color: const Color(0xFFFEFEFE),
            //     borderRadius: BorderRadius.circular(20),
            //     boxShadow: [boxShadow],
            //   ),
            //   child: ClipRRect(
            //     borderRadius: const BorderRadius.only(
            //       topLeft: Radius.circular(20.0),
            //       topRight: Radius.circular(20.0),
            //     ),
            //     child: BottomAppBar(
            //       padding: EdgeInsets.all(5),
            //       elevation: 0,
            //       child: BottomNavigationBar(
            //         onTap: (index) => setState(() {
            //           currentIndex = index;
            //         }),
            //         backgroundColor: Colors.transparent,
            //         selectedItemColor: blue,
            //         currentIndex: currentIndex,
            //         type: BottomNavigationBarType.fixed,
            //         selectedFontSize: 10,
            //         unselectedFontSize: 10,
            //         selectedLabelStyle: TextStyle(
            //           fontWeight: FontWeight.w600,
            //           color: blue,
            //           fontSize: 14,
            //         ),
            //         unselectedLabelStyle: TextStyle(
            //           color: black,
            //           fontWeight: FontWeight.w400,
            //         ),
            //         elevation: 0,
            //         items: [
            //           getDashBoardItem(UniconsLine.monitor, 'sale'),
            //           getDashBoardItem(UniconsLine.receipt, 'checks'),
            //           getDashBoardItem(UniconsLine.backward, 'return'),
            //           getDashBoardItem(UniconsLine.user, 'profile'),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
          );
        },
      ),
    );
  }

  showSecondModalConfirm() {
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
