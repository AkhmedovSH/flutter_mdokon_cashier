import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';

class OnCredit extends StatefulWidget {
  const OnCredit({Key? key, this.setPayload, this.data, this.setData}) : super(key: key);
  final dynamic data;
  final Function? setPayload;
  final Function? setData;

  @override
  _OnCreditState createState() => _OnCreditState();
}

class _OnCreditState extends State<OnCredit> {
  dynamic clients = [];
  dynamic data = Get.arguments;
  dynamic client = {'name': 'КЛИЕНТ'};
  final _formKey = GlobalKey<FormState>();
  final cashController = TextEditingController();
  final terminalController = TextEditingController();
  dynamic sendData = {'comment': '', 'name': '', 'phone1': '', 'phone2': ''};
  dynamic addList = [
    {'name': 'Наименование контакта', 'value': '', 'icon': Icons.person, 'keyboardType': TextInputType.text},
    {'name': 'Телефон', 'value': '', 'icon': Icons.phone, 'keyboardType': TextInputType.number},
    {'name': 'Телефон', 'value': '', 'icon': Icons.phone, 'keyboardType': TextInputType.number},
    {'name': 'Комментарий', 'value': '', 'icon': Icons.comment_outlined, 'keyboardType': TextInputType.text},
  ];

  createClient() async {
    final response = await post('/services/desktop/api/clients', sendData);
    if (response != null && response['success']) {
      Get.back();
      showSelectUserDialog();
    }
  }

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
    change = (paid - data['totalPrice']) as double;

    setState(() {
      data['change'] = change;
      data['paid'] = paid;
    });
  }

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

  selectDebtorClient(Function setDebtorState, index) {
    dynamic clientsCopy = clients;
    for (var i = 0; i < clientsCopy.length; i++) {
      clientsCopy[i]['selected'] = false;
    }
    clientsCopy[index]['selected'] = true;
    setDebtorState(() {
      clients = clientsCopy;
    });
  }

  @override
  void initState() {
    //print(data['itemsList']);
    super.initState();
    dynamic totalAmount = 0;
    for (var i = 0; i < data['itemsList'].length; i++) {
      totalAmount += data['itemsList'][i]['totalPrice'];
    }
    setState(() {
      data = widget.data!;
      data['totalPrice'] = double.parse(totalAmount.toString());
      data['change'] = -double.parse(totalAmount.toString());
      data['paid'] = 0;
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
            margin: EdgeInsets.only(top: 20, bottom: 5),
            child: Text(
              'КЛИЕНТ:',
              style: TextStyle(fontSize: 16, color: darkGrey, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Обязательное поле';
                }
                return null;
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
                    showSelectUserDialog();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFf1b44c)),
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
                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
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
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            width: MediaQuery.of(context).size.width,
                                            child: TextFormField(
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Обязательное поле';
                                                }
                                                return null;
                                              },
                                              onChanged: (value) {
                                                if (i == 0) {
                                                  setState(() {
                                                    sendData['name'] = value;
                                                  });
                                                }
                                                if (i == 1) {
                                                  setState(() {
                                                    sendData['phone1'] = value;
                                                  });
                                                }
                                                if (i == 2) {
                                                  setState(() {
                                                    sendData['phone2'] = value;
                                                  });
                                                }
                                                if (i == 3) {
                                                  setState(() {
                                                    sendData['comment'] = value;
                                                  });
                                                }
                                              },
                                              keyboardType: addList[i]['keyboardType'],
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
                                      createClient();
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
              style: TextStyle(fontSize: 16, color: a2, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Обязательное поле';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  client['comment'] = value;
                });
                widget.setPayload!('clientComment', client['comment']);
              },
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
                child: Text('К ОПЛАТЕ', style: TextStyle(color: darkGrey, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Container(
                  margin: EdgeInsets.only(bottom: 10),
                  child:
                      Text('${formatMoney(data['totalPrice'])} сум', style: TextStyle(color: darkGrey, fontSize: 16, fontWeight: FontWeight.bold))),
              Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          margin: EdgeInsets.only(bottom: 5), child: Text('Наличные', style: TextStyle(fontWeight: FontWeight.bold, color: grey))),
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          controller: cashController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Обязательное поле';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            calculateChange();
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
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
                          margin: EdgeInsets.only(bottom: 5), child: Text('Терминал', style: TextStyle(fontWeight: FontWeight.bold, color: grey))),
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          controller: terminalController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Обязательное поле';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            calculateChange();
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
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
              Text('СУММА ДОЛГА:', style: TextStyle(color: darkGrey, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                  margin: EdgeInsets.only(bottom: 10, top: 5),
                  child: Text('${formatMoney(data['change'])} сум', style: TextStyle(color: darkGrey, fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }

  showSelectUserDialog() async {
    await getClients();
    final result = await showDialog(
        context: context,
        useSafeArea: true,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(''),
              titlePadding: EdgeInsets.all(0),
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              insetPadding: EdgeInsets.all(10),
              actionsPadding: EdgeInsets.all(0),
              buttonPadding: EdgeInsets.all(0),
              scrollable: true,
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(width: 1, color: Color(0xFFDADADa), style: BorderStyle.solid),
                        ),
                        children: [
                          TableRow(children: const [
                            Text(
                              'Контакт',
                            ),
                            Text(
                              'Номер',
                            ),
                            Text('Комментарий'),
                          ]),
                          for (var i = 0; i < clients.length; i++)
                            TableRow(children: [
                              GestureDetector(
                                onTap: () {
                                  selectDebtorClient(setState, i);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  color: clients[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
                                  child: Text(
                                    '${clients[i]['name']}',
                                    style: TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  selectDebtorClient(setState, i);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  color: clients[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
                                  child: Text('${clients[i]['phone1']}'),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  selectDebtorClient(setState, i);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  color: clients[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
                                  child: Text("${clients[i]['comment'] == null ? '' : clients[i]['comment']}"),
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
                      for (var i = 0; i < clients.length; i++) {
                        if (clients[i]['selected']) {
                          Navigator.pop(context, clients);
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
    if (result != null) {
      for (var i = 0; i < result.length; i++) {
        if (result[i]['selected'] == true) {
          widget.setPayload!('clientName', result[i]['name'].toString());
          widget.setPayload!('clientId', result[i]['id']);
          widget.setPayload!('clientComment', result[i]['comment']);
          setState(() {
            client = result[i];
          });
        }
      }
    }
  }
}
