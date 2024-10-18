import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:get_storage/get_storage.dart';

import 'package:kassa/widgets/custom_app_bar.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/helper.dart';

class XReport extends StatefulWidget {
  const XReport({Key? key}) : super(key: key);

  @override
  _XReportState createState() => _XReportState();
}

class _XReportState extends State<XReport> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GetStorage storage = GetStorage();

  Map report = {};
  List reportList = [];
  Map cashbox = {};

  getReport() async {
    final prefsCashbox = jsonDecode(storage.read('cashbox')!);
    int cashboxId = 0;
    if (prefsCashbox['id'] != null) {
      cashboxId = prefsCashbox['id'];
      cashbox = prefsCashbox;
    } else {
      final shift = jsonDecode(storage.read('shift')!);
      cashboxId = shift['id'];
      cashbox = shift;
    }
    dynamic response = await get('/services/desktop/api/shift-xreport/$cashboxId');

    setState(() {
      report = response;
      reportList = report['xReportList'];
      report['shiftOpenDate'] = DateFormat('dd.MM.yyyy HH:ss').format(DateTime.parse(
        response['shiftOpenDate'],
      ));
    });
  }

  @override
  void initState() {
    super.initState();
    getReport();
  }

  buildRow(String text, text2, {fz = 16.0}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.tr(text),
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: fz),
        ),
        Text(
          '${text2 ?? ''}',
          style: TextStyle(fontSize: fz),
        )
      ],
    );
  }

  buildRow2(text, text2, {fz = 16.0}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                flex: 6,
                child: Text(
                  text,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: fz),
                )),
            Expanded(
              flex: 3,
              child: Text(
                '${formatMoney(text2)}',
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: fz),
              ),
            )
          ],
        ),
        Divider(color: Colors.black)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: CustomAppBar(
          title: 'X_report',
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
                  )),
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
                      '${report['posName']}',
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
                      '${context.tr('phone')}: ${cashbox['posPhone'] != null ? formatPhone(cashbox['posPhone']) : ''}',
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
                      textAlign: TextAlign.center,
                    ),
                  ),
                  buildRow('cashier', report['cashierName']),
                  buildRow('${context.tr('cashbox')} №', report['shiftNumber']),
                  report['tin'] != null ? buildRow('ИНН', report['tin'] ?? '') : Container(),
                  buildRow('date', report['shiftOpenDate']),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      '*****************************************************************************************',
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  for (var i = 0; i < reportList.length; i++)
                    reportList[i]['amountIn'] != 0
                        ? buildRow2(
                            '${reportList[i]['paymentTypeName']} ${reportList[i]['paymentPurposeName']} Приход (${reportList[i]['currencyName']}) ',
                            reportList[i]['amountIn'])
                        : buildRow2(
                            '${reportList[i]['paymentTypeName']} ${reportList[i]['paymentPurposeName']} Расход (${reportList[i]['currencyName']}) ',
                            reportList[i]['amountOut']),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      '*****************************************************************************************',
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  buildRow('sold_on_credit', report['debt']),
                  buildRow('discount_amount', report['discountAmount']),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      '*****************************************************************************************',
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  buildRow('cash_balance', report['cashboxTotalAmount']),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      '*****************************************************************************************',
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  buildRow('NUMBER_X_OF_REPORTS', report['countRequest']),
                  SizedBox(height: 20)
                ],
              ),
            ),
          ),
        ));
  }
}
