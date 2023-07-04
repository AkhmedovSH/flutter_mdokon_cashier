import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:kassa/helpers/globals.dart';
import 'package:kassa/helpers/api.dart';

class AgentDrawerAppBar extends StatefulWidget {
  const AgentDrawerAppBar({Key? key}) : super(key: key);

  @override
  _AgentDrawerAppBarState createState() => _AgentDrawerAppBarState();
}

class _AgentDrawerAppBarState extends State<AgentDrawerAppBar> {
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
    final response =
        await post('/services/desktop/api/close-shift', {'cashboxId': cashbox['cashboxId'], 'posId': cashbox['posId'], 'offline': false, 'id': id});
    if (response['success']) {
      Get.offAllNamed('/login');
    }
    //print(response);
  }

  void _launchURL() async {
    if (!await launch("tel://+998781137373")) throw 'Could not launch';
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
                    '/agent',
                  ),
                  buildListTile(
                    'История',
                    Icons.list_alt_outlined,
                    '/agent/history',
                  ),
                ],
              ),
            ),
            const Expanded(child: SizedBox()),
            SizedBox(
              child: ElevatedButton(
                onPressed: () {
                  Get.offAllNamed('/login');
                },
                style: ElevatedButton.styleFrom(backgroundColor: red),
                child: const Text('Выход'),
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
