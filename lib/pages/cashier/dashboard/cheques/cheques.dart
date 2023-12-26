import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:kassa/components/loading_layout.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';
import 'package:kassa/helpers/controller.dart';
import 'package:unicons/unicons.dart';

class Cheques extends StatefulWidget {
  const Cheques({Key? key}) : super(key: key);

  @override
  _ChequesState createState() => _ChequesState();
}

class _ChequesState extends State<Cheques> {
  final Controller controller = Get.put(Controller());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GetStorage storage = GetStorage();

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
    'toPaid': '',
    'size': 2000,
  };

  Future<void> getCheques() async {
    controller.showLoading();
    print(controller.loading);
    setState(() {});
    dynamic cashbox = jsonDecode(storage.read('cashbox')!);
    setState(() {
      sendData['posId'] = cashbox['posId'];
    });
    final response = await get('/services/desktop/api/cashier-cheque-pageList', payload: sendData);
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

  getStatus(status) {
    if (status == 0) {
      return 'successful'.tr;
    } else if (status == 1) {
      return 'item_returned_partially'.tr;
    } else if (status == 2) {
      return 'item_returned'.tr;
    }
  }

  getColor(status) {
    if (status == 0) {
      return success;
    } else if (status == 1) {
      return warning;
    } else if (status == 2) {
      return danger;
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      sendData['endDate'] = selectedDate.toUtc().millisecondsSinceEpoch;
      sendData['startDate'] = selectedDate.subtract(Duration(days: 10)).toUtc().millisecondsSinceEpoch;
      filter['startDate'].text = DateFormat('dd.MM.yyyy').format(DateTime.now());
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
            'checks'.tr,
            style: TextStyle(color: white),
          ),
          centerTitle: true,
          backgroundColor: blue,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                showFilterDialog();
              },
              icon: Icon(UniconsLine.filter),
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: getCheques,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 15),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        width: 0.7,
                        color: tableBorderColor,
                        style: BorderStyle.solid,
                      ),
                    ), // Allows to add a border decoration around your table
                    children: [
                      TableRow(children: [
                        Container(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'status'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'total_amount'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'date'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]),
                      for (var i = 0; i < cheques.length; i++)
                        TableRow(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                Get.toNamed('/cheq-detail', arguments: cheques[i]['id']);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  '${i + 1}. ${getStatus(cheques[i]['returned'])}',
                                  style: TextStyle(
                                    color: getColor(cheques[i]['returned']),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                Get.toNamed('/cheq-detail', arguments: cheques[i]['id']);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  //cheques[i]['totalPrice']
                                  '${formatMoney(cheques[i]['totalPrice'], decimalDigits: 0)} ${'sum'.tr}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                Get.toNamed('/cheq-detail', arguments: cheques[i]['id']);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  '${formatUnixTime(cheques[i]['chequeDate'])}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  selectDate(BuildContext context, date) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (date == 1) {
      if (picked != null && picked != filter['startDate'].text) {
        setState(() {
          filter['startDate'].text = DateFormat('dd.MM.yyyy').format(picked);
          sendData['startDate'] = picked.toUtc().millisecondsSinceEpoch;
        });
      }
    }
    print(picked!.toUtc().millisecondsSinceEpoch);
    if (date == 2) {
      if (picked != filter['startDate'].text) {
        setState(() {
          filter['endDate'].text = DateFormat('dd.MM.yyyy').format(picked);
          sendData['endDate'] = picked.toUtc().millisecondsSinceEpoch;
        });
      }
    }
  }

  showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              selectDate(context, 1);
                            },
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.44,
                              child: TextField(
                                controller: filter['startDate'],
                                textInputAction: TextInputAction.next,
                                enabled: false,
                                enableInteractiveSelection: false,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
                                  border: OutlineInputBorder(
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
                                  hintStyle: TextStyle(color: Color(0xFF495057)),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              selectDate(context, 2);
                            },
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.44,
                              child: TextField(
                                controller: filter['endDate'],
                                textInputAction: TextInputAction.next,
                                enabled: false,
                                enableInteractiveSelection: false,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
                                  border: OutlineInputBorder(
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
                                  hintStyle: TextStyle(color: Color(0xFF495057)),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.44,
                            child: TextField(
                              controller: filter['fromPaid'],
                              textInputAction: TextInputAction.next,
                              onChanged: (value) {
                                setState(() {
                                  sendData['fromPaid'] = value;
                                });
                              },
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
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
                                hintText: 'amount_from'.tr,
                                hintStyle: TextStyle(color: Color(0xFF495057)),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.44,
                            child: TextField(
                              controller: filter['toPaid'],
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  sendData['toPaid'] = value;
                                });
                              },
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
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
                                hintText: 'amount_to',
                                hintStyle: TextStyle(color: Color(0xFF495057)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.only(top: 25, bottom: 370),
                      child: TextField(
                        controller: filter['search'],
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          setState(() {
                            sendData['search'] = value;
                          });
                        },
                        scrollPadding: EdgeInsets.only(bottom: 350),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
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
                          hintText: 'search'.tr,
                          hintStyle: TextStyle(color: Color(0xFF495057)),
                        ),
                      ),
                    ),
                    SizedBox(height: 50)
                  ],
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: ElevatedButton(
                    onPressed: () {
                      getCheques();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                    child: Text('filter'.tr),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
