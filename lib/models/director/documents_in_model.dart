import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class DocumentsInModel extends ChangeNotifier {
  GetStorage storage = GetStorage();
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
}
