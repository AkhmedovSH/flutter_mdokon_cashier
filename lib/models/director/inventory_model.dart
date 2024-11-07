import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/loading_model.dart';
import 'package:provider/provider.dart';

class InventoryModel extends ChangeNotifier {
  GetStorage storage = GetStorage();
  TextEditingController searchController = TextEditingController();
  Timer? debounce; // Timer для дебаунса

  Map data = {
    "productList": [],
    "posId": 0,
  };

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
    notifyListeners();
  }

  Future<void> save(BuildContext context) async {
    Provider.of<LoadingModel>(context, listen: false).showLoader(num: 2);

    if (await checkData(context)) {
      var sendData = Map.from(data);

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
      List response = await post('/services/web/api/product-inventory-list', {
        'name': barcode,
        'posId': data['posId'],
        'currencyId': data['currencyId'],
      });
      if (httpOk(response)) {
        if (response.length == 1) {
          var newProduct = response[0];
          var existingProduct = data['productList'].firstWhere(
            (product) => product['productId'] == newProduct['productId'],
            orElse: () => null,
          );

          if (existingProduct != null) {
            // if (existingProduct['quantity'] != null) {
            //   existingProduct['quantity'] = 1;
            // } else {
            //   existingProduct['quantity'] += 1;
            // }
            showDangerToast('Продукт уже добавлен');
          } else {
            // newProduct['focusNode'] = FocusNode();
            newProduct['vat'] = data['defaultVat'];
            data['productList'].add(newProduct);
          }
        }
      } else {
        data['productList'] = [];
      }
      searchController.text = '';
      notifyListeners();
    });
  }

  void removeProduct(int index) {
    data['productList'].removeAt(index);
    notifyListeners(); // Уведомляем слушателей об изменении
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
