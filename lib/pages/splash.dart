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
  @override
  void initState() {
    super.initState();
    checkVersion();
  }

  void checkVersion() async {
    final newVersion = NewVersion(androidId: 'com.mdokon.cabinet');
    // newVersion.showAlertIfNecessary(context: context);
    final status = await newVersion.getVersionStatus();
    if (status!.canUpdate) {
      newVersion.showUpdateDialog(
        context: context,
        versionStatus: status,
        dialogTitle: 'Вышло обновление',
        dialogText: 'Вы можете обновиться с версии ${status.localVersion} до ${status.storeVersion}',
        updateButtonText: 'Обновить',
        dismissButtonText: 'Позже',
        dismissAction: () => SystemNavigator.pop(),
      );
    } else {
      startTimer();
    }
  }

  startTimer() {
    var _duration = const Duration(milliseconds: 1500);
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
