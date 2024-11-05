import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/data_model.dart';
import 'package:kassa/models/loading_model.dart';
import 'package:provider/provider.dart';

class InventoryModel extends ChangeNotifier {
  GetStorage storage = GetStorage();
  TextEditingController searchController = TextEditingController();
  Timer? debounce; // Timer для дебаунса

  Map data = {
    "productList": [],
    "posId": 0,
  };

  Map get currentItem => data;

  setDataValue(String key, dynamic value) {
    data[key] = value;
    notifyListeners();
  }

  setProductListValue(int index, String key, dynamic value) {
    data['productList'][index][key] = value;
    notifyListeners();
  }

  Future<void> save(BuildContext context) async {
    Provider.of<LoadingModel>(context, listen: false).showLoader(num: 2);

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

  Future<void> checkData(BuildContext context) async {
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
  }

  Future<void> search(String barcode) async {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () async {
      List response = await post('/services/web/api/product-inventory-list', {
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
            // if (existingProduct['quantity'] != null) {
            //   existingProduct['quantity'] = 1;
            // } else {
            //   existingProduct['quantity'] += 1;
            // }
            showDangerToast('Продукт уже добавлен');
          } else {
            // newProduct['focusNode'] = FocusNode();
            newProduct['vat'] = data['defaultVat'];
            data['productList'].add(newProduct);
          }
        }
      } else {
        data['productList'] = [];
      }
      searchController.text = '';
      notifyListeners();
    });
  }

  void removeProduct(int index) {
    data['productList'].removeAt(index);
    notifyListeners(); // Уведомляем слушателей об изменении
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
