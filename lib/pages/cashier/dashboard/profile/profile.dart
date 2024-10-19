import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:unicons/unicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '/helpers/api.dart';
import '../../../../helpers/helper.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  GetStorage storage = GetStorage();

  Map cashbox = {};
  Map account = {'firstName': "", 'lastName': ""};

  void openPhoneCall() async {
    if (!await launchUrl(Uri.parse("tel://+998555000089"))) throw 'Could not launch';
  }

  void getCashboxInfo() async {
    cashbox = jsonDecode(storage.read('cashbox')!);
    account = jsonDecode(storage.read('account')!);
    setState(() {});
    print(account);
  }

  @override
  void initState() {
    super.initState();
    getCashboxInfo();
  }

  buildRow(IconData icon, String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (title == 'X_report') {
                context.go('/cashier/x-report');
              }
              if (title == 'balance') {
                context.go('/cashier/balance');
              }
              if (title == 'info') {
                context.go('/cashier/info');
              }
              if (title == 'settings') {
                context.go('/cashier/settings');
              }
              if (title == 'close_shift') {
                openModal('close_shift');
              }
              if (title == 'logout') {
                openModal('logout');
              }
              if (title == 'support') {
                openPhoneCall();
              }
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: borderColor,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 26,
                  ),
                  SizedBox(width: 10),
                  Text(
                    context.tr(title),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarColor: mainColor, // Status bar
        ),
        bottomOpacity: 0.0,
        title: Text(
          context.tr('profile'),
          style: TextStyle(color: white),
        ),
        centerTitle: true,
        backgroundColor: mainColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: blue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                  margin: const EdgeInsets.only(right: 15),
                  height: 64,
                  width: 64,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account['firstName'] + ' ' + account['lastName'],
                      style: TextStyle(
                        fontSize: 16,
                        color: white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${context.tr('login')}: ${account['login']}',
                      style: TextStyle(
                        color: white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'ID: ${cashbox['posId']} (${cashbox['posName']})',
                      style: TextStyle(
                        color: white,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          if (cashbox['isAgent'] != true) buildRow(UniconsLine.clipboard_alt, 'X_report'),
          buildRow(UniconsLine.box, 'balance'),
          buildRow(UniconsLine.question_circle, 'info'),
          if (cashbox['isAgent'] != true) buildRow(UniconsLine.cog, 'settings'),
          if (cashbox['isAgent'] != true) buildRow(UniconsLine.sign_out_alt, 'close_shift'),
          buildRow(UniconsLine.sign_out_alt, 'logout'),
          buildRow(UniconsLine.calling, 'support'),
        ],
      ),
    );
  }

  void closeShift() async {
    int id = 0;
    dynamic shift = {'id': null};
    Map response = {
      'success': true,
    };
    if (cashbox['isAgent'] != true) {
      if (storage.read('shift') != null) {
        shift = jsonDecode(storage.read('shift')!);
      }
      if (shift['id'] != null) {
        id = shift['id'];
      } else {
        id = cashbox['id'];
      }
      response = await post('/services/desktop/api/close-shift', {
        'cashboxId': cashbox['cashboxId'],
        'posId': cashbox['posId'],
        'offline': false,
        'id': id,
      });
    }

    storage.remove('user');
    storage.remove('access_token');
    if (response['success']) {
      context.go('/auth/login');
    }
    //print(response);
  }

  void logout() async {
    storage.remove('user');
    storage.remove('access_token');
    context.go('/auth/login');
    //print(response);
  }

  openModal(type) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(24.0),
          ),
        ),
        title: const Text(''),
        titlePadding: const EdgeInsets.all(0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        actionsPadding: const EdgeInsets.all(0),
        buttonPadding: const EdgeInsets.all(0),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.21,
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(
                type == 'logout' ? context.tr('are_you_sure_you_want_to_go_out') : context.tr('are_you_sure_you_want_to_close_your_shift'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: danger,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(context.tr('cancel')),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.pop();
                        if (type == 'logout') {
                          logout();
                        } else {
                          closeShift();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(context.tr('continue')),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
