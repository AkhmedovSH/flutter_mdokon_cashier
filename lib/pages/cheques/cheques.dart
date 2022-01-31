import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kassa/components/loading_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';
import 'package:kassa/helpers/controller.dart';

import '../../components/drawer_app_bar.dart';

class Cheques extends StatefulWidget {
  const Cheques({Key? key}) : super(key: key);

  @override
  _ChequesState createState() => _ChequesState();
}

class _ChequesState extends State<Cheques> {
  final Controller controller = Get.put(Controller());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime selectedDate = DateTime.now();
  dynamic cheques = [];
  dynamic filter = {
    'startDate': TextEditingController(),
    'endDate': TextEditingController(),
    'search': TextEditingController(),
    'fromPaid': TextEditingController(),
    'toPaid': TextEditingController(),
  };
  // TextEditingController startDate = TextEditingController();
  // TextEditingController endDate = TextEditingController();
  // TextEditingController search =  TextEditingController();
  // TextEditingController fromPaid = new TextEditingController();
  // TextEditingController toPaid = new TextEditingController();
  bool loading = false;
  dynamic sendData = {
    'startDate': '',
    'endDate': '',
    'posId': '',
    'outType': false,
    'search': '',
    'fromPaid': '',
    'toPaid': '',
    'size': 2000,
  };

  getCheques() async {
    controller.showLoading();
    print(controller.loading);
    setState(() {});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic cashbox = jsonDecode(prefs.getString('cashbox')!);
    setState(() {
      sendData['posId'] = cashbox['posId'];
    });
    final response = await get('/services/desktop/api/cashier-cheque-pageList',
        payload: sendData);
    controller.hideLoading();
    if (response != null) {
      setState(() {
        cheques = response;
      });
    } else {
      if (mounted) {
        setState(() {
          cheques = [];
        });
      }
    }
  }

  selectDate(BuildContext context, date) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (date == 1) {
      if (picked != null && picked != filter['startDate'].text) {
        setState(() {
          filter['startDate'].text = DateFormat('dd.MM.yyyy').format(picked);
          sendData['startDate'] = DateFormat('dd.MM.yyyy').format(picked);
        });
      }
    }
    if (date == 2) {
      if (picked != null && picked != filter['startDate'].text) {
        setState(() {
          filter['endDate'].text = DateFormat('dd.MM.yyyy').format(picked);
          sendData['endDate'] = DateFormat('dd.MM.yyyy').format(picked);
        });
      }
    }
  }

  getStatus(status) {
    if (status == 0) {
      return 'Успешно';
    } else if (status == 1) {
      return 'Товар возвращен частично';
    } else if (status == 2) {
      return 'Товар возвращен';
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      sendData['endDate'] = selectedDate.toUtc().millisecondsSinceEpoch;
      sendData['startDate'] = selectedDate
          .subtract(Duration(days: 10))
          .toUtc()
          .millisecondsSinceEpoch;
      filter['startDate'].text =
          DateFormat('dd.MM.yyyy').format(DateTime.now());
      filter['endDate'].text = DateFormat('dd.MM.yyyy').format(DateTime.now());
    });
    getCheques();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingLayout(
      body: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: Brightness.light,
              statusBarColor: blue, // Status bar
            ),
            bottomOpacity: 0.0,
            title: Text(
              'Чеки',
              style: TextStyle(color: white),
            ),
            centerTitle: true,
            backgroundColor: blue,
            elevation: 0,
            // centerTitle: true,
            leading: IconButton(
              onPressed: () {
                _scaffoldKey.currentState!.openDrawer();
              },
              icon: Icon(Icons.menu, color: white),
            ),
            actions: [
              IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16))),
                      builder: (BuildContext context) {
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.65,
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          child: Stack(
                            children: [
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(top: 50),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              selectDate(context, 1);
                                            },
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.44,
                                              child: TextField(
                                                controller: filter['startDate'],
                                                textInputAction:
                                                    TextInputAction.next,
                                                enabled: false,
                                                enableInteractiveSelection:
                                                    false,
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets.fromLTRB(
                                                          10, 5, 10, 10),
                                                  border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0xFFced4da),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0xFFced4da),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  hintStyle: TextStyle(
                                                      color: Color(0xFF495057)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              selectDate(context, 2);
                                            },
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.44,
                                              child: TextField(
                                                controller: filter['endDate'],
                                                textInputAction:
                                                    TextInputAction.next,
                                                enabled: false,
                                                enableInteractiveSelection:
                                                    false,
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets.fromLTRB(
                                                          10, 5, 10, 10),
                                                  border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0xFFced4da),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0xFFced4da),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  hintStyle: TextStyle(
                                                      color: Color(0xFF495057)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.44,
                                            child: TextField(
                                              controller: filter['fromPaid'],
                                              textInputAction:
                                                  TextInputAction.next,
                                              onChanged: (value) {
                                                setState(() {
                                                  sendData['fromPaid'] = value;
                                                });
                                              },
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.fromLTRB(
                                                        10, 5, 10, 10),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Color(0xFFced4da),
                                                    width: 1,
                                                  ),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Color(0xFFced4da),
                                                    width: 1,
                                                  ),
                                                ),
                                                hintText: 'Сумма от',
                                                hintStyle: TextStyle(
                                                    color: Color(0xFF495057)),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.44,
                                            child: TextField(
                                              controller: filter['toPaid'],
                                              textInputAction:
                                                  TextInputAction.next,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                setState(() {
                                                  sendData['toPaid'] = value;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.fromLTRB(
                                                        10, 5, 10, 10),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Color(0xFFced4da),
                                                    width: 1,
                                                  ),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Color(0xFFced4da),
                                                    width: 1,
                                                  ),
                                                ),
                                                hintText: 'Сумма до',
                                                hintStyle: TextStyle(
                                                    color: Color(0xFF495057)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin:
                                          EdgeInsets.only(top: 25, bottom: 370),
                                      child: TextField(
                                        controller: filter['search'],
                                        textInputAction: TextInputAction.next,
                                        onChanged: (value) {
                                          setState(() {
                                            sendData['search'] = value;
                                          });
                                        },
                                        scrollPadding:
                                            EdgeInsets.only(bottom: 350),
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                  10, 5, 10, 10),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFced4da),
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFced4da),
                                              width: 1,
                                            ),
                                          ),
                                          hintText: 'Поиск',
                                          hintStyle: TextStyle(
                                              color: Color(0xFF495057)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom +
                                          20,
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        getCheques();
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 16)),
                                      child: Text('Фильтр'),
                                    ),
                                  ))
                            ],
                          ),
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.filter_alt))
            ],
          ),
          drawer: SizedBox(
            width: MediaQuery.of(context).size.width * 0.70,
            child: const DrawerAppBar(),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 15),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Table(
                      border: TableBorder(
                          horizontalInside: BorderSide(
                              width: 1,
                              color: Color(0xFFDADADA),
                              style: BorderStyle
                                  .solid)), // Allows to add a border decoration around your table
                      children: [
                        TableRow(children: [
                          Container(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text('Статус',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text('Итоговая сумма',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text('Дата',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ]),
                        for (var i = 0; i < cheques.length; i++)
                          TableRow(children: [
                            GestureDetector(
                              onTap: () {
                                Get.toNamed('/cheq-detail',
                                    arguments: cheques[i]['id']);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                    '${i + 1}. ${getStatus(cheques[i]['returned'])}'),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Get.toNamed('/cheq-detail',
                                    arguments: cheques[i]['id']);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  '${cheques[i]['paid']}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Get.toNamed('/cheq-detail',
                                    arguments: cheques[i]['id']);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  '${formatUnixTime(cheques[i]['chequeDate'])}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ]),
                      ]),
                )
              ],
            ),
          )),
    );
  }
}
