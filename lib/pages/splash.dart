import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../helpers/api.dart';
import '../helpers/helper.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  String vesrion = '';
  Uri url = Uri.parse('https://play.google.com/store/apps/details?id=com.mdokon.cabinet');
  bool isRequired = false;

  checkVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String localVersion = packageInfo.version;

    vesrion = localVersion;
    setState(() {});
    var playMarketVersion = await get('/services/admin/api/get-version?name=com.mdokon.cabinet');
    if (playMarketVersion == null || playMarketVersion['version'] == null) {
      startTimer();
      return;
    }
    if (int.parse(playMarketVersion['version'].split('.')[2]) > int.parse(localVersion.split('.')[2])) {
      if (playMarketVersion['required']) {
        setState(() {
          isRequired = true;
        });
      }
      await showUpdateDialog();
      if (isRequired) {
        SystemNavigator.pop();
      } else {
        startTimer();
      }
    } else {
      startTimer();
    }
  }

  startTimer() {
    var _duration = const Duration(milliseconds: 1500);
    return Timer(_duration, navigate);
  }

  navigate() async {
    context.go('/auth');
  }

  @override
  void initState() {
    super.initState();
    checkVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Image.asset(
                  'images/splash_logo.png',
                  width: MediaQuery.of(context).size.width * 0.5,
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
          Container(
            alignment: Alignment.bottomCenter,
            margin: EdgeInsets.only(bottom: 10),
            child: Text(
              vesrion,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  showUpdateDialog() async {
    await showDialog(
        context: context,
        // barrierDismissible: !isRequired,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              insetPadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
              title: Text(
                'Обновить приложение moneyBek',
                style: const TextStyle(color: Colors.black),
                // textAlign: TextAlign.center,
              ),
              scrollable: true,
              content: SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      isRequired
                          ? 'Требуется установить последнюю версию чтобы продолжить использовать приложение moneyBek'
                          : 'Рекомендуем установить последнюю версию приложения moneyBek Во время скачивания обновлений вы по-прежнему сможете им пользоваться.',
                      style: const TextStyle(color: Colors.black, height: 1.2),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Container(
                      padding: const EdgeInsets.only(bottom: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          isRequired
                              ? Container()
                              : Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  child: TextButton(
                                    onPressed: () {
                                      context.pop();
                                    },
                                    style: TextButton.styleFrom(backgroundColor: const Color(0xFF00865F)),
                                    child: Text(
                                      'НЕТ, СПАСИБО',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                          ElevatedButton(
                            onPressed: () {
                              launchUrl(url);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00865F),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              elevation: 0,
                            ),
                            child: Text('Обновить'),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: Image.asset(
                        'images/google_play.png',
                        height: 25,
                        fit: BoxFit.cover,
                      ),
                    )
                  ],
                ),
              ),
            );
          });
        });
  }
}
