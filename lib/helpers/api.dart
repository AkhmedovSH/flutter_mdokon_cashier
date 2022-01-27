import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

const hostUrl = "https://cabinet.mdokon.uz";
var dio = Dio();

checkToken() async {

}

Future get(String url, {payload}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  print(hostUrl + url);
  try {
    final response = await dio.get(hostUrl + url,
        queryParameters: payload,
        options: Options(headers: {
          "authorization": "Bearer ${prefs.getString('access_token')}",
        }));
    print(response.data);
    return response.data;
  } on DioError catch (e) {
    print(e.response?.statusCode);
    return statuscheker(e, url, payload: payload);
  }
}

Future post(String url, dynamic payload) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  print(payload);
  try {
    
    final response = await dio.post(hostUrl + url,
        data: payload,
        options: Options(headers: {
          "authorization": "Bearer ${prefs.getString('access_token')}",
        }));
      print(200);
    return response.data;
  } on DioError catch (e) {
    print(e.response?.statusCode);
    print(e.response?.data);
    if (e.response?.statusCode == 400) {
      return;
    }
  }
}

Future guestPost(String url, dynamic payload) async {
  try {
    final response = await dio.post(hostUrl + url, data: payload);
    return response.data;
  } on DioError catch (e) {
    if (e.response?.statusCode == 400) {
      print(e.response?.statusCode);
      return;
    }
    if (e.response?.statusCode == 401) {
      print(e.response?.statusCode);
    }
  }
}

statuscheker(e, url, {payload}) async {
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
      await getAccessPos(url, payload);
    }
  }
}

getAccessPos(url, payload) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final response = await get('/services/desktop/api/get-access-pos');
  if (response['openShift']) {
    prefs.remove('shift');
    prefs.setString('cashbox', jsonEncode(response['shift']));
    get(url, payload: payload);
  } else {
    Get.offAllNamed('/cashboxes', arguments: response['posList']);
  }
}
