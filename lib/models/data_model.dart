import 'package:flutter/material.dart';
import 'package:kassa/helpers/api.dart';

class DataModel extends ChangeNotifier {
  Map item = {};

  List<Map<String, dynamic>> productList = [];
  List<Map<String, dynamic>> poses = [];
  List<Map<String, dynamic>> organizations = [];
  List<Map<String, dynamic>> paymentTypes = [];
  List<Map<String, dynamic>> uoms = [];
  List<Map<String, dynamic>> cashiers = [];
  List<Map<String, dynamic>> agents = [];
  List<Map<String, dynamic>> wallets = [];
  List<Map<String, dynamic>> banks = [];
  List<Map<String, dynamic>> currencies = [
    {"id": 1, "name": "So`m"},
    {"id": 2, "name": "USD"},
  ];
  List<Map<String, dynamic>> seasons = [
    {'id': '', 'name': '-'},
    {'id': 1, 'name': ('seasonal')},
    {'id': 2, 'name': ('not_seasonal')}
  ];

  String get posId => storage.read('user')['posId'].toString();
  Map get currentItem => item;
  List<Map<String, dynamic>> get currentProductList => productList;

  void setItem(Map payload) {
    item = payload;
    notifyListeners();
  }

  void setProductList(List<Map<String, dynamic>> payload) {
    productList = payload;
    notifyListeners();
  }

  Future<void> getData() async {
    await Future.wait([
      fetchPoses(),
      fetchOrganizations(),
      fetchPaymentTypes(),
      fetchProductUoms(),
      fetchCashiers(),
      fetchAgents(),
    ]);
    notifyListeners();
  }

  Future<void> fetchPoses() async {
    final response = await get('/services/web/api/pos-helper');
    final List<Map<String, dynamic>> mapList = List<Map<String, dynamic>>.from(response);
    poses = mapList;
  }

  Future<void> fetchOrganizations() async {
    final response = await get('/services/web/api/organization-helper');
    final List<Map<String, dynamic>> mapList = List<Map<String, dynamic>>.from(response);
    mapList.insert(0, {'id': '', 'name': '-'});
    organizations = mapList;
  }

  Future<void> fetchPaymentTypes() async {
    final response = await get('/services/web/api/product-uom-helper');
    final List<Map<String, dynamic>> mapList = List<Map<String, dynamic>>.from(response);
    mapList.insert(0, {'id': '', 'name': '-'});
    paymentTypes = mapList;
  }

  Future<void> fetchProductUoms() async {
    final response = await get('/services/web/api/organization-helper');
    final List<Map<String, dynamic>> mapList = List<Map<String, dynamic>>.from(response);
    mapList.insert(0, {'id': '', 'name': '-'});
    uoms = mapList;
  }

  Future<void> fetchCashiers() async {
    final response = await get('/services/web/api/cashier-helper');
    final List<Map<String, dynamic>> mapList = List<Map<String, dynamic>>.from(response);
    mapList.insert(0, {'id': '', 'name': '-'});
    cashiers = mapList;
  }

  Future<void> fetchAgents() async {
    final response = await get('/services/web/api/agent-helper');
    final List<Map<String, dynamic>> mapList = List<Map<String, dynamic>>.from(response);
    mapList.insert(0, {'id': '', 'name': '-'});
    agents = mapList;
  }

  Future<void> fetchWallets(currencyId) async {
    final response = await get('/services/web/api/wallet-helper', payload: {'currencyId': currencyId});
    final List<Map<String, dynamic>> mapList = List<Map<String, dynamic>>.from(response);
    mapList.insert(0, {'walletId': '', 'walletName': '-'});
    print(mapList);
    wallets = mapList;
  }

  Future<void> fetchBanks(currencyId) async {
    final response = await get('/services/web/api/bank-helper', payload: {'currencyId': currencyId});
    final List<Map<String, dynamic>> mapList = List<Map<String, dynamic>>.from(response);
    mapList.insert(0, {'bankId': '', 'bankName': '-'});
    print(mapList);
    banks = mapList;
  }
}
