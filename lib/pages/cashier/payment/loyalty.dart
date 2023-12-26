import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';
import 'package:unicons/unicons.dart';

class Loyalty extends StatefulWidget {
  const Loyalty({Key? key, this.setPayload, this.data, this.setLoyaltyData}) : super(key: key);
  final dynamic data;
  final Function? setPayload;
  final Function? setLoyaltyData;

  @override
  _LoyaltyState createState() => _LoyaltyState();
}

class _LoyaltyState extends State<Loyalty> {
  GetStorage storage = GetStorage();

  Timer? _debounce;
  dynamic data = {};
  dynamic clientInfoController = TextEditingController();
  dynamic clientBalanceController = TextEditingController();
  dynamic pointsController = TextEditingController();
  dynamic cashController = TextEditingController();
  dynamic terminalController = TextEditingController();
  dynamic awardController = TextEditingController();
  dynamic cashbox = {};
  dynamic list = [
    {'label': 'enter_QR_code_or_phone_number', 'icon': UniconsLine.chat_bubble_user, 'enabled': true},
    {'label': 'client', 'icon': UniconsLine.user, 'enabled': false},
    {'label': 'accumulated_points', 'icon': UniconsLine.money_withdraw, 'enabled': false},
    {'label': 'points_to_be_written_off', 'icon': UniconsLine.money_insert, 'enabled': true},
    {'label': 'cash_amount', 'icon': UniconsLine.money_bill, 'enabled': true},
    {'label': 'terminal_amount', 'icon': UniconsLine.credit_card, 'enabled': true},
    {'label': 'points_to_be_awarded', 'icon': UniconsLine.bill, 'enabled': false},
  ];
  dynamic search = '';

  searchUserBalance() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (search.length == 6 || search.length == 12) {
        var sendData = {'clientCode': search, 'key': cashbox['loyaltyApi']};
        final response = await lPost('/services/gocashapi/api/get-user-balance', sendData);
        print(response);
        if (response != null && response['reason'] == "SUCCESS") {
          setState(() {
            clientInfoController.text =
                '${response['firstName'] + ' ' + response['lastName'] + '[' + response['status'] + ' ' + response['award'].round().toString() + '%]'}';
            clientBalanceController.text = response['balance'].round().toString();
            widget.setPayload!('loyaltyClientName', response['firstName'] + response['lastName']);
            widget.setPayload!('clientCode', search);
            data['award'] = response['award'].round();

            awardController.text = (data['totalPrice'] * (double.parse(data['award'].toString()) / 100)).toStringAsFixed(2);
          });
        } else {
          showDangerToast('user_not_found'.tr);
        }
      }
    });
  }

  getData() async {
    cashbox = jsonDecode(storage.read('cashbox')!);
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      data = widget.data!;
    });
    getData();
    // clientInfoController.text = "1";
    // clientBalanceController.text = "2";
    // pointsController.text = "3";
    // cashController.text = "4";
    // terminalController.text = "5";
    // awardController.text = "6";
  }

  calculateAward(value, type) {
    //debugger();
    if (value == "") {
      value = "0";
    }

    if (type == 'points') {
      cashController.text = (data['totalPrice'] - double.parse(value)).toStringAsFixed(0);
    }
    if (type == 'cash') {}
    if (type == 'terminal') {}

    dynamic totalPrice = 0;
    if (pointsController.text != "") {
      totalPrice += double.parse(pointsController.text);
    }
    if (cashController.text != "") {
      totalPrice += double.parse(cashController.text);
    }
    if (terminalController.text != "") {
      totalPrice += double.parse(terminalController.text);
    }

    dynamic loyaltyAmountIn = 0;
    if (pointsController.text == "") {
      loyaltyAmountIn = "0";
    } else {
      loyaltyAmountIn = pointsController.text;
    }

    awardController.text =
        ((double.parse(data['totalPrice'].toString()) - double.parse(loyaltyAmountIn)) * (double.parse(data['award'].toString()) / 100))
            .toStringAsFixed(2);

    dynamic loyaltyData = {
      "points": pointsController.text,
      "cash": cashController.text,
      "terminal": terminalController.text,
      "loyaltyBonus": awardController.text,
      "paid": totalPrice,
    };
    widget.setLoyaltyData!(loyaltyData);
  }

  buildTextField(String label, icon, item, index, {scrollPadding, enabled}) {
    //print(index);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width,
          child: TextFormField(
            controller: index == 1
                ? clientInfoController
                : index == 2
                    ? clientBalanceController
                    : index == 3
                        ? pointsController
                        : index == 4
                            ? cashController
                            : index == 5
                                ? terminalController
                                : index == 6
                                    ? awardController
                                    : null,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'required_field'.tr;
              }
              return null;
            },
            onChanged: (value) {
              if (index == 0) {
                setState(() {
                  search = value;
                });
                searchUserBalance();
              }
              if (index == 3) {
                if (value != "" && double.parse(value) > double.parse(clientBalanceController.text)) {
                  pointsController.text = pointsController.text.substring(0, pointsController.text.length - 1);
                  pointsController.selection = TextSelection.fromPosition(TextPosition(offset: pointsController.text.length));
                  return;
                }
                calculateAward(value, 'points');
              }
              if (index == 4) {
                if (value != "" && double.parse(value) > data['totalPrice']) {
                  cashController.text = cashController.text.substring(0, cashController.text.length - 1);
                  cashController.selection = TextSelection.fromPosition(TextPosition(offset: cashController.text.length));
                  return;
                }
                calculateAward(value, 'cash');
              }
              if (index == 5) {
                calculateAward(value, 'terminal');
              }
            },
            enabled: item['enabled'],
            enableInteractiveSelection: item['enabled'],
            scrollPadding: EdgeInsets.only(bottom: 100),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: inputFocusBorder,
              errorBorder: inputErrorBorder,
              focusedErrorBorder: inputErrorBorder,
              suffixIcon: Icon(icon),
              focusColor: blue,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 20),
            child: Text(
              'TO_PAY'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 10),
            child: Text(
              '${formatMoney(data['totalPrice'])} сум',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          for (var i = 0; i < list.length; i++) buildTextField(list[i]['label'], list[i]['icon'], list[i], i)
        ],
      ),
    );
  }
}
