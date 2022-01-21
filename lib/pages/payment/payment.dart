import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import './on_credit.dart';
import './loyalty.dart';

class Payment extends StatefulWidget {
  const Payment({Key? key}) : super(key: key);

  @override
  _PaymentState createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  int currentIndex = 0;

  final _formKey = GlobalKey<FormState>();
  final textController = TextEditingController();
  final textController2 = TextEditingController();
  dynamic products = Get.arguments;
  dynamic data = {
    "cashboxVersion": '',
    "login": '',
    "cashboxId": '',
    "change": 0,
    "chequeDate": 0,
    "chequeNumber": "",
    "clientAmount": 0,
    "clientComment": "",
    "clientId": 0,
    "currencyId": '',
    "currencyRate": 0,
    "discount": 0,
    "note": "",
    "offline": false,
    "outType": false,
    "paid": 0,
    "posId": '',
    "saleCurrencyId": '',
    "shiftId": 'cashbox.id ? cashbox.id : shift.id',
    "totalPriceBeforeDiscount": 0, // this is only for showing when sale v
    "totalPrice": 0,
    "transactionId": "",
    "itemsList": [],
    "transactionsList": []
  };

  createCheque() async {
    var transactionsList = data['transactionsList'];
    if (textController.text.length > 0) {
      transactionsList.add({
        'amountIn': textController.text,
        'amountOut': 0,
        'paymentPurposeId': 1,
        'paymentTypeId': 1,
      });
    }

    //print(textController2.text.length > 0);
    if (textController2.text.length > 0) {
      transactionsList.add({
        'amountIn': textController2.text,
        'amountOut': 0,
        'paymentPurposeId': 1,
        'paymentTypeId': 2,
      });
    }

    if (data['change'] > 0) {
      transactionsList.add({
        'amountIn': 0,
        'amountOut': data['change'],
        'paymentPurposeId': 2,
        'paymentTypeId': 1,
      });
    }
    setState(() {
      if (textController2.text.length > 0) {
        data['paid'] =
            int.parse(textController.text) + int.parse(textController2.text);
      } else {
        data['paid'] = int.parse(textController.text);
      }
      data['transactionsList'] = transactionsList;
      data['itemsList'] = products;
    });
    //print('${data}');
    final response = await post('/services/desktop/api/cheque', data);
    if (response['success']) {
      Get.offAllNamed('/');
    }
  }

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    final cashbox = jsonDecode(prefs.getString('cashbox')!);
    final username = prefs.getString('username');
    if (prefs.getString('shift') != null) {
      final shift = jsonDecode(prefs.getString('shift')!);
      setState(() {
        data['shiftId'] = shift['id'];
      });
    } else {
      setState(() {
        data['shiftId'] = cashbox['id'];
      });
    }
    final transactionId = generateTransactionId(
        cashbox['posId'].toString(),
        cashbox['cashboxId'].toString(),
        prefs.getString('shift') != null
            ? jsonDecode(prefs.getString('shift')!)['id']
            : cashbox['cashboxId'].toString());
    setState(() {
      data['login'] = username;
      data['cashierLogin'] = username;
      data['cashboxId'] = cashbox['cashboxId'];
      data['cashboxVersion'] = version;
      data['chequeDate'] = DateTime.now().toUtc().millisecondsSinceEpoch;
      data['currencyId'] = cashbox['defaultCurrency'];
      data['saleCurrencyId'] = cashbox['defaultCurrency'];
      data['posId'] = cashbox['posId'];
      data['chequeNumber'] = generateChequeNumber();
      data['transactionId'] = transactionId;
    });
  }

  @override
  void initState() {
    super.initState();
    dynamic totalAmount = 0;
    for (var i = 0; i < products.length; i++) {
      totalAmount += products[i]['total_amount'];
    }
    setState(() {
      data['totalPrice'] = totalAmount.round();
      data['change'] = 0;
      data['paid'] = totalAmount.round();
    });
    textController.text = data['totalPrice'].toString();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarColor: white,
        ),
        title: Text(
          'Продажа',
          style: TextStyle(color: black),
        ),
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: black,
            )),
        centerTitle: true,
        backgroundColor: white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultTabController(
            length: 3,
            child: TabBar(
              onTap: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              labelColor: black,
              indicatorColor: blue,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                  fontSize: 14.0, color: black, fontWeight: FontWeight.w500),
              unselectedLabelStyle:
                  TextStyle(fontSize: 14.0, color: Color(0xFF9B9B9B)),
              // controller: ,
              tabs: const [
                Tab(
                  text: 'Оплата',
                ),
                Tab(
                  text: 'В долг',
                ),
                Tab(
                  text: 'Лояльность',
                ),
              ],
            ),
          ),
          currentIndex == 0
              ? Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        child: Text('К ОПЛАТЕ',
                            style: TextStyle(
                                color: darkGrey,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                      Container(
                          margin: EdgeInsets.only(bottom: 10),
                          child: Text('${data['totalPrice']} сум',
                              style: TextStyle(
                                  color: darkGrey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold))),
                      Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  margin: EdgeInsets.only(bottom: 5),
                                  child: Text('Наличные',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: grey))),
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: TextFormField(
                                  controller: textController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Обязательное поле';
                                    }
                                  },
                                  onChanged: (value) {
                                    // textController.text = value;
                                    if (value.length > 0) {
                                      if (textController2.text.length > 0) {
                                        setState(() {
                                          data['change'] = (int.parse(
                                                      textController.text) +
                                                  int.parse(
                                                      textController2.text)) -
                                              (data['totalPrice']);
                                        });
                                      } else {
                                        setState(() {
                                          data['change'] =
                                              (int.parse(textController.text)) -
                                                  (data['totalPrice']);
                                        });
                                      }
                                    }
                                  },
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        10, 15, 10, 10),
                                    suffixIcon: Icon(
                                      Icons.payments_outlined,
                                      size: 30,
                                      color: Color(0xFF7b8190),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: blue,
                                        width: 2,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: blue,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: borderColor,
                                    focusColor: blue,
                                    hintText: '0.00 сум',
                                    hintStyle: TextStyle(color: a2),
                                  ),
                                ),
                              ),
                              Container(
                                  margin: EdgeInsets.only(bottom: 5),
                                  child: Text('Банковская карточка',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: grey))),
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: TextFormField(
                                  controller: textController2,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Обязательное поле';
                                    }
                                  },
                                  onChanged: (value) {
                                    if (value.length > 0) {
                                      if (textController.text.length > 0) {
                                        setState(() {
                                          data['change'] = (int.parse(
                                                      textController.text) +
                                                  int.parse(
                                                      textController2.text)) -
                                              (data['totalPrice']);
                                        });
                                      } else {
                                        setState(() {
                                          data['change'] = (int.parse(
                                                  textController2.text)) -
                                              (data['totalPrice']);
                                        });
                                      }
                                    }
                                  },
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        10, 15, 10, 10),
                                    suffixIcon: Icon(
                                      Icons.payment_outlined,
                                      size: 30,
                                      color: Color(0xFF7b8190),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: blue,
                                        width: 2,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: blue,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: borderColor,
                                    hintText: '0.00 сум',
                                    hintStyle: TextStyle(color: a2),
                                  ),
                                ),
                              ),
                            ],
                          )),
                      Text('СДАЧА:',
                          style: TextStyle(
                              color: darkGrey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Container(
                          margin: EdgeInsets.only(bottom: 10, top: 5),
                          child: Text('${data['change']} сум',
                              style: TextStyle(
                                  color: darkGrey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                )
              : currentIndex == 1
                  ? OnCredit()
                  : Loyalty(),
          Container(
            margin: EdgeInsets.only(bottom: 70),
          )
        ],
      )),
      floatingActionButton: Container(
        margin: EdgeInsets.only(left: 32),
        width: MediaQuery.of(context).size.width,
        child: ElevatedButton(
            onPressed: () {
              if (data['change'] >= 0) {
                createCheque();
              }
            },
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                primary: data['change'] < 0 ? blue.withOpacity(0.65) : blue),
            child: Text('ПРИНЯТЬ')),
      ),
    );
  }
}
