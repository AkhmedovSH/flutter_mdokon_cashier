import 'package:flutter/material.dart';

class LoaderModel extends ChangeNotifier {
  int loading = 0;

  int get currentLoading => loading;

  void showLoader({int num = 1}) {
    loading = num;
    notifyListeners();
  }

  void hideLoader() {
    loading = 0;
    notifyListeners();
  }
}
