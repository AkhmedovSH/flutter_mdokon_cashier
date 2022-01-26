import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  getCheq() async {
    dynamic response =
        await get('/services/desktop/api/cheque-byId/${Get.arguments}');

    setState(() {
      cheq = response;
      itemsList = response['itemsList'];
      transactionsList = response['transactionsList'];
      cheq['discount'] = cheq['discount'];
      cheq['to_pay'] =
          cheq['totalPrice'] - (cheq['totalPrice'] * cheq['discount']) / 100;
      cheq['chequeDate'] = formatUnixTime(cheq['chequeDate']);
    });
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
                      'M Dokon',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: b8, fontSize: 16),
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Телефон: 998977655885',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: b8, fontSize: 16),
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Адресс: Glinka',
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
                ],
              ),
            ),
          ),
        ));
  }
}
