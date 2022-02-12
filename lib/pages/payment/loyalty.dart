import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kassa/helpers/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kassa/helpers/globals.dart';

class Loyalty extends StatefulWidget {
  const Loyalty({Key? key, this.setPayload, this.data, this.setData})
      : super(key: key);
  final dynamic data;
  final Function? setPayload;
  final Function? setData;

  @override
  _LoyaltyState createState() => _LoyaltyState();
}

class _LoyaltyState extends State<Loyalty> {
  Timer? _debounce;
  dynamic data = {};
  dynamic textController1 = TextEditingController();
  dynamic textController2 = TextEditingController();
  dynamic textController3 = TextEditingController();
  dynamic textController4 = TextEditingController();
  dynamic textController5 = TextEditingController();
  dynamic textController6 = TextEditingController();
  dynamic cashbox = {};
  dynamic list = [
    {
      'label': 'Введите QR код или Номер телефона',
      'icon': Icons.person_pin_rounded,
      'fieldName': 'search',
      'enabled': true
    },
    {
      'label': 'Клиент',
      'icon': Icons.person,
      'fieldName': '',
      'enabled': false
    },
    {
      'label': 'Накопленные баллы',
      'icon': Icons.add,
      'fieldName': '',
      'enabled': false
    },
    {
      'label': 'Баллы к списанию',
      'icon': Icons.remove,
      'fieldName': '',
      'enabled': true
    },
    {
      'label': 'Сумма наличные',
      'icon': Icons.payments,
      'fieldName': '',
      'enabled': true
    },
    {
      'label': 'Сумма терминал',
      'icon': Icons.payment,
      'fieldName': '',
      'enabled': true
    },
    {
      'label': 'Баллы к начислению',
      'icon': Icons.payments,
      'fieldName': '',
      'enabled': false
    },
  ];
  dynamic search = '';

  searchUserBalance() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (search.length == 6 || search.length == 12) {
        //print(cashbox);
        var sendData = {'clientCode': search, 'key': cashbox['loyaltyApi']};
        final response =
            await lPost('/services/gocashapi/api/get-user-balance', sendData);
        print(response);
        if (response != null && response['reason'] == "SUCCESS") {
          setState(() {
            textController1.text =
                '${response['firstName'] + ' ' + response['lastName'] + '[' + response['status'] + ' ' + response['award'].round().toString() + '%]'}';
            textController2.text = response['balance'].round().toString();
            widget.setPayload!('loyaltyClientName',
                response['firstName'] + response['lastName']);
            widget.setPayload!('clientCode', search);
            data['award'] = response['award'].round();
            // data['amount'] = response['amount'].round();
          });
        } else {
          showDangerToast('Не найден пользователь');
        }
      }
    });
  }

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    cashbox = jsonDecode(prefs.getString('cashbox')!);
    print(cashbox);
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      data = widget.data!;
    });
    getData();
    // textController1.text = "1";
    // textController2.text = "2";
    // textController3.text = "3";
    // textController4.text = "4";
    // textController5.text = "5";
    // textController6.text = "6";
  }

  calculateAward(value, type) {
    if (value == "") {
      value = "0";
    }
    if (type == 'points') {
      textController4.text = (data['totalPrice'] - int.parse(value)).toString();
    }
    if (type == 'cash') {
      setState(() {
        data['amountIn'] = value;
      });
      widget.setData!(textController3.text, textController4.text);
    }
    if (type == 'terminal') {
      // widget.setData!(textController3.text, textController4.text,
      //     payload: textController5.text);
    }
    dynamic totalPrice = 0;
    if (textController3.text != "") {
      totalPrice += int.parse(textController3.text);
    }
    if (textController4.text != "") {
      totalPrice += int.parse(textController4.text);
    }
    if (textController5.text != "") {
      totalPrice += int.parse(textController5.text);
    }
    textController6.text =
        ((data['totalPrice'] - totalPrice) * (data['award'] / 100))
            .toStringAsFixed(2);
  }

  buildTextField(label, icon, item, index, {scrollPadding, enabled}) {
    //print(index);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width,
          child: TextFormField(
            controller: index == 1
                ? textController1
                : index == 2
                    ? textController2
                    : index == 3
                        ? textController3
                        : index == 4
                            ? textController4
                            : index == 5
                                ? textController5
                                : index == 6
                                    ? textController6
                                    : null,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Обязательное поле';
              }
            },
            onChanged: (value) {
              if (index == 0) {
                setState(() {
                  search = value;
                });
                searchUserBalance();
              }
              if (index == 3) {
                if (value != "" &&
                    double.parse(value) > double.parse(textController2.text)) {
                  textController3.text = textController3.text
                      .substring(0, textController3.text.length - 1);
                  textController3.selection = TextSelection.fromPosition(
                      TextPosition(offset: textController3.text.length));
                  return;
                }
                calculateAward(value, 'points');
                // if (value.isNotEmpty) {
                //   setState(() {
                //     (data['totalPrice'] - int.parse(value)).toString();
                //     widget.setPayload!('loyaltyClientAmount', value);
                //     if (data['award'] != null) {
                //       textController5.text =
                //           ((data['totalPrice'] - int.parse(value)) *
                //                   (data['award'] / 100))
                //               .round()
                //               .toString();
                //     }
                //     widget.setPayload!('loyaltyBonus', textController5.text);
                //   });
                //   widget.setData!(
                //     textController3.text,
                //     value,
                //   );
                // } else {
                //   textController3.text = (data['totalPrice']).toString();
                //   widget.setPayload!('loyaltyClientAmount', 0);
                //   if (data['award'] != null) {
                //     textController5.text =
                //         ((data['totalPrice']) * (data['award'] / 100))
                //             .round()
                //             .toString();
                //   }
                //   widget.setPayload!('loyaltyBonus', textController5.text);
                // }
              }
              if (index == 4) {
                if (value != "" && double.parse(value) > data['totalPrice']) {
                  textController4.text = textController4.text
                      .substring(0, textController4.text.length - 1);
                  textController4.selection = TextSelection.fromPosition(
                      TextPosition(offset: textController4.text.length));
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
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: blue,
                  width: 2,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: blue,
                  width: 2,
                ),
              ),
              suffixIcon: Icon(icon),
              filled: true,
              fillColor: borderColor,
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
            child: Text('К ОПЛАТЕ',
                style: TextStyle(
                    color: darkGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          Container(
              margin: EdgeInsets.only(bottom: 10),
              child: Text('${data['totalPrice']} сум',
                  style: TextStyle(
                      color: darkGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold))),
          for (var i = 0; i < list.length; i++)
            buildTextField(list[i]['label'], list[i]['icon'], list[i], i)
        ],
      ),
    );
  }
}
