import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:kassa/pages/payment/payment.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';

import 'package:package_info_plus/package_info_plus.dart';

import './on_credit.dart';
import './loyalty.dart';

class PaymentSample extends StatefulWidget {
  const PaymentSample({Key? key}) : super(key: key);

  @override
  _PaymentSampleState createState() => _PaymentSampleState();
}

class _PaymentSampleState extends State<PaymentSample> {
  int currentIndex = 0;
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
    "shiftId": '',
    "totalPriceBeforeDiscount": 0, // this is only for showing when sale v
    "totalPrice": 0,
    "transactionId": "",
    "itemsList": [],
    "transactionsList": []
  };
  dynamic products = Get.arguments;
  dynamic textController = {};
  dynamic textController2 = {};

  setData(payload, payload2) {
    setState(() {
      textController = payload;
      textController2 = payload2;
    });
    print(textController);
  }

  setPayload(key, payload) {
    setState(() {
      data[key] = payload;
    });
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
    // for (String key in data.keys) {
    //   print('$key : ${data[key]}');
    // }

    final response = await post('/services/desktop/api/cheque', data);
    if (response['success']) {
      Get.offAllNamed('/');
    }
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
      data['text'] = data['totalPrice'].toString();
    });
    // textController.text = data['totalPrice'].toString();
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
              ? Payment(getPayload: setPayload, data: data, setData: setData)
              : currentIndex == 1
                  ? OnCredit(getPayload: setPayload, data: data)
                  : Loyalty(getPayload: setPayload, data: data),
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
              if (currentIndex == 0 && data['change'] > 0) {
                createCheque();
              }
            },
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                primary: data['change'] < 0 ? blue.withOpacity(0.8) : blue),
            child: Text('ПРИНЯТЬ')),
      ),
    );
  }
}
