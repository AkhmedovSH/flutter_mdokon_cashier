import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';
import 'package:unicons/unicons.dart';

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
  dynamic client = {'name': 'CLIENT'.tr};
  final _formKey = GlobalKey<FormState>();
  final cashController = TextEditingController();
  final terminalController = TextEditingController();
  dynamic sendData = {'comment': '', 'name': '', 'phone1': '', 'phone2': ''};
  dynamic addList = [
    {'name': 'contact_name', 'value': '', 'icon': UniconsLine.user, 'keyboardType': TextInputType.text},
    {'name': 'phone', 'value': '', 'icon': UniconsLine.phone, 'keyboardType': TextInputType.number},
    {'name': 'phone', 'value': '', 'icon': UniconsLine.phone, 'keyboardType': TextInputType.number},
    {'name': 'comment', 'value': '', 'icon': UniconsLine.comment_lines, 'keyboardType': TextInputType.text},
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
              '${'CLIENT'.tr}:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'required_field'.tr;
                }
                return null;
              },
              onChanged: (value) {},
              enabled: false,
              enableInteractiveSelection: false,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                border: inputBorder,
                enabledBorder: inputBorder,
                focusedBorder: inputFocusBorder,
                errorBorder: inputErrorBorder,
                focusedErrorBorder: inputErrorBorder,
                focusColor: blue,
                hintText: '${client['name']}',
                hintStyle: TextStyle(color: a2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () async {
                      showSelectUserDialog();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFf1b44c)),
                    child: Text('choose'.tr),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          useSafeArea: true,
                          builder: (BuildContext context) {
                            return StatefulBuilder(builder: (context, setState) {
                              return AlertDialog(
                                title: Text(''),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(24.0),
                                  ),
                                ),
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
                                            SizedBox(height: 5),
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 10),
                                              width: MediaQuery.of(context).size.width,
                                              child: TextFormField(
                                                validator: (value) {
                                                  if (value == null || value.isEmpty) {
                                                    return 'required_field'.tr;
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
                                                  enabledBorder: inputBorder,
                                                  focusedBorder: inputFocusBorder,
                                                  errorBorder: inputErrorBorder,
                                                  focusedErrorBorder: inputErrorBorder,
                                                  suffixIcon: Icon(addList[i]['icon']),
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
                                    margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
                                    height: 45,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        createClient();
                                      },
                                      child: Text('save'.tr),
                                    ),
                                  ),
                                ],
                              );
                            });
                          });
                    },
                    child: Text('add'.tr),
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 10, bottom: 5),
            child: Text(
              'NOTE'.tr,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'required_field'.tr;
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
                enabledBorder: inputBorder,
                focusedBorder: inputFocusBorder,
                errorBorder: inputErrorBorder,
                focusedErrorBorder: inputErrorBorder,
                focusColor: blue,
                hintText: 'NOTE'.tr,
                hintStyle: TextStyle(color: a2),
              ),
            ),
          ),
          Column(
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
                  '${formatMoney(data['totalPrice'])} ${'sum'.tr}',
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
                        margin: EdgeInsets.only(bottom: 5),
                        child: Text(
                          'cash'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          controller: cashController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'required_field'.tr;
                            }
                            return null;
                          },
                          onChanged: (value) {
                            calculateChange();
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                            suffixIcon: Icon(
                              UniconsLine.money_bill,
                              size: 30,
                              color: Color(0xFF7b8190),
                            ),
                            enabledBorder: inputBorder,
                            focusedBorder: inputFocusBorder,
                            errorBorder: inputErrorBorder,
                            focusedErrorBorder: inputErrorBorder,
                            focusColor: blue,
                            hintText: '0.00 ${'sum'.tr}',
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
                              return 'required_field'.tr;
                            }
                            return null;
                          },
                          onChanged: (value) {
                            calculateChange();
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                            suffixIcon: Icon(
                              UniconsLine.credit_card,
                              size: 30,
                              color: Color(0xFF7b8190),
                            ),
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
                '${'AMOUNT_OF_DEBT'.tr}:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 10, top: 5),
                child: Text(
                  '${formatMoney(data['change'])} сум',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
                          horizontalInside: BorderSide(width: 1, color: tableBorderColor, style: BorderStyle.solid),
                        ),
                        children: [
                          TableRow(children: [
                            Text(
                              'contact'.tr,
                            ),
                            Text(
                              'number'.tr,
                            ),
                            Text('comment'.tr),
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
                                  child: Text(clients[i]['comment'] ?? ''),
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
                    child: Text('choose'.tr),
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
