import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:get_storage/get_storage.dart';

import '/widgets/custom_app_bar.dart';

import '/helpers/api.dart';
import '/helpers/helper.dart';

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
    final prefsCashbox = storage.read('cashbox');
    print(prefsCashbox);
    int cashboxId = 0;
    if (prefsCashbox['id'] != null) {
      cashboxId = prefsCashbox['id'];
      cashbox = prefsCashbox;
    } else {
      final shift = (storage.read('shift')!);
      cashboxId = shift['id'];
      cashbox = shift;
    }
    final response = await get('/services/desktop/api/shift-xreport-v2/$cashboxId');
    print(response);
    setState(() {
      report = response;
    });
  }

  @override
  void initState() {
    super.initState();
    getReport();
  }

  buildRow(String text, text2, {fz = 16.0, leftPadding = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.only(left: leftPadding ? 16 : 0),
          child: Text(
            context.tr(text),
            style: TextStyle(fontSize: fz),
          ),
        ),
        Text(
          '${text2 ?? ''}',
          style: TextStyle(fontSize: fz),
        ),
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
                style: TextStyle(
                  fontSize: fz,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                '${formatMoney(text2)}',
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: fz),
              ),
            ),
          ],
        ),
        Divider(color: Colors.black),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: context.tr('X_report'), // Добавлена локализация заголовка
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
                // Тип отчета (X или Z)
                _buildCenterText(report['isZReport'] == true ? context.tr('z_report') : context.tr('x_report')),
                _buildCenterText('${report['posName'] ?? ''}'),
                _buildCenterText('${context.tr('phone')}: ${cashbox['posPhone'] ?? ''}'),

                const SizedBox(height: 10),

                buildRow('pos', report['posName']),
                buildRow('cashier', report['cashierName']),
                buildRow('shift_ID', report['shiftId']),
                buildRow('cashbox_number', report['shiftNumber']),
                if (report['tin'] != null) buildRow('inn', report['tin']),
                buildRow('date', report['shiftOpenDate']),
                buildRow('shift_duration', report['shiftDuration']),

                _buildDivider(),

                buildRow('number_of_receipts', report['totalCountCheque']),
                buildRow('number_of_returned_receipts', report['countReturnedCheque']),
                buildRow('number_of_returned_products', report['countReturnedProducts']),

                if ((report['countDeletedCheque'] ?? 0) > 0)
                  buildRow('${context.tr('number_of_receipts')} [${context.tr('deleted')}]', report['countDeletedCheque']),

                _buildDivider(),

                if (report['salesList'] != null)
                  for (var item in report['salesList']) ...[
                    buildRow('${context.tr('sales_amount')} (${item['currencyName']})', formatMoney(item['salesAmount'])),
                    buildRow('${context.tr('discount_amount')} (${item['currencyName']})', formatMoney(item['discountAmount'])),
                    buildRow('${context.tr('return_amount')} (${item['currencyName']})', formatMoney(item['returnAmount'])),
                    const SizedBox(height: 10),
                  ],

                _buildDivider(),

                if (report['amountInList'] != null && report['amountInList'].isNotEmpty) ...[
                  _buildSectionTitle(context.tr('income')),
                  for (var item in report['amountInList'])
                    buildRow(
                      '${item['paymentTypeName']} ${item['paymentPurposeName']}',
                      '${formatMoney(item['amountIn'])} ${item['currencyName']}',
                      leftPadding: true,
                    ),
                ],

                if (report['amountOutList'] != null && report['amountOutList'].isNotEmpty) ...[
                  _buildSectionTitle(context.tr('expense')),
                  for (var item in report['amountOutList'])
                    buildRow('${item['paymentTypeName']} ${item['paymentPurposeName']}', '${formatMoney(item['amountOut'])} ${item['currencyName']}'),
                ],

                // Баланс кассы (balanceList)
                if (report['balanceList'] != null)
                  for (var item in report['balanceList']) buildRow('cashbox_balance', '${formatMoney(item['balance'])} ${item['currencyName']}'),

                _buildDivider(),

                // Итоговые данные (totalList)
                if (report['totalList'] != null)
                  for (var item in report['totalList']) ...[
                    if ((item['totalCash'] ?? 0) > 0)
                      buildRow('${context.tr('total_cash')} (${item['currencyName']})', formatMoney(item['totalCash'])),
                    if ((item['totalBank'] ?? 0) > 0)
                      buildRow('${context.tr('total_bank')} (${item['currencyName']})', formatMoney(item['totalBank'])),
                  ],

                if ((report['countRequest'] ?? 0) > 0) buildRow('number_of_x_reports', report['countRequest']),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Вспомогательные виджеты для чистоты кода
  Widget _buildCenterText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '*****************************************************************************************',
        overflow: TextOverflow.clip,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
