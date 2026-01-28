import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easy_localization/easy_localization.dart';

import 'helper.dart';

const hostUrl = "https://cabinet.mdokon.uz";

GetStorage storage = GetStorage();

BaseOptions options = BaseOptions(
  baseUrl: hostUrl,
  receiveDataWhenStatusError: true,
  connectTimeout: const Duration(seconds: 5),
  // receiveTimeout: const Duration(seconds: 20),
);
var dio = Dio(options);

checkToken() async {
  if (storage.read('lastLogin') != null) {
    var lastLogin = (storage.read('lastLogin'));
    if (minutesBetween(lastLogin, DateTime.now()) >= 55) {
      final response = await post(
        '/auth/login',
        {
          "username": storage.read('user')['username'],
          "password": storage.read('user')['password'],
        },
        isGuest: true,
      );
      if (response != null) {
        var lastLogin = {
          'year': DateTime.now().year,
          'month': DateTime.now().month,
          'day': DateTime.now().day,
          'hour': DateTime.now().hour,
          'minute': DateTime.now().minute,
        };
        storage.write('access_token', response['access_token'].toString());
        storage.write('lastLogin', (lastLogin));
        return true;
      }
    }
  }
}

Future get(String url, {payload, isGuest = false}) async {
  try {
    if (storage.read('access_token') != null && !isGuest) {
      await checkToken();
      dio.options.headers["authorization"] = "Bearer ${storage.read('access_token')}";
      dio.options.headers["Accept"] = "application/json";
    } else {
      dio.options.headers["authorization"] = "";
    }
    print(hostUrl + url);
    final response = await dio.get(
      hostUrl + url,
      queryParameters: payload,
    );
    return response.data;
  } catch (e) {
    statuscheker(e);
  }
  return false;
}

Future pget(String url, {payload, isGuest = false}) async {
  try {
    if (storage.read('access_token') != null && !isGuest) {
      await checkToken();
      dio.options.headers["authorization"] = "Bearer ${storage.read('access_token')}";
      dio.options.headers["Accept"] = "application/json";
    } else {
      dio.options.headers["authorization"] = "";
    }
    print(hostUrl + url);
    print(payload);
    final response = await dio.get(
      hostUrl + url,
      queryParameters: payload,
    );
    print(response);
    return {
      'data': response.data,
      'total': int.parse(response.headers.value('x-total-count').toString()),
    };
  } catch (e) {
    statuscheker(e);
  }
  return false;
}

Future post(String url, dynamic payload, {isGuest = false}) async {
  try {
    if (storage.read('access_token') != null && !isGuest) {
      await checkToken();
      dio.options.headers["authorization"] = "Bearer ${storage.read('access_token')}";
      dio.options.headers["Accept"] = "application/json";
    } else {
      dio.options.headers["authorization"] = "";
    }
    final response = await dio.post(
      hostUrl + url,
      data: payload,
    );
    return response.data;
  } catch (e) {
    statuscheker(e);
  }
  return false;
}

Future put(String url, dynamic payload) async {
  // print(payload);
  // controller.showLoading;
  try {
    if (storage.read('access_token') != null) {
      dio.options.headers["authorization"] = "Bearer ${storage.read('access_token')}";
      dio.options.headers["Accept"] = "application/json";
    }
    final response = await dio.put(
      hostUrl + url,
      data: payload,
    );
    return response.data;
  } catch (e) {
    statuscheker(e);
  }
  return false;
}

bool httpOk(response) {
  if (response != null && response != false && response != {} && response != "") {
    return true;
  }
  return false;
}

statuscheker(e) async {
  print(e);
  if (e.response != null && e.response.statusCode != null) {
    log(jsonEncode(e.response.toString()));

    switch (e.response.statusCode) {
      case 400:
        final message = jsonDecode(e.response.toString());
        if (message['message'] == 'error.validation') {
          showDangerToast('error.validation', description: message['fieldErrors']);
        } else {
          showDangerToast(message['message']);
        }
        break;
      case 401:
        showDangerToast(tr('Неправильный логин или пароль'));
        break;
      case 403:
        showDangerToast(tr('Нет доступа'));
        break;
      case 404:
        showDangerToast(tr('Не найдено'));
        break;
      case 415:
        showDangerToast(tr('error'));
        break;
      case 500:
        showDangerToast(e.message);
        break;
      default:
    }
  } else {
    showDangerToast(tr('error'));
  }
}

Future lPost(String url, dynamic payload) async {
  try {
    dio.options.headers["authorization"] = "";
    final response = await dio.post(
      'https://cabinet.cashbek.uz' + url,
      data: payload,
    );
    return response.data;
  } catch (e) {
    print(e);
    statuscheker(e);
  }
}
