import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';
import 'package:unicons/unicons.dart';

class AgentIndex extends StatefulWidget {
  const AgentIndex({Key? key}) : super(key: key);

  @override
  _AgentIndexState createState() => _AgentIndexState();
}

// class ProductWithParamsUnit {
//   final String packaging;
//   final String piece;
//   final double quantity;
//   final double totalPrice;
//   const ProductWithParamsUnit(this.packaging, this.piece, this.quantity, this.totalPrice);
// }

class _AgentIndexState extends State<AgentIndex> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  dynamic shortcutController = TextEditingController();
  dynamic shortcutFocusNode = FocusNode();
  dynamic packagingController = TextEditingController();
  dynamic pieceController = TextEditingController();

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

  dynamic productWithParams = {
    "selectedUnit": {"name": "", "quantity": ""},
    "modificationList": [],
    'unitList': [],
  };

  dynamic productWithParamsUnit = {
    "packaging": "",
    "piece": "",
    "quantity": "0",
    "totalPrice": "0",
  };

  dynamic cashbox = {};
  dynamic clients = [];
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
  dynamic shortCutList = ["+", "-", "*", "/", "%", "%-"];

  bool isEdit = false;

  sendToCashbox() async {
    var sendData = {
      'posId': cashbox['posId'],
      'cheque': jsonEncode(data),
    };
    if (isEdit) {
      sendData['id'] = data['id'];
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
    final cashbox = jsonDecode(storage.read('cashbox')!);
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
      showDangerToast('discount_has_been_applied'.tr);
      return;
    }
    final products = await Get.toNamed('/search', arguments: {'activePrice': data['activePrice']});
    print(products);
    if (products == null) {
      // showErrorToast('Ошибка при добавлении продуктов');
      return;
    }
    for (var i = 0; i < products.length; i++) {
      if (products[i] != null) {
        var product = Map.from(products[i]);
        product['discount'] = 0;
        product['outType'] = false;

        if (data['activePrice'] == 1) {
          product['wholesale'] = true;
        } else {
          product['wholesale'] = false;
        }

        if (product['unitList'].length > 0) {
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
              showDangerToast('limit_exceeded'.tr);
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
            showDangerToast('wrong_quantity'.tr);
            shortcutController.text = "";
            FocusManager.instance.primaryFocus?.unfocus();
            return;
          } else {
            if (!cashbox['saleMinus'] && (double.parse(inputData) > productsCopy[i]['balance'])) {
              showDangerToast('limit_exceeded'.tr);
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
            showDangerToast('sale_price_cannot_be_lower_than_receipt_price'.tr);
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
            showDangerToast('wrong_quantity'.tr);
            shortcutController.text = "";
          } else {
            if (!cashbox['saleMinus'] && (double.parse(inputData) / productsCopy[i]['salePrice'] > productsCopy[i]['balance'])) {
              showDangerToast('limit_exceeded'.tr);
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
    setState(() {
      cashbox = jsonDecode(storage.read('cashbox')!);
    });
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

  @override
  void initState() {
    super.initState();
    getCashbox();
    if (Get.arguments != null && Get.arguments['cheque'] != null) {
      setState(() {
        isEdit = true;
        data = jsonDecode(Get.arguments['cheque']);
        data['id'] = Get.arguments['id'];
      });
    }
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
          statusBarColor: mainColor, // Status bar
        ),
        bottomOpacity: 0.0,
        centerTitle: false,
        title: Text(
          'sale'.tr,
          style: TextStyle(color: white),
        ),
        backgroundColor: mainColor,
        elevation: 0,
        actions: [
          if (data['itemsList'].length > 0)
            SizedBox(
              child: IconButton(
                onPressed: () {
                  if (data["itemsList"].length > 0) {
                    openConfirmModal();
                  }
                },
                icon: Icon(UniconsLine.trash_alt),
              ),
            ),
          SizedBox(
            child: Tooltip(
              message: 'wholesale_price'.tr,
              child: Checkbox(
                activeColor: mainColor,
                checkColor: white,
                focusColor: white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                side: MaterialStateBorderSide.resolveWith(
                  (states) => BorderSide(width: 2.0, color: white),
                ),
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
                Get.isDarkMode
                    ? SvgPicture.asset(
                        'images/icons/scanner_dark.svg',
                        height: 350,
                      )
                    : SvgPicture.asset(
                        'images/icons/scanner.svg',
                        height: 350,
                      ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'scan_barcode_from_product_packaging_or_enter_it_manually'.tr,
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
                              hintText: 'enter_value'.tr,
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
                        Text('total'.tr, style: TextStyle(fontSize: 16)),
                        data['discount'] == 0
                            ? Text(formatMoney(data['totalPrice']) + ' Сум', style: TextStyle(fontSize: 16))
                            : Text(formatMoney(data['totalPriceBeforeDiscount']) + ' Сум', style: TextStyle(fontSize: 16)),
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
                          'discount'.tr,
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
                                    '0,00 ${'sum'.tr}',
                                    style: TextStyle(fontSize: 16),
                                  )
                                : Text(
                                    formatMoney(
                                            double.parse(data['totalPriceBeforeDiscount'].toString()) - double.parse(data['totalPrice'].toString())) +
                                        'sum'.tr,
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
                        Text('to_pay'.tr, style: TextStyle(fontSize: 16)),
                        Text(
                          formatMoney(data['totalPrice']) + ' Сум',
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
                              icon: Icons.delete,
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
                                      style: TextStyle(fontSize: 16, color: Get.isDarkMode ? white : black),
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
                                    '${formatMoney(data["itemsList"][i]['totalPrice'])}So\'m',
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
          Container(
            margin: EdgeInsets.only(left: 32),
            width: MediaQuery.of(context).size.width * 0.5,
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
              child: Text('send_to_cashbox'.tr),
            ),
          ),
          FloatingActionButton(
            backgroundColor: data['discount'] == 0 ? mainColor : lightGrey,
            onPressed: () {
              redirectToSearch();
            },
            child: const Icon(Icons.add, size: 28),
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
                'are_you_sure_you_want_to_remove_all_products'.tr,
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
                      child: Text('cancel'.tr),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        deleteAllProducts();
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('continue'.tr),
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

  showDeleteDialog() {
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
                    backgroundColor: red,
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.33,
                child: ElevatedButton(
                  onPressed: () {
                    deleteAllProducts(type: true);
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
                        hintText: '0',
                        hintStyle: TextStyle(color: a2),
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
                        hintText: '0',
                        hintStyle: TextStyle(color: a2),
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
                    backgroundColor: (packagingController.text != "" || pieceController.text != "") ? blue : lightGrey,
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
}
