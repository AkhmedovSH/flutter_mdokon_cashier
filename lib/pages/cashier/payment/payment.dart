import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:kassa/helpers/helper.dart';
import 'package:unicons/unicons.dart';

class Payment extends StatefulWidget {
  const Payment({Key? key, this.setPayload, this.data, this.setData}) : super(key: key);
  final Function? setPayload;
  final Function? setData;
  final dynamic data;

  @override
  _PaymentState createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  int currentIndex = 0;
  final _formKey = GlobalKey<FormState>();
  final cashController = TextEditingController();
  final terminalController = TextEditingController();
  dynamic sendData = {};
  dynamic data = {};

  calculateChange() {
    widget.setData!(cashController.text, terminalController.text);
    dynamic change = 0;
    dynamic paid = 0;
    if (cashController.text.isNotEmpty) {
      paid += double.parse(cashController.text);
    }
    if (terminalController.text.isNotEmpty) {
      paid += double.parse(terminalController.text);
    }
    change = (paid - double.parse(data['totalPrice'].toString()));
    setState(() {
      data['change'] = change;
      data['paid'] = paid;
    });
  }

  @override
  void initState() {
    super.initState();
    data = widget.data;
    cashController.text = double.parse(data['text']).toStringAsFixed(0);
    Timer(Duration(milliseconds: 300), () {
      calculateChange();
    });
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
              context.tr('TO_PAY'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 10),
            child: Text(
              '${formatMoney(data['totalPrice'])} ${context.tr('sum')}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 8),
                    child: Text(
                      context.tr('cash'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: TextFormField(
                      controller: cashController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('required_field');
                        }
                        return null;
                      },
                      onChanged: (value) {
                        calculateChange();
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                        suffixIcon: Icon(UniconsLine.money_bill),
                        enabledBorder: inputBorder,
                        focusedBorder: inputFocusBorder,
                        errorBorder: inputErrorBorder,
                        focusedErrorBorder: inputErrorBorder,
                        hintText: '0.00 ${context.tr('sum')}',
                        hintStyle: TextStyle(color: a2),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 8),
                    child: Text(
                      context.tr('terminal'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: TextFormField(
                      controller: terminalController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('required_field');
                        }
                        return null;
                      },
                      onChanged: (value) {
                        calculateChange();
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                        suffixIcon: Icon(UniconsLine.credit_card),
                        enabledBorder: inputBorder,
                        focusedBorder: inputFocusBorder,
                        errorBorder: inputErrorBorder,
                        focusedErrorBorder: inputErrorBorder,
                        hintText: '0.00 ${'sum'.tr}',
                        hintStyle: TextStyle(color: a2),
                      ),
                    ),
                  ),
                ],
              )),
          Text(
            '${'CHANGE'.tr}:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 10, top: 5),
            child: Text(
              '${formatMoney(data['change'])} ${'sum'.tr}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
