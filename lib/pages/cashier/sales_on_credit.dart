import 'package:flutter/material.dart';
import 'package:kassa/widgets/custom_app_bar.dart';

import '../../helpers/helper.dart';

class SalesOnCredit extends StatefulWidget {
  const SalesOnCredit({Key? key}) : super(key: key);

  @override
  _SalesOnCreditState createState() => _SalesOnCreditState();
}

class _SalesOnCreditState extends State<SalesOnCredit> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Продажи в долг',
        leading: true,
      ),
      body: Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 30,
                  child: TextField(
                    decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(2),
                        isDense: true,
                        prefixIcon: Icon(
                          Icons.search,
                          color: grey,
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: borderColor,
                            ),
                            borderRadius: const BorderRadius.all(Radius.circular(24))),
                        hintText: 'Поиск по номеру, фио клиента ...',
                        hintStyle: TextStyle(color: lightGrey, fontSize: 14)),
                  ),
                ),
                for (var i = 0; i < 7; i++)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: CircleAvatar(
                            radius: 30.0,
                            backgroundColor: Colors.transparent,
                            child: Image.asset('images/circle_avatar.png'),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Durdona Abdulazizova',
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      '+998-88-888-88-88',
                                      style: TextStyle(color: lightGrey),
                                    ),
                                  ],
                                )),
                            Container(
                              margin: EdgeInsets.only(bottom: 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(right: 30),
                                    child: Text(
                                      'Баланс(UZS):',
                                      style: TextStyle(color: lightGrey, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(right: 5),
                                        child: Text(
                                          '- 0 000 000.00',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: red),
                                        ),
                                      ),
                                      Text(
                                        'СУМ',
                                        style: TextStyle(color: red, fontWeight: FontWeight.w400, fontSize: 12),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(bottom: 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(right: 30),
                                    child: Text(
                                      'Баланс(USD):',
                                      style: TextStyle(color: lightGrey, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(right: 5),
                                        child: Text(
                                          '- 0 000 000.00',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: red),
                                        ),
                                      ),
                                      Text(
                                        'USD',
                                        style: TextStyle(color: red, fontWeight: FontWeight.w400, fontSize: 12),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  )
              ],
            ),
          )),
    );
  }
}
