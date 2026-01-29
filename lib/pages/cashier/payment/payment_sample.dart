// import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mdokon/models/cashier/cashbox_model.dart';
import 'package:flutter_mdokon/models/cashier/print_model.dart';
import 'package:flutter_mdokon/models/loading_model.dart';

import 'package:get_storage/get_storage.dart';
import '/widgets/custom_app_bar.dart';

import 'package:provider/provider.dart';

import '/helpers/api.dart';
import '../../../helpers/helper.dart';

import '../../../widgets/loading_layout.dart';
import './on_credit.dart';
import './loyalty.dart';
import './payment.dart';

class PaymentSample extends StatefulWidget {
  const PaymentSample({
    Key? key,
  }) : super(key: key);

  @override
  _PaymentSampleState createState() => _PaymentSampleState();
}

class _PaymentSampleState extends State<PaymentSample> {
  GetStorage storage = GetStorage();

  @override
  Widget build(BuildContext context) {
    return LoadingLayout(
      body: Scaffold(
        appBar: CustomAppBar(
          title: 'sale',
          leading: true,
        ),
        body: Selector<CashboxModel, int>(
          selector: (context, model) => model.currentIndex,
          builder: (context, currentIndex, child) {
            return SingleChildScrollView(
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
                                  CashboxModel model = Provider.of<CashboxModel>(context, listen: false);

                                  model.setIndex(i);
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
            );
          },
        ),
        floatingActionButton: Consumer<CashboxModel>(
          builder: (context, model, child) {
            return Container(
              margin: const EdgeInsets.only(left: 32),
              width: MediaQuery.of(context).size.width,
              child: ElevatedButton(
                onPressed: model.isSubmitDisabled
                    ? () async {
                        LoadingModel loadingModel = Provider.of<LoadingModel>(context, listen: false);
                        PrinterModel printerModel = Provider.of<PrinterModel>(context, listen: false);
                        loadingModel.showLoader(num: 2);
                        var result = await model.createCheque();
                        loadingModel.hideLoader();
                        if (customIf(result)) {
                          if (customIf(storage.read('settings')['printAfterSale'])) {
                            await printerModel.printFullCheque(model.data, model.data['itemsList']);
                          }
                          if (context.mounted) Navigator.pop(context, result);
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
    CashboxModel model = Provider.of<CashboxModel>(context, listen: false);

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
          model.setDataKey('clientName', result[i]['name'].toString());
          model.setDataKey('clientId', result[i]['id']);
          model.setDataKey('clientComment', result[i]['comment']);
          setState(() {});
        }
      }
    }
  }
}
