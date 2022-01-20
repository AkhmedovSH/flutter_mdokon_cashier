import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';

class OnCredit extends StatefulWidget {
  const OnCredit({Key? key}) : super(key: key);

  @override
  _OnCreditState createState() => _OnCreditState();
}

class _OnCreditState extends State<OnCredit> {
  dynamic clients = [];

  getClients() async {
    final response = await get('/services/desktop/api/clients-helper');
    print(response);
    setState(() {
      clients = response;
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
                hintText: 'Клиент',
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
                    showDialog(
                      context: context,
                      useSafeArea: true,
                      builder: (BuildContext context) => AlertDialog(
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
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                width: MediaQuery.of(context).size.width,
                                child: TextFormField(
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Обязательное поле';
                                    }
                                  },
                                  onChanged: (value) {},
                                  enableInteractiveSelection: false,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.fromLTRB(
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
                              Table(
                                  border: TableBorder(bottom: BorderSide(color: Color(0xFFDADADA),width: 1)), // Allows to add a border decoration around your table
                                  children: const [
                                    TableRow(children: [
                                      Text('Контакт'),
                                      Text('Номер телефона'),
                                      Text('Номер телефона'),
                                      Text('Комментарий'),
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
                              onPressed: () {},
                              child: Text('Выбрать'),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(primary: Color(0xFFf1b44c)),
                  child: Text('Выбрать'),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: ElevatedButton(
                  onPressed: () {},
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
                  child: Text('270 000.00 сум',
                      style: TextStyle(
                          color: darkGrey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold))),
              Form(
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
                      scrollPadding: EdgeInsets.only(bottom: 170),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Обязательное поле';
                        }
                      },
                      onChanged: (value) {},
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
                      scrollPadding: EdgeInsets.only(bottom: 90),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Обязательное поле';
                        }
                      },
                      onChanged: (value) {},
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
              Text('СУММА ДОЛГА:',
                  style: TextStyle(
                      color: darkGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Container(
                  margin: EdgeInsets.only(bottom: 10, top: 5),
                  child: Text('-10 800 000.00 сум',
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
