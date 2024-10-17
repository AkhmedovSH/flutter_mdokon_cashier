import 'package:flutter/material.dart';

class DataModel extends ChangeNotifier {
  Map item = {};

  List<Map<String, dynamic>> accountTypes = [
    {'id': '', 'name': '-'},
    {'id': 1, 'name': ('safe')},
    {'id': 2, 'name': ('bank_account')},
  ];
  List<Map<String, dynamic>> expenseTypes = [
    {'id': '', 'name': '-'},
    {'id': 'id', 'name': ('safe')},
    {'id': 'shift_id', 'name': ('cashbox')},
    {'id': 'document_in_id', 'name': ('good_reception')},
    {'id': 'expense_id', 'name': ('expense')},
    {'id': 'employee_payment_id', 'name': ('salary')},
    {'id': 'supplier_payment_id', 'name': ('supplier')},
    {'id': 'organization_payment_id', 'name': ('organization')},
  ];

  List<Map<String, dynamic>> poses = [];
  List<Map<String, dynamic>> paymentPurposeTypes = [];
  List<Map<String, dynamic>> cashiers = [];
  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> months = [];
  List<Map<String, dynamic>> elementTypes = [];
  List<Map<String, dynamic>> waiters = [];
  List<Map<String, dynamic>> menu = [];

  int get firstPosId => poses[0]['id'];

  void setItem(Map payload) {
    item = payload;
    notifyListeners();
  }

  void setPoses(List<Map<String, dynamic>> payload) {
    poses = payload;
    notifyListeners();
  }

  void setMonths(List<Map<String, dynamic>> payload) {
    months = payload;
    notifyListeners();
  }

  void setPaymentPurposeTypes(List<Map<String, dynamic>> payload) {
    payload.insert(0, {'id': '', 'name': '-'});

    paymentPurposeTypes = payload;
    notifyListeners();
  }

  void setCashiers(List<Map<String, dynamic>> payload) {
    payload.insert(0, {'login': '', 'first_name': '-'});
    cashiers = payload;
    notifyListeners();
  }

  void setSuppliers(List<Map<String, dynamic>> payload) {
    payload.insert(0, {'id': '', 'name': '-'});
    suppliers = payload;
    notifyListeners();
  }

  void setElementTypes(List<Map<String, dynamic>> payload) {
    payload.insert(0, {'id': '', 'name': '-'});
    elementTypes = payload;
    notifyListeners();
  }

  void setWaiters(List<Map<String, dynamic>> payload) {
    payload.insert(0, {'login': '', 'first_name': '-'});
    waiters = payload;
    notifyListeners();
  }

  void setMenu(List<Map<String, dynamic>> payload) {
    payload.insert(0, {'id': '', 'name': '-'});
    menu = payload;
    notifyListeners();
  }
}
