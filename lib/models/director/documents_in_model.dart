import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class DocumentsInModel extends ChangeNotifier {
  GetStorage storage = GetStorage();
  Data data = Data();

  Data get currentItem => data;
}

class Data {
  List<Map<String, dynamic>> productList;
  int? posId;
  int? productCategoryId;
  int paymentTypeId;
  String walletId;
  String bankId;
  int paid;
  int? based;
  int? organizationId;
  int currencyId;
  String currencyName;
  bool productSerial;
  bool importExcel;
  double wholesalePriceMarkup;
  double bankPriceMarkup;
  double salePriceMarkup;
  double defaultVat;
  double totalAmount;
  String expense;

  Data({
    this.productList = const [],
    this.posId,
    this.productCategoryId,
    this.paymentTypeId = 1,
    this.walletId = '',
    this.bankId = '',
    this.paid = 1,
    this.based,
    this.organizationId,
    this.currencyId = 1,
    this.currencyName = '',
    this.productSerial = false,
    this.importExcel = false,
    this.wholesalePriceMarkup = 0,
    this.bankPriceMarkup = 0,
    this.salePriceMarkup = 0,
    this.defaultVat = 0,
    this.totalAmount = 0,
    this.expense = '',
  });
}
