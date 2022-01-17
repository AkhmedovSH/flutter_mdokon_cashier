import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/globals.dart';
import '../components/drawer_app_bar.dart';

class ClientDebt extends StatefulWidget {
  const ClientDebt({Key? key}) : super(key: key);

  @override
  _ClientDebtState createState() => _ClientDebtState();
}

class _ClientDebtState extends State<ClientDebt> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
            title: Text(
              'Долг клиента',
              style: TextStyle(color: black),
            ),
            backgroundColor: white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
                onPressed: () {
                  _scaffoldKey.currentState!.openDrawer();
                },
                icon: Icon(
                  Icons.menu,
                  color: black,
                ))),
        drawer: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: const DrawerAppBar(),
        ),
        body: Container(
          margin: EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 15),
                      width: 64,
                      height: 64,
                      child: CircleAvatar(
                        radius: 30.0,
                        backgroundColor: Colors.transparent,
                        child: Image.asset('images/circle_avatar.png'),
                      ),
                    ),
                    const Text(
                      'Durdona Abdulazizova',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 30),
                      child: Text(
                        '+998-88-888-88-88',
                        style: TextStyle(color: lightGrey),
                      ),
                    ),
                    Text(
                      'Баланс:',
                      style: TextStyle(
                          color: lightGrey, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      margin: EdgeInsets.only(bottom: 10, top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 5),
                            child: Text(
                              '- 0 000 000.00',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: red),
                            ),
                          ),
                          Text(
                            'СУМ',
                            style: TextStyle(
                                color: red,
                                fontWeight: FontWeight.w400,
                                fontSize: 16),
                          )
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 5),
                          child: Text(
                            '- 0 000 000.00',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: red),
                          ),
                        ),
                        Text(
                          'USD',
                          style: TextStyle(
                              color: red,
                              fontWeight: FontWeight.w400,
                              fontSize: 16),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 15),
                padding: EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                    color: orange,
                    borderRadius: const BorderRadius.all(Radius.circular(20))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 5),
                      child: Icon(Icons.history, color: white),
                    ),
                    Text(
                      'История взаиморасчетов',
                      style:
                          TextStyle(color: white, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.only(left: 48, right: 32, bottom: 20),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Get.offAllNamed('/');
                    },
                    child: Text(
                      'ПРИНИМАТЬ ДЕНЬГИ',
                      style: TextStyle(color: white),
                    ))),
            Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.only(left: 48, right: 32),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: blue,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      'ВЫДАВАТЬ ДЕНЬГИ',
                      style: TextStyle(color: blue),
                    ))),
          ],
        ));
  }
}
