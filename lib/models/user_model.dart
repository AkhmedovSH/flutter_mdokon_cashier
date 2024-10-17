import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class UserModel extends ChangeNotifier {
  GetStorage storage = GetStorage();
  Map _user = {};

  UserModel(this._user);

  Map get user => _user;

  void setUser(Map payload) {
    _user = payload;
    storage.write('user', payload);
    storage.write('token', payload['token']);
    notifyListeners();
  }
}
