import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/api.dart';

import 'package:unicons/unicons.dart';

class Balance extends StatefulWidget {
  const Balance({Key? key}) : super(key: key);

  @override
  State<Balance> createState() => _BalanceState();
}

class _BalanceState extends State<Balance> {
  List data = [];

  getData() async {
    final response = await get('/services/desktop/api/get-all-balance-product-list');
    if (response != null) {
      setState(() {
        data = response;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        // centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(
            UniconsLine.arrow_left,
            size: 32,
            color: context.theme.iconTheme.color,
          ),
        ),
        title: Text(
          'balance'.tr,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('name'.tr),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'barcode'.tr,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'balance'.tr,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              for (var i = 0; i < data.length; i++)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Tooltip(
                          message: '${data[i]['productName']}',
                          triggerMode: TooltipTriggerMode.tap,
                          child: Text(
                            '${data[i]['productName']}',
                            maxLines: 1,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${data[i]['barcode']}',
                          textAlign: TextAlign.end,
                          maxLines: 1,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${data[i]['balance']}',
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
