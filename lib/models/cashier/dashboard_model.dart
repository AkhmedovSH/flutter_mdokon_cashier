import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardModel extends ChangeNotifier {
  int currentIndex = 0;

  Map returnCheque = {};

  void setCurrentIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void setCurrentCheque(Map cheque) {
    returnCheque = cheque;
  }

  Future<void> closeApp() async {
    SystemNavigator.pop();
  }
}
