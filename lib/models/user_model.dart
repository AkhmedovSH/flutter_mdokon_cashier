import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class UserModel extends ChangeNotifier {
  GetStorage storage = GetStorage();
  Map _user = {};
  Map _cashbox = {};

  UserModel(this._user, this._cashbox);

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
}
