import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:unicons/unicons.dart';

import './home/index.dart';
import './reports/index.dart';
import './settings.dart';

import '../../../helpers/helper.dart';

class DirectorDashboard extends StatefulWidget {
  final int initialPage;
  const DirectorDashboard({
    Key? key,
    this.initialPage = 0,
  }) : super(key: key);

  @override
  State<DirectorDashboard> createState() => _DashboardState();
}

class _DashboardState extends State<DirectorDashboard> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GetStorage storage = GetStorage();

  late Animation<double> animation;

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
    currentIndex = widget.initialPage;
  }

  @override
  void dispose() {
    super.dispose();
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
            children: const [
              Home(),
              Report(),
              Settings(),
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
                onTap: (index) => setState(() {
                  currentIndex = index;
                }),
                backgroundColor: Colors.transparent,
                selectedItemColor: mainColor,
                currentIndex: currentIndex,
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
                    icon: Icon(UniconsLine.estate),
                    label: context.tr('home'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(UniconsLine.chart_pie_alt),
                    label: context.tr('report'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(UniconsLine.cog),
                    label: context.tr('settings'),
                  ),
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
                        closeApp();
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
