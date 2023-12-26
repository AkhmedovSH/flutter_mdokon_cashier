import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:unicons/unicons.dart';

import '../../helpers/globals.dart';
import '../../helpers/api.dart';

class CashBoxes extends StatefulWidget {
  const CashBoxes({Key? key}) : super(key: key);

  @override
  _CashBoxesState createState() => _CashBoxesState();
}

class _CashBoxesState extends State<CashBoxes> {
  final storage = GetStorage();

  dynamic poses = Get.arguments;

  selectCashbox(pos, cashbox) async {
    final prepareprefs = {
      'defaultCurrency': pos['defaultCurrency'],
      'defaultCurrencyName': pos['defaultCurrencyName'],
      'hidePriceIn': pos['hidePriceIn'],
      'loyaltyApi': pos['loyaltyApi'],
      'saleMinus': pos['saleMinus'],
      'posId': pos['posId'],
      'posName': pos['posName'],
      'posAddress': pos['posAddress'],
      'posPhone': pos['posPhone'],
      'cashboxId': cashbox['id'],
      'cashboxName': cashbox['name'],
    };
    storage.write('cashbox', jsonEncode(prepareprefs));
    final response = await post('/services/desktop/api/open-shift', {
      'posId': pos['posId'],
      'cashboxId': cashbox['id'],
      'offline': false,
    });
    storage.write('shift', jsonEncode(response));
    if (response['success']) {
      Get.offAllNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                SvgPicture.asset(
                  'images/icons/cashbox.svg',
                  width: MediaQuery.of(context).size.width,
                ),
                Positioned(
                  top: 5,
                  left: 10,
                  child: IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(
                      UniconsLine.arrow_left,
                      color: black,
                      size: 32,
                    ),
                  ),
                ),
                Positioned(
                    bottom: -10,
                    child: Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 5),
                            padding: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: white, width: 1),
                              ),
                            ),
                            child: Text(
                              'Свободные кассы',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: black,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Выберите кассу для входа',
                              style: TextStyle(
                                color: black,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < poses.length; i++) ...[
                      Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              poses[i]['posName'],
                              style: TextStyle(
                                color: black,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          for (var j = 0; j < poses[i]['cashboxList'].length; j++)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: blue,
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                  side: const BorderSide(
                                    color: Color.fromARGB(0, 0, 100, 1),
                                  ),
                                ),
                                onPressed: () {
                                  selectCashbox(poses[i], poses[i]['cashboxList'][j]);
                                },
                                child: Text(
                                  poses[i]['cashboxList'][j]['name'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
