import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './controller.dart';

const hostUrl = "https://cabinet.mdokon.uz";
BaseOptions options = BaseOptions(
  baseUrl: hostUrl,
  receiveDataWhenStatusError: true,
  connectTimeout: 10 * 1000, // 10 seconds
  receiveTimeout: 10 * 1000, // 10 seconds
);
var dio = Dio(options);

final Controller controller = Get.put(Controller());

Future get(String url, {payload, loading = true, setState}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (loading) {
    controller.showLoading;
  }
  //print(hostUrl + url);
  try {
    final response = await dio.get(hostUrl + url,
        queryParameters: payload,
        options: Options(headers: {
          "authorization": "Bearer ${prefs.getString('access_token')}",
        }));
    //print(response.data);
    if (loading) {
      controller.hideLoading;
    }
    return response.data;
  } on DioError catch (e) {
    //print(e.response?.statusCode);
    return await statuscheker(e, url, payload: payload);
  }
}

Future post(String url, dynamic payload) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // print(payload);
  controller.showLoading;
  try {
    //print(hostUrl + url);
    final response = await dio.post(hostUrl + url,
        data: payload,
        options: Options(headers: {
          "authorization": "Bearer ${prefs.getString('access_token')}",
        }));
    print(200);
    controller.hideLoading;
    return response.data;
  } on DioError catch (e) {
    //print(e.response?.statusCode);
    //print(e.response?.data);
    if (e.response?.statusCode == 400) {
      return;
    }
  }
}

Future guestPost(String url, dynamic payload, {loading = true}) async {
  try {
    if (loading) {
      controller.showLoading;
    }
    final response = await dio.post(hostUrl + url, data: payload);
    if (loading) {
      controller.hideLoading;
    }
    // Get.snackbar('Успешно', 'Операция выполнена успешно');
    return response.data;
  } on DioError catch (e) {
    if (e.response?.statusCode == 400) {
      //print(e.response?.statusCode);
      return;
    }
    if (e.response?.statusCode == 401) {
      //print(e.response?.statusCode);
    }
  }
}

statuscheker(e, url, {payload, method = 'get'}) async {
  if (e.response?.statusCode == 401) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final data = await guestPost('/auth/login', {
      'username': prefs.getString('username'),
      'password': prefs.getString('password'),
    });
    prefs.setString('access_token', data['access_token']);

    final account = await get('/services/uaa/api/account');
    var checker = false;
    for (var i = 0; i < account['authorities'].length; i++) {
      if (account['authorities'][i] == "ROLE_CASHIER") {
        checker = true;
      }
    }
    if (checker == true) {
      prefs.setString('user_roles', account['authorities'].toString());
      return await getAccessPos(url, payload, method: method);
    }
  }
}

getAccessPos(url, payload, {method}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final response = await get('/services/desktop/api/get-access-pos');
  if (response['openShift']) {
    prefs.remove('shift');
    prefs.setString('cashbox', jsonEncode(response['shift']));
    if (method == 'get') {
      return await get(url, payload: payload);
    }
    if (method == 'post') {
      return await post(url, payload);
    }
  } else {
    Get.offAllNamed('/cashboxes', arguments: response['posList']);
  }
}

Future lPost(String url, dynamic payload) async {
  controller.showLoading;
  try {
    final response = await dio.post(
      'https://cabinet.cashbek.uz' + url,
      data: payload,
    );
    //print(response);
    controller.hideLoading;
    return response.data;
  } on DioError catch (e) {
    //print(e.response?.statusCode);
    //print(e.response?.data);
    if (e.response?.statusCode == 401) {
      return;
    }
  }
}
