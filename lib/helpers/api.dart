import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easy_localization/easy_localization.dart';

import 'helper.dart';

const hostUrl = "https://cabinet.mdokon.uz";

GetStorage storage = GetStorage();

BaseOptions options = BaseOptions(
  baseUrl: hostUrl,
  receiveDataWhenStatusError: true,
  connectTimeout: const Duration(seconds: 20),
  receiveTimeout: const Duration(seconds: 20),
);
var dio = Dio(options);

Future get(String url, {payload}) async {
  try {
    if (storage.read('token') != null) {
      dio.options.headers["authorization"] = "Bearer ${storage.read('token')}";
      dio.options.headers["Accept"] = "application/json";
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

Future post(String url, dynamic payload) async {
  // print(payload);
  // controller.showLoading;
  try {
    if (storage.read('token') != null) {
      dio.options.headers["authorization"] = "Bearer ${storage.read('token')}";
      dio.options.headers["Accept"] = "application/json";
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
    if (storage.read('token') != null) {
      dio.options.headers["authorization"] = "Bearer ${storage.read('token')}";
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

bool httpOk(data) {
  if (data != null && data != false && data != {} && data != "") {
    return true;
  }
  return false;
}

statuscheker(e) async {
  print(e);
  if (e.response != null && e.response.statusCode != null) {
    switch (e.response.statusCode) {
      case 400:
        final message = jsonDecode(e.response.toString());
        showDangerToast(message['message']);
        break;
      case 401:
        showDangerToast(tr('Неправильный логин или пароль'));
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
    if (storage.read('access_token') != null) {
      dio.options.headers["authorization"] = "";
      dio.options.headers["Accept"] = "application/json";
    }
    final response = await dio.post(
      'https://cabinet.cashbek.uz' + url,
      data: payload,
    );
    return response.data;
  } catch (e) {
    statuscheker(e);
  }
}