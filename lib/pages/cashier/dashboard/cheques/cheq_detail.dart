import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:kassa/widgets/custom_app_bar.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
//
import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:unicons/unicons.dart';

import '/helpers/api.dart';
import '../../../../helpers/helper.dart';
import '/helpers/cheque.dart';

class CheqDetail extends StatefulWidget {
  final int id;
  const CheqDetail({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  _CheqDetailState createState() => _CheqDetailState();
}

class _CheqDetailState extends State<CheqDetail> {
  Timer? timer;
  ScreenshotController screenshotController = ScreenshotController();
  GetStorage storage = GetStorage();

  bool bluetoothPermission = false;
  bool connected = false;

  List itemsList = [];
  List transactionsList = [];
  List availableBluetoothDevices = [];

  Map cheque = {
    "id": 0,
    "cashierName": "",
    "chequeNumber": 0,
    "chequeDate": 0,
    "saleCurrencyId": 0,
    "saleCurrencyName": "Сум",
    "totalPrice": 0,
    "discount": 0,
    "paid": 0,
    "change": 0,
    "clientId": 0,
    "clientName": "",
    "clientAmount": 0,
    "clientCurrencyId": 0,
    "clientCurrencyName": "",
    "loyaltyClientName": "",
    "loyaltyClientAmount": 0,
    "loyaltyBonus": 0,
    "transactionId": "",
    "returned": 0,
    "returnedPrice": 0,
    "itemsList": [],
    "transactionsList": []
  };
  Map cashbox = {
    "posName": "",
    "posPhone": "",
    "posAddress": "",
  };

  dynamic tips;
  dynamic device;

  Future<void> getBluetooth() async {
    final List? bluetooths = await BluetoothThermalPrinter.getBluetooths;
    if (bluetooths != null) {
      availableBluetoothDevices = bluetooths;
      var status = await BluetoothThermalPrinter.connectionStatus;
      if (status == 'true') {
        connected = true;
      } else {
        connected = false;
      }
      if (availableBluetoothDevices.isNotEmpty) {
        // openBluetoothDevices();
      } else {
        showDangerToast(context.tr('there_are_no_active_devices_bluetooth_is_disabled'));
      }
      setState(() {});
    }
  }

  // Future<void> setConnect(String mac, newSetState) async {
  //   if (timer != null) {
  //     Get.closeCurrentSnackbar();
  //     timer!.cancel();
  //   }
  //   Get.showSnackbar(
  //     GetSnackBar(
  //       messageText: Row(
  //         children: [
  //           Text(
  //             'connection'.tr,
  //             style: TextStyle(color: black),
  //           ),
  //           const SizedBox(width: 10),
  //           SizedBox(
  //             height: 16,
  //             width: 16,
  //             child: CircularProgressIndicator(
  //               color: black,
  //               strokeWidth: 2,
  //             ),
  //           ),
  //         ],
  //       ),
  //       backgroundColor: mainColor,
  //     ),
  //   );
  //   try {
  //     timer = Timer(const Duration(seconds: 5), () {
  //       if (!connected) {
  //         Get.closeAllSnackbars();
  //         showErrorToast('failed_to_connect'.tr);
  //         return;
  //       }
  //     });
  //     final String? result = await BluetoothThermalPrinter.connect(mac);
  //     Get.closeAllSnackbars();
  //     if (result == "true") {
  //       newSetState(() {
  //         connected = true;
  //       });
  //     } else {
  //       if (timer != null) {
  //         timer!.cancel();
  //       }
  //       showErrorToast('no_connection'.tr);
  //       newSetState(() {
  //         connected = false;
  //       });
  //     }
  //   } catch (e) {
  //     Get.closeAllSnackbars();
  //     print(e);
  //     showErrorToast(e);
  //   }
  // }

  getCheque() async {
    dynamic response = await get('/services/desktop/api/cheque-byId/${widget.id}');
    //print(response);
    setState(() {
      cashbox = jsonDecode(storage.read('cashbox')!);
      cheque = response;
      itemsList = response['itemsList'];
      transactionsList = response['transactionsList'];
      cheque['discount'] = cheque['discount'];
      cheque['to_pay'] = cheque['totalPrice'] - (cheque['totalPrice'] * cheque['discount']) / 100;
      cheque['chequeDate'] = formatUnixTime(cheque['chequeDate']);
    });
    //print(cheque);
  }

  getColor(status) {
    if (status == 0) {
      return null;
    } else if (status == 1) {
      return const Color(0xFFF3A919);
    } else if (status == 2) {
      return Colors.red;
    }
  }

  checkStatus() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    if (statuses[Permission.bluetooth] == PermissionStatus.permanentlyDenied || statuses[Permission.bluetooth] == PermissionStatus.denied) {
      return;
    }
    if (statuses[Permission.bluetoothConnect] == PermissionStatus.permanentlyDenied ||
        statuses[Permission.bluetoothConnect] == PermissionStatus.denied) {
      return;
    }
    if (statuses[Permission.location] == PermissionStatus.permanentlyDenied || statuses[Permission.location] == PermissionStatus.denied) {
      return;
    }
    setState(() {
      bluetoothPermission = true;
    });
  }

  @override
  void initState() {
    super.initState();
    getCheque();
    checkStatus();
  }

  @override
  dispose() {
    super.dispose();
    if (timer != null) {
      timer!.cancel();
    }
  }

  buildRow(text, text2, {fz = 16.0}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: fz),
        ),
        Text(
          '$text2',
          style: TextStyle(fontSize: fz),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '',
        leading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Center(
                  child: Image.asset(
                    'images/splash_logo.png',
                    height: 64,
                    width: 200,
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(bottom: 10),
                  child: Text(
                    context.tr('DUPLICATE'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${cashbox['posName']}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${context.tr('phone')}: ${cashbox['posPhone'] ?? ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${context.tr('address')}: ${cashbox['posAddress'] ?? ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                buildRow(context.tr('cashier'), cheque['cashierName']),
                buildRow('№ ${context.tr('cheque')}', cheque['chequeNumber']),
                buildRow(context.tr('date'), cheque['chequeDate']),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '*****************************************************************************************',
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                Table(columnWidths: const {
                  0: FlexColumnWidth(5),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(3),
                }, children: [
                  TableRow(children: [
                    Container(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        '№ ${context.tr('product')}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        context.tr('qty'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        context.tr('price'),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]),
                  for (var i = 0; i < itemsList.length; i++)
                    TableRow(children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${i + 1} ${itemsList[i]['productName']}',
                          style: TextStyle(
                            decoration: itemsList[i]['returned'] > 0 ? TextDecoration.lineThrough : null,
                            decorationColor: getColor(itemsList[i]['returned']),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          itemsList[i]['returnedQuantity'] != itemsList[i]['quantity']
                              ? Container(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '${formatMoney(itemsList[i]['quantity'])}* ${formatMoney(itemsList[i]['salePrice'])}',
                                  ),
                                )
                              : Container(),
                          itemsList[i]['returnedQuantity'] != 0
                              ? Container(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '${formatMoney(itemsList[i]['returnedQuantity'])}* ${formatMoney(itemsList[i]['salePrice'])}',
                                    style: TextStyle(
                                      decoration: itemsList[i]['returned'] > 0 ? TextDecoration.lineThrough : null,
                                      decorationColor: getColor(itemsList[i]['returned']),
                                    ),
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          itemsList[i]['returnedPrice'] != itemsList[i]['totalPrice']
                              ? Container(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '${formatMoney(itemsList[i]['totalPrice'])}',
                                    textAlign: TextAlign.end,
                                  ),
                                )
                              : Container(),
                          itemsList[i]['returnedPrice'] != 0
                              ? Container(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '${formatMoney(itemsList[i]['returnedPrice'])}',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      decoration: itemsList[i]['returned'] > 0 ? TextDecoration.lineThrough : null,
                                      decorationColor: getColor(itemsList[i]['returned']),
                                    ),
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ])
                ]),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '*****************************************************************************************',
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                buildRow(context.tr('sale_amount'), formatMoney(cheque['totalPrice'])),
                buildRow(context.tr('discount'), formatMoney((cheque['totalPrice'] * cheque['discount']) / 100)),
                buildRow(context.tr('to_pay'), formatMoney(cheque['to_pay']), fz: 20.0),
                buildRow(context.tr('paid'), formatMoney(cheque['paid'])),
                buildRow('${context.tr('VAT')} %', formatMoney(cheque['totalVatAmount']) ?? formatMoney(0)),
                cheque['saleCurrencyId'] == 1 ? buildRow('Валюта', 'Сум ') : Container(),
                cheque['saleCurrencyId'] == 2 ? buildRow('Валюта', 'USD ') : Container(),
                for (var i = 0; i < transactionsList.length; i++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${transactionsList[i]['paymentTypeName']}',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        '${formatMoney(transactionsList[i]['amountIn'])}',
                        style: TextStyle(fontSize: 16),
                      )
                    ],
                  ),
                cheque['clientAmount'] > 0 ? buildRow('Сумма долга', formatMoney(cheque['clientAmount'])) : Container(),
                cheque['clientAmount'] > 0 ? buildRow('Должник', cheque['clientName'] + ' ') : Container(),
                (cheque['clientAmount'] == 0 && cheque['clientName'] != null) ? buildRow('Клиент', cheque['clientName']) : Container(),
                (cheque['loyaltyClientName'] != null) ? buildRow('Клиент', cheque['loyaltyClientName']) : Container(),
                cheque['loyaltyBonus'] > 0 ? buildRow('mDokon Loyalty ${context.tr('bonus')}', formatMoney(cheque['loyaltyBonus'])) : Container(),
                buildRow(context.tr('change'), formatMoney(cheque['change'])),
                Container(
                    margin: EdgeInsets.only(top: 15, bottom: 10), height: 50, width: 200, child: SfBarcodeGenerator(value: '${cheque['barcode']}')),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '*****************************************************************************************',
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                Center(
                  child: Text(
                    '${context.tr('thank_you_for_your_purchase')}!',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(
                  height: 70,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  getBluetooth();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(UniconsLine.print),
                    SizedBox(width: 10),
                    Text(context.tr('PRINT')),
                  ],
                ),
              ),
            ),
            if (cheque['status'] != 2) ...[
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/cashier', extra: {'value': 2, 'id': cheque['chequeNumber']});
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: danger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(UniconsLine.backward),
                      SizedBox(width: 10),
                      Text(context.tr('RETURN')),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  // openBluetoothDevices() async {
  //   await showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.only(
  //         topLeft: Radius.circular(24),
  //         topRight: Radius.circular(24),
  //       ),
  //     ),
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(builder: (context, newSetState) {
  //         return Container(
  //           color: Colors.transparent,
  //           child: Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 16),
  //             decoration: BoxDecoration(
  //               color: context.theme.cardColor,
  //               borderRadius: const BorderRadius.only(
  //                 topLeft: Radius.circular(24),
  //                 topRight: Radius.circular(24),
  //               ),
  //             ),
  //             child: SingleChildScrollView(
  //               child: Container(
  //                 padding: const EdgeInsets.symmetric(vertical: 16),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     SizedBox(
  //                       height: 300,
  //                       child: ListView.builder(
  //                         itemCount: availableBluetoothDevices.isNotEmpty ? availableBluetoothDevices.length : 0,
  //                         itemBuilder: (context, index) {
  //                           return ListTile(
  //                             onTap: () {
  //                               String select = availableBluetoothDevices[index];
  //                               List list = select.split("#");
  //                               String mac = list[1];
  //                               setConnect(mac, newSetState);
  //                             },
  //                             title: Text('${availableBluetoothDevices[index]}'),
  //                             subtitle: Text("click_to_connect".tr),
  //                           );
  //                         },
  //                       ),
  //                     ),
  //                     const SizedBox(height: 15),
  //                     if (connected)
  //                       SizedBox(
  //                         width: Get.width,
  //                         height: 48,
  //                         child: ElevatedButton(
  //                           onPressed: () {
  //                             printCheque(cheque, itemsList);
  //                           },
  //                           child: Text(
  //                             'PRINT'.tr,
  //                             style: TextStyle(
  //                               color: white,
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     Padding(
  //                       padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         );
  //       });
  //     },
  //   );
  //   setState(() {
  //     availableBluetoothDevices = [];
  //   });
  // }
}
