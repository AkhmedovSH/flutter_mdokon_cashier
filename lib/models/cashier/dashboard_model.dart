import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardModel extends ChangeNotifier {
  int currentIndex = 0;

  Map returnCheque = {};

  setCurrentIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }

  setCurrentCheque(Map cheque) {
    returnCheque = cheque;
    notifyListeners();
  }

  closeApp() async {
    SystemNavigator.pop();
  }
}
