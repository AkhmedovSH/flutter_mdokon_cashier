import 'package:flutter/material.dart';

import 'package:kassa/helpers/helper.dart';
import 'package:kassa/widgets/custom_app_bar.dart';
import 'package:unicons/unicons.dart';

class Info extends StatelessWidget {
  const Info({Key? key}) : super(key: key);

  static List shortCutList = [
    {
      'icon': "+",
      'title': "Изменить количество выбранного товара",
      'description': "TEST",
    },
    {
      'icon': "-",
      'title': "Изменить общую сумму выбранного товара",
      'description': "TEST",
    },
    {
      'icon': "*",
      'title': "Изменить цену выбранного товара",
      'description': "TEST",
    },
    {
      'icon': "s",
      'title': "Дать скидку выбранному товару",
      'description': "TEST",
    },
    {
      'icon': "/",
      'title': "Изменить кол-во упаковочного выбранного товара",
      'description': "TEST",
    },
    {
      'icon': "%",
      'title': "Финальная скидка из всей суммы в процентах",
      'description': "TEST",
    },
    {
      'icon': "%-",
      'title': "Финальная скидка из всей суммы в процентах",
      'description': "TEST",
    },
    {
      'icon': UniconsLine.credit_card,
      'title': "Должники",
      'description': "TEST",
    },
    {
      'icon': UniconsLine.usd_circle,
      'title': "Расходы",
      'description': "TEST",
    },
    {
      'icon': UniconsLine.trash_alt,
      'title': "Удаление всех продуктов",
      'description': "TEST",
    },
    {
      'icon': UniconsLine.square_shape,
      'title': "Включить оптовую цену",
      'description': "TEST",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'info'),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              for (var i = 0; i < shortCutList.length; i++)
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 10),
                        alignment: Alignment.center,
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: mainColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: shortCutList[i]['icon'] is String
                            ? Text(
                                shortCutList[i]['icon'],
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 20),
                              )
                            : Icon(
                                shortCutList[i]['icon'],
                                color: Colors.white,
                              ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: Text(
                                shortCutList[i]['title'],
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            // SizedBox(height: 5),
                            // Padding(
                            //   padding: EdgeInsets.only(left: 5),
                            //   child: Text(
                            //     shortCutList[i]['description'],
                            //     style: TextStyle(fontSize: 16),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
