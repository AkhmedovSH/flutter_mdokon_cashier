import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

class UserModel extends ChangeNotifier {
  GetStorage storage = GetStorage();
  String _route = '/';

  String get route => _route;

  void navigate(BuildContext context, String payload) {
    _route = payload;
    storage.write('route', payload);
    context.go(payload);
    notifyListeners();
  }
}
