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
  dynamic data = Get.arguments;
  dynamic cashController = TextEditingController();
  dynamic terminalController = TextEditingController();
  dynamic loyaltyController = TextEditingController();
  dynamic cashbox = {};

  setData(payload, payload2) {
    setState(() {
      cashController.text = payload;
      terminalController.text = payload2;
    });
  }

  setLoyaltyData(payload) {
    setState(() {
      data['loyaltyClientAmount'] = payload['points'];
      cashController.text = payload['cash'];
      terminalController.text = payload['terminal'];
      loyaltyController.text = payload['points'];
      data['loyaltyBonus'] = payload['loyaltyBonus'];
      data['paid'] = payload['paid'];
    });
  }

  setPayload(key, payload) {
    setState(() {
      data[key] = payload;
    });
  }

  createCheque() async {
    dynamic dataCopy = data;
    dataCopy['transactionsList'] = [];

    if (currentIndex == 2) {
      dataCopy['clientId'] = 0;
      dataCopy['clientAmount'] = 0;
      dataCopy['clientComment'] = "";
    }

    if (currentIndex == 1) {
      dataCopy.remove('loyaltyBonus');
      dataCopy.remove('loyaltyClientAmount');
      dataCopy.remove('loyaltyClientName');
    }

    if (cashController.text.length > 0) {
      dataCopy['transactionsList'].add({
        'amountIn': cashController.text,
        'amountOut': 0,
        'paymentPurposeId': 1,
        'paymentTypeId': 1,
      });
    }

    if (terminalController.text.length > 0) {
      dataCopy['transactionsList'].add({
        'amountIn': terminalController.text,
        'amountOut': 0,
        'paymentPurposeId': 1,
        'paymentTypeId': 2,
      });
    }

    if (dataCopy['change'] > 0 && dataCopy['paid'] != dataCopy['change']) {
      dataCopy['transactionsList'].add({
        'amountIn': 0,
        'amountOut': dataCopy['change'],
        'paymentPurposeId': 2,
        'paymentTypeId': 1,
      });
    }

    if (dataCopy['clientId'] != 0) {
      dataCopy['change'] = 0;
    }

    if (dataCopy['discount'] > 0) {
      dataCopy['totalPrice'] = dataCopy['totalPriceBeforeDiscount'];
    }

    if (currentIndex == 1) {
      if (cashController.text.length > 0) {
        if (terminalController.text.length > 0) {
          setState(() {
            dataCopy['paid'] = double.parse(cashController.text) + double.parse(terminalController.text);
            dataCopy['clientAmount'] = dataCopy['totalPrice'] - (double.parse(cashController.text) + double.parse(terminalController.text));
          });
        } else {
          dataCopy['clientAmount'] = dataCopy['totalPrice'] - double.parse(cashController.text);
          dataCopy['paid'] = double.parse(cashController.text);
        }
      } else {
        dataCopy['clientAmount'] = dataCopy['totalPrice'];
        dataCopy['paid'] = 0;
      }
    }

    if (currentIndex == 2) {
      if (loyaltyController.text.length > 0) {
        dataCopy['transactionsList'].add({
          'amountIn': loyaltyController.text,
          'amountOut': 0,
          'paymentPurposeId': 9,
          'paymentTypeId': 4,
        });
      }
    }
    //print(dataCopy);
    //return;
    final response = await post('/services/desktop/api/cheque', dataCopy);

    if (currentIndex == 2) {
      var sendData = {
        "cashierName": dataCopy['loyaltyClientName'],
        "chequeDate": getUnixTime().toString().substring(0, 10),
        "chequeId": response['id'],
        "clientCode": dataCopy['clientCode'],
        "key": cashbox['loyaltyApi'],
        "products": [],
        "totalAmount": dataCopy['totalPrice'],
        "writeOff": dataCopy['loyaltyBonus'] ?? 0
      };
      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        sendData['products'].add({
          "amount": dataCopy['itemsList'][i]['salePrice'],
          "barcode": dataCopy['itemsList'][i]['barcode'],
          "name": dataCopy['itemsList'][i]['productName'],
          "quantity": dataCopy['itemsList'][i]['quantity'],
          "unit": dataCopy['itemsList'][i]['uomId'],
        });
      }
      await lPost('/services/gocashapi/api/create-cheque', sendData);
    }

    if (response['success']) {
      controller.hideLoading();
      setState(() {});
      Get.offAllNamed('/');
    }
  }

  setInitState() {
    setState(() {
      data['change'] = 0;
      data['text'] = data['totalPrice'].toString();
    });
    cashController.text = '';
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
    final transactionId = generateTransactionId(cashbox['posId'].toString(), cashbox['cashboxId'].toString(),
        prefs.getString('shift') != null ? jsonDecode(prefs.getString('shift')!)['id'] : cashbox['cashboxId'].toString());
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

      cashController.text = data['text'];
    });
  }

  isDisabled() {
    if (currentIndex == 0) {
      return data['change'] < 0 ? lightGrey : blue;
    }

    if (currentIndex == 1) {
      return data['clientId'] == 0 ? lightGrey : blue;
    }

    if (currentIndex == 2) {
      if (data['loyaltyClientName'] != null &&
          data['loyaltyClientAmount'] != null &&
          data['loyaltyBonus'] != null &&
          (data['totalPrice'] == data['paid'])) {
        return blue;
      } else {
        return lightGrey;
      }
    }
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
                labelStyle: TextStyle(fontSize: 14.0, color: black, fontWeight: FontWeight.w500),
                unselectedLabelStyle: TextStyle(fontSize: 14.0, color: Color(0xFF9B9B9B)),
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
                ? Payment(setPayload: setPayload, data: data, setData: setData)
                : currentIndex == 1
                    ? OnCredit(setPayload: setPayload, data: data, setData: setData)
                    : Loyalty(setPayload: setPayload, data: data, setLoyaltyData: setLoyaltyData),
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
              if (currentIndex == 1 && data['change'] < 0 && data['clientId'] != 0) {
                createCheque();
              }
              if (currentIndex == 2 && (isDisabled() == blue)) {
                createCheque();
              }
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: isDisabled(),
            ),
            child: Text('ПРИНЯТЬ'),
          ),
        ),
      ),
    );
  }
}
