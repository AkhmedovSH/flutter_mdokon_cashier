import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import 'package:unicons/unicons.dart';
import 'package:get/get.dart';

import '../cashier/dashboard/home/index.dart';
import 'cheques.dart';

import '../../../helpers/globals.dart';

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({Key? key}) : super(key: key);

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GetStorage storage = GetStorage();

  late Animation<double> animation;
  PageController? pageController;

  int currentIndex = 0;
  bool expanded = true;

  closeApp() async {
    if (storage.read('account') != null) {
      storage.remove('access_token');
      storage.remove('username');
      storage.remove('password');
      storage.remove('account');
    }
    SystemNavigator.pop();
  }

  changeExpanded() {
    setState(() {});
  }

  changeIndex(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    try {
      setState(() {
        if (Get.arguments != null && Get.arguments['value'] != null) {
          currentIndex = Get.arguments['value'];
          pageController = PageController(initialPage: Get.arguments['value']);
        } else {
          pageController = PageController();
        }
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    pageController!.dispose();
    super.dispose();
  }

  getDashBoardItem(IconData icon, String text) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: text.tr,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showSecondModalConfirm();
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SizedBox.expand(
          child: IndexedStack(
            index: currentIndex,
            // controller: pageController,
            // onPageChanged: (index) {
            //   setState(() => currentIndex = index);
            // },
            children: [
              currentIndex == 0 ? Index() : Container(),
              currentIndex == 1 ? AgentHistory() : Container(),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFEFEFE),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [boxShadow],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            child: BottomAppBar(
              padding: EdgeInsets.all(5),
              elevation: 0,
              child: BottomNavigationBar(
                onTap: (index) => setState(() {
                  currentIndex = index;
                }),
                backgroundColor: Colors.transparent,
                selectedItemColor: blue,
                currentIndex: currentIndex,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 10,
                unselectedFontSize: 10,
                selectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: blue,
                  fontSize: 14,
                ),
                unselectedLabelStyle: TextStyle(
                  color: black,
                  fontWeight: FontWeight.w400,
                ),
                elevation: 0,
                items: [
                  getDashBoardItem(UniconsLine.monitor, 'sale'),
                  getDashBoardItem(UniconsLine.receipt, 'checks'),
                ],
              ),
            ),
          ),
        ),
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
                    'are_you_sure_you_want_to_go_out'.tr,
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
                        'cancel'.tr,
                        style: TextStyle(color: black),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        closeApp();
                      },
                      child: Text(
                        'confirm'.tr,
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
