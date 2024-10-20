import 'package:flutter/material.dart';

class DataModel extends ChangeNotifier {
  Map item = {};

  List<Map<String, dynamic>> productList = [];

  Map get currentItem => item;
  List<Map<String, dynamic>> get currentProductList => productList;

  void setItem(Map payload) {
    item = payload;
    notifyListeners();
  }

  void setProductList(List<Map<String, dynamic>> payload) {
    productList = payload;
    notifyListeners();
  }
}
