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
    print(response);
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
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 15),
              child: Icon(
                icon,
                size: 26,
                color: Colors.grey,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: Color(0xFF525355),
              ),
            )
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
          mainAxisSize: MainAxisSize.max,
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
                        'Shokhrukh',
                        style: TextStyle(fontSize: 16, color: white),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'ID: 84 (M Dokon)',
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
              margin: const EdgeInsets.only(top: 15, left: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: Text(
                      'Меню',
                      style: TextStyle(
                        fontSize: 18,
                        color: grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  buildListTile(
                    'Долг клиента',
                    Icons.account_circle_outlined,
                    '/client-debt',
                  ),
                  buildListTile(
                    'Продажи в долг',
                    Icons.sync_problem,
                    '/sales-on-credit',
                  ),
                  buildListTile(
                    'Калькулятор',
                    Icons.calculate,
                    '/calculator',
                  ),
                  buildListTile(
                    'Чеки',
                    Icons.list_alt,
                    '/calculator',
                  ),
                  buildListTile(
                    'Возврат товаров',
                    Icons.reply_all_outlined,
                    '/calculator',
                  ),
                  buildListTile(
                    'X Отчет',
                    Icons.bar_chart,
                    '/calculator',
                  ),
                ],
              ),
            ),
            const Expanded(child: SizedBox()),
            SizedBox(
              child: ElevatedButton(
                onPressed: () {
                  closeShift();
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
