import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class FilterModel extends ChangeNotifier {
  GetStorage storage = GetStorage();
  Map<String, dynamic> filterDataCopy = {};
  Map<String, dynamic> filterData = {};

  Map<String, dynamic> get currentFilterData => filterData;
  String get posId => storage.read('user')['posId'].toString();
  // String get currencyId => storage.read('user')['posId'].toString();

  void initFilterData(Map<String, dynamic> payload) {
    print(storage.read('user'));
    filterData = payload;
    filterDataCopy = Map.from(payload);
    notifyListeners();
  }

  void setFilterData(String key, dynamic value) {
    filterData[key] = value;
    notifyListeners();
  }

  void resetFilterData() {
    print(filterDataCopy);
    filterData = filterDataCopy;
    notifyListeners();
  }
}
