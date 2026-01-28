import 'dart:convert';
import 'dart:developer';

// import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mdokon/models/cashier/cashbox_model.dart';

import 'package:get_storage/get_storage.dart';
import '/models/loading_model.dart';
import '/widgets/custom_app_bar.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '/helpers/api.dart';
import '../../../helpers/helper.dart';

import '../../../widgets/loading_layout.dart';
import './on_credit.dart';
import './loyalty.dart';
import './payment.dart';

class PaymentSample extends StatefulWidget {
  final Map data;
  const PaymentSample({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  _PaymentSampleState createState() => _PaymentSampleState();
}

class _PaymentSampleState extends State<PaymentSample> {
  GetStorage storage = GetStorage();

  int currentIndex = 0;
  bool loading = false;
  Map data = {};
  TextEditingController cashController = TextEditingController();
  TextEditingController terminalController = TextEditingController();
  TextEditingController loyaltyController = TextEditingController();
  Map cashbox = {};

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

  setInitState() {
    setState(() {
      data = widget.data;
      data['change'] = 0;
      data['text'] = data['totalPrice'].toString();
    });
    cashController.text = '';
  }

  getData() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    setState(() {
      cashbox = (storage.read('cashbox')!);
    });
    final username = storage.read('user')['username'];
    if (storage.read('shift') != null) {
      final shift = (storage.read('shift')!);
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
      storage.read('shift') != null ? (storage.read('shift')!)['id'] : cashbox['cashboxId'].toString(),
    );
    setState(() {
      data['login'] = username;
      data['cashierLogin'] = username;
      data['cashboxId'] = cashbox['cashboxId'];
      data['device'] = 'android';
      data['cashboxVersion'] = version;
      data['chequeDate'] = DateTime.now().toUtc().millisecondsSinceEpoch;
      data['currencyId'] = data['currencyId'];
      data['saleCurrencyId'] = data['currencyId'];
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
      if (data['loyaltyClientName'] != null && data['clientCode'] != null && data['loyaltyBonus'] != null && (data['totalPrice'] == data['paid'])) {
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
        appBar: CustomAppBar(
          title: 'sale',
          leading: true,
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
                      if (i != 1 || (i == 1 && checkRole('CASHBOX_DEBT')))
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
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: currentIndex == i ? blue : grey,
                                ),
                              ),
                              child: Text(
                                i == 0
                                    ? context.tr('payment')
                                    : i == 1
                                    ? context.tr('on_credit')
                                    : context.tr('loyalty'),
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
              if (currentIndex == 0) Payment(),
              if (currentIndex == 1) OnCredit(),
              if (currentIndex == 2) Loyalty(),
              SizedBox(height: 70),
            ],
          ),
        ),
        floatingActionButton: Consumer<CashboxModel>(
          builder: (context, model, child) {
            return Container(
              margin: const EdgeInsets.only(left: 32),
              width: MediaQuery.of(context).size.width,
              child: ElevatedButton(
                onPressed: model.isSubmitDisabled
                    ? () async {
                        var result = await model.createCheque();
                        if (customIf(result) && context.mounted) {
                          Navigator.pop(context, result);
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
                  context.tr('accept'),
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
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
        return StatefulBuilder(
          builder: (context, setState) {
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
                        TableRow(
                          children: [
                            Text(
                              context.tr('contact'),
                            ),
                            Text(
                              context.tr('number'),
                            ),
                            Text(
                              context.tr('comment'),
                            ),
                          ],
                        ),
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
                    ),
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
                    child: Text(context.tr('choose')),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
