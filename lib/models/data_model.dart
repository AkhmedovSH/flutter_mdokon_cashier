import 'package:flutter/material.dart';
import 'package:kassa/helpers/api.dart';

class DataModel extends ChangeNotifier {
  Map item = {};

  List<Map<String, dynamic>> productList = [];
  List<Map<String, dynamic>> poses = [];
  List<Map<String, dynamic>> organizations = [];
  List<Map<String, dynamic>> currencies = [
    {"id": 1, "name": "So`m"},
    {"id": 2, "name": "USD"},
  ];

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

  Future<void> getData() async {
    await Future.wait([
      fetchPoses(),
      fetchOrganizations(),
    ]);
    notifyListeners();
  }

  Future<void> fetchPoses() async {
    final response = await get('/services/web/api/pos-helper');
    final List<Map<String, dynamic>> mapList = List<Map<String, dynamic>>.from(response);
    poses = mapList;
  }

  Future<void> fetchOrganizations() async {
    final response = await get('/services/web/api/organization-helper');
    final List<Map<String, dynamic>> mapList = List<Map<String, dynamic>>.from(response);
    organizations = mapList;
  }
}
