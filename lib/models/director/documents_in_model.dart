import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kassa/helpers/api.dart';

class DocumentsInModel extends ChangeNotifier {
  GetStorage storage = GetStorage();
  TextEditingController searchController = TextEditingController();
  Timer? debounce; // Timer для дебаунса

  Map data = {
    "productList": const [],
    "posId": 0,
    "productCategoryId": '',
    "paymentTypeId": 1,
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
  };

  Map get currentItem => data;

  setDataValue(String key, dynamic value) {
    data[key] = value;
    notifyListeners();
  }

  setProductListValue(int index, String key, dynamic value) {
    data['productList'][index][key] = value;
    countTotalAmount();
  }

  countTotalAmount() {
    notifyListeners();
  }

  Future<void> search(String barcode) async {
    debounce?.cancel();

    // Устанавливаем новый таймер с задержкой в 500 миллисекунд
    debounce = Timer(const Duration(milliseconds: 500), () async {
      List response = await get('/services/web/api/product-in-helper', payload: {
        'name': barcode,
        'posId': data['posId'],
        'currencyId': data['currencyId'],
      });
      print(httpOk(response));
      print(response);
      if (httpOk(response)) {
        if (response.length == 1) {
          data['productList'].add(response[0]);
        }
      } else {
        data['productList'] = [];
      }
      searchController.text = '';
      countTotalAmount();
    });
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
