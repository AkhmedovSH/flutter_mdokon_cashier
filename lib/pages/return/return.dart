import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'package:kassa/helpers/globals.dart';

import '../../components/drawer_app_bar.dart';

class Return extends StatefulWidget {
  const Return({Key? key}) : super(key: key);

  @override
  State<Return> createState() => _ReturnState();
}

class _ReturnState extends State<Return> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  dynamic itemsList = [];
  dynamic returnedList = [];
  dynamic id = 0;
  dynamic data = {'cashierName': 'Фамилия И.О.', 'chequeNumber': '000000'};
  dynamic sendData = {
    'actionDate': 0,
    'cashboxId': '',
    'chequeId': 0,
    'clientAmount': 0,
    'clientId': 0,
    'currencyId': "",
    'saleCurrencyId': "",
    'itemsList': [],
    'note': "",
    'offline': false,
    'posId': '',
    'shiftId': '',
    'totalAmount': 0,
    'transactionId': "",
    'transactionsList': [
      {"amountIn": 0, "amountOut": 0, "paymentTypeId": 1, "paymentPurposeId": 3}
    ]
  };

  searchCheq() async {
    dynamic response;
    if (id != null) {
      response = await get(
          '/services/desktop/api/cheque-byNumber/$id/${sendData['posId']}');
    } else {
      response = await get(
          '/services/desktop/api/cheque-byNumber/$id/${sendData['posId']}');
    }
    if (response['id'] != null) {
      setState(() {
        data = response;
        itemsList = data['itemsList'];
      });
      for (var i = 0; i < itemsList.length; i++) {
        print(itemsList[i]['discount'].runtimeType);
        itemsList[i]['discount'] = itemsList[i]['discount'].round();
      }
    }
  }

  addToReturnList(item) {
    setState(() {
      sendData['itemsList'].add(item);
    });
  }

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cashbox = jsonDecode(prefs.getString('cashbox')!);
    dynamic shift = {};
    if (prefs.getString('shift') != null) {
      shift = jsonDecode(prefs.getString('shift')!);
    }
    final shiftId = cashbox['id'] != null ? cashbox['id'] : shift['id'];
    setState(() {
      sendData['cashboxId'] = cashbox['cashboxId'];
      sendData['posId'] = cashbox['posId'];
      sendData['shiftId'] = shiftId;
    });
    print(Get.arguments);
    if (Get.arguments != null) {
      setState(() {
        id = Get.arguments;
      });
      searchCheq();
    }
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarColor: blue, // Status bar
        ),
        bottomOpacity: 0.0,
        title: Text(
          'Возврат',
          style: TextStyle(color: white),
        ),
        centerTitle: true,
        backgroundColor: blue,
        elevation: 0,
        // centerTitle: true,
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
          },
          icon: Icon(Icons.menu, color: white),
        ),
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.70,
        child: const DrawerAppBar(),
      ),
      body: Container(
        margin: EdgeInsets.only(top: 10, left: 8, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  margin: EdgeInsets.only(bottom: 10),
                  height: 40,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        id = value;
                      });
                    },
                    onSubmitted: (value) {
                      searchCheq();
                    },
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(top: 5, left: 10),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFced4da),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFced4da),
                          width: 2,
                        ),
                      ),
                      hintText: 'Поиск',
                      filled: true,
                      fillColor: white,
                      focusColor: blue,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  width: MediaQuery.of(context).size.width * 0.23,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      searchCheq();
                    },
                    child: Text('Поиск'),
                  ),
                )
              ],
            ),
            Container(
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    border: Border(
                  bottom: BorderSide(color: Color(0xFFced4da), width: 1),
                )),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 5),
                        child: Text(
                          'Кассовый чек №: ${data['chequeNumber']}',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: b8),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text(
                              'Дата: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: b8),
                            ),
                            Container(
                              margin: EdgeInsets.only(right: 20),
                              child: Text(
                                '${data['chequeDate'] != null ? formatUnixTime(data['chequeDate']) : '00.00.0000 - 00:00'}',
                                style: TextStyle(color: b8),
                              ),
                            ),
                            Text(
                              'Кассир: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: b8),
                            ),
                            Text(
                              '${data['cashierName']}',
                              style: TextStyle(color: b8),
                            )
                          ],
                        ),
                      ),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(3),
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(
                              width: 1,
                              color: Color(0xFFDADADa),
                              style: BorderStyle.solid),
                        ),
                        children: [
                          TableRow(children: [
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Наименование товара',
                                style: TextStyle(
                                    color: Color(0xFF495057),
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Цена со скидкой',
                                style: TextStyle(
                                    color: Color(0xFF495057),
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Кол-во',
                                style: TextStyle(
                                    color: Color(0xFF495057),
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Сумма оплаты',
                                style: TextStyle(
                                    color: Color(0xFF495057),
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ]),
                          for (var i = 0; i < itemsList.length; i++)
                            TableRow(children: [
                              // HERE IT IS...
                              TableRowInkWell(
                                onDoubleTap: () {
                                  addToReturnList(itemsList[i]);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '${itemsList[i]['productName']} ',
                                    style: TextStyle(color: Color(0xFF495057)),
                                  ),
                                ),
                              ),
                              TableRowInkWell(
                                onDoubleTap: () {
                                  addToReturnList(itemsList[i]);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: (itemsList[i]['discount']) > 0 
                                      ? Text(
                                          '${itemsList[i]['salePrice'] - (int.parse(itemsList[i]['salePrice']) / 100 * int.parse(itemsList[i]['discount']))}',
                                          style: TextStyle(
                                              color: Color(0xFF495057)),
                                          textAlign: TextAlign.center,
                                        )
                                      : Text(
                                          '${itemsList[i]['salePrice']}',
                                          style: TextStyle(
                                              color: Color(0xFF495057)),
                                          textAlign: TextAlign.center,
                                        ),
                                ),
                              ),
                              TableRowInkWell(
                                onDoubleTap: () {
                                  addToReturnList(itemsList[i]);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '${itemsList[i]['quantity']}',
                                    style: TextStyle(color: Color(0xFF495057)),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              TableRowInkWell(
                                onDoubleTap: () {
                                  addToReturnList(itemsList[i]);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '${itemsList[i]['totalPrice']}',
                                    style: TextStyle(color: Color(0xFF495057)),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ),
                            ]),
                        ],
                      )
                    ],
                  ),
                )),
            Container(
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    border: Border(
                  bottom: BorderSide(color: Color(0xFFced4da), width: 1),
                )),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(3),
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(
                              width: 1,
                              color: Color(0xFFDADADa),
                              style: BorderStyle.solid),
                        ),
                        children: [
                          TableRow(children: [
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Наименование товара',
                                style: TextStyle(
                                    color: Color(0xFF495057),
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Цена со скидкой',
                                style: TextStyle(
                                    color: Color(0xFF495057),
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Кол-во возврата',
                                style: TextStyle(
                                    color: Color(0xFF495057),
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Сумма оплаты',
                                style: TextStyle(
                                    color: Color(0xFF495057),
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ]),
                          for (var i = 0; i < sendData['itemsList'].length; i++)
                            TableRow(children: [
                              // HERE IT IS...
                              TableRowInkWell(
                                onTap: () {
                                  addToReturnList(itemsList[i]);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '${sendData['itemsList'][i]['productName']} ',
                                    style: TextStyle(color: Color(0xFF495057)),
                                  ),
                                ),
                              ),
                              TableRowInkWell(
                                onTap: () {
                                  addToReturnList(itemsList[i]);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child:
                                      (sendData['itemsList'][i]['discount']) > 0
                                          ? Text(
                                              '${sendData['itemsList'][i]['salePrice'] - (int.parse(itemsList[i]['salePrice']) / 100 * int.parse(itemsList[i]['discount']))}',
                                              style: TextStyle(
                                                  color: Color(0xFF495057)),
                                              textAlign: TextAlign.center,
                                            )
                                          : Text(
                                              '${sendData['itemsList'][i]['salePrice']}',
                                              style: TextStyle(
                                                  color: Color(0xFF495057)),
                                              textAlign: TextAlign.center,
                                            ),
                                ),
                              ),
                              TableRowInkWell(
                                onDoubleTap: () {
                                  addToReturnList(sendData['itemsList'][i]);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '${sendData['itemsList'][i]['quantity']}',
                                    style: TextStyle(color: Color(0xFF495057)),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              TableRowInkWell(
                                onDoubleTap: () {
                                  addToReturnList(sendData['itemsList'][i]);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '${sendData['itemsList'][i]['totalPrice']}',
                                    style: TextStyle(color: Color(0xFF495057)),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ),
                            ]),
                        ],
                      )
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
