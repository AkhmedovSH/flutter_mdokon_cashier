import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/data_model.dart';
import 'package:kassa/models/loading_model.dart';
import 'package:provider/provider.dart';

class DocumentsInModel extends ChangeNotifier {
  GetStorage storage = GetStorage();
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocus = FocusNode();
  TextEditingController paidAmountController = TextEditingController();
  Timer? debounce; // Timer для дебаунса

  Map data = {
    "productList": [],
    "posId": 0,
    "productCategoryId": '',
    "paymentTypeId": '1',
    "walletId": '',
    "bankId": '',
    "paid": 1,
    "based": '',
    "organizationId": '',
    "currencyId": 1,
    "currencyName": '',
    "productSerial": false,
    "importExcel": false,
    "wholesalePriceMarkup": 0,
    "bankPriceMarkup": 0,
    "salePriceMarkup": 0,
    "defaultVat": 0,
    "totalAmount": 0,
    "expense": '',
    "totalQuantity": 0,
    "totalIncome": 0,
    "totalSale": 0,
  };

  Map get currentItem => data;

  setDataValue(String key, dynamic value) {
    data[key] = value;
    notifyListeners();
  }

  setProductListValue(int index, String key, dynamic value) {
    data['productList'][index][key] = value;
    data['productList'][index]['controller'].text = value.toString();
    countTotalAmount();
  }

  setPaidAmount(String key, dynamic value) {
    data[key] = value;
    paidAmountController.text = value.toString();
    notifyListeners();
  }

  clearControllers() {
    for (var i = 0; i < data['productList'].length; i++) {
      data['productList'][i]['controller'] = null;
      data['productList'][i]['focus'] = null;
    }
  }

  Future<void> saveToDraft(BuildContext context) async {
    Provider.of<LoadingModel>(context, listen: false).showLoader(num: 2);

    clearControllers();
    var sendData = Map.from(data);

    var response = {};
    // Provider.of<LoadingModel>(context, listen: false).hideLoader();
    // return;
    if (data['id'] != null) {
      response = await put('/services/web/api/documents-in-draft', sendData);
    } else {
      response = await post('/services/web/api/documents-in-draft', sendData);
    }
    if (httpOk(response)) {
      data = {
        "productList": [],
        "posId": 0,
        "productCategoryId": '',
        "paymentTypeId": '1',
        "walletId": '',
        "bankId": '',
        "paid": 1,
        "based": '',
        "organizationId": '',
        "currencyId": 1,
        "currencyName": '',
        "productSerial": false,
        "importExcel": false,
        "wholesalePriceMarkup": 0,
        "bankPriceMarkup": 0,
        "salePriceMarkup": 0,
        "defaultVat": 0,
        "totalAmount": 0,
        "expense": '',
        "totalQuantity": 0,
        "totalIncome": 0,
        "totalSale": 0,
      };
      context.go('/director/documents-in');
    }
    notifyListeners();

    Provider.of<LoadingModel>(context, listen: false).hideLoader();
  }

  Future<void> save(BuildContext context) async {
    Provider.of<LoadingModel>(context, listen: false).showLoader(num: 2);

    clearControllers();
    var sendData = Map.from(data);
    sendData['totalAmount'] = sendData['totalIncome'];

    final response = await post('/services/web/api/documents-in', sendData);
    if (httpOk(response)) {
      data = {
        "productList": [],
        "posId": 0,
        "productCategoryId": '',
        "paymentTypeId": '1',
        "walletId": '',
        "bankId": '',
        "paid": 1,
        "based": '',
        "organizationId": '',
        "currencyId": 1,
        "currencyName": '',
        "productSerial": false,
        "importExcel": false,
        "wholesalePriceMarkup": 0,
        "bankPriceMarkup": 0,
        "salePriceMarkup": 0,
        "defaultVat": 0,
        "totalAmount": 0,
        "expense": '',
        "totalQuantity": 0,
        "totalIncome": 0,
        "totalSale": 0,
      };
      context.go('/director/documents-in');
    }

    Provider.of<LoadingModel>(context, listen: false).hideLoader();
    notifyListeners();
  }

  Future<bool> checkData(BuildContext context) async {
    bool error = false;
    for (var i = 0; i < data['productList'].length; i++) {
      var item = data['productList'][i];
      print(item['quantity']);
      if (item['quantity'] == null || item['quantity'] == '' || double.parse(item['quantity'].toString()) <= 0) {
        error = true;
      }
      if (item['price'] != null && item['price'] <= 0) {
        error = true;
      }
    }
    if (!error) {
      final dataModel = Provider.of<DataModel>(context, listen: false);

      await Future.wait([
        dataModel.fetchBanks(data['currencyId']),
        dataModel.fetchWallets(data['currencyId']),
      ]);
      context.go('/director/documents-in/create/complete');
    } else {
      showDangerToast('Проверьте заполненные поля');
    }
    notifyListeners();
    return !error;
  }

  countTotalAmount() {
    double temporaryTotalQuantity = 0;
    double temporaryTotalIncome = 0;
    double temporaryTotalSale = 0;
    for (var i = 0; i < data['productList'].length; i++) {
      var item = data['productList'][i];
      if (item['price'] != null && double.parse(item['price'].toString()) > 0 && item['quantity'] != null && item['quantity'] != '') {
        data['productList'][i]['totalAmount'] = double.parse((item['quantity']).toString()) * double.parse(item['price'].toString());
        temporaryTotalQuantity += double.parse(item['quantity'].toString());
        temporaryTotalIncome += double.parse(item['price'].toString()) * double.parse(item['quantity'].toString());
        temporaryTotalSale += double.parse(item['salePrice'].toString()) * double.parse(item['quantity'].toString());
      }
    }
    data['totalQuantity'] = temporaryTotalQuantity;
    data['totalIncome'] = temporaryTotalIncome;
    data['totalAmount'] = temporaryTotalIncome;
    data['totalSale'] = temporaryTotalSale;
    notifyListeners();
  }

  Future<void> search(String barcode) async {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () async {
      List response = await get('/services/web/api/product-in-helper', payload: {
        'name': barcode,
        'posId': data['posId'],
        'currencyId': data['currencyId'],
      });
      if (httpOk(response)) {
        if (response.length == 1) {
          var newProduct = response[0];
          var existingProduct = data['productList'].firstWhere(
            (product) => product['productId'] == newProduct['productId'],
            orElse: () => null,
          );

          if (existingProduct != null) {
            newProduct['vat'] = data['defaultVat'];
            newProduct['controller'] = TextEditingController();
            newProduct['focus'] = FocusNode();
            data['productList'].add(newProduct);
            Timer(Duration(milliseconds: 300), () {
              data['productList'][data['productList'].length - 1]['focus'].requestFocus();
            });
            // if (existingProduct['quantity'] != null) {
            //   existingProduct['quantity'] = 1;
            // } else {
            //   existingProduct['quantity'] += 1;
            // }
            // showDangerToast('Продукт уже добавлен');
          } else {
            // newProduct['focusNode'] = FocusNode();
            newProduct['vat'] = data['defaultVat'];
            newProduct['controller'] = TextEditingController();
            newProduct['focus'] = FocusNode();
            data['productList'].add(newProduct);
            Timer(Duration(milliseconds: 300), () {
              data['productList'][data['productList'].length - 1]['focus'].requestFocus();
            });
          }
        }
      } else {
        data['productList'] = [];
      }
      searchController.text = '';
      countTotalAmount();
    });
  }

  void removeProduct(int index) {
    data['productList'].removeAt(index);
    countTotalAmount(); // Обновляем общую сумму после удаления продукта
    notifyListeners(); // Уведомляем слушателей об изменении
  }

  Future<void> getData(context, id) async {
    Provider.of<LoadingModel>(context, listen: false).showLoader(num: 2);

    final response = await get('/services/web/api/documents-in/$id');
    if (httpOk(response)) {
      response['productList'] = response['productList']['content'];
      for (var i = 0; i < response['productList'].length; i++) {
        response['productList'][i]['name'] = response['productList'][i]['productName'];
        response['productList'][i]['controller'] = TextEditingController(text: response['productList'][i]['quantity'].round().toString());
        response['productList'][i]['focus'] = FocusNode();
      }
      if (response['walletId'] == 0) {
        response['walletId'] = '';
      }
      if (response['bankId'] == 0) {
        response['bankId'] = '';
      }
      data = response;
      countTotalAmount();
    }
    Provider.of<LoadingModel>(context, listen: false).hideLoader();
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
