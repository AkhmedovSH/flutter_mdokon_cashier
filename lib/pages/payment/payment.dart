import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:kassa/helpers/globals.dart';


class Payment extends StatefulWidget {
  const Payment({Key? key, this.getPayload, this.data, this.setData})
      : super(key: key);
  final Function? getPayload;
  final Function? setData;
  final dynamic data;

  @override
  _PaymentState createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  int currentIndex = 0;
  final _formKey = GlobalKey<FormState>();
  final textController = TextEditingController();
  final textController2 = TextEditingController();
  dynamic products = Get.arguments;
  dynamic sendData = {};
  dynamic data = {};

  @override
  void initState() {
    super.initState();
    setState(() {
      data = widget.data;
      textController.text = data['text'];
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
          Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      margin: EdgeInsets.only(bottom: 5),
                      child: Text('Наличные',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: grey))),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: textController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Обязательное поле';
                        }
                      },
                      onChanged: (value) {
                        // textController.text = value;
                        if (value.length > 0) {
                          if (textController2.text.length > 0) {
                            setState(() {
                              data['change'] = (int.parse(textController.text) +
                                      int.parse(textController2.text)) -
                                  (data['totalPrice']);
                              widget.setData!(textController.text, textController2.text);
                            });
                          } else {
                            setState(() {
                              data['change'] =
                                  (int.parse(textController.text)) -
                                      (data['totalPrice']);
                              widget.setData!(textController.text, textController2.text);
                            });
                          }
                        } else {
                          setState(() {
                            data['change'] = 0 - (data['totalPrice']);
                            widget.setData!(textController.text, textController2.text);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.fromLTRB(10, 15, 10, 10),
                        suffixIcon: Icon(
                          Icons.payments_outlined,
                          size: 30,
                          color: Color(0xFF7b8190),
                        ),
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
                        filled: true,
                        fillColor: borderColor,
                        focusColor: blue,
                        hintText: '0.00 сум',
                        hintStyle: TextStyle(color: a2),
                      ),
                    ),
                  ),
                  Container(
                      margin: EdgeInsets.only(bottom: 5),
                      child: Text('Банковская карточка',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: grey))),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: textController2,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Обязательное поле';
                        }
                      },
                      onChanged: (value) {
                        if (value.length > 0) {
                          if (textController.text.length > 0) {
                            setState(() {
                              data['change'] = (int.parse(textController.text) +
                                      int.parse(textController2.text)) -
                                  (data['totalPrice']);
                              widget.setData!(textController.text, textController2.text);
                            });
                          } else {
                            setState(() {
                              data['change'] =
                                  (int.parse(textController2.text)) -
                                      (data['totalPrice']);
                              widget.setData!(textController.text, textController2.text);
                            });
                          }
                        } else {
                          setState(() {
                            data['change'] = 0 - (data['totalPrice']);
                            widget.setData!(textController.text, textController2.text);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.fromLTRB(10, 15, 10, 10),
                        suffixIcon: Icon(
                          Icons.payment_outlined,
                          size: 30,
                          color: Color(0xFF7b8190),
                        ),
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
                        filled: true,
                        fillColor: borderColor,
                        hintText: '0.00 сум',
                        hintStyle: TextStyle(color: a2),
                      ),
                    ),
                  ),
                ],
              )),
          Text('СДАЧА:',
              style: TextStyle(
                  color: darkGrey, fontSize: 16, fontWeight: FontWeight.bold)),
          Container(
              margin: EdgeInsets.only(bottom: 10, top: 5),
              child: Text('${data['change']} сум',
                  style: TextStyle(
                      color: darkGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
