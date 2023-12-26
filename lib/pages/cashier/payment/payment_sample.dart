import 'dart:convert';

import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:unicons/unicons.dart';

import '/helpers/api.dart';
import '/helpers/cheque.dart';
import '/helpers/globals.dart';
import '/helpers/controller.dart';

import '/components/loading_layout.dart';
import './on_credit.dart';
import './loyalty.dart';
import './payment.dart';

class PaymentSample extends StatefulWidget {
  const PaymentSample({Key? key}) : super(key: key);

  @override
  _PaymentSampleState createState() => _PaymentSampleState();
}

class _PaymentSampleState extends State<PaymentSample> {
  final Controller controller = Get.put(Controller());
  GetStorage storage = GetStorage();

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
    var settings = jsonDecode(storage.read('settings'));
    if (settings['selectUserAftersale']) {
      await showSelectUserDialog();
    }
    controller.showLoading();
    setState(() {});
    dynamic dataCopy = data;
    dataCopy['transactionsList'] = [];
    for (var i = 0; i < dataCopy['itemsList'].length; i++) {
      dataCopy['itemsList'][i]['scrollKey'] = null;
    }

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

    if (settings['printAfterSale']) {
      var status = await BluetoothThermalPrinter.connectionStatus;
      if (status == 'true') {
        printCheque(dataCopy, dataCopy['itemsList']);
      } else {
        var result = await connectToPrinter();
        if (result) {
          printCheque(dataCopy, dataCopy['itemsList']);
        } else {
          showDangerToast('failed_to_connect'.tr);
        }
      }
    }

    if (response != null && response['success']) {
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
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    setState(() {
      cashbox = jsonDecode(storage.read('cashbox')!);
    });
    final username = storage.read('username');
    if (storage.read('shift') != null) {
      final shift = jsonDecode(storage.read('shift')!);
      setState(() {
        data['shiftId'] = shift['id'];
      });
    } else {
      setState(() {
        data['shiftId'] = cashbox['id'];
      });
    }
    final transactionId = generateTransactionId(cashbox['posId'].toString(), cashbox['cashboxId'].toString(),
        storage.read('shift') != null ? jsonDecode(storage.read('shift')!)['id'] : cashbox['cashboxId'].toString());
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
      return data['change'] < 0 ? false : true;
    }

    if (currentIndex == 1) {
      return data['clientId'] == 0 ? false : true;
    }

    if (currentIndex == 2) {
      if (data['loyaltyClientName'] != null &&
          data['loyaltyClientAmount'] != null &&
          data['loyaltyBonus'] != null &&
          (data['totalPrice'] == data['paid'])) {
        return true;
      } else {
        return false;
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
          title: Text(
            'sale'.tr,
          ),
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              UniconsLine.arrow_left,
              size: 32,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              currentIndex = i;
                            });
                            setInitState();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: currentIndex == i ? blue : grey,
                              ),
                            ),
                            child: Text(
                              i == 0
                                  ? 'payment'.tr
                                  : i == 1
                                      ? 'on_credit'.tr
                                      : 'loyalty'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: currentIndex == i ? blue : black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (currentIndex == 0) Payment(setPayload: setPayload, data: data, setData: setData),
              if (currentIndex == 1) OnCredit(setPayload: setPayload, data: data, setData: setData),
              if (currentIndex == 2) Loyalty(setPayload: setPayload, data: data, setLoyaltyData: setLoyaltyData),
              SizedBox(height: 70)
            ],
          ),
        ),
        floatingActionButton: Container(
          margin: const EdgeInsets.only(left: 32),
          width: MediaQuery.of(context).size.width,
          child: ElevatedButton(
            onPressed: isDisabled()
                ? () {
                    if (currentIndex == 0 && data['change'] >= 0) {
                      createCheque();
                    }
                    if (currentIndex == 1 && data['change'] < 0 && data['clientId'] != 0) {
                      createCheque();
                    }
                    if (currentIndex == 2 && (isDisabled() == mainColor)) {
                      createCheque();
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              elevation: 1,
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: mainColor,
              disabledBackgroundColor: disabledColor,
              disabledForegroundColor: black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'accept'.tr,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List clients = [];

  getClients() async {
    final response = await get('/services/desktop/api/clients-helper');
    //print(response);
    for (var i = 0; i < response.length; i++) {
      response[i]['selected'] = false;
    }
    setState(() {
      clients = response;
    });
  }

  selectDebtorClient(Function setDebtorState, index) {
    dynamic clientsCopy = clients;
    for (var i = 0; i < clientsCopy.length; i++) {
      clientsCopy[i]['selected'] = false;
    }
    clientsCopy[index]['selected'] = true;
    setDebtorState(() {
      clients = clientsCopy;
    });
  }

  showSelectUserDialog() async {
    await getClients();
    final result = await showDialog(
        context: context,
        useSafeArea: true,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(''),
              titlePadding: EdgeInsets.all(0),
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              insetPadding: EdgeInsets.all(10),
              actionsPadding: EdgeInsets.all(0),
              buttonPadding: EdgeInsets.all(0),
              scrollable: true,
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    Table(
                      border: TableBorder(
                        horizontalInside: BorderSide(width: 1, color: tableBorderColor, style: BorderStyle.solid),
                      ),
                      children: [
                        TableRow(children: [
                          Text(
                            'contact'.tr,
                          ),
                          Text(
                            'number'.tr,
                          ),
                          Text(
                            'comment'.tr,
                          ),
                        ]),
                        for (var i = 0; i < clients.length; i++)
                          TableRow(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  selectDebtorClient(setState, i);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  color: clients[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
                                  child: Text(
                                    '${clients[i]['name']}',
                                    style: TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  selectDebtorClient(setState, i);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  color: clients[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
                                  child: Text('${clients[i]['phone1']}'),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  selectDebtorClient(setState, i);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  color: clients[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
                                  child: Text("${clients[i]['comment'] ?? ''}"),
                                ),
                              ),
                            ],
                          ),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.fromLTRB(10, 0, 10, 5),
                  child: ElevatedButton(
                    onPressed: () {
                      for (var i = 0; i < clients.length; i++) {
                        if (clients[i]['selected']) {
                          Navigator.pop(context, clients);
                        }
                      }
                    },
                    child: Text('choose'.tr),
                  ),
                )
              ],
            );
          });
        });
    if (result != null) {
      for (var i = 0; i < result.length; i++) {
        if (result[i]['selected'] == true) {
          data['clientName'] = result[i]['name'].toString();
          data['clientId'] = result[i]['id'];
          data['clientComment'] = result[i]['comment'];
          setState(() {});
        }
      }
    }
  }
}
