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
  double height = 30;
  dynamic itemsList = [];
  dynamic returnedList = [];
  dynamic search = 0;
  dynamic cashbox = {};
  dynamic shift = {};
  dynamic data = {'cashierName': 'Фамилия И.О.', 'chequeNumber': '000000'};
  dynamic sendData = {
    'actionDate': 0,
    'cashboxId': '',
    'chequeId': 0,
    'clientAmount': 0,
    'clientId': 0,
    'saleCurrencyId': "",
    'itemsList': [],
    'note': "",
    'offline': false,
    'posId': '',
    'shiftId': '',
    'totalAmount': 0,
    'transactionId': "",
  };

  searchCheque(id) async {
    dynamic response;
    if (id != null) {
      response = await get('/services/desktop/api/cheque-byNumber/$id/${sendData['posId']}');
    } else {
      response = await get('/services/desktop/api/cheque-byNumber/$search/${sendData['posId']}');
    }
    if (response['id'] != null) {
      setState(() {
        data = response;
        itemsList = data['itemsList'];
      });
      final list = itemsList;
      for (var i = 0; i < list.length; i++) {
        list[i]['validate'] = false;
        print(list[i]['discount'].runtimeType);
        list[i]['discount'] = list[i]['discount'].round();
        print(list[i]['uomId']);
        if (list[i]['uomId'] == 1) {
          list[i]['uomId'].round();
        }
      }
      setState(() {
        itemsList = list;
      });
    }
  }

  addToReturnList(item, index) {
    if (item['returned'] == 1) {
      item['initialQuantity'] = item['quantity'];
      item['oldQuantity'] = item['quantity'] - item['returnedQuantity'];
      item['quantity'] = item['quantity'] - item['returnedQuantity'];
    }

    if (item['returned'] == 2) {
      showDangerToast('Товар уже возвращен');
      return;
    }

    item['controller'] = TextEditingController();
    item['controller'].text = item['quantity'].round().toString();
    item['errorText'] = '';

    setState(() {
      itemsList.removeAt(index);
      sendData['itemsList'].add(item);
    });

    dynamic totalAmount = 0;
    for (var i = 0; i < sendData['itemsList'].length; i++) {
      totalAmount += (sendData['itemsList'][i]['salePrice'] - (sendData['itemsList'][i]['salePrice'] * sendData['itemsList'][i]['discount'] / 100)) *
          sendData['itemsList'][i]['quantity'];
    }

    setState(() {
      sendData['totalAmount'] = totalAmount;
    });
  }

  addToItemsList(item, index) {
    item['quantity'] = item['initialQuantity'];

    setState(() {
      sendData['itemsList'].removeAt(index);
      itemsList.add(item);
    });

    dynamic totalAmount = 0;
    for (var i = 0; i < sendData['itemsList'].length; i++) {
      totalAmount += (sendData['itemsList'][i]['salePrice'] - (sendData['itemsList'][i]['salePrice'] * sendData['itemsList'][i]['salePrice'] / 100)) *
          sendData['itemsList'][i]['quantity'];
    }

    setState(() {
      sendData['totalAmount'] = totalAmount;
    });
  }

  setQuantity(item, i, value) {
    var itemCopy = Map.from(item);

    if (value == '' || value == 0) {
      item['controller'].text = "1";
      item['controller'].selection = TextSelection.fromPosition(TextPosition(offset: item['controller'].text.length));
      return;
    }

    var dotExist = '.'.allMatches(value).length == 1 ? true : false;
    if (itemCopy['uomId'] == 1 && dotExist) {
      setState(() {
        sendData['itemsList'][i]['validate'] = true;
        sendData['itemsList'][i]['validateText'] = 'Неверное кол.';
        height = 20;
      });
      return;
    }

    if (value[value.length - 1] != '.') {
      if (double.parse(value).round() > (itemCopy['quantity'].round())) {
        setState(() {
          sendData['itemsList'][i]['validate'] = true;
          sendData['itemsList'][i]['validateText'] = 'Не больше ${itemCopy['quantity'].round()}';
          height = 20;
        });
        return;
      }
    }

    setState(() {
      sendData['itemsList'][i]['quantity'] = int.parse(value);
      sendData['itemsList'][i]['totalPrice'] =
          (sendData['itemsList'][i]['salePrice'] - (sendData['itemsList'][i]['salePrice'] * sendData['itemsList'][i]['discount'] / 100)) *
              int.parse(value);
    });

    dynamic totalAmount = 0;
    for (var i = 0; i < sendData['itemsList'].length; i++) {
      totalAmount += (sendData['itemsList'][i]['salePrice'] - (sendData['itemsList'][i]['salePrice'] * sendData['itemsList'][i]['discount'] / 100)) *
          sendData['itemsList'][i]['quantity'];
    }

    setState(() {
      sendData['totalAmount'] = totalAmount;
      sendData['itemsList'][i]['validate'] = false;
      sendData['itemsList'][i]['validateText'] = '';
    });
    return;
  }

  isValid() {
    dynamic error = false;
    if (sendData['itemsList'].length == 0) {
      return false;
    }

    for (var i = 0; i < sendData['itemsList'].length; i++) {
      if (sendData['itemsList'][i]['validateText'] != "") {
        error = true;
        break;
      }
    }

    if (error) {
      return false;
    } else {
      return true;
    }
  }

  returnCheque() async {
    if (!isValid()) {
      showSuccessToast('Проверьте количество');
      return;
    }
    setState(() {
      sendData['actionDate'] = getUnixTime();
      sendData['chequeId'] = data['id'];
      sendData['clientAmount'] = data['clientAmount'];
      if (data['clientAmount'] > 0) {
        if (sendData['totalAmount'] <= data['clientAmount']) {
          sendData['totalAmount'] = sendData['totalAmount'];
        }
      }
      sendData['clientId'] = data['clientId'];
      sendData['saleCurrencyId'] = data['saleCurrencyId'];
      sendData['transactionId'] = generateTransactionId(
        cashbox['posId'],
        cashbox['cashboxId'],
        shift['id'] ?? cashbox['id'],
      );
      sendData['transactionsList'] = [
        {'amountIn': 0, 'amountOut': sendData['totalAmount'], 'paymentTypeId': 1, 'paymentPurposeId': 3}
      ];
      for (var i = 0; i < sendData['itemsList'].length; i++) {
        setState(() {
          sendData['itemsList'][i]['controller'] = null;
          sendData['itemsList'][i]['validate'] = null;
        });
      }
    });
    final response = await post('/services/desktop/api/cheque-returned', sendData);
    if (response['success']) {
      showSuccessToast('Возврат выполнен успешно');
      setInitState();
    }
  }

  setInitState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cashbox = jsonDecode(prefs.getString('cashbox')!);
      if (prefs.getString('shift') != null) {
        shift = jsonDecode(prefs.getString('shift')!);
      }
    });
    // dynamic shift = {};
    if (prefs.getString('shift') != null) {
      shift = jsonDecode(prefs.getString('shift')!);
    }
    final shiftId = cashbox['id'] ?? shift['id'];
    setState(() {
      sendData = {
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
      };
      sendData['cashboxId'] = cashbox['cashboxId'];
      sendData['posId'] = cashbox['posId'];
      sendData['shiftId'] = shiftId;
    });
  }

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cashbox = jsonDecode(prefs.getString('cashbox')!);
      if (prefs.getString('shift') != null) {
        shift = jsonDecode(prefs.getString('shift')!);
      }
    });
    // dynamic shift = {};
    if (prefs.getString('shift') != null) {
      shift = jsonDecode(prefs.getString('shift')!);
    }
    final shiftId = cashbox['id'] ?? shift['id'];
    setState(() {
      sendData['cashboxId'] = cashbox['cashboxId'];
      sendData['posId'] = cashbox['posId'];
      sendData['shiftId'] = shiftId;
    });
    if (Get.arguments != null) {
      final id = Get.arguments;
      data['id'] = id.toString();
      searchCheque(id);
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
        body: SingleChildScrollView(
          child: Container(
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
                            search = value;
                          });
                        },
                        onSubmitted: (value) {
                          if (search.length > 0) {
                            searchCheque(null);
                          }
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
                          if (search.length > 0) {
                            searchCheque(null);
                          }
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
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: b8),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Text(
                                  'Дата: ',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: b8),
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
                                  style: TextStyle(fontWeight: FontWeight.bold, color: b8),
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
                              horizontalInside: BorderSide(width: 1, color: Color(0xFFDADADa), style: BorderStyle.solid),
                            ),
                            children: [
                              TableRow(children: [
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Наименование товара',
                                    style: TextStyle(color: Color(0xFF495057), fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Цена со скидкой',
                                    style: TextStyle(color: Color(0xFF495057), fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Кол-во',
                                    style: TextStyle(color: Color(0xFF495057), fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Сумма оплаты',
                                    style: TextStyle(color: Color(0xFF495057), fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ]),
                              for (var i = 0; i < itemsList.length; i++)
                                TableRow(children: [
                                  // HERE IT IS...
                                  TableRowInkWell(
                                    onDoubleTap: () {
                                      addToReturnList(itemsList[i], i);
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
                                      addToReturnList(itemsList[i], i);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: (itemsList[i]['discount']) > 0
                                          ? Text(
                                              '${itemsList[i]['salePrice'] - (int.parse(itemsList[i]['salePrice']) / 100 * int.parse(itemsList[i]['discount']))}',
                                              style: TextStyle(color: Color(0xFF495057)),
                                              textAlign: TextAlign.center,
                                            )
                                          : Text(
                                              '${formatMoney(itemsList[i]['salePrice'])}',
                                              style: TextStyle(color: Color(0xFF495057)),
                                              textAlign: TextAlign.center,
                                            ),
                                    ),
                                  ),
                                  TableRowInkWell(
                                    onDoubleTap: () {
                                      addToReturnList(itemsList[i], i);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        '${formatMoney(itemsList[i]['quantity'])} / ${formatMoney(itemsList[i]['returnedQuantity'])}',
                                        style: TextStyle(color: Color(0xFF495057)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  TableRowInkWell(
                                    onDoubleTap: () {
                                      addToReturnList(itemsList[i], i);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        '${formatMoney(itemsList[i]['totalPrice'])}',
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
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            columnWidths: const {
                              0: FixedColumnWidth(130.0),
                              1: FlexColumnWidth(3),
                              2: FlexColumnWidth(2),
                              3: FlexColumnWidth(3),
                            },
                            border: TableBorder(
                              horizontalInside: BorderSide(width: 1, color: Color(0xFFDADADa), style: BorderStyle.solid),
                            ),
                            children: [
                              TableRow(children: [
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Наименование товара',
                                    style: TextStyle(color: Color(0xFF495057), fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Цена со скидкой',
                                    style: TextStyle(color: Color(0xFF495057), fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Кол-во возврата',
                                    style: TextStyle(color: Color(0xFF495057), fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Сумма оплаты',
                                    style: TextStyle(color: Color(0xFF495057), fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ]),
                              for (var i = 0; i < sendData['itemsList'].length; i++)
                                TableRow(children: [
                                  // HERE IT IS...
                                  Container(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: SizedBox(
                                        height: 30,
                                        width: 50,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(left: 5),
                                              child: IconButton(
                                                  onPressed: () {
                                                    addToItemsList(
                                                      sendData['itemsList'][i],
                                                      i,
                                                    );
                                                  },
                                                  padding: EdgeInsets.zero,
                                                  constraints: BoxConstraints(),
                                                  icon: Icon(
                                                    Icons.arrow_back_ios,
                                                    size: 14,
                                                  )),
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.25,
                                              child: Text(
                                                '${sendData['itemsList'][i]['productName']} ',
                                                style: TextStyle(color: Color(0xFF495057)),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),

                                  Container(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: (sendData['itemsList'][i]['discount']) > 0
                                        ? Container(
                                            height: 30,
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${sendData['itemsList'][i]['salePrice'] - (int.parse(itemsList[i]['salePrice']) / 100 * int.parse(itemsList[i]['discount']))}',
                                              style: TextStyle(color: Color(0xFF495057)),
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        : Container(
                                            height: 30,
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${formatMoney(sendData['itemsList'][i]['salePrice'])}',
                                              style: TextStyle(color: Color(0xFF495057)),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                  ),
                                  Container(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: SizedBox(
                                          child: Column(
                                        children: [
                                          SizedBox(
                                            height: 30,
                                            child: TextFormField(
                                              textAlign: TextAlign.center,
                                              controller: sendData['itemsList'][i]['controller'],
                                              onChanged: (value) {
                                                setQuantity(sendData['itemsList'][i], i, value);
                                              },
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.2))),
                                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.2))),
                                                errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.2))),
                                                contentPadding: EdgeInsets.only(
                                                  top: 5,
                                                ),
                                                // errorText: sendData['itemsList'][i]['validate'] ? '${sendData['itemsList'][i]['validateText']}' : null,
                                                // errorStyle: TextStyle(fontSize: 10)
                                              ),
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          sendData['itemsList'][i]['validateText'] != null
                                              ? Text(
                                                  '${sendData['itemsList'][i]['validateText'] ?? ''}',
                                                  overflow: TextOverflow.fade,
                                                  maxLines: 1,
                                                  style: TextStyle(fontSize: 8, color: Color(0xFFf46a6a)),
                                                )
                                              : Container()
                                        ],
                                      ))),
                                  Container(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Container(
                                        height: 30,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '${formatMoney(sendData['itemsList'][i]['totalPrice'])}',
                                          style: TextStyle(color: Color(0xFF495057)),
                                          textAlign: TextAlign.end,
                                        ),
                                      )),
                                ]),
                            ],
                          )
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        // resizeToAvoidBottomPadding: false,
        resizeToAvoidBottomInset: false,
        floatingActionButton: Container(
          margin: EdgeInsets.only(left: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'К ВЫПЛАТЕ:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formatMoney(sendData['totalAmount'])}',
                          style: TextStyle(color: blue, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'сум',
                          style: TextStyle(color: blue, fontWeight: FontWeight.w500, fontSize: 18),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                    onPressed: () {
                      returnCheque();
                    },
                    style: ElevatedButton.styleFrom(
                        primary: sendData['itemsList'].length > 0 ? Color(0xFFf46a6a) : Color(0xFFf46a6a).withOpacity(0.65),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12)),
                    child: Text(
                      'Осуществить возврат',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    )),
              )
            ],
          ),
        ));
  }

  // showConfirmModal() {
  //   return showDialog(
  //     context: context,
  //     builder: (BuildContext context) => AlertDialog(
  //       title: const Text('Вы уверены?'),
  //       // content: const Text('AlertDialog description'),
  //       actions: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             SizedBox(
  //               width: MediaQuery.of(context).size.width * 0.33,
  //               child: ElevatedButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 style: ElevatedButton.styleFrom(
  //                     primary: red,
  //                     padding: EdgeInsets.symmetric(vertical: 10)),
  //                 child: const Text('Отмена'),
  //               ),
  //             ),
  //             SizedBox(
  //               width: MediaQuery.of(context).size.width * 0.33,
  //               child: ElevatedButton(
  //                 onPressed: () {
  //                   returnCheque();
  //                   Navigator.pop(context);
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                     padding: EdgeInsets.symmetric(vertical: 10)),
  //                 child: const Text('Продолжить'),
  //               ),
  //             )
  //           ],
  //         )
  //       ],
  //     ),
  //   );
  // }
}
