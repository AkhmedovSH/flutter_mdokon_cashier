import 'package:flutter/material.dart';

class FilterModel extends ChangeNotifier {
  Map<String, dynamic> filterDataCopy = {};
  Map<String, dynamic> filterData = {};

  Map<String, dynamic> get currentFilterData => filterData;

  void initFilterData(Map<String, dynamic> payload) {
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
