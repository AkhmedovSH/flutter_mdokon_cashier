import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:kassa/helpers/globals.dart';
import 'package:kassa/helpers/api.dart';

class DrawerAppBar extends StatefulWidget {
  const DrawerAppBar({Key? key}) : super(key: key);

  @override
  _DrawerAppBarState createState() => _DrawerAppBarState();
}

class _DrawerAppBarState extends State<DrawerAppBar> {
  dynamic cashbox = {};
  dynamic account = {'firstName': "", 'lastName': ""};

  @override
  void initState() {
    super.initState();
    getCashboxInfo();
  }

  void getCashboxInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      cashbox = jsonDecode(prefs.getString('cashbox')!);
      account = jsonDecode(prefs.getString('account')!);
    });
  }

  closeShift() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int id = 0;
    dynamic shift = {'id': null};
    final cashbox = jsonDecode(prefs.getString('cashbox')!);
    if (prefs.getString('shift') != null) {
      shift = jsonDecode(prefs.getString('shift')!);
    }
    if (shift['id'] != null) {
      id = shift['id'];
    } else {
      id = cashbox['id'];
    }
    final response = await post('/services/desktop/api/close-shift', {
      'cashboxId': cashbox['cashboxId'],
      'posId': cashbox['posId'],
      'offline': false,
      'id': id
    });
    if (response['success']) {
      Get.offAllNamed('/login');
    }
    //print(response);
  }

  void _launchURL() async {
    if (!await launch("tel://+998994398808")) throw 'Could not launch';
  }

  Widget buildListTile(
    String title,
    IconData icon,
    String routeName,
  ) {
    return InkWell(
      onTap: () {
        Get.offAllNamed(routeName);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 15),
            Container(
              margin: const EdgeInsets.only(right: 15),
              child: Icon(
                icon,
                size: 24,
                color: Color(0xFF525355),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF525355),
              ),
            ),
            SizedBox(width: 15),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              color: blue,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    child: CircleAvatar(
                      radius: 30.0,
                      backgroundColor: const Color(0xFFF8F8F8),
                      child: Image.asset(
                        'images/build-logo.png',
                        width: 50,
                      ),
                    ),
                    margin: const EdgeInsets.only(right: 10, left: 10),
                    height: 64,
                    width: 64,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account['firstName'] + ' ' + account['lastName'],
                        style: TextStyle(fontSize: 16, color: white),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'ID: ${cashbox['posId']} (${cashbox['posName']})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: white,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildListTile(
                    'Продажа',
                    Icons.dashboard_outlined,
                    '/',
                  ),
                  buildListTile(
                    'Чеки',
                    Icons.list_alt_outlined,
                    '/cheques',
                  ),
                  buildListTile(
                    'Возврат товаров',
                    Icons.reply_all_outlined,
                    '/return',
                  ),
                  buildListTile(
                    'X Отчет',
                    Icons.bar_chart_outlined,
                    '/x-report',
                  ),
                ],
              ),
            ),
            const Expanded(child: SizedBox()),
            SizedBox(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Вы уверены?'),
                      // content: const Text('AlertDialog description'),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.33,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                    primary: red,
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10)),
                                child: const Text('Отмена'),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.33,
                              child: ElevatedButton(
                                onPressed: () {
                                  closeShift();
                                  Get.back();
                                },
                                style: ElevatedButton.styleFrom(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10)),
                                child: const Text('Продолжить'),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(primary: red),
                child: const Text('Закрыть смену'),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: Color(0xFF48A8FF)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _launchURL();
                      },
                      child: Row(
                        children: const [
                          Icon(
                            Icons.support_agent_outlined,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Служба поддержки',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
