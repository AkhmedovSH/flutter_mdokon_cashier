import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';
import 'package:kassa/helpers/controller.dart';

import '../components/drawer_app_bar.dart';

class Index extends StatefulWidget {
  const Index({Key? key}) : super(key: key);

  @override
  _IndexState createState() => _IndexState();
}

class _IndexState extends State<Index> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  dynamic cashbox = {};
  dynamic products = [];
  dynamic clients = [];
  dynamic textController = TextEditingController();
  dynamic textController2 = TextEditingController();
  dynamic expenseOut = {
    "cashboxId": '',
    "posId": '',
    "shiftId": '',
    'note': '',
    'amountOut': '',
    'paymentPurposeId': '1',
  };
  dynamic debtIn = {
    "amountIn": 0,
    "cash": "",
    "terminal": "",
    "amountOut": 0,
    "cashboxId": '',
    "clientId": 0,
    "currencyId": 0,
    "posId": '',
    "shiftId": '',
    "transactionsList": []
  };
  dynamic itemList = [
    {
      'label': 'Наличные',
      'icon': Icons.payments,
      'fieldName': 'cash',
    },
    {
      'label': 'Банковская карточка',
      'icon': Icons.payment,
      'fieldName': 'terminal',
    },
    {
      'label': 'Примечание',
      'fieldName': 'note',
    },
  ];

  getClients() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cashbox = jsonDecode(prefs.getString('cashbox')!);
    final response =
        await get('/services/desktop/api/client-debt-list/${cashbox['posId']}');
    //print(response);
    for (var i = 0; i < response.length; i++) {
      response[i]['selected'] = false;
    }
    setState(() {
      clients = response;
      debtIn['cashboxId'] = cashbox['cashboxId'];
      debtIn['posId'] = cashbox['posId'];
      if (prefs.getString('shift') != null) {
        debtIn['shiftId'] = jsonDecode(prefs.getString('shift')!)['id'];
      } else {
        debtIn['shiftId'] = cashbox['id'];
      }
    });
  }

  createDebtorOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cashbox = jsonDecode(prefs.getString('cashbox')!);
    setState(() {
      expenseOut['cashboxId'] = cashbox['cashboxId'].toString();
      expenseOut['posId'] = cashbox['posId'].toString();
      expenseOut['currencyId'] = cashbox['defaultCurrency'].toString();
      if (prefs.getString('shift') != null) {
        expenseOut['shiftId'] = jsonDecode(prefs.getString('shift')!)['id'];
      } else {
        expenseOut['shiftId'] = cashbox['id'].toString();
      }
    });
    final response =
        await post('/services/desktop/api/expense-out', expenseOut);
    if (response['success']) {
      Navigator.pop(context);
    }
  }

  createClientDebt() async {
    final list = [];
    if (debtIn['cash'].length > 0) {
      list.add({
        "amountIn": debtIn['cash'],
        "amountOut": "",
        "paymentTypeId": 1,
        "paymentPurposeId": 5
      });
    }
    if (debtIn['terminal'].length > 0) {
      list.add({
        "amountIn": debtIn['terminal'],
        "amountOut": "",
        "paymentTypeId": 2,
        "paymentPurposeId": 5
      });
    }

    dynamic sendData = Map.from(debtIn);
    if (sendData['cash'] != "") {
      sendData['cash'] = double.parse(sendData['cash']);
    } else {
      sendData['cash'] = 0;
    }
    if (sendData['terminal'] != "") {
      sendData['terminal'] = double.parse(sendData['terminal']);
    } else {
      sendData['terminal'] = 0;
    }
    sendData['amountIn'] = (sendData['cash'] + sendData['terminal']);
    await post('/services/desktop/api/client-debt-in', sendData);
    setState(() {
      debtIn = {
        "cash": "",
        "terminal": "",
        "amountIn": 0,
        "amountOut": 0,
        "cashboxId": '',
        "clientId": 0,
        "currencyId": 0,
        "posId": '',
        "shiftId": '',
        "transactionsList": []
      };
    });
  }

  redirectToCalculator(i) async {
    final result = await Get.toNamed('/calculator', arguments: products[i]);
    if (result != null) {
      var arr = products;
      for (var i = 0; i < arr.length; i++) {
        if (arr[i]['productId'] == result['productId']) {
          arr[i]['total_amount'] =
              double.parse(arr[i]['quantity']) * (arr[i]['salePrice'].round());
          arr[i] = result;
        }
      }
      setState(() {
        products = arr;
      });
    }
  }

  redirectToSearch() async {
    final result = await Get.toNamed('/search');
    //print(result);
    if (result != null) {
      var found = false;
      for (var i = 0; i < products.length; i++) {
        if (products[i]['productId'] == result['productId']) {
          found = true;
          dynamic arr = products;

          //print('cashbox${cashbox}');

          if (products[i]['quantity'] >= products[i]['balance'] &&
              !cashbox['saleMinus']) {
            showDangerToast('Превышен лимит');
            return;
          }

          arr[i]['quantity'] = arr[i]['quantity'] + 1;
          arr[i]['discount'] = 0;
          arr[i]['total_amount'] = arr[i]['quantity'] * arr[i]['salePrice'];
          setState(() {
            products = arr;
          });
          print(products[i]['discount']);
        }
      }
      if (!found) {
        result['quantity'] = 1;
        result['discount'] = 0;
        result['total_amount'] = result['quantity'] * result['salePrice'];
        result['totalPrice'] = result['total_amount'];
        setState(() {
          products.add(result);
        });
      }
    }
  }

  getCashbox() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cashbox = jsonDecode(prefs.getString('cashbox')!);
    });
  }

  @override
  void initState() {
    super.initState();
    getCashbox();
  }

  buildTextField(label, icon, item, index, setDialogState,
      {scrollPadding, enabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label',
          style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width,
          child: TextFormField(
            keyboardType:
                index != 2 ? TextInputType.number : TextInputType.text,
            onChanged: (value) {
              setDialogState(() {
                debtIn[item['fieldName']] = value;
              });
            },
            scrollPadding: EdgeInsets.only(bottom: 100),
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
              suffixIcon: Icon(icon),
              filled: true,
              fillColor: borderColor,
              focusColor: blue,
            ),
          ),
        ),
      ],
    );
  }

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
          'Продажа',
          style: TextStyle(color: white),
        ),
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
          SizedBox(
            child: IconButton(
              onPressed: () {
                showModalDebtor();
              },
              icon: Icon(Icons.payment),
            ),
          ),
          SizedBox(
            child: IconButton(
              onPressed: () {
                showModalExpense();
              },
              icon: Icon(Icons.paid_outlined),
            ),
          ),
          SizedBox(
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.qr_code_2_outlined),
            ),
          ),
          SizedBox(
            child: IconButton(
              onPressed: () {
                if (products.length > 0) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Вы уверены?'),
                      // content: const Text('AlertDialog description'),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.33,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                    primary: red,
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10)),
                                child: const Text('Отмена'),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.33,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    products = [];
                                  });
                                  Get.back();
                                },
                                style: ElevatedButton.styleFrom(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10)),
                                child: const Text('Продолжить'),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  );
                }
              },
              icon: Icon(Icons.delete),
            ),
          ),
        ],
      ),
      drawerEnableOpenDragGesture: false,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.70,
        child: const DrawerAppBar(),
      ),
      body: products.length == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/barcode-scanner.png',
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'Отсканируйте штрихкод с упаковки товара \nили введите его вручную.',
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Итого', style: TextStyle(fontSize: 16)),
                    Text('100 Сум', style: TextStyle(fontSize: 16)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Скидка', style: TextStyle(fontSize: 16)),
                    Wrap(
                      children: const [
                        Text('0%', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 10),
                        Text('0 Сум', style: TextStyle(fontSize: 16)),
                      ],
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        SizedBox(height: 10),
                        Text('К оплате', style: TextStyle(fontSize: 16)),
                        Text('0 Сум', style: TextStyle(fontSize: 16)),
                      ],
                    )
                  ],
                ),
                Divider(),
                for (var i = 0; i < products.length; i++)
                  Dismissible(
                    key: ValueKey(products[i]['productName']),
                    onDismissed: (DismissDirection direction) {
                      setState(() {
                        products.removeAt(i);
                      });
                    },
                    background: Container(
                      color: white,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.delete, color: red),
                    ),
                    direction: DismissDirection.endToStart,
                    child: GestureDetector(
                      onTap: () async {
                        redirectToCalculator(i);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: Color(0xFFF5F3F5), width: 1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${products[i]['productName']}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    Text(
                                      '${formatMoney(products[i]['salePrice'])}x ${products[i]['quantity']}',
                                      style: TextStyle(color: lightGrey),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${formatMoney(products[i]['totalPrice'])}So\'m',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: blue,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
              ],
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: EdgeInsets.only(left: 32),
            child: ElevatedButton(
              onPressed: () {
                if (products.length > 0) {
                  Get.toNamed('/payment', arguments: products);
                }
              },
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  primary: products.length > 0 ? blue : lightGrey),
              child: Text('Продать'),
            ),
          ),
          FloatingActionButton(
            backgroundColor: blue,
            onPressed: () {
              redirectToSearch();
            },
            child: const Icon(Icons.add, size: 28),
          )
        ],
      ),
    );
  }

  showModalExpense() async {
    await showDialog(
        context: context,
        useSafeArea: true,
        builder: (BuildContext context) {
          List filter = [
            {"id": 1, "name": "Продажа"},
            {"id": 2, "name": "Сдача"},
            {"id": 3, "name": "Возврат товаров"},
            {"id": 4, "name": "Долг"},
            {"id": 5, "name": "Погашение задолженности "},
            {"id": 6, "name": "Для собственных нужд"},
            {"id": 7, "name": "Для нужд торговой точки"},
            {"id": 8, "name": "Прочие"},
          ];
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(''),
              titlePadding: EdgeInsets.all(0),
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              insetPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              actionsPadding: EdgeInsets.all(0),
              buttonPadding: EdgeInsets.all(0),
              scrollable: true,
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 15),
                      width: double.infinity,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              width: 1.0,
                              style: BorderStyle.solid,
                              color: Color(0xFFECECEC)),
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton(
                            value: expenseOut['paymentPurposeId'],
                            isExpanded: true,
                            hint: Text('${filter[0]['name']}'),
                            icon: const Icon(Icons.expand_more_outlined),
                            iconSize: 24,
                            iconEnabledColor: blue,
                            elevation: 16,
                            style: const TextStyle(color: Color(0xFF313131)),
                            underline: Container(
                              height: 2,
                              color: blue,
                            ),
                            onChanged: (newValue) {
                              setState(() {
                                expenseOut['paymentPurposeId'] = newValue;
                              });
                            },
                            items: filter.map((item) {
                              return DropdownMenuItem<String>(
                                value: '${item['id']}',
                                child: Text(item['name']),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Наличные (Сум)',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: b8),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      width: MediaQuery.of(context).size.width,
                      child: TextFormField(
                        onChanged: (value) {
                          setState(() {
                            expenseOut['amountOut'] = value;
                          });
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.fromLTRB(10, 15, 10, 10),
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
                          suffixIcon: Icon(Icons.payment),
                          filled: true,
                          fillColor: borderColor,
                          focusColor: blue,
                          hintText: '0 сум',
                          hintStyle: TextStyle(color: a2),
                        ),
                      ),
                    ),
                    Text(
                      'ПРИМЕЧАНИЕ',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: b8),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      width: MediaQuery.of(context).size.width,
                      child: TextFormField(
                        onChanged: (value) {
                          setState(() {
                            expenseOut['note'] = value;
                          });
                        },
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.fromLTRB(10, 15, 10, 10),
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
                          hintText: 'Примечание',
                          hintStyle: TextStyle(color: a2),
                        ),
                      ),
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
                      if (expenseOut['amountOut'].length != 0) {
                        createDebtorOut();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      primary: expenseOut['amountOut'].length == 0
                          ? lightGrey
                          : blue,
                    ),
                    child: Text('Принять'),
                  ),
                )
              ],
            );
          });
        });
  }

  showModalDebtor() async {
    await getClients();
    final result = await showDialog(
        context: context,
        useSafeArea: true,
        builder: (BuildContext context) {
          dynamic content = clients;
          dynamic client = null;
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(''),
              titlePadding: EdgeInsets.all(0),
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              insetPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
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
                        onChanged: (value) {},
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.fromLTRB(10, 15, 10, 10),
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
                    SizedBox(height: 5),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.2,
                        child: SingleChildScrollView(
                          child: Table(
                              border: TableBorder(
                                  horizontalInside: BorderSide(
                                      width: 1,
                                      color: Color(0xFFDADADa),
                                      style: BorderStyle.solid)),
                              children: [
                                TableRow(children: const [
                                  Text(
                                    'Контакт',
                                  ),
                                  Text(
                                    'Валюта',
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'Сумма долга',
                                    textAlign: TextAlign.end,
                                  ),
                                ]),
                                for (var i = 0; i < content.length; i++)
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
                                            arr[j]['selected'] = false;
                                          }
                                          arr[i]['selected'] = true;
                                        }
                                        setState(() {
                                          content = arr;
                                          client = arr[i];
                                        });
                                      },
                                      child: Container(
                                        padding:
                                            EdgeInsets.fromLTRB(5, 8, 0, 8),
                                        color: content[i]['selected']
                                            ? Color(0xFF91a0e7)
                                            : Colors.transparent,
                                        child:
                                            Text('${content[i]['clientName']}'),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        dynamic arr = content;
                                        arr[i]['selected'] =
                                            !arr[i]['selected'];
                                        setState(() {
                                          content = arr;
                                          client = arr[i];
                                        });
                                      },
                                      child: Container(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 8),
                                        color: content[i]['selected']
                                            ? Color(0xFF91a0e7)
                                            : Colors.transparent,
                                        child: Text(
                                          content[i]['currencyName'],
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        dynamic arr = content;
                                        arr[i]['selected'] =
                                            !arr[i]['selected'];
                                        setState(() {
                                          content = arr;
                                          client = arr[i];
                                        });
                                      },
                                      child: Container(
                                        padding:
                                            EdgeInsets.fromLTRB(0, 8, 5, 8),
                                        color: content[i]['selected']
                                            ? Color(0xFF91a0e7)
                                            : Colors.transparent,
                                        child: Text(
                                          '${content[i]['balance']}',
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ),
                                  ]),
                              ]),
                        )),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: blue, width: 4))),
                      child: Text(
                        'Приход',
                        style: TextStyle(fontSize: 20, color: blue),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    for (var i = 0; i < itemList.length; i++)
                      buildTextField(
                        itemList[i]['label'],
                        itemList[i]['icon'],
                        itemList[i],
                        i,
                        setState,
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
                      print(client != null);
                      if (debtIn['cash'].length > 0 ||
                          debtIn['terminal'].toString().isNotEmpty ||
                          client != null) {
                        Navigator.pop(context, client);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      primary: debtIn['cash'].length > 0 ||
                              debtIn['cash'].length > 0 && client != null
                          ? blue
                          : lightGrey,
                    ),
                    child: Text('Принять'),
                  ),
                )
              ],
            );
          });
        });
    if (result != null) {
      setState(() {
        debtIn['clientId'] = result['clientId'];
        debtIn['balance'] = result['balance'];
        debtIn['clientName'] = result['clientName'];
        debtIn['currencyName'] = result['currencyName'];
        debtIn['currencyId'] = result['currencyId'];
      });
      createClientDebt();
    }
  }
}
