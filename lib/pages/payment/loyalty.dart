import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/globals.dart';

class Loyalty extends StatefulWidget {
  const Loyalty({Key? key, this.getPayload, this.data}) : super(key: key);
  final dynamic data;
  final Function? getPayload;

  @override
  _LoyaltyState createState() => _LoyaltyState();
}

class _LoyaltyState extends State<Loyalty> {
  dynamic data = {};
  dynamic list = [
    {
      'label': 'Введите QR код или Номер телефона',
      'icon': Icons.person_pin_rounded,
      'fieldName': ''
    },
    {
      'label': 'Клиент',
      'icon': Icons.person,
      'fieldName': ''
    },
    {
      'label': 'Накопленные баллы',
      'icon': Icons.add,
      'fieldName': ''
    },
    {
      'label': 'Баллы к списанию',
      'icon': Icons.remove,
      'fieldName': ''
    },
    {
      'label': 'Сумма наличные',
      'icon': Icons.payments,
      'fieldName': ''
    },
    {
      'label': 'Сумма терминал',
      'icon': Icons.payment,
      'fieldName': ''
    },
    {
      'label': 'Баллы к начислению',
      'icon': Icons.payments,
      'fieldName': ''
    },
  ];

  @override
  void initState() {
    super.initState();
    setState(() {
      data = widget.data!;
    });
  }

  buildTextField(label, icon, fieldName, {scrollPadding}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label',
          style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width,
          child: TextFormField(
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Обязательное поле';
              }
            },
            onChanged: (value) {
            },
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
                      buildTextField(list[i]['label'], list[i]['icon'], list[i]['fieldName'])
        ],
      ),
    );
  }
}
