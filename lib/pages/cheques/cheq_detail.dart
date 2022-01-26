import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';

class CheqDetail extends StatefulWidget {
  const CheqDetail({Key? key}) : super(key: key);

  @override
  _CheqDetailState createState() => _CheqDetailState();
}

class _CheqDetailState extends State<CheqDetail> {
  dynamic cheq = {};
  dynamic itemsList = [];
  dynamic transactionsList = [];
  dynamic cashbox = {};

  getCheq() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic response =
        await get('/services/desktop/api/cheque-byId/${Get.arguments}');

    setState(() {
      cashbox = jsonDecode(prefs.getString('cashbox')!);
      cheq = response;
      itemsList = response['itemsList'];
      transactionsList = response['transactionsList'];
      cheq['discount'] = cheq['discount'];
      cheq['to_pay'] =
          cheq['totalPrice'] - (cheq['totalPrice'] * cheq['discount']) / 100;
      cheq['chequeDate'] = formatUnixTime(cheq['chequeDate']);
    });
    print(cheq);
  }

  @override
  void initState() {
    super.initState();
    getCheq();
  }

  buildRow(text, text2, {fz = 16.0}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style:
              TextStyle(fontWeight: FontWeight.w600, color: b8, fontSize: fz),
        ),
        Text(
          '$text2',
          style: TextStyle(color: b8, fontSize: fz),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: Icon(
                Icons.arrow_back,
                color: black,
              ))),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Center(
                    child: Image.asset(
                  'images/logo.jpg',
                  height: 64,
                  width: 200,
                )),
                Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'ДУБЛИКАТ',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: b8, fontSize: 18),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${cashbox['posName']}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: b8, fontSize: 16),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Телефон: ${cashbox['posPhone']}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: b8, fontSize: 16),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Адресс: ${cashbox['posAddress']}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: b8, fontSize: 16),
                  ),
                ),
                buildRow('Кассир', cheq['cashierName']),
                buildRow('№ чека', cheq['chequeNumber']),
                buildRow('Дата', cheq['chequeDate']),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '*****************************************************************************************',
                    style: TextStyle(color: b8),
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
                      child: Text('№ Товар',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: b8)),
                    ),
                    Container(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Кол-во',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: b8)),
                    ),
                    Container(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Цена',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: b8)),
                    ),
                  ]),
                  for (var i = 0; i < itemsList.length; i++)
                    TableRow(children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${i + 1} ${itemsList[i]['productName']}',
                          style: TextStyle(color: b8),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${itemsList[i]['quantity']} * ${itemsList[i]['salePrice']}',
                          style: TextStyle(color: b8),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${itemsList[i]['totalPrice']}',
                          textAlign: TextAlign.end,
                          style: TextStyle(color: b8),
                        ),
                      ),
                    ])
                ]),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '*****************************************************************************************',
                    style: TextStyle(color: b8),
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                buildRow('Сумма продажи', cheq['totalPrice']),
                buildRow('Скидка', cheq['discount']),
                buildRow('К оплате', cheq['to_pay'], fz: 20.0),
                buildRow('Оплачено', cheq['paid']),
                cheq['totalVatAmount'] != null && cheq['totalVatAmount'] > 0
                    ? buildRow('НДС %', cheq['totalVatAmount'])
                    : Container(),
                for (var i = 0; i < transactionsList.length; i++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${transactionsList[i]['paymentTypeName']}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: b8,
                            fontSize: 16),
                      ),
                      Text(
                        '${transactionsList[i]['amountIn']}',
                        style: TextStyle(color: b8, fontSize: 16),
                      )
                    ],
                  ),
                Container(
                    margin: EdgeInsets.only(top: 15, bottom: 10),
                    height: 50,
                    width: 200,
                    child: SfBarcodeGenerator(value: '${cheq['barcode']}')),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '*****************************************************************************************',
                    style: TextStyle(color: b8),
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                Center(
                  child: Text(
                    'Спасибо за покупку!',
                    style: TextStyle(color: b8, fontSize: 16),
                  ),
                ),
                SizedBox(height: 70,)
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: EdgeInsets.only(left: 32),
            width: MediaQuery.of(context).size.width * 0.43,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14)
              ),
              child: Text('ПЕЧАТЬ'),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.43,
            child: ElevatedButton(
              onPressed: () {
                Get.offAllNamed('/return', arguments: cheq['id']);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                primary: Color(0xFFf46a6a)
              ),
              child: Text('ВОЗВРАТ'),
            ),
          ),
        ],
      ),
    );
  }
}
