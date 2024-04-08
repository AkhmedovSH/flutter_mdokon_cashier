import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kassa/helpers/api.dart';

import 'package:flutter/services.dart';

import 'package:kassa/helpers/globals.dart';
import 'package:unicons/unicons.dart';

class Return extends StatefulWidget {
  const Return({Key? key}) : super(key: key);

  @override
  State<Return> createState() => _ReturnState();
}

class _ReturnState extends State<Return> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GetStorage storage = GetStorage();

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

  int focusedFieldIndex = 0;
  bool scrollMargin = false;

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
        list[i]['discount'] = list[i]['discount'].round();
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
    if (item['returned'] == 0) {
      item['initialQuantity'] = item['quantity'];
    }

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
    item['controller'].text = double.parse(item['quantity'].toString()).round().toString();
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
      item['controller'].text = "";
      item['controller'].selection = TextSelection.fromPosition(TextPosition(offset: item['controller'].text.length));
      return;
    }

    var dotExist = '.'.allMatches(value).length == 1 ? true : false;
    if (itemCopy['uomId'] == 1 && dotExist) {
      setState(() {
        sendData['itemsList'][i]['validate'] = true;
        sendData['itemsList'][i]['validateText'] = 'wrong_count'.tr;
        height = 20;
      });
      return;
    }
    if (value[value.length - 1] != '.') {
      if (double.parse(value) > double.parse(itemCopy['quantity'].toString())) {
        setState(() {
          sendData['itemsList'][i]['validate'] = true;
          sendData['itemsList'][i]['validateText'] = 'not_more'.trParams({'quantity': itemCopy['quantity'] - itemCopy['returnedQuantity']});
          height = 20;
        });
        return;
      }
    }

    setState(() {
      sendData['itemsList'][i]['changedQuantity'] = int.parse(value);
      sendData['itemsList'][i]['totalPrice'] =
          (sendData['itemsList'][i]['salePrice'] - (sendData['itemsList'][i]['salePrice'] * sendData['itemsList'][i]['discount'] / 100)) *
              int.parse(value);
    });

    dynamic totalAmount = 0;
    for (var i = 0; i < sendData['itemsList'].length; i++) {
      totalAmount += (sendData['itemsList'][i]['salePrice'] - (sendData['itemsList'][i]['salePrice'] * sendData['itemsList'][i]['discount'] / 100)) *
          int.parse(value);
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
      if (sendData['itemsList'][i]['validateText'] != "" && sendData['itemsList'][i]['validateText'] != null) {
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
      showDangerToast('check_quantity'.tr);
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
      // sendData['transactionsList'] = [
      //   {'amountIn': 0, 'amountOut': sendData['totalAmount'], 'paymentTypeId': 1, 'paymentPurposeId': 3}
      // ];
      for (var i = 0; i < sendData['itemsList'].length; i++) {
        setState(() {
          sendData['itemsList'][i]['controller'] = null;
          sendData['itemsList'][i]['validate'] = null;
          sendData['itemsList'][i]['quantity'] = sendData['itemsList'][i]['changedQuantity'] ?? sendData['itemsList'][i]['quantity'];
        });
      }
    });
    final response = await post('/services/desktop/api/cheque-returned', sendData);
    if (response['success']) {
      showSuccessToast('return_completed_successfully'.tr);
      setInitState();
    }
  }

  setInitState() async {
    setState(() {
      cashbox = jsonDecode(storage.read('cashbox')!);
      if (storage.read('shift') != null) {
        shift = jsonDecode(storage.read('shift')!);
      }
    });
    // dynamic shift = {};
    if (storage.read('shift') != null) {
      shift = jsonDecode(storage.read('shift')!);
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
    setState(() {
      cashbox = jsonDecode(storage.read('cashbox')!);
      if (storage.read('shift') != null) {
        shift = jsonDecode(storage.read('shift')!);
      }
    });
    // dynamic shift = {};
    if (storage.read('shift') != null) {
      shift = jsonDecode(storage.read('shift')!);
    }
    final shiftId = cashbox['id'] ?? shift['id'];
    setState(() {
      sendData['cashboxId'] = cashbox['cashboxId'];
      sendData['posId'] = cashbox['posId'];
      sendData['shiftId'] = shiftId;
    });
    if (Get.arguments != null) {
      final id = Get.arguments['id'];
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
          'return'.tr,
          style: TextStyle(color: white),
        ),
        centerTitle: true,
        backgroundColor: blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 10, left: 8, right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
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
                        enabledBorder: inputBorder,
                        focusedBorder: inputFocusBorder,
                        hintText: 'search'.tr,
                        filled: true,
                        fillColor: white,
                        focusColor: blue,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 10),
                      width: 60,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          if (search.length > 0) {
                            searchCheque(null);
                          } else {}
                        },
                        style: ElevatedButton.styleFrom(),
                        child: Icon(UniconsLine.search),
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 5),
                        child: Text(
                          '${'cash_receipt'.tr} №: ${data['chequeNumber']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: grey,
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text(
                              'date'.tr + ': ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: grey,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(right: 20),
                              child: Text(
                                '${data['chequeDate'] != null ? formatUnixTime(data['chequeDate']) : '00.00.0000 - 00:00'}',
                              ),
                            ),
                            Text(
                              '${'cashier'.tr}: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: grey,
                              ),
                            ),
                            Text(
                              '${data['cashierName']}',
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
                            color: tableBorderColor,
                            style: BorderStyle.solid,
                          ),
                        ),
                        children: [
                          TableRow(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'name'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'price'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'qty'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'payment_amount'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                          for (var i = 0; i < itemsList.length; i++)
                            TableRow(
                              children: [
                                TableRowInkWell(
                                  onDoubleTap: () {
                                    addToReturnList(itemsList[i], i);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      '${itemsList[i]['productName']} ',
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
                                            textAlign: TextAlign.center,
                                          )
                                        : Text(
                                            '${formatMoney(itemsList[i]['salePrice'])}',
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
                                      '${formatMoney(itemsList[i]['quantity'])} ${itemsList[i]['returnedQuantity'] > 0 ? formatMoney(itemsList[i]['returnedQuantity']) : ''}',
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
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: tableBorderColor, width: 1),
                    top: BorderSide(color: tableBorderColor, width: 1),
                  ),
                ),
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
                          horizontalInside: BorderSide(width: 1, color: tableBorderColor, style: BorderStyle.solid),
                        ),
                        children: [
                          TableRow(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'name'.tr,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'price'.tr,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'return_quantity'.tr,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'payment_amount'.tr,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                          for (var i = 0; i < sendData['itemsList'].length; i++)
                            TableRow(
                              children: [
                                Container(
                                  margin: MediaQuery.of(context).viewInsets.bottom > 0 && i == sendData['itemsList'].length - 1
                                      ? EdgeInsets.only(bottom: 100)
                                      : EdgeInsets.zero,
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: SizedBox(
                                    height: 30,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(left: 5),
                                          child: IconButton(
                                            onPressed: () {
                                              addToItemsList(sendData['itemsList'][i], i);
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                            tooltip: 'return_to_list'.tr,
                                            icon: Icon(
                                              UniconsLine.angle_left_b,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            '${sendData['itemsList'][i]['productName']} ',
                                            style: TextStyle(color: Color(0xFF495057)),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: MediaQuery.of(context).viewInsets.bottom > 0 && i == sendData['itemsList'].length - 1
                                      ? EdgeInsets.only(bottom: 100)
                                      : EdgeInsets.zero,
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
                                  margin: MediaQuery.of(context).viewInsets.bottom > 0 && i == sendData['itemsList'].length - 1
                                      ? EdgeInsets.only(bottom: 100)
                                      : EdgeInsets.zero,
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
                                            scrollPadding: EdgeInsets.only(bottom: 100),
                                            decoration: InputDecoration(
                                              enabledBorder: inputBorder,
                                              focusedBorder: inputFocusBorder,
                                              errorBorder: inputErrorBorder,
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
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: danger,
                                                ),
                                              )
                                            : Container()
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: MediaQuery.of(context).viewInsets.bottom > 0 && i == sendData['itemsList'].length - 1
                                      ? EdgeInsets.only(bottom: 100)
                                      : EdgeInsets.zero,
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Container(
                                    height: 30,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${formatMoney(sendData['itemsList'][i]['totalPrice'])}',
                                      style: TextStyle(color: Color(0xFF495057)),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'TO_PAYOFF'.tr}:',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatMoney(sendData['totalAmount'])}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'sum'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    )
                  ],
                ),
              ],
            ),
            SizedBox(height: 5),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: ElevatedButton(
                onPressed: sendData['itemsList'].length > 0
                    ? () {
                        returnCheque();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: danger,
                  disabledBackgroundColor: danger.withOpacity(0.65),
                  disabledForegroundColor: white,
                ),
                child: Text(
                  'make_return'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
