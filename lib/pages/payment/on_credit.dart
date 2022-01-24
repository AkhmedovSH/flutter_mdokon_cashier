import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';

class OnCredit extends StatefulWidget {
  const OnCredit({Key? key, this.getPayload}) : super(key: key);
  final Function? getPayload;

  @override
  _OnCreditState createState() => _OnCreditState();
}

class _OnCreditState extends State<OnCredit> {
  dynamic clients = [];
  dynamic products = Get.arguments;
  dynamic data = {
    "cashboxVersion": '',
    "login": '',
    "cashboxId": '',
    "change": 0,
    "chequeDate": 0,
    "chequeNumber": "",
    "clientAmount": 0,
    "clientComment": "",
    "clientId": 0,
    "currencyId": '',
    "currencyRate": 0,
    "discount": 0,
    "note": "",
    "offline": false,
    "outType": false,
    "paid": 0,
    "posId": '',
    "saleCurrencyId": '',
    "shiftId": '',
    "totalPriceBeforeDiscount": 0,
    "totalPrice": 0,
    "transactionId": "",
    "itemsList": [],
    "transactionsList": []
  };
  dynamic client = {'name': 'КЛИЕНТ'};
  Timer? _debounce;
  final _formKey = GlobalKey<FormState>();
  final textController = TextEditingController();
  final textController2 = TextEditingController();
  dynamic addList = [
    {
      'name': 'Наименование контакта',
      'value': '',
      'icon': Icons.person,
    },
    {
      'name': 'Телефон',
      'value': '',
      'icon': Icons.phone,
    },
    {
      'name': 'Телефон',
      'value': '',
      'icon': Icons.phone,
    },
    {
      'name': 'Комментарий',
      'value': '',
      'icon': Icons.comment_outlined,
    },
  ];

  getClients() async {
    final response = await get('/services/desktop/api/clients-helper');
    //print(response);
    for (var i = 0; i < response.length; i++) {
      response[i]['selected'] = false;
    }
    setState(() {
      clients = response;
    });
  }

  _onSearchChanged(String text) {
    List<dynamic> _searchList = [];
    if (text.isEmpty) {
      _searchList = clients;
      setState(() {});
      return;
    }
    clients.forEach((client) {
      if (client['name'].contains(text)) {
        _searchList.add(client);
      }
    });

    // if (_debounce?.isActive ?? false) _debounce!.cancel();
    // _debounce = Timer(const Duration(milliseconds: 500), () {
    // });

    print(_searchList);
    setState(() {
      clients = _searchList;
    });
    print(clients);
  }

  @override
  void initState() {
    super.initState();
    print(Get.arguments);
    dynamic totalAmount = 0;
    for (var i = 0; i < products.length; i++) {
      totalAmount += products[i]['total_amount'];
    }
    setState(() {
      data['totalPrice'] = totalAmount.round();
      data['change'] = 0;
      data['paid'] = totalAmount.round();
    });
    textController.text = data['totalPrice'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 20, bottom: 5),
            child: Text(
              'КЛИЕНТ:',
              style: TextStyle(
                  fontSize: 16, color: darkGrey, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Обязательное поле';
                }
              },
              onChanged: (value) {},
              enabled: false,
              enableInteractiveSelection: false,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                border: UnderlineInputBorder(
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
                hintText: '${client['name']}',
                hintStyle: TextStyle(color: a2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: ElevatedButton(
                  onPressed: () async {
                    await getClients();
                    final result = await showDialog(
                        context: context,
                        useSafeArea: true,
                        builder: (BuildContext context) {
                          dynamic content = clients;
                          return StatefulBuilder(builder: (context, setState) {
                            return AlertDialog(
                              title: Text(''),
                              titlePadding: EdgeInsets.all(0),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10),
                              insetPadding: EdgeInsets.all(10),
                              actionsPadding: EdgeInsets.all(0),
                              buttonPadding: EdgeInsets.all(0),
                              scrollable: true,
                              content: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Column(
                                  children: [
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
                                          _onSearchChanged(value);
                                        },
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                  10, 15, 10, 10),
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
                                          hintText: 'Поиск по контактам',
                                          hintStyle: TextStyle(color: a2),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Table(
                                        border: TableBorder(
                                            verticalInside: BorderSide(
                                                width: 0,
                                                color: Colors.transparent),
                                            horizontalInside: BorderSide(
                                                width: 1,
                                                color: Color(0xFFDADADa),
                                                style: BorderStyle
                                                    .solid)), // Allows to add a border decoration around your table
                                        children: [
                                          TableRow(children: const [
                                            Text(
                                              'Контакт',
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              'Номер телефона',
                                              textAlign: TextAlign.center,
                                            ),
                                            Text('Комментарий'),
                                          ]),
                                          for (var i = 0;
                                              i < content.length;
                                              i++)
                                            TableRow(children: [
                                              GestureDetector(
                                                onTap: () {
                                                  dynamic arr = content;
                                                  if (arr[i]['selected']) {
                                                    arr[i]['selected'] = false;
                                                  } else {
                                                    for (var j = 0;
                                                        j < content.length;
                                                        j++) {
                                                      arr[j]['selected'] =
                                                          false;
                                                    }
                                                    arr[i]['selected'] = true;
                                                  }
                                                  setState(() {
                                                    content = arr;
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 8),
                                                  color: content[i]['selected']
                                                      ? Color(0xFF91a0e7)
                                                      : Colors.transparent,
                                                  child: Text(
                                                      '${content[i]['name']}'),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  dynamic arr = content;
                                                  arr[i]['selected'] =
                                                      !arr[i]['selected'];
                                                  setState(() {
                                                    content = arr;
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 8),
                                                  color: content[i]['selected']
                                                      ? Color(0xFF91a0e7)
                                                      : Colors.transparent,
                                                  child: Text(
                                                      '${content[i]['phone1']}'),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  dynamic arr = content;
                                                  arr[i]['selected'] =
                                                      !arr[i]['selected'];
                                                  setState(() {
                                                    content = arr;
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 8),
                                                  color: content[i]['selected']
                                                      ? Color(0xFF91a0e7)
                                                      : Colors.transparent,
                                                  child: Text(
                                                      '${content[i]['comment']}'),
                                                ),
                                              ),
                                            ]),
                                        ])
                                  ],
                                ),
                              ),
                              actions: [
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: EdgeInsets.fromLTRB(10, 0, 10, 5),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      for (var i = 0; i < content.length; i++) {
                                        if (content[i]['selected']) {
                                          Navigator.pop(context, content[i]);
                                        }
                                      }
                                    },
                                    child: Text('Выбрать'),
                                  ),
                                )
                              ],
                            );
                          });
                        });
                    print(result);
                    setState(() {
                      client = result;
                    });
                  },
                  style: ElevatedButton.styleFrom(primary: Color(0xFFf1b44c)),
                  child: Text('Выбрать'),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        useSafeArea: true,
                        builder: (BuildContext context) {
                          return StatefulBuilder(builder: (context, setState) {
                            return AlertDialog(
                              title: Text(''),
                              titlePadding: EdgeInsets.all(0),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10),
                              insetPadding: EdgeInsets.all(10),
                              actionsPadding: EdgeInsets.all(0),
                              buttonPadding: EdgeInsets.all(0),
                              scrollable: true,
                              content: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < addList.length; i++)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${addList[i]['name']}',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: b8),
                                        ),
                                        Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 10),
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: TextFormField(
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Обязательное поле';
                                              }
                                            },
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  const EdgeInsets.fromLTRB(
                                                      10, 15, 10, 10),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: blue,
                                                  width: 2,
                                                ),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: blue,
                                                  width: 2,
                                                ),
                                              ),
                                              suffixIcon: Icon(addList[i]['icon']),
                                              filled: true,
                                              fillColor: borderColor,
                                              focusColor: blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: EdgeInsets.fromLTRB(10, 0, 10, 5),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // for (var i = 0; i < content.length; i++) {
                                      //   if (content[i]['selected']) {
                                      //     Navigator.pop(context, content[i]);
                                      //   }
                                      // }
                                    },
                                    child: Text('Сохранить'),
                                  ),
                                )
                              ],
                            );
                          });
                        });
                  },
                  child: Text('Добавить'),
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 10, bottom: 5),
            child: Text(
              'ПРИМЕЧАНИЕ',
              style: TextStyle(
                  fontSize: 16, color: a2, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Обязательное поле';
                }
              },
              onChanged: (value) {},
              enableInteractiveSelection: false,
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
                filled: true,
                fillColor: borderColor,
                focusColor: blue,
                hintText: 'ПРИМЕЧАНИЕ',
                hintStyle: TextStyle(color: a2),
              ),
            ),
          ),
          Column(
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
                                  data['change'] =
                                      (int.parse(textController.text) +
                                              int.parse(textController2.text)) -
                                          (data['totalPrice']);
                                });
                              } else {
                                setState(() {
                                  data['change'] =
                                      (int.parse(textController.text)) -
                                          (data['totalPrice']);
                                });
                              }
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
                                  data['change'] =
                                      (int.parse(textController.text) +
                                              int.parse(textController2.text)) -
                                          (data['totalPrice']);
                                });
                              } else {
                                setState(() {
                                  data['change'] =
                                      (int.parse(textController2.text)) -
                                          (data['totalPrice']);
                                });
                              }
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
                      color: darkGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Container(
                  margin: EdgeInsets.only(bottom: 10, top: 5),
                  child: Text('${data['change']} сум',
                      style: TextStyle(
                          color: darkGrey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }
}

// DataTable(
//                                       showCheckboxColumn: true,
//                                       border: TableBorder(
//                                           horizontalInside: BorderSide(
//                                               width: 1,
//                                               color: Color(0xFFDADADa),
//                                               style: BorderStyle
//                                                   .solid)), // Allows to add a border decoration around your table

//                                       columns: [
//                                         DataColumn(label: Text(
//                                               'Контакт',
//                                               textAlign: TextAlign.center,
//                                             ),),
//                                         DataColumn(label: Text(
//                                               'Номер телефона',
//                                               textAlign: TextAlign.center,
//                                             ),),
//                                         DataColumn(label: Text('Комментарий')),
//                                       ],
//                                       rows: [
//                                         for (var i = 0; i < clients.length; i++)
//                                           DataRow(cells: [
//                                             DataCell(
//                                               Container(
//                                                 padding: EdgeInsets.symmetric(
//                                                     vertical: 8),
//                                                 child: Text(
//                                                     '${clients[i]['name']}'),
//                                               ),
//                                             ),
//                                             DataCell(
//                                               Container(
//                                                 padding: EdgeInsets.symmetric(
//                                                     vertical: 8),
//                                                 child: Text(
//                                                     '${clients[i]['phone1']}'),
//                                               ),
//                                             ),
//                                             DataCell(
//                                               Container(
//                                                 padding: EdgeInsets.symmetric(
//                                                     vertical: 8),
//                                                 child: Text(
//                                                     '${clients[i]['comment']}'),
//                                               ),
//                                             )
//                                           ]),
//                                       ])