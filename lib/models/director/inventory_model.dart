import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/filter_model.dart';
import 'package:kassa/models/loading_model.dart';
import 'package:provider/provider.dart';

class InventoryModel extends ChangeNotifier {
  GetStorage storage = GetStorage();
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocus = FocusNode();
  Timer? debounce; // Timer для дебаунса

  Map data = {
    "productList": [],
    "posId": 0,
  };

  List pageList = [];
  int totalCount = 0;

  Map get currentItem => data;

  Future<void> redirect(BuildContext context, id) async {
    final response = await get('/services/web/api/inventory/$id');
    if (httpOk(response)) {
      data = response;
      context.go('/director/inventory/create');
    }
    notifyListeners();
  }

  setDataValue(String key, dynamic value) {
    data[key] = value;
    notifyListeners();
  }

  setProductListValue(int index, String key, dynamic value) {
    data['productList'][index][key] = value;
    data['productList'][index]['controller'].text = value.toString();
    notifyListeners();
  }

  void clearData() {
    data = {
      "productList": [],
      "posId": 0,
    };
    notifyListeners();
  }

  Future<void> save(BuildContext context) async {
    Provider.of<LoadingModel>(context, listen: false).showLoader(num: 2);

    if (await checkData(context)) {
      var sendData = Map.from(data);

      for (var i = 0; i < sendData['productList'].length; i++) {
        sendData['productList'][i]['controller'] = '';
        sendData['productList'][i]['focus'] = '';
      }

      var response = {};
      if (data['id'] != null) {
        response = await put('/services/web/api/inventory-completed', sendData);
      } else {
        response = await post('/services/web/api/inventory-completed', sendData);
      }
      if (httpOk(response)) {
        data = {
          "productList": [],
          "posId": storage.read('user')['posId'],
        };
        await getPageList(context);
        context.go('/director/inventory');
      }
      notifyListeners();
    }
    Provider.of<LoadingModel>(context, listen: false).hideLoader();
  }

  Future<void> saveToDraft(BuildContext context) async {
    Provider.of<LoadingModel>(context, listen: false).showLoader(num: 2);

    if (await checkData(context)) {
      var sendData = Map.from(data);

      for (var i = 0; i < sendData['productList'].length; i++) {
        sendData['productList'][i]['controller'] = '';
        sendData['productList'][i]['focus'] = '';
      }

      var response = {};
      if (data['id'] != null) {
        response = await put('/services/web/api/inventory', sendData);
      } else {
        response = await post('/services/web/api/inventory', sendData);
      }
      if (httpOk(response)) {
        data = {
          "productList": [],
          "posId": storage.read('user')['posId'],
        };
        await getPageList(context);
        context.go('/director/inventory');
      }
      notifyListeners();
    }
    Provider.of<LoadingModel>(context, listen: false).hideLoader();
  }

  Future<bool> checkData(BuildContext context) async {
    bool error = false;
    for (var i = 0; i < data['productList'].length; i++) {
      var item = data['productList'][i];
      if (item['actualBalance'] == null || item['actualBalance'] == '' || double.parse(item['actualBalance'].toString()) <= 0) {
        error = true;
      }
      if (!error) {
        item['differenceAmount'] =
            (double.parse(item['actualBalance'].toString()) - double.parse(item['balance'].toString())) * double.parse(item['price'].toString());
        item['divergence'] = double.parse(item['actualBalance'].toString()) - double.parse(item['balance'].toString());
      }
    }
    if (error) {
      showDangerToast('Проверьте заполненные поля');
    }
    return !error;
  }

  Future<void> search(String barcode) async {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () async {
      print({
        'name': barcode,
        'posId': data['posId'],
        'categoryList': [],
        'barcode': true,
      });
      List response = await post('/services/web/api/product-inventory-list', {
        'name': barcode,
        'posId': data['posId'],
        'categoryList': [],
        'barcode': true,
      });
      print(response);
      if (httpOk(response)) {
        if (response.length == 1) {
          var newProduct = response[0];
          var existingProduct = data['productList'].firstWhere(
            (product) => product['productId'] == newProduct['productId'],
            orElse: () => null,
          );

          if (existingProduct != null) {
            showWarningToast('Продукт уже добавлен');
          }

          newProduct['vat'] = data['defaultVat'];
          newProduct['controller'] = TextEditingController();
          newProduct['focus'] = FocusNode();
          data['productList'].insert(0, newProduct);
          Timer(Duration(milliseconds: 300), () {
            data['productList'][0]['focus'].requestFocus();
          });
        }
      } else {
        data['productList'] = [];
      }
      searchFocus.requestFocus();
      searchController.text = '';
      notifyListeners();
    });
  }

  void removeProduct(int index) {
    data['productList'].removeAt(index);
    notifyListeners(); // Уведомляем слушателей об изменении
  }

  Future<void> getPageList(BuildContext context) async {
    Provider.of<LoadingModel>(context, listen: false).showLoader();
    FilterModel filterModel = Provider.of<FilterModel>(context, listen: false);
    final response = await pget(
      '/services/web/api/inventory-pageList/${filterModel.currentFilterData['posId']}',
      payload: filterModel.currentFilterData,
    );
    if (context.mounted) {
      if (httpOk(response)) {
        pageList = response['data'];
        totalCount = response['total'];
      }
      Provider.of<LoadingModel>(context, listen: false).hideLoader();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }
}
