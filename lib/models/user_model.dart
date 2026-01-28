import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class UserModel extends ChangeNotifier {
  GetStorage storage = GetStorage();
  Map _user = {};
  Map _cashbox = {};
  List paymentTypes = [];

  UserModel(this._user, this._cashbox, this.paymentTypes);

  Map get user => _user;
  Map get cashbox => _cashbox;

  void setUser(Map payload) {
    log(payload.toString());
    _user = payload;
    storage.write('user', payload);
    notifyListeners();
  }

  void setCashbox(Map payload) {
    _cashbox = payload;
    storage.write('cashbox', payload);
    notifyListeners();
  }

  void setPaymentTypes(List payload) {
    paymentTypes = payload;
    storage.write('paymentTypes', payload);
    notifyListeners();
  }
}
