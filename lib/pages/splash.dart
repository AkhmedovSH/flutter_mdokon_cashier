import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:get/get.dart';

import 'package:new_version/new_version.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final status = await newVersion.getVersionStatus();
    if (status!.storeVersion != status.localVersion) {
      Navigator.of(context).push(RequiredUpdatePage(status.appStoreLink.toString()));
      return;
    } else {
      startTimer();
    }
    //print(status.storeVersion);
    // print(status.appStoreLink);
    // dynamic requiredUpdate = false;
    // print(status.localVersion.substring(2, 3));
    // if (status.localVersion.substring(0, 1) != status.storeVersion.substring(0, 1)) {
    //   requiredUpdate = true;
    // }
    // if (status.localVersion.substring(2, 3) != status.storeVersion.substring(2, 3)) {
    //   requiredUpdate = true;
    // }
    // if (status.canUpdate) {
    //   if (requiredUpdate) {
    //     Navigator.of(context).push(RequiredUpdatePage(status.appStoreLink.toString()));
    //   } else {
    //     showDialog(
    //         context: context,
    //         useSafeArea: true,
    //         builder: (BuildContext context) {
    //           return AlertDialog(
    //             // title: Text('Вышло обновление'),
    //             titlePadding: EdgeInsets.all(0),
    //             insetPadding: EdgeInsets.symmetric(horizontal: 50),
    //             content: SizedBox(
    //               height: MediaQuery.of(context).size.height * 0.14,
    //               child: Column(
    //                 children: [
    //                   Image.asset(
    //                     'images/splash_logo.png',
    //                     height: 50,
    //                     // width: 50,
    //                   ),
    //                   Container(
    //                       margin: EdgeInsets.only(top: 15),
    //                       child: Text(
    //                         'Вы можете обновиться с версии ${status.localVersion} до ${status.storeVersion}',
    //                         style: TextStyle(color: globals.b8, fontWeight: FontWeight.w500, fontSize: 16),
    //                         textAlign: TextAlign.center,
    //                       ))
    //                 ],
    //               ),
    //             ),
    //             actions: [
    //               TextButton(
    //                   onPressed: () {
    //                     startTimer();
    //                     Navigator.pop(context);
    //                   },
    //                   style: TextButton.styleFrom(primary: globals.blue),
    //                   child: Text(
    //                     'Позже',
    //                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    //                   )),
    //               TextButton(
    //                   onPressed: () {
    //                     launch(status.appStoreLink);
    //                   },
    //                   style: TextButton.styleFrom(primary: globals.blue),
    //                   child: Text(
    //                     'Обновить',
    //                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    //                   )),
    //             ],
    //           );
    //         });
    //   }
    // } else {
    //   startTimer();
    // }
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

class RequiredUpdatePage extends ModalRoute<void> {
  final String url;

  RequiredUpdatePage(this.url);

  @override
  Duration get transitionDuration => Duration(milliseconds: 200);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.5);

  @override
  String get barrierLabel => '';

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // This makes sure that text and other content follows the material style
    return Material(
      type: MaterialType.transparency,
      // make sure that the overlay content is not cut off
      child: SafeArea(
        child: _buildOverlayContent(context),
      ),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/splash_logo.png',
                height: 50,
                // width: 50,
              ),
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 10),
                child: Text(
                  'Чтобы использовать mDokon, загрузите последнюю версию',
                  style: TextStyle(fontSize: 16, color: globals.b8, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                    onPressed: () {
                      launch(url);
                    },
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                    child: Text(
                      'Обновить',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    )),
              ),
              SizedBox(
                height: 20,
              )
            ],
          ),
        ),
        Positioned(
            top: 10,
            right: 10,
            child: IconButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                icon: Icon(
                  Icons.close,
                  size: 32,
                )))
      ],
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    // You can add your own animations for the overlay content
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  }
}
