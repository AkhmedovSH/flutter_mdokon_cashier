import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/globals.dart';
import '../../helpers/api.dart';

class CashBoxes extends StatefulWidget {
  const CashBoxes({Key? key}) : super(key: key);

  @override
  _CashBoxesState createState() => _CashBoxesState();
}

class _CashBoxesState extends State<CashBoxes> {
  dynamic poses = Get.arguments;

  selectCashbox(pos, cashbox) async {
    print(111);
    print(pos);
    print(cashbox);
    print(DateTime);
    final response = await post('/services/desktop/api/open-shift', {
      'posId': pos['posId'],
      'cashboxId': cashbox['id'],
      'offline': false,
      // 'acttionDate':
    });
    if (response['success']) {
      Get.offAllNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF5b73e8), Color(0xFF776bcc)])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: white, width: 1))),
              child: Text(
                'Свободные кассы',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w500, color: white),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Выберите кассу для входа',
                style: TextStyle(
                    color: white, fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            Column(
              children: [
                for (var i = 0; i < poses.length; i++)
                  Container(
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 10),
                          child: Text(
                            poses[i]['posName'],
                            style: TextStyle(
                                color: white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        for (var j = 0; j < poses[i]['cashboxList'].length; j++)
                          Container(
                            margin: EdgeInsets.only(bottom: 10),
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: blue,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                                side: const BorderSide(
                                  color: Color.fromARGB(0, 0, 100, 1),
                                ),
                              ),
                              onPressed: () {
                                selectCashbox(
                                    poses[i], poses[i]['cashboxList'][j]);
                              },
                              child: Text(
                                poses[i]['cashboxList'][j]['name'],
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                  primary: white,
                                  padding: EdgeInsets.symmetric(vertical: 12)),
                              child: Text(
                                'Выйти',
                                style: TextStyle(
                                    color: blue,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18),
                              ),
                            ))
                      ],
                    ),
                  )
              ],
            )
          ],
        ),
      ),
    );
  }
}
