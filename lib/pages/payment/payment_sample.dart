import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:kassa/pages/payment/payment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';
import 'package:kassa/helpers/controller.dart';

import 'package:kassa/components/loading_layout.dart';
import './on_credit.dart';
import './loyalty.dart';

class PaymentSample extends StatefulWidget {
  const PaymentSample({Key? key}) : super(key: key);

  @override
  _PaymentSampleState createState() => _PaymentSampleState();
}

class _PaymentSampleState extends State<PaymentSample> {
  final Controller controller = Get.put(Controller());
  int currentIndex = 0;
  bool loading = false;
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
  dynamic textController = TextEditingController();
  dynamic textController2 = TextEditingController();
  dynamic textController3 = TextEditingController();
  dynamic cashbox = {};

  setData(payload, payload2, {dynamic payload3}) {
    setState(() {
      textController.text = payload;
      textController2.text = payload2;
      if (payload3 != null && payload3.length > 0) {
        textController3.text = payload3;
      }
    });
  }

  setPayload(key, payload) {
    setState(() {
      data[key] = payload;
    });
  }

  createCheque() async {
    var transactionsList = [];
    if (currentIndex == 0 || currentIndex == 1) {
      setState(() {});
      if (textController.text.length > 0) {
        transactionsList.add({
          'amountIn': textController.text,
          'amountOut': 0,
          'paymentPurposeId': 1,
          'paymentTypeId': 1,
        });
      }
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

      if (textController2.text.length > 0) {
        setState(() {
          data['paid'] =
              int.parse(textController.text) + int.parse(textController2.text);
          data['change'] = (int.parse(textController.text) +
                  int.parse(textController2.text)) -
              (data['totalPrice']);
        });
      } else {
        setState(() {
          if (currentIndex == 0) {
            data['paid'] = (textController.text);
          }
        });
      }
    }
    if (currentIndex == 1) {
      if (textController.text.length > 0) {
        if (textController2.text.length > 0) {
          setState(() {
            data['change'] = (int.parse(textController.text) +
                    int.parse(textController2.text)) -
                (data['totalPrice']);
            data['paid'] = int.parse(textController.text) +
                int.parse(textController2.text);
            data['clientAmount'] = data['totalPrice'] -
                (int.parse(textController.text) +
                    int.parse(textController2.text));
          });
        } else {
          setState(() {
            data['clientAmount'] =
                data['totalPrice'] - int.parse(textController.text);
            data['paid'] = int.parse(textController.text);
          });
        }
      } else {
        setPayload('clientAmount', data['totalPrice']);
        setPayload('paid', 0);
      }
    }
    if (currentIndex == 2) {
      var list = [];
      list.add({
        'amountIn': textController.text,
        'amountOut': 0,
        'paymentPurposeId': 1,
        'paymentTypeId': 1,
      });

      if (textController3.text.length > 0) {
        list.add({
          'amountIn': textController3.text,
          'amountOut': 0,
          'paymentPurposeId': 1,
          'paymentTypeId': 1,
        });
      }

      list.add({
        'amountIn': textController2.text,
        'amountOut': 0,
        'paymentPurposeId': 9,
        'paymentTypeId': 4,
      });

      setState(() {
        data['transactionsList'] = list;
        data['itemsList'] = products;
      });

      final response = await post('/services/desktop/api/cheque', data);

      var sendData = {
        'cashierName': data['loyaltyClientName'],
        'chequeDate': getUnixTime().toString().substring(0, 10),
        'chequeId': response['id'],
        'clientCode': data['clientCode'],
        'key': cashbox['loyaltyApi'],
        'products': [],
        'totalAmount': data['totalPrice'],
        'writeOff': data['loyaltyBonus'] ?? 0
      };
      final responseLoyalty =
          await lPost('/services/gocashapi/api/create-cheque', sendData);
      if (responseLoyalty['success']) {
        Get.offAllNamed('/');
      }
      return;
    }
    //print(transactionsList);
    setState(() {
      if (currentIndex == 1) {
        data['change'] = 0;
      }
      data['transactionsList'] = transactionsList;
      data['itemsList'] = products;
    });
    print(data['itemsList']);
    // final response = await post('/services/desktop/api/cheque', data);
    // if (response['success']) {
    //   controller.hideLoading();
    //   setState(() {});
    //   Get.offAllNamed('/');
    // }
  }

  setInitState() {
    dynamic totalAmount = 0;
    for (var i = 0; i < products.length; i++) {
      if (products[i]['quantity'].runtimeType == int) {
        totalAmount += products[i]['salePrice'] * (products[i]['quantity']);
      } else {
        totalAmount +=
            products[i]['salePrice'] * int.parse(products[i]['quantity']);
      }
    }
    setState(() {
      data['totalPrice'] = totalAmount.round();
      data['change'] = 0;
      data['paid'] = totalAmount.round();
      data['text'] = data['totalPrice'].toString();
    });
    textController.text = '';
  }

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    setState(() {
      cashbox = jsonDecode(prefs.getString('cashbox')!);
    });
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

      textController.text = data['text'];
    });
  }

  @override
  void initState() {
    super.initState();
    setInitState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingLayout(
      body: Scaffold(
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
                  setInitState();
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
                    ? OnCredit(
                        getPayload: setPayload, data: data, setData: setData)
                    : Loyalty(
                        setPayload: setPayload, data: data, setData: setData),
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
                if (currentIndex == 0 && data['change'] >= 0) {
                  createCheque();
                }
                if (currentIndex == 1 &&
                    data['change'] < 0 &&
                    data['clientId'] != 0) {
                  createCheque();
                }
                if (currentIndex == 2) {
                  createCheque();
                }
              },
              style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  primary: currentIndex == 0
                      ? data['change'] < 0
                          ? lightGrey
                          : blue
                      : currentIndex == 1
                          ? data['clientId'] == 0
                              ? lightGrey
                              : blue
                          : data['loyaltyClientName'] == null &&
                                  data['loyaltyClientAmount'] == null &&
                                  data['loyaltyBonus'] == null
                              ? lightGrey
                              : blue),
              child: Text('ПРИНЯТЬ')),
        ),
      ),
    );
  }
}
