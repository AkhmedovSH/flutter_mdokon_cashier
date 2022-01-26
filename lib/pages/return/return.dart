import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'package:kassa/helpers/globals.dart';

import '../../components/drawer_app_bar.dart';

class Return extends StatefulWidget {
  const Return({Key? key}) : super(key: key);

  @override
  State<Return> createState() => _ReturnState();
}

class _ReturnState extends State<Return> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  dynamic products = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarColor: blue, // Status bar
        ),
        bottomOpacity: 0.0,
        title: Text(
          'Возврат',
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
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.70,
        child: const DrawerAppBar(),
      ),
      body: Container(
        margin: EdgeInsets.only(top: 10, left: 8, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  margin: EdgeInsets.only(bottom: 10),
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(top: 5, left: 10),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFced4da),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFced4da),
                          width: 2,
                        ),
                      ),
                      hintText: 'Поиск',
                      filled: true,
                      fillColor: white,
                      focusColor: blue,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20)),
                    child: Text('Поиск'),
                  ),
                )
              ],
            ),
            Container(
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width,
                
                decoration: BoxDecoration(
                    border: Border(
                  bottom: BorderSide(color: Color(0xFFced4da), width: 1),
                )),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 5),
                        child: Text(
                          'Кассовый чек №: 90223387',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: b8),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text(
                              'Дата: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: b8),
                            ),
                            Container(
                              margin: EdgeInsets.only(right: 20),
                              child: Text(
                                '25.01.2022 10:57:03',
                                style: TextStyle(color: b8),
                              ),
                            ),
                            Text(
                              'Кассир: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: b8),
                            ),
                            Text(
                              'Ibrohim Rasulov',
                              style: TextStyle(color: b8),
                            )
                          ],
                        ),
                      ),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(3),
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(
                              width: 1,
                              color: Color(0xFFDADADa),
                              style: BorderStyle.solid),
                        ),
                        children: [
                          TableRow(children: [
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Наименование товара',
                                style: TextStyle(
                                    color: Color(0xFF495057),
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Цена со скидкой',
                                style: TextStyle(
                                    color: Color(0xFF495057),
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Кол-во',
                                style: TextStyle(
                                    color: Color(0xFF495057),
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Сумма оплаты',
                                style: TextStyle(
                                    color: Color(0xFF495057),
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ]),
                          // for (var i = 0; i < products.length; i++)
                          TableRow(children: [
                            // HERE IT IS...
                            TableRowInkWell(
                              onTap: () {
                                print('tab');
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'data',
                                  style: TextStyle(color: Color(0xFF495057)),
                                ),
                              ),
                            ),
                            TableRowInkWell(
                              onTap: () {
                                print('tab');
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'data',
                                  style: TextStyle(color: Color(0xFF495057)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            TableRowInkWell(
                              onDoubleTap: () {
                                print('tab');
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'data',
                                  style: TextStyle(color: Color(0xFF495057)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            TableRowInkWell(
                              onDoubleTap: () {
                                print('tab');
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'data',
                                  style: TextStyle(color: Color(0xFF495057)),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ),
                          ]),
                        ],
                      )
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
