import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:go_router/go_router.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/data_model.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class Index extends StatefulWidget {
  const Index({Key? key}) : super(key: key);

  @override
  _IndexState createState() => _IndexState();
}

// class ProductWithParamsUnit {
//   final String packaging;
//   final String piece;
//   final double quantity;
//   final double totalPrice;
//   const ProductWithParamsUnit(this.packaging, this.piece, this.quantity, this.totalPrice);
// }

class _IndexState extends State<Index> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GetStorage storage = GetStorage();

  TextEditingController shortcutController = TextEditingController();
  FocusNode shortcutFocusNode = FocusNode();
  TextEditingController textController = TextEditingController();
  TextEditingController textController2 = TextEditingController();
  TextEditingController packagingController = TextEditingController();
  TextEditingController pieceController = TextEditingController();

  Map<String, dynamic> data = {
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
    "currencyName": "So'm",
    "currencyRate": 0,
    "discount": 0,
    "discountAmount": 0,
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
    "transactionsList": [],
    "activePrice": 0,
  };

  Map productWithParams = {
    "selectedUnit": {"name": "", "quantity": ""},
    "modificationList": [],
    'unitList': [],
  };

  Map productWithParamsUnit = {
    "packaging": "",
    "piece": "",
    "quantity": "0",
    "totalPrice": "0",
  };

  Map cashbox = {};
  List clients = [];
  List expenses = [];
  Map expenseOut = {
    "cashboxId": '',
    "posId": '',
    "shiftId": '',
    'note': '',
    'amountOut': '',
    'expenseId': '',
  };
  Map debtIn = {
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
  List itemList = [
    {
      'label': 'cash',
      'icon': Icons.payments,
      'fieldName': 'cash',
    },
    {
      'label': 'terminal',
      'icon': Icons.payment,
      'fieldName': 'terminal',
    },
    {
      'label': 'note',
      'fieldName': 'note',
    },
  ];
  List shortCutList = ["+", "-", "*", "s", "/", "%", "%-"];

  dynamic subscription;

  bool isDeviceConnected = false;
  bool isEdit = false;

  sendToCashbox() async {
    var dataCopy = {...data};
    if (dataCopy['currencyId'] == "") {
      dataCopy['currencyId'] = cashbox['defaultCurrency'];
    }
    var sendData = {
      'posId': cashbox['posId'],
      'cheque': jsonEncode(dataCopy),
    };
    if (isEdit) {
      sendData['id'] = dataCopy['id'];
    }

    Map? response;
    if (isEdit) {
      response = await put('/services/desktop/api/cheque-online', sendData);
    } else {
      response = await post('/services/desktop/api/cheque-online', sendData);
    }
    if (response != null && response['success']) {
      deleteAllProducts();
    }
  }

  getClients() async {
    final cashbox = (storage.read('cashbox')!);
    final response = await get('/services/desktop/api/client-debt-list/${cashbox['posId']}');
    //print(response);
    for (var i = 0; i < response.length; i++) {
      response[i]['selected'] = false;
    }
    setState(() {
      clients = response;
      debtIn['cashboxId'] = cashbox['cashboxId'];
      debtIn['posId'] = cashbox['posId'];
      if (storage.read('shift') != null) {
        debtIn['shiftId'] = jsonDecode(storage.read('shift')!)['id'];
      } else {
        debtIn['shiftId'] = cashbox['id'];
      }
    });
  }

  redirectToSearch() async {
    if (data['discount'] > 0) {
      showDangerToast(context.tr('discount_has_been_applied'));
      return;
    }
    await context.push('/cashier/search', extra: {
      'activePrice': data['activePrice'],
      'currencyId': data['currencyId'],
      'currencyName': data['currencyName'],
    });
    List<Map<String, dynamic>> products = Provider.of<DataModel>(context, listen: false).currentProductList;
    Provider.of<DataModel>(context, listen: false).setProductList([]);
    if (products.isEmpty) {
      // showErrorToast('Ошибка при добавлении продуктов');
      return;
    }
    for (var i = 0; i < products.length; i++) {
      var product = Map.from(products[i]);
      print(product);
      product['discount'] = 0;
      product['outType'] = false;

      if (data['activePrice'] == 1) {
        product['wholesale'] = true;
      } else {
        product['wholesale'] = false;
      }

      if (product['unitList'] != null && product['unitList'].length > 0) {
        setState(() {
          productWithParams = product;
          productWithParams['quantity'] = "";
          productWithParams['totalPrice'] = "";
          productWithParams['selectedUnit'] = product['unitList'][0];
        });
        showProductsWithParams();
        return;
      }
      var existSameProduct = false;
      dynamic productsCopy = data["itemsList"];
      for (var i = 0; i < productsCopy.length; i++) {
        if (productsCopy[i]['productId'] == product['productId']) {
          existSameProduct = true;

          if (productsCopy[i]['quantity'] >= productsCopy[i]['balance'] && !cashbox['saleMinus']) {
            showDangerToast(context.tr('limit_exceeded'));
            return;
          }
          addToList(product);
        }
      }

      if (!existSameProduct) {
        addToList(product);
      }
    }
  }

  addToList(response, {weight = 0, unit = false}) {
    dynamic dataCopy = data;
    dataCopy['totalPrice'] = 0;
    dynamic index = dataCopy['itemsList'].indexWhere((e) => e['balanceId'] == response['balanceId']);
    if (index == -1) {
      if (!response.containsKey('quantity')) {
        // response['quantity'] = 1;
        if (weight != 0) {
          response['quantity'] = weight;
        }
      }
      response['selected'] = false;
      response['totalPrice'] = 0;
      response['originalSalePrice'] = response['salePrice'];
      dataCopy['itemsList'].add(response);

      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        dataCopy['itemsList'][i]['selected'] = false;
      }
      dataCopy['itemsList'][dataCopy['itemsList'].length - 1]['selected'] = true;

      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        if (dataCopy['itemsList'][i]['wholesale'] == true) {
          dataCopy['itemsList'][i]['salePrice'] = double.parse(dataCopy['itemsList'][i]['wholesalePrice'].toString());
          dataCopy['totalPrice'] +=
              double.parse(dataCopy['itemsList'][i]['wholesalePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
          dataCopy['itemsList'][i]['totalPrice'] =
              double.parse(dataCopy['itemsList'][i]['wholesalePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
        } else {
          dataCopy['totalPrice'] +=
              double.parse(dataCopy['itemsList'][i]['salePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
          dataCopy['itemsList'][i]['totalPrice'] =
              double.parse(dataCopy['itemsList'][i]['salePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
        }
      }
    } else {
      print(response['quantity']);
      if (response['quantity'] != "") {
        // if scaleProduct
        if (weight > 0) {
          dataCopy['itemsList'][index]['quantity'] =
              double.parse(dataCopy['itemsList'][index]['quantity'].toString()) + double.parse(weight.toString());
        } else if (unit) {
          // not needed
          // dataCopy['itemsList'][index]['quantity'] = response['quantity']
        } else {
          dataCopy['itemsList'][index]['quantity'] = double.parse(response['quantity'].toString());
        }
      } else {
        dataCopy['itemsList'][index]['quantity'] = response['quantity'];
      }
      dataCopy['itemsList'][index]['discount'] = 0;
      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        if (dataCopy['itemsList'][i]['wholesale'] == true) {
          dataCopy['itemsList'][i]['wholesale'] = true;
          dataCopy['itemsList'][i]['salePrice'] = double.parse(dataCopy['itemsList'][i]['wholesalePrice'].toString());
          dataCopy['totalPrice'] +=
              double.parse(dataCopy['itemsList'][i]['wholesalePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
          dataCopy['itemsList'][i]['totalPrice'] =
              double.parse(dataCopy['itemsList'][i]['wholesalePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
        } else {
          dataCopy['itemsList'][i]['wholesale'] = false;
          dataCopy['totalPrice'] +=
              double.parse(dataCopy['itemsList'][i]['salePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
          dataCopy['itemsList'][i]['totalPrice'] =
              double.parse(dataCopy['itemsList'][i]['salePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
        }
      }
    }

    setState(() {
      data = dataCopy;
    });
    if (unit) {
      Navigator.pop(context);
    }
  }

  addToListUnit() {
    setState(() {
      productWithParams['quantity'] = productWithParamsUnit['quantity'];
    });
    addToList(productWithParams, unit: true);
  }

  deleteProduct(i) {
    if (data["itemsList"].length == 1) {
      print(111);
      deleteAllProducts();
      return;
    }
    double totalPrice = 0;
    double totalPriceBeforeDiscount = 0;

    dynamic productsCopy = data["itemsList"];
    productsCopy.removeAt(i);

    for (var i = 0; i < productsCopy.length; i++) {
      productsCopy[i]['totalPrice'] = productsCopy[i]['quantity'] * productsCopy[i]['salePrice'];
      if (productsCopy[i]['totalPriceOriginal'] != null) {
        totalPriceBeforeDiscount += double.parse(productsCopy[i]['totalPriceOriginal'].toString());
      } else {
        totalPriceBeforeDiscount += double.parse(productsCopy[i]['totalPrice'].toString());
      }
      totalPrice += productsCopy[i]['totalPrice'];
    }
    data['discount'] = 100 - (totalPrice * 100 / totalPriceBeforeDiscount);
    data["itemsList"] = productsCopy;
    data['totalPriceBeforeDiscount'] = totalPriceBeforeDiscount;
    data['totalPrice'] = totalPrice;
    setState(() {});
  }

  deleteAllProducts({type = false}) {
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
      "currencyId": data['currencyId'],
      "currencyName": data['currencyName'] == 1 ? 'So\'m' : 'USD',
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
      "transactionsList": [],
      "activePrice": data['activePrice'],
    };
    setState(() {});
    if (type) {
      Navigator.pop(context);
    }
  }

  handleShortCut(type) {
    if (shortcutController.text.isEmpty && type != "/") return;
    dynamic productsCopy = data["itemsList"];
    var inputData = shortcutController.text;
    var isFloat = '.'.allMatches(inputData).isEmpty ? false : true;

    if (type == "+") {
      for (var i = 0; i < productsCopy.length; i++) {
        if (productsCopy[i]['selected']) {
          // Штучные товары нельзя вводить дробным числом
          if (isFloat && productsCopy[i]['uomId'] == 1) {
            showDangerToast(context.tr('wrong_quantity'));
            shortcutController.text = "";
            FocusManager.instance.primaryFocus?.unfocus();
            return;
          } else {
            if (!cashbox['saleMinus'] && (double.parse(inputData) > productsCopy[i]['balance'])) {
              showDangerToast(context.tr('limit_exceeded'));
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
            showDangerToast(context.tr('sale_price_cannot_be_lower_than_receipt_price'));
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
            showDangerToast(context.tr('wrong_quantity'));
            shortcutController.text = "";
          } else {
            if (!cashbox['saleMinus'] && (double.parse(inputData) / productsCopy[i]['salePrice'] > productsCopy[i]['balance'])) {
              showDangerToast(context.tr('limit_exceeded'));
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
          setState(() {
            productWithParams = productsCopy[i];
            productWithParams['quantity'] = "";
            productWithParams['totalPrice'] = "";
            productWithParams['selectedUnit'] = productsCopy[i]['unitList'][0];
          });
          showProductsWithParams();
          return;
        }
      }
    }

    if (type == "%") {
      calculateDiscount("%", inputData);
      shortcutController.text = "";
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    if (type == "s") {
      calculateDiscount("s", inputData);
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
    if (key != 's') {
      if (dataCopy['discount'] > 0) {
        dataCopy['discount'] = 0;
        dataCopy['totalPrice'] = double.parse(dataCopy['totalPriceBeforeDiscount'].toString());
        dataCopy['totalPriceBeforeDiscount'] = 0;
        for (var i = 0; i < dataCopy["itemsList"].length; i++) {
          dataCopy["itemsList"][i]['discount'] = 0;
          dataCopy["itemsList"][i]['totalPrice'] =
              double.parse(dataCopy["itemsList"][i]['salePrice'].toString()) * double.parse(dataCopy["itemsList"][i]['quantity'].toString());
        }
      }
    }

    if (key == "%") {
      dataCopy['discountAmount'] = value;
      dataCopy['totalPrice'] = 0;
      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        dataCopy['totalPrice'] +=
            double.parse(dataCopy['itemsList'][i]['salePrice'].toString()) * double.parse(dataCopy['itemsList'][i]['quantity'].toString());
        dataCopy['itemsList'][i]['discountAmount'] = value;
        dataCopy['itemsList'][i]['totalPrice'] = dataCopy['itemsList'][i]['totalPrice'] - value;
      }
      dataCopy['totalPriceBeforeDiscount'] = dataCopy['totalPrice'];
      dataCopy['discount'] = double.parse(value.toString()) * 100 / dataCopy['totalPriceBeforeDiscount'];
      dataCopy['totalPrice'] = dataCopy['totalPrice'] - (dataCopy['totalPrice'] * dataCopy['discount']) / 100;
    }
    if (key == "s") {
      dataCopy['totalPrice'] = 0;
      dataCopy['totalPriceBeforeDiscount'] = 0;
      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        if (dataCopy['itemsList'][i]['selected']) {
          if (dataCopy['itemsList'][i]['discount'] == 0) {
            dataCopy['itemsList'][i]['totalPriceOriginal'] = dataCopy['itemsList'][i]['totalPrice'];
            dataCopy['itemsList'][i]['totalPrice'] = (dataCopy['itemsList'][i]['totalPrice'] - value);
          } else {
            dataCopy['itemsList'][i]['totalPrice'] = (dataCopy['itemsList'][i]['totalPriceOriginal'] - value);
          }
          dataCopy['itemsList'][i]['discount'] = (100 / (dataCopy['itemsList'][i]['totalPriceOriginal'] / value));
        }

        if (dataCopy['itemsList'][i]['totalPriceOriginal'] != null) {
          dataCopy['totalPriceBeforeDiscount'] += double.parse(dataCopy['itemsList'][i]['totalPriceOriginal'].toString());
        } else {
          dataCopy['totalPriceBeforeDiscount'] += double.parse(dataCopy['itemsList'][i]['totalPrice'].toString());
        }
        dataCopy['totalPrice'] += double.parse(dataCopy['itemsList'][i]['totalPrice'].toString());

        print(dataCopy['itemsList'][i]['totalPrice']);
      }
      dynamic percent = 100 - (dataCopy['totalPrice'] * 100 / dataCopy['totalPriceBeforeDiscount']);
      dataCopy['discount'] = percent;
      dataCopy['discountAmount'] = double.parse(data['totalPriceBeforeDiscount'].toString()) - double.parse(data['totalPrice'].toString());
    }

    if (key == "%-") {
      dataCopy['discountAmount'] = value;
      dynamic percent = 100 / (dataCopy['totalPrice'] / value);
      dataCopy['discount'] = percent;
      dataCopy['totalPriceBeforeDiscount'] = dataCopy['totalPrice'];
      dataCopy['totalPrice'] = dataCopy['totalPriceBeforeDiscount'] - (dataCopy['totalPrice'] * percent) / 100;

      for (var i = 0; i < dataCopy['itemsList'].length; i++) {
        dataCopy['itemsList'][i]['discount'] = percent;
        dataCopy['itemsList'][i]['totalPrice'] = dataCopy['itemsList'][i]['totalPrice'] - ((dataCopy['itemsList'][i]['totalPrice'] * percent) / 100);
      }
    }

    data = dataCopy;
    setState(() {});
  }

  calculateProductWithParamsUnit(Function setDialogState) {
    //debugger();
    dynamic quantity = 0;
    dynamic totalPrice = 0;

    dynamic packaging = packagingController.text.isEmpty ? 0 : double.parse(packagingController.text);
    dynamic piece = pieceController.text.isEmpty ? 0 : double.parse(pieceController.text);

    dynamic salePrice = double.parse(productWithParams['salePrice'].toString());
    dynamic selectedUnitQuantity = double.parse(productWithParams['selectedUnit']['quantity'].toString());

    if (packaging == 0 && piece == 0) {
      setDialogState(() {
        productWithParamsUnit['packaging'] = "";
        productWithParamsUnit['piece'] = "";
        productWithParamsUnit['quantity'] = "0";
        productWithParamsUnit['totalPrice'] = "0";
      });
      return;
    }

    if (packaging > 0 && piece == 0) {
      quantity = packaging;
      totalPrice = salePrice * packaging;
      setDialogState(() {
        productWithParamsUnit['quantity'] = quantity.toString();
        productWithParamsUnit['totalPrice'] = totalPrice.toString();
      });
      return;
    }

    if (piece != 0 && piece > selectedUnitQuantity) {
      setDialogState(() {
        productWithParamsUnit['piece'] = "";
      });
      return;
    }

    if (packaging > 0 && piece > 0) {
      if (piece == selectedUnitQuantity) {
        quantity = packaging + 1;
        totalPrice = salePrice * packaging + 1;
        setDialogState(() {
          productWithParamsUnit['quantity'] = quantity.toString();
          productWithParamsUnit['totalPrice'] = totalPrice.toString();
        });
      } else {
        quantity = packaging + piece / selectedUnitQuantity;
        totalPrice = salePrice * quantity;
        setDialogState(() {
          productWithParamsUnit['quantity'] = quantity.toString();
          productWithParamsUnit['totalPrice'] = totalPrice.toString();
        });
      }
      return;
    }

    if (packaging == 0 && piece > 0) {
      quantity = piece / selectedUnitQuantity;
      totalPrice = salePrice * quantity;
      setDialogState(() {
        productWithParamsUnit['quantity'] = quantity.toString();
        productWithParamsUnit['totalPrice'] = totalPrice.toString();
      });
      return;
    }
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
    cashbox = storage.read('cashbox');
    data['currencyId'] = cashbox['defaultCurrency'];
    data['currencyName'] = cashbox['defaultCurrency'] == 1 ? 'So\'m' : 'USD';
    print(data);
    setState(() {});
  }

  selectDebtorClient(Function setDebtorState, index) {
    dynamic clientsCopy = clients;
    for (var i = 0; i < clientsCopy.length; i++) {
      clientsCopy[i]['selected'] = false;
    }
    clientsCopy[index]['selected'] = true;
    setDebtorState(() {
      clients = clientsCopy;
      debtIn['clientId'] = clientsCopy[index]['clientId'];
      debtIn['currencyId'] = clientsCopy[index]['currencyId'];
      debtIn['currencyName'] = clientsCopy[index]['currencyName'];
    });
  }

  getExpenses() async {
    final response = await get('/services/desktop/api/expense-helper');
    if (response != null) {
      setState(() {
        expenses = response;
        expenseOut['expenseId'] = response[0]['id'].toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getCashbox();
    getExpenses();
    // if (Get.arguments != null && Get.arguments['cheque'] != null) {
    //   setState(() {
    //     isEdit = true;
    //     data = jsonDecode(Get.arguments['cheque']);
    //     data['id'] = Get.arguments['id'];
    //   });
    // }
  }

  buildTextField(label, icon, item, index, setDialogState, {scrollPadding, enabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
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
              enabledBorder: inputBorder,
              focusedBorder: inputFocusBorder,
              errorBorder: inputErrorBorder,
              focusedErrorBorder: inputErrorBorder,
              suffixIcon: Icon(icon),
              focusColor: mainColor,
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
          statusBarColor: mainColor, // Status bar
        ),
        bottomOpacity: 0.0,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              context.tr('sale'),
              style: TextStyle(color: white),
            ),
            SizedBox(width: 10),
            SizedBox(
              width: 55,
              height: 32,
              child: ElevatedButton(
                onPressed: data['itemsList'].length == 0
                    ? () {
                        if (data['currencyId'] == 1) {
                          data['currencyId'] = 2;
                          data['currencyName'] = 'USD';
                        } else {
                          data['currencyId'] = 1;
                          data['currencyName'] = 'So\'m';
                        }
                        setState(() {});
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: white,
                  foregroundColor: mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '${data['currencyName']}',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: mainColor,
        elevation: 0,
        actions: [
          // SizedBox(
          //   child: IconButton(
          //     onPressed: () {},
          //     tooltip: 'Подключение к интернету',
          //     icon: Icon(isDeviceConnected ? UniconsLine.wifi : UniconsLine.wifi_slash),
          //   ),
          // ),
          if (cashbox['isAgent'] != true)
            SizedBox(
              child: IconButton(
                onPressed: () {
                  showModalDebtor();
                },
                tooltip: context.tr('amortization'),
                icon: Icon(
                  UniconsLine.credit_card,
                  color: white,
                ),
              ),
            ),
          if (cashbox['isAgent'] != true)
            SizedBox(
              child: IconButton(
                onPressed: () {
                  showModalExpense();
                },
                tooltip: context.tr('expenses'),
                icon: Icon(
                  UniconsLine.usd_circle,
                  color: white,
                ),
              ),
            ),
          if (cashbox['isAgent'] == true)
            SizedBox(
              child: IconButton(
                onPressed: () {
                  showSelectUserDialog();
                },
                tooltip: context.tr('Выбрать клиента'),
                icon: Icon(
                  UniconsLine.user,
                  size: 22,
                ),
              ),
            ),
          if (cashbox['isAgent'] == true)
            SizedBox(
              child: IconButton(
                onPressed: () {
                  showCreateUserModal();
                },
                tooltip: context.tr('Создать клиента'),
                icon: Icon(
                  UniconsLine.user_plus,
                  color: white,
                ),
              ),
            ),
          if (data['itemsList'].length > 0)
            SizedBox(
              child: IconButton(
                onPressed: () {
                  if (data["itemsList"].length > 0) {
                    openConfirmModal();
                  }
                },
                icon: Icon(
                  UniconsLine.trash_alt,
                  color: white,
                ),
              ),
            ),
          SizedBox(
            child: Tooltip(
              message: context.tr('wholesale_price'),
              child: Checkbox(
                activeColor: mainColor,
                checkColor: white,
                focusColor: white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                // side: MaterialStateBorderSide.resolveWith(
                //   (states) => BorderSide(width: 2.0, color: white),
                // ),
                value: data['activePrice'] == 1,
                onChanged: data['itemsList'].length == 0
                    ? (value) {
                        if (data['activePrice'] == 1) {
                          data['activePrice'] = 0;
                        } else {
                          data['activePrice'] = 1;
                        }
                        setState(() {});
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: data["itemsList"].length == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'images/icons/scanner_dark.svg',
                  height: 350,
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      context.tr('scan_barcode_from_product_packaging_or_enter_it_manually'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: 100),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 10),
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
                              alignment: Alignment.center,
                              height: 50,
                              decoration: BoxDecoration(
                                color: mainColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                  SizedBox(height: 15),
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
                              contentPadding: const EdgeInsets.all(12),
                              isDense: true,
                              border: inputBorder,
                              enabledBorder: inputBorder,
                              focusedBorder: inputFocusBorder,
                              hintText: context.tr('enter_value'),
                              hintStyle: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr('total'), style: TextStyle(fontSize: 16)),
                        data['discount'] == 0
                            ? Text(formatMoney(data['totalPrice']) + ' ${data['currencyName']}', style: TextStyle(fontSize: 16))
                            : Text(formatMoney(data['totalPriceBeforeDiscount']) + ' ${data['currencyName']}', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('discount'),
                          style: TextStyle(fontSize: 16),
                        ),
                        Wrap(
                          children: [
                            data['discount'] == 0
                                ? Text(
                                    '(0%)',
                                    style: TextStyle(fontSize: 16),
                                  )
                                : Text(
                                    '(' + formatMoney(data['discount']) + '%)',
                                    style: TextStyle(fontSize: 16),
                                  ),
                            SizedBox(width: 10),
                            data['discount'] == 0
                                ? Text(
                                    '0,00 ${context.tr('sum')}',
                                    style: TextStyle(fontSize: 16),
                                  )
                                : Text(
                                    formatMoney(
                                            double.parse(data['totalPriceBeforeDiscount'].toString()) - double.parse(data['totalPrice'].toString())) +
                                        context.tr('sum'),
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('to_pay'),
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          formatMoney(data['totalPrice']) + ' ${data['currencyName']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  for (var i = data["itemsList"].length - 1; i >= 0; i--)
                    InkWell(
                      onTap: () {
                        selectProduct(i);
                      },
                      onLongPress: () {},
                      // borderRadius: BorderRadius.circular(16),
                      highlightColor: mainColor.withOpacity(0.1),
                      splashColor: mainColor.withOpacity(0.5),
                      child: Slidable(
                        key: UniqueKey(),
                        closeOnScroll: false,
                        useTextDirection: false,
                        endActionPane: ActionPane(
                          motion: const StretchMotion(),
                          dismissible: DismissiblePane(
                            onDismissed: () {
                              deleteProduct(i);
                            },
                          ),
                          children: [
                            SlidableAction(
                              onPressed: (value) {
                                deleteProduct(i);
                              },
                              // borderRadius: BorderRadius.circular(24),
                              backgroundColor: const Color(0xFFFE4A49),
                              foregroundColor: Colors.white,
                              icon: UniconsLine.trash_alt,
                              padding: const EdgeInsets.all(12),
                            ),
                          ],
                        ),
                        child: Container(
                          // margin: const EdgeInsets.only(bottom: 10, right: 8, left: 8),
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: data["itemsList"][i]['selected'] ? mainColor : Color(0xFFF5F3F5),
                              ),
                              bottom: BorderSide(
                                color: data["itemsList"][i]['selected'] ? mainColor : Color(0xFFF5F3F5),
                              ),
                            ),
                            // borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                (i + 1).toString() + '. ' + data["itemsList"][i]['productName'],
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                              ),
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      text: '${formatMoney(data["itemsList"][i]['salePrice'])} x ${formatMoney(data["itemsList"][i]['quantity'])}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: CustomTheme.of(context).textColor,
                                      ),
                                      children: <TextSpan>[
                                        if (data["itemsList"][i]['discount'] > 0)
                                          TextSpan(
                                            text: '(${formatMoney(data["itemsList"][i]['discount'], decimalDigits: 0)}%)',
                                            style: TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${formatMoney(data["itemsList"][i]['totalPrice'])} ${data['currencyName']}',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: mainColor, fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 80)
                ],
              ),
            ),
      resizeToAvoidBottomInset: false,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          cashbox['isAgent'] == true
              ? Container(
                  margin: EdgeInsets.only(left: 32),
                  width: MediaQuery.of(context).size.width * 0.65,
                  child: ElevatedButton(
                    onPressed: data["itemsList"].length > 0
                        ? () {
                            sendToCashbox();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      backgroundColor: mainColor,
                      disabledBackgroundColor: disabledColor,
                      disabledForegroundColor: black,
                    ),
                    child: Text(context.tr('send_to_cashbox')),
                  ),
                )
              : Container(
                  margin: EdgeInsets.only(left: 32),
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: ElevatedButton(
                    onPressed: data["itemsList"].length > 0
                        ? () async {
                            dynamic result = await context.push('/cashier/payment', extra: data);
                            if (result == true) {
                              deleteAllProducts();
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      backgroundColor: mainColor,
                      disabledBackgroundColor: disabledColor,
                      disabledForegroundColor: black,
                    ),
                    child: Text(context.tr('sell')),
                  ),
                ),
          FloatingActionButton(
            backgroundColor: data['discount'] == 0 ? mainColor : lightGrey,
            onPressed: () {
              redirectToSearch();
            },
            child: Icon(
              Icons.add,
              size: 28,
              color: white,
            ),
          )
        ],
      ),
    );
  }

  openConfirmModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(24.0),
          ),
        ),
        title: const Text(''),
        titlePadding: const EdgeInsets.all(0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        actionsPadding: const EdgeInsets.all(0),
        buttonPadding: const EdgeInsets.all(0),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.21,
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(
                context.tr('are_you_sure_you_want_to_remove_all_products'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: danger,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(context.tr('cancel')),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        deleteAllProducts();
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(context.tr('continue')),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  bool loading = false;

  createDebtorOut(setState) async {
    setState(() {
      loading = true;
    });

    final cashbox = (storage.read('cashbox')!);
    setState(() {
      expenseOut['cashboxId'] = cashbox['cashboxId'].toString();
      expenseOut['posId'] = cashbox['posId'].toString();
      expenseOut['currencyId'] = cashbox['defaultCurrency'].toString();
      if (storage.read('shift') != null) {
        expenseOut['shiftId'] = jsonDecode(storage.read('shift')!)['id'];
      } else {
        expenseOut['shiftId'] = cashbox['id'].toString();
      }
    });
    final response = await post('/services/desktop/api/expense-out', expenseOut);
    if (response['success']) {
      Navigator.pop(context);
    }
    setState(() {
      loading = false;
    });
  }

  showModalExpense() async {
    await showDialog(
        context: context,
        useSafeArea: true,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(''),
              titlePadding: EdgeInsets.all(0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(24.0),
                ),
              ),
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
                      decoration: border,
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: false,
                          child: DropdownButton2(
                            value: expenseOut['expenseId'],
                            dropdownStyleData: DropdownStyleData(
                              decoration: BoxDecoration(
                                color: CustomTheme.of(context).cardColor,
                              ),
                              maxHeight: 400,
                            ),
                            underline: Container(),
                            isExpanded: true,
                            hint: Text('${expenses[0]['name']}'),
                            iconStyleData: IconStyleData(
                              icon: const Icon(UniconsLine.angle_down),
                              iconSize: 24,
                              iconEnabledColor: mainColor,
                            ),
                            onChanged: (newValue) {
                              setState(() {
                                expenseOut['expenseId'] = newValue;
                              });
                            },
                            items: expenses.map((item) {
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
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 5),
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
                          enabledBorder: inputBorder,
                          focusedBorder: inputFocusBorder,
                          errorBorder: inputErrorBorder,
                          focusedErrorBorder: inputErrorBorder,
                          suffixIcon: Icon(UniconsLine.credit_card),
                          focusColor: mainColor,
                          hintText: '0 сум',
                        ),
                      ),
                    ),
                    Text(
                      'Примечание',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 5),
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
                          enabledBorder: inputBorder,
                          focusedBorder: inputFocusBorder,
                          errorBorder: inputErrorBorder,
                          focusedErrorBorder: inputErrorBorder,
                          focusColor: mainColor,
                          hintText: 'Примечание',
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
                    onPressed: (expenseOut['amountOut'].length != 0 && !loading)
                        ? () {
                            if (expenseOut['amountOut'].length != 0) {
                              createDebtorOut(setState);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: mainColor,
                      disabledBackgroundColor: disabledColor,
                      disabledForegroundColor: black,
                    ),
                    child: Text('Принять'),
                  ),
                )
              ],
            );
          });
        });
  }

  createClientDebt(setState) async {
    setState(() {
      loading = true;
    });
    dynamic debtInCopy = Map.from(debtIn);

    final list = [];
    if (debtInCopy['cash'].length > 0) {
      list.add({"amountIn": double.parse(debtInCopy['cash']), "amountOut": "", "paymentTypeId": 1, "paymentPurposeId": 5});
      debtInCopy['amountIn'] += double.parse(debtInCopy['cash']);
    }
    if (debtInCopy['terminal'].length > 0) {
      list.add({"amountIn": double.parse(debtInCopy['terminal']), "amountOut": "", "paymentTypeId": 2, "paymentPurposeId": 5});
      debtInCopy['amountIn'] += double.parse(debtInCopy['terminal']);
    }
    debtInCopy['transactionsList'] = list;

    await post('/services/desktop/api/client-debt-in', debtInCopy);
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
    Navigator.pop(context);
    setState(() {
      loading = false;
    });
  }

  showModalDebtor() async {
    await getClients();
    var closed = await showDialog(
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
              insetPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              actionsPadding: EdgeInsets.all(0),
              buttonPadding: EdgeInsets.all(0),
              scrollable: true,
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: SingleChildScrollView(
                        child: Table(
                            border: TableBorder(horizontalInside: BorderSide(width: 1, color: tableBorderColor, style: BorderStyle.solid)),
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
                              for (var i = 0; i < clients.length; i++)
                                TableRow(children: [
                                  GestureDetector(
                                    onTap: () {
                                      selectDebtorClient(setState, i);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.fromLTRB(5, 8, 0, 8),
                                      color: clients[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
                                      child: Text(
                                        '${clients[i]['clientName']}',
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
                                      child: Text(
                                        clients[i]['currencyName'],
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      selectDebtorClient(setState, i);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.fromLTRB(0, 8, 5, 8),
                                      color: clients[i]['selected'] ? Color(0xFF91a0e7) : Colors.transparent,
                                      child: Text(
                                        '${formatMoney(clients[i]['balance'])}',
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ),
                                ]),
                            ]),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    for (var i = 0; i < itemList.length; i++)
                      buildTextField(
                        context.tr(itemList[i]['label']),
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
                    onPressed: (debtIn['clientId'] != 0 && (debtIn['cash'].length > 0 || debtIn['terminal'].length > 0) && !loading)
                        ? () {
                            if (debtIn['cash'].length > 0 || debtIn['terminal'].length > 0) {
                              createClientDebt(setState);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: mainColor,
                      disabledBackgroundColor: disabledColor,
                      disabledForegroundColor: black,
                    ),
                    child: Text('Принять'),
                  ),
                )
              ],
            );
          });
        });
    if (closed == null) {
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
  }

  showProductsWithParams() async {
    var closed = await showDialog(
      context: context,
      useSafeArea: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
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
                  Text(
                    'Кол во',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: MediaQuery.of(context).size.width,
                    child: TextFormField(
                      controller: packagingController,
                      onChanged: (value) {
                        calculateProductWithParamsUnit(setState);
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: mainColor,
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: mainColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: borderColor,
                        focusColor: mainColor,
                        hintText: '0',
                      ),
                    ),
                  ),
                  Text(
                    'Из упаковки',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: MediaQuery.of(context).size.width,
                    child: TextFormField(
                      controller: pieceController,
                      onChanged: (value) {
                        calculateProductWithParamsUnit(setState);
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: mainColor,
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: mainColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: borderColor,
                        focusColor: mainColor,
                        hintText: '0',
                      ),
                    ),
                  ),
                  Text('Наименование: ${productWithParams['productName']}'),
                  Text('В упаковке: ${formatMoney(productWithParams['selectedUnit']['quantity'])}'),
                  Text('Цена: ${formatMoney(productWithParams['salePrice'])}'),
                  Text('Кол-во: ${formatMoney(productWithParamsUnit['quantity'])}'),
                  Text('К оплате: ${formatMoney(productWithParamsUnit['totalPrice'])}'),
                  SizedBox(height: 10),
                ],
              ),
            ),
            actions: [
              Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.fromLTRB(10, 0, 10, 5),
                child: ElevatedButton(
                  onPressed: () {
                    if (packagingController.text != "" || pieceController.text != "") {
                      addToListUnit();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: (packagingController.text != "" || pieceController.text != "") ? mainColor : lightGrey,
                  ),
                  child: Text('Принять'),
                ),
              )
            ],
          );
        });
      },
    );
    if (closed == null) {
      packagingController.text = "";
      pieceController.text = "";
      setState(() {
        productWithParamsUnit = {
          "quantity": "",
          "totalPrice": "",
        };
      });
    }
  }

  Map sendData = {
    'comment': '',
    'name': '',
    'phone1': '',
    'phone2': '',
  };

  List addList = [
    {'name': 'contact_name', 'value': '', 'icon': UniconsLine.user, 'keyboardType': TextInputType.text},
    {'name': 'phone', 'value': '', 'icon': UniconsLine.phone, 'keyboardType': TextInputType.number},
    {'name': 'phone', 'value': '', 'icon': UniconsLine.phone, 'keyboardType': TextInputType.number},
    {'name': 'address', 'value': '', 'icon': UniconsLine.map, 'keyboardType': TextInputType.text},
    {'name': 'comment', 'value': '', 'icon': UniconsLine.comment_lines, 'keyboardType': TextInputType.text},
  ];

  createClient() async {
    final response = await post('/services/desktop/api/clients', sendData);
    if (response != null && response['success']) {
      context.pop();
      showSelectUserDialog();
    }
  }

  showCreateUserModal() {
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
                          Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text(
                              context.tr(addList[i]['name']),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
                            ),
                          ),
                          SizedBox(height: 5),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            width: MediaQuery.of(context).size.width,
                            child: TextFormField(
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return context.tr('required_field');
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
                                    sendData['address'] = value;
                                  });
                                }
                                if (i == 4) {
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
                    child: Text(context.tr('save')),
                  ),
                ),
              ],
            );
          });
        });
  }

  Timer? debounce;

  searchUsers(value, setState) {
    if (debounce?.isActive ?? false) debounce!.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () async {
      final response = await get('/services/desktop/api/clients-helper?search=$value');
      if (response != null) {
        for (var i = 0; i < response.length; i++) {
          response[i]['selected'] = false;
        }
        setState(() {
          clients = response;
        });
      }
    });
  }

  showSelectUserDialog() async {
    final response = await get('/services/desktop/api/clients-helper');
    //print(response);
    for (var i = 0; i < response.length; i++) {
      response[i]['selected'] = false;
    }
    setState(() {
      clients = response;
    });
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
                height: MediaQuery.of(context).size.height * 0.6,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 45,
                        child: TextField(
                          onChanged: (value) {
                            searchUsers(value, setState);
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(2),
                            isDense: true,
                            prefixIcon: Icon(
                              UniconsLine.search,
                              size: 18,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: borderColor),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(24),
                              ),
                            ),
                            hintText: context.tr('search'),
                            hintStyle: TextStyle(
                              color: lightGrey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(width: 1, color: tableBorderColor, style: BorderStyle.solid),
                        ),
                        children: [
                          TableRow(
                            children: [
                              Text(
                                context.tr('contact'),
                              ),
                              Text(
                                context.tr('number'),
                              ),
                              Text(
                                context.tr('comment'),
                              ),
                            ],
                          ),
                          for (var i = 0; i < clients.length; i++)
                            TableRow(
                              children: [
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
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
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
                    child: Text(context.tr('choose')),
                  ),
                )
              ],
            );
          });
        });
    if (result != null) {
      for (var i = 0; i < result.length; i++) {
        if (result[i]['selected'] == true) {
          data['clientName'] = result[i]['name'].toString();
          data['clientId'] = result[i]['id'].toString();
          data['clientComment'] = result[i]['comment'].toString();
          data['clientAddress'] = result[i]['address'].toString();
          data['clientPhone1'] = result[i]['phone1'].toString();
          data['clientPhone2'] = result[i]['phone2'].toString();
        }
      }
    }
  }
}
