import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import './controller.dart';

const hostUrl = "https://cabinet.mdokon.uz";
BaseOptions options = BaseOptions(
  baseUrl: hostUrl,
  receiveDataWhenStatusError: true,
  connectTimeout: 20 * 1000, // 10 seconds
  receiveTimeout: 20 * 1000, // 10 seconds
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
    if (loading) {
      controller.hideLoading;
    }
    return response.data;
  } on DioError catch (e) {
    statuscheker(e);
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
    controller.hideLoading;
    return response.data;
  } on DioError catch (e) {
    statuscheker(e);
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
    statuscheker(e);
  }
}

statuscheker(e) async {
  if (e.response?.statusCode == 400) {
    Fluttertoast.showToast(
        msg: e.message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: red,
        textColor: white,
        fontSize: 16.0);
  }
  if (e.response?.statusCode == 401) {
    Fluttertoast.showToast(
        msg: "Неправильный логин или пароль",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: red,
        textColor: white,
        fontSize: 16.0);
  }
  if (e.response?.statusCode == 403) {}
  if (e.response?.statusCode == 404) {
    Fluttertoast.showToast(
        msg: 'Не найдено',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: red,
        textColor: white,
        fontSize: 16.0);
  }
  if (e.response?.statusCode == 415) {
    Fluttertoast.showToast(
        msg: 'Ошибка',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: red,
        textColor: white,
        fontSize: 16.0);
  }
  if (e.response?.statusCode == 500) {
    Fluttertoast.showToast(
        msg: e.message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: red,
        textColor: white,
        fontSize: 16.0);
  }
}

Future lPost(String url, dynamic payload) async {
  controller.showLoading;
  try {
    final response = await dio.post(
      'https://cabinet.cashbek.uz' + url,
      data: payload,
    );
    print(response);
    controller.hideLoading;
    return response.data;
  } on DioError catch (e) {
    statuscheker(e);
  }
}
