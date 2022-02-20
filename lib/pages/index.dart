import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';

import '../components/drawer_app_bar.dart';

class Index extends StatefulWidget {
  const Index({Key? key}) : super(key: key);

  @override
  _IndexState createState() => _IndexState();
}

class _IndexState extends State<Index> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  dynamic shortcutController = TextEditingController();
  dynamic shortcutFocusNode = FocusNode();
  dynamic textController = TextEditingController();
  dynamic textController2 = TextEditingController();

  dynamic data = {
    "cashboxVersion": "",
    "login": "",
    "loyaltyBonus": 0,
    "loyaltyClientAmount": 0,
    "loyaltyClientName": "",
    "cashboxId": "",
    "change": 0,
    "chequeDate": 0,
    "chequeNumber": "",
    "clientAmount": 0,
    "clientComment": "",
    "clientId": 0,
    "currencyId": "",
    "currencyRate": 0,
    "discount": 0,
    "note": "",
    "offline": false,
    "outType": false,
    "paid": 0,
    "posId": "",
    "saleCurrencyId": "",
    "shiftId": '',
    "totalPriceBeforeDiscount": 0, // this is only for showing when sale
    "totalPrice": 0,
    "transactionId": "",
    "itemsList": [],
    "transactionsList": []
  };

  dynamic cashbox = {};
  dynamic clients = [];
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
      'label': 'Терминал',
      'icon': Icons.payment,
      'fieldName': 'terminal',
    },
    {
      'label': 'Примечание',
      'fieldName': 'note',
    },
  ];
  dynamic shortCutList = ["+", "-", "*", "/", "%", "%-"];

  getClients() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cashbox = jsonDecode(prefs.getString('cashbox')!);
    final response = await get('/services/desktop/api/client-debt-list/${cashbox['posId']}');
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
    final response = await post('/services/desktop/api/expense-out', expenseOut);
    if (response['success']) {
      Navigator.pop(context);
    }
  }

  createClientDebt() async {
    final list = [];
    if (debtIn['cash'].length > 0) {
      list.add({"amountIn": debtIn['cash'], "amountOut": "", "paymentTypeId": 1, "paymentPurposeId": 5});
    }
    if (debtIn['terminal'].length > 0) {
      list.add({"amountIn": debtIn['terminal'], "amountOut": "", "paymentTypeId": 2, "paymentPurposeId": 5});
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
    final product = await Get.toNamed('/calculator', arguments: data["itemsList"][i]);
    //print('product${product}');
    if (product != null) {
      var arr = data["itemsList"];
      double totalPrice = 0;

      for (var i = 0; i < arr.length; i++) {
        if (arr[i]['productId'] == product['productId']) {
          arr[i]['totalPrice'] = double.parse(arr[i]['quantity'].toString()) * double.parse(arr[i]['salePrice'].toString());
          arr[i] = product;
        }
        totalPrice += double.parse(arr[i]['quantity'].toString()) * double.parse(arr[i]['salePrice'].toString());
      }

      setState(() {
        data["itemsList"] = arr;
        data["totalPrice"] = totalPrice;
      });
    }
  }

  redirectToSearch() async {
    if (data['discount'] > 0) {
      showDangerToast('Была пременина скидка');
      return;
    }
    final product = await Get.toNamed('/search');
    if (product != null) {
      var existSameProduct = false;
      double totalPrice = 0;
      dynamic productsCopy = data["itemsList"];
      for (var i = 0; i < productsCopy.length; i++) {
        if (productsCopy[i]['productId'] == product['productId']) {
          existSameProduct = true;

          if (productsCopy[i]['quantity'] >= productsCopy[i]['balance'] && !cashbox['saleMinus']) {
            showDangerToast('Превышен лимит');
            return;
          }

          productsCopy[i]['quantity'] = productsCopy[i]['quantity'] + 1;
          productsCopy[i]['discount'] = 0;
          productsCopy[i]['totalPrice'] = productsCopy[i]['quantity'] * productsCopy[i]['salePrice'];
          totalPrice += productsCopy[i]['totalPrice'];

          setState(() {
            data["itemsList"] = productsCopy;
            data['totalPrice'] = totalPrice;
          });
        }
      }

      if (!existSameProduct) {
        product['quantity'] = 1;
        product['discount'] = 0;
        productsCopy.add(product);

        for (var i = 0; i < productsCopy.length; i++) {
          productsCopy[i]['selected'] = false;
          productsCopy[i]['totalPrice'] = productsCopy[i]['quantity'] * productsCopy[i]['salePrice'];
          totalPrice += productsCopy[i]['totalPrice'];
        }
        productsCopy[productsCopy.length - 1]['selected'] = true;

        setState(() {
          data["itemsList"] = productsCopy;
          data['totalPrice'] = totalPrice;
        });
      }
    }
  }

  addToList(product) {}

  deleteProduct(i) {
    if (data["itemsList"].length == 1) {
      deleteAllProducts();
      return;
    }
    double totalPrice = 0;
    dynamic productsCopy = data["itemsList"];
    productsCopy.removeAt(i);

    for (var i = 0; i < productsCopy.length; i++) {
      productsCopy[i]['totalPrice'] = productsCopy[i]['quantity'] * productsCopy[i]['salePrice'];
      totalPrice += productsCopy[i]['totalPrice'];
    }

    setState(() {
      data["itemsList"] = productsCopy;
      data['totalPrice'] = totalPrice;
    });
  }

  deleteAllProducts() {
    setState(() {
      data = {
        "cashboxVersion": "",
        "login": "",
        "loyaltyBonus": 0,
        "loyaltyClientAmount": 0,
        "loyaltyClientName": "",
        "cashboxId": "",
        "change": 0,
        "chequeDate": 0,
        "chequeNumber": "",
        "clientAmount": 0,
        "clientComment": "",
        "clientId": 0,
        "currencyId": "",
        "currencyRate": 0,
        "discount": 0,
        "note": "",
        "offline": false,
        "outType": false,
        "paid": 0,
        "posId": "",
        "saleCurrencyId": "",
        "shiftId": '',
        "totalPriceBeforeDiscount": 0, // this is only for showing when sale
        "totalPrice": 0,
        "transactionId": "",
        "itemsList": [],
        "transactionsList": []
      };
    });
  }

  handleShortCut(type) {
    if (shortcutController.text.length == 0) return;
    dynamic productsCopy = data["itemsList"];
    var inputData = shortcutController.text;
    var isFloat = '.'.allMatches(inputData).isEmpty ? false : true;

    if (type == "+") {
      for (var i = 0; i < productsCopy.length; i++) {
        if (productsCopy[i]['selected']) {
          // Штучные товары нельзя вводить дробным числом
          if (isFloat && productsCopy[i]['uomId'] == 1) {
            showDangerToast('Неверное количество');
            shortcutController.text = "";
            FocusManager.instance.primaryFocus?.unfocus();
            return;
          } else {
            if (!cashbox['saleMinus'] && (double.parse(inputData) > productsCopy[i]['balance'])) {
              showDangerToast('Превышен лимит');
              productsCopy[i]['quantity'] = productsCopy[i]['balance'];
              calculateTotalPrice(productsCopy);
              shortcutController.text = "";
              FocusManager.instance.primaryFocus?.unfocus();
            } else {
              shortcutController.text = "";
              FocusManager.instance.primaryFocus?.unfocus();
              productsCopy[i]['quantity'] = inputData;
              calculateTotalPrice(productsCopy);
            }
            break;
          }
        }
      }
    } else {
      shortcutController.text = "";
      FocusManager.instance.primaryFocus?.unfocus();
    }

    if (type == "*") {
      for (var i = 0; i < productsCopy.length; i++) {
        if (productsCopy[i]['selected']) {
          if (double.parse(inputData) < productsCopy[i]['price']) {
            showDangerToast('Цена продажи не может быть ниже чем цена поступления');
            shortcutController.text = "";
            FocusManager.instance.primaryFocus?.unfocus();
            break;
          } else {
            productsCopy[i]['salePrice'] = double.parse(inputData);
          }
          calculateTotalPrice(productsCopy);
          shortcutController.text = "";
          FocusManager.instance.primaryFocus?.unfocus();
          break;
        }
      }
    }
    if (type == "-") {
      for (var i = 0; i < productsCopy.length; i++) {
        if (productsCopy[i]['selected']) {
          if (productsCopy[i]['uomId'] == 1) {
            showDangerToast('Неверное количество');
            shortcutController.text = "";
          } else {
            if (!cashbox['saleMinus'] && (double.parse(inputData) / productsCopy[i]['salePrice'] > productsCopy[i]['balance'])) {
              showDangerToast('Превышен лимит');
            } else if (!cashbox['saleMinus'] && (productsCopy[i]['balance'] > (double.parse(inputData) / productsCopy[i]['salePrice']))) {
              productsCopy[i]['quantity'] = double.parse(inputData) / productsCopy[i]['salePrice'];
            } else {
              productsCopy[i]['quantity'] = double.parse(inputData) / productsCopy[i]['salePrice'];
            }
          }
          calculateTotalPrice(productsCopy);
          shortcutController.text = "";
          FocusManager.instance.primaryFocus?.unfocus();
          break;
        }
      }
    }
    if (type == "/") {
      shortcutController.text = "";
      for (var i = 0; i < productsCopy.length; i++) {
        if (productsCopy[i]['selected'] && productsCopy[i]['unitList'].length > 0) {
          //
        }
      }
    }
    if (type == "%") {
      calculateDiscount("%", inputData);
      shortcutController.text = "";
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    if (type == "%-") {
      calculateDiscount("%-", inputData);
      shortcutController.text = "";
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    setState(() {
      data["itemsList"] = productsCopy;
    });
  }

  calculateTotalPrice(productsCopy) {
    dynamic totalPrice = 0;
    for (var i = 0; i < productsCopy.length; i++) {
      productsCopy[i]['totalPrice'] = double.parse(productsCopy[i]['quantity'].toString()) * double.parse(productsCopy[i]['salePrice'].toString());
      totalPrice += productsCopy[i]['totalPrice'];
    }
    setState(() {
      data['totalPrice'] = totalPrice;
      data["itemsList"] = productsCopy;
    });
  }

  calculateDiscount(key, value) {
    value = double.parse(value);
    dynamic dataCopy = data;
    if (dataCopy['discount'] > 0) {
      dataCopy['discount'] = 0;
      dataCopy['totalPrice'] = dataCopy['totalPriceBeforeDiscount'];
      dataCopy['totalPriceBeforeDiscount'] = 0;
      for (var i = 0; i < dataCopy["itemsList"].length; i++) {
        dataCopy["itemsList"][i]['discount'] = 0;
        dataCopy["itemsList"][i]['totalPrice'] = dataCopy["itemsList"][i]['salePrice'] * dataCopy["itemsList"][i]['quantity'];
      }
    }

    if (key == "%") {
      dataCopy['discount'] = value;
      dataCopy['totalPrice'] = 0;
      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        dataCopy['totalPrice'] +=
            double.parse(dataCopy['itemsList'][i]['salePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
        dataCopy['itemsList'][i]['discount'] = value;
        dataCopy['itemsList'][i]['totalPrice'] = dataCopy['itemsList'][i]['totalPrice'] - (dataCopy['itemsList'][i]['totalPrice'] * value) / 100;
      }
      dataCopy['totalPriceBeforeDiscount'] = dataCopy['totalPrice'];
      dataCopy['totalPrice'] = dataCopy['totalPrice'] - (dataCopy['totalPrice'] * value) / 100;
    }
    if (key == "%-") {
      dynamic percent = 100 / (dataCopy['totalPrice'] / value);
      dataCopy['discount'] = percent;
      dataCopy['totalPriceBeforeDiscount'] = dataCopy['totalPrice'];
      dataCopy['totalPrice'] = dataCopy['totalPriceBeforeDiscount'] - (dataCopy['totalPrice'] * percent) / 100;

      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        dataCopy['itemsList'][i]['discount'] = percent;
        dataCopy['itemsList'][i]['totalPrice'] = dataCopy['itemsList'][i]['totalPrice'] - ((dataCopy['itemsList'][i]['totalPrice'] * percent) / 100);
      }
    }

    setState(() {
      data = dataCopy;
    });
  }

  selectProduct(index) {
    dynamic productsCopy = data["itemsList"];
    for (var i = 0; i < productsCopy.length; i++) {
      productsCopy[i]['selected'] = false;
    }
    productsCopy[index]['selected'] = true;
    setState(() {
      data["itemsList"] = productsCopy;
    });
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

  buildTextField(label, icon, item, index, setDialogState, {scrollPadding, enabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width,
          child: TextFormField(
            keyboardType: index != 2 ? TextInputType.number : TextInputType.text,
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
                  width: 1,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: blue,
                  width: 1,
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
              onPressed: () {
                if (data["itemsList"].length > 0) {
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
                                style: ElevatedButton.styleFrom(primary: red, padding: EdgeInsets.symmetric(vertical: 10)),
                                child: const Text('Отмена'),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.33,
                              child: ElevatedButton(
                                onPressed: () {
                                  deleteAllProducts();
                                },
                                style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 10)),
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
      body: data["itemsList"].length == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.asset('images/lottie/scan_1.json'),
                ),
                // Image.asset(
                //   'images/barcode-scanner.png',
                // ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'Отсканируйте штрихкод с упаковки товара \nили введите его вручную.',
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var i = 0; i < shortCutList.length; i++)
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              handleShortCut(shortCutList[i]);
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 3),
                              color: blue,
                              padding: EdgeInsets.all(5),
                              child: Text(
                                shortCutList[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: TextField(
                            controller: shortcutController,
                            focusNode: shortcutFocusNode,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(10),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: borderColor),
                                borderRadius: const BorderRadius.all(Radius.circular(24)),
                              ),
                              hintText: 'Введите значение',
                              hintStyle: TextStyle(
                                color: lightGrey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Итого', style: TextStyle(fontSize: 16)),
                      data['discount'] == 0
                          ? Text(formatMoney(data['totalPrice']) + ' Сум', style: TextStyle(fontSize: 16))
                          : Text(formatMoney(data['totalPriceBeforeDiscount']) + ' Сум', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Скидка', style: TextStyle(fontSize: 16)),
                      Wrap(
                        children: [
                          data['discount'] == 0
                              ? Text('(0%)', style: TextStyle(fontSize: 16))
                              : Text('(' + formatMoney(data['discount']) + '%)', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 10),
                          data['discount'] == 0
                              ? Text('0,00 Сум', style: TextStyle(fontSize: 16))
                              : Text(
                                  formatMoney(
                                          double.parse(data['totalPriceBeforeDiscount'].toString()) - double.parse(data['totalPrice'].toString())) +
                                      'Сум',
                                  style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 10),
                          Text('К оплате', style: TextStyle(fontSize: 16)),
                          Text(formatMoney(data['totalPrice']) + ' Сум', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    ],
                  ),
                  for (var i = data["itemsList"].length - 1; i >= 0; i--)
                    Dismissible(
                      key: ValueKey(data["itemsList"][i]['productName']),
                      onDismissed: (DismissDirection direction) {
                        deleteProduct(i);
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
                          selectProduct(i);
                          //redirectToCalculator(i);
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.only(bottom: 5),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: data["itemsList"][i]['selected'] ? Color(0xFF5b73e8) : Color(0xFFF5F3F5), width: 1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(i + 1).toString() + '. ' + data["itemsList"][i]['productName']}',
                                style: const TextStyle(fontSize: 16),
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
                                        '${formatMoney(data["itemsList"][i]['salePrice'])}x ${data["itemsList"][i]['quantity']}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${formatMoney(data["itemsList"][i]['totalPrice'])}So\'m',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: blue, fontSize: 16),
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
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: EdgeInsets.only(left: 32),
            child: ElevatedButton(
              onPressed: () {
                if (data["itemsList"].length > 0) {
                  Get.toNamed('/payment', arguments: data);
                }
              },
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32), primary: data["itemsList"].length > 0 ? blue : lightGrey),
              child: Text('Продать'),
            ),
          ),
          FloatingActionButton(
            backgroundColor: data['discount'] == 0 ? blue : lightGrey,
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
                          side: BorderSide(width: 1.0, style: BorderStyle.solid, color: Color(0xFFECECEC)),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
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
                      primary: expenseOut['amountOut'].length == 0 ? lightGrey : blue,
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
          dynamic client = '';
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
                              border: TableBorder(horizontalInside: BorderSide(width: 1, color: Color(0xFFDADADa), style: BorderStyle.solid)),
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
                                          for (var j = 0; j < content.length; j++) {
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
                                        padding: EdgeInsets.fromLTRB(5, 8, 0, 8),
                                        color: content[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
                                        child: Text('${content[i]['clientName']}'),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        dynamic arr = content;
                                        arr[i]['selected'] = !arr[i]['selected'];
                                        setState(() {
                                          content = arr;
                                          client = arr[i];
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        color: content[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
                                        child: Text(
                                          content[i]['currencyName'],
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        dynamic arr = content;
                                        arr[i]['selected'] = !arr[i]['selected'];
                                        setState(() {
                                          content = arr;
                                          client = arr[i];
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.fromLTRB(0, 8, 5, 8),
                                        color: content[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
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
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: blue, width: 4))),
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
                      if (debtIn['cash'].length > 0 || debtIn['terminal'].toString().isNotEmpty || client != '') {
                        Navigator.pop(context, client);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      primary: debtIn['cash'].length > 0 || debtIn['cash'].length > 0 && client != null ? blue : lightGrey,
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
