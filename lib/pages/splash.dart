import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:get/get.dart';

import 'package:in_app_update/in_app_update.dart';
import 'package:new_version/new_version.dart';

import '../helpers/globals.dart' as globals;

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  AppUpdateInfo? updateInfo;
  dynamic test = {};

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  bool flexibleUpdateAvailable = false;

  @override
  void initState() {
    super.initState();
    checkForUpdate();
    checkVersion();
    startTimer();
  }

  void checkVersion() async {
    final newVersion = NewVersion(androidId: 'com.mdokon.cabinet');
    newVersion.showAlertIfNecessary(context: context);
    final status = await newVersion.getVersionStatus();
    setState(() {
      test = status;
    });
    print(status!.canUpdate);
    print(status.localVersion);
    print(status.storeVersion);
    print(status.appStoreLink);
    newVersion.showUpdateDialog(
      context: context,
      versionStatus: status,
      dialogTitle: 'Custom dialog title',
      dialogText: 'Custom dialog text',
      updateButtonText: 'Custom update button text',
      dismissButtonText: 'Custom dismiss button text',
      dismissAction: () => SystemNavigator.pop(),
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> checkForUpdate() async {
    InAppUpdate.checkForUpdate().then((info) {
      print('Starting app updates');

      setState(() {
        updateInfo = info;
      });
      print(updateInfo?.updateAvailability);
      print(UpdateAvailability.updateAvailable);
      print(updateInfo?.updateAvailability == UpdateAvailability.updateAvailable);
      // if (updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
      //   print(111);
      InAppUpdate.performImmediateUpdate().catchError((e) => print(e.toString() + '312312312'));
      // }
      setState(() {});
    }).catchError((e) {
      print(e);
      showSnack(e.toString());
    });
  }

  void showSnack(String text) {
    if (scaffoldKey.currentContext != null) {
      ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  startTimer() {
    var _duration = const Duration(milliseconds: 2000);
    return Timer(_duration, navigate);
  }

  void navigate() async {
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    // bool lightMode =
    //     MediaQuery.of(context).platformBrightness == Brightness.light;
    return Scaffold(
        backgroundColor: globals.white,
        // body: SafeArea(
        //     child: Column(
        //   children: [
        //     Center(
        //       child: Text('Update info: $updateInfo'),
        //     ),
        //     Center(
        //       child: Text(updateInfo?.updateAvailability == UpdateAvailability.updateAvailable ? 'true' : 'false'),
        //     ),
        //     Center(
        //       child: Text('${test.localVersion}'),
        //     ),
        //     Center(
        //       child: Text('${test.storeVersion}'),
        //     ),
        //     Center(
        //       child: Text('${test.appStoreLink}'),
        //     ),
        //     ElevatedButton(
        //       child: Text('Check for Update'),
        //       onPressed: () => checkForUpdate(),
        //     ),
        //   ],
        // ))
        body: Center(
          child: Image.asset(
            'images/splash_logo.png',
            height: 200,
            width: 200,
          ),
        ),
        );
  }
}
