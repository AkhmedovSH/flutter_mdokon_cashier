import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:kassa/helpers/globals.dart';

class Calculator extends StatefulWidget {
  const Calculator({Key? key}) : super(key: key);

  @override
  _CalculatorState createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  dynamic product = Get.arguments;
  dynamic prevProduct = {};

  increment(number) {
    print(product['quantity'] == 0);
    if (product['quantity'] != 0) {
      setState(() {
        product['quantity'] = product['quantity'].toString() + number;
      });
    } else {
      setState(() {
        product['quantity'] = number;
      });
    }
  }

  _delete() {
    if (int.parse(product['quantity']) > 1) {
      String string = product['quantity'].toString();
      string = string.substring(0, string.length - 1);
      //print(string);
      setState(() {
        product['quantity'] = string;
      });
    } else {
      setState(() {
        product['quantity'] = 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      prevProduct = product;
    });
  }

  dynamic items = [
    {'id': 1, 'title': '7'},
    {'id': 1, 'title': '8'},
    {'id': 1, 'title': '9'},
    {'id': 2, 'title': 'кол-во', 'active': true},
  ];

  dynamic items2 = [
    {'id': 1, 'title': '4'},
    {'id': 1, 'title': '5'},
    {'id': 1, 'title': '6'},
    {'id': 2, 'title': 'своб.цена', 'active': false},
  ];

  dynamic items3 = [
    {'id': 1, 'title': '1'},
    {'id': 1, 'title': '2'},
    {'id': 1, 'title': '3'},
    {'id': 2, 'title': 'сумма', 'active': false},
  ];

  dynamic items4 = [
    {'id': 1, 'title': '0'},
    {'id': 1, 'title': '.'},
    {'id': 1, 'title': ''},
    {'id': 2, 'title': 'скидка', 'active': false},
  ];

  buildNumber(item) {
    return GestureDetector(
      onTap: () {
        increment(item['title']);
      },
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: Color(0xFFDADADA)),
                  bottom: BorderSide(color: Color(0xFFDADADA)))),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                border: item['title'] == '.' ||
                        item['title'] == '0' ||
                        int.parse(item['title']) % 3 != 0
                    ? const Border(right: BorderSide(color: Color(0xFFDADADA)))
                    : const Border()),
            child: Text(
              item['title'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          )),
    );
  }

  buildButton(item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      color: item['active'] ? blue : const Color(0xFFDADADA),
      child: Text(
        item['title'],
        style:
            TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: white,
              border: Border.all(color: borderColor, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  spreadRadius: -5,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
              borderRadius: const BorderRadius.all(Radius.circular(16))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 5),
                child: Text(
                  product['productName'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${product['price']} So\'m x ${product['quantity']} кг',
                    style: TextStyle(color: lightGrey),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 5),
                        child: Text(
                          '${product['total_amount']}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const Text(
                        'So\'m',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12),
                      )
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 13, bottom: 5),
                child: const Text(
                  'КОЛ-ВО ПОШТУЧНО, УПК',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              Text(
                '1 упк(30шт) + 15шт  = 1,5 упк',
                style: TextStyle(fontWeight: FontWeight.w500, color: lightGrey),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            child: Text(
              '${product['quantity']}',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w300),
            ),
          ),
        ),
        Container(
            margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 8),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
                color: blue,
                borderRadius: const BorderRadius.all(Radius.circular(20))),
            child: Text(
              'Продажа в распакованном виде',
              style: TextStyle(color: white),
              textAlign: TextAlign.center,
            )),
        Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                    flex: 2,
                    child: items[i]['id'] == 1
                        ? buildNumber(items[i])
                        : buildButton(items[i]))
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items2.length; i++)
                Expanded(
                    flex: 2,
                    child: items2[i]['id'] == 1
                        ? buildNumber(items2[i])
                        : buildButton(items2[i]))
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items3.length; i++)
                Expanded(
                    flex: 2,
                    child: items3[i]['id'] == 1
                        ? buildNumber(items3[i])
                        : buildButton(items3[i]))
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items4.length; i++)
                Expanded(
                    flex: 2,
                    child: items4[i]['id'] == 1
                        ? i == 2
                            ? GestureDetector(
                                onTap: () {
                                  _delete();
                                },
                                child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 1),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: const BoxDecoration(
                                        border: Border(
                                            top: BorderSide(
                                                color: Color(0xFFDADADA)),
                                            bottom: BorderSide(
                                                color: Color(0xFFDADADA)))),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      child: const Icon(
                                        Icons.backspace_outlined,
                                        size: 18,
                                      ),
                                    )),
                              )
                            : buildNumber(items4[i])
                        : buildButton(items4[i]))
            ],
          ),
        ]),
        Container(
          margin: const EdgeInsets.only(top: 15, bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.45,
                child: ElevatedButton(
                  onPressed: () {
                    //print(prevProduct);
                    Get.back(result: prevProduct);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: blue, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'ОТМЕНА',
                    style: TextStyle(
                      fontSize: 16,
                      color: blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.45,
                child: ElevatedButton(
                  onPressed: () {
                    //print(prevProduct);
                    Get.back(result: prevProduct);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'В ЧЕК',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    )));
  }
}
