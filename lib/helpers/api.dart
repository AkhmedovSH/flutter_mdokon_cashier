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

  if (prefs.getString('access_token') != null) {
    dio.options.headers["authorization"] = "Bearer ${prefs.getString('access_token')}";
    dio.options.headers["Accept"] = "application/json";
  }

  try {
    final response = await dio.get(
      hostUrl + url,
      queryParameters: payload,
      options: Options(headers: {
        "authorization": "Bearer ${prefs.getString('access_token')}",
      }),
    );
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
    if (prefs.getString('access_token') != null) {
      dio.options.headers["authorization"] = "Bearer ${prefs.getString('access_token')}";
      dio.options.headers["Accept"] = "application/json";
    }
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

Future put(String url, dynamic payload) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // print(payload);
  controller.showLoading;
  try {
    if (prefs.getString('access_token') != null) {
      dio.options.headers["authorization"] = "Bearer ${prefs.getString('access_token')}";
      dio.options.headers["Accept"] = "application/json";
    }
    //print(hostUrl + url);
    final response = await dio.put(hostUrl + url,
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('access_token') != null) {
      dio.options.headers["authorization"] = "";
      dio.options.headers["Accept"] = "application/json";
    }
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

Future guestGet(String url, {payload}) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('access_token') != null) {
      dio.options.headers["authorization"] = "";
      dio.options.headers["Accept"] = "application/json";
    }
    final response = await dio.get(
      hostUrl + url,
      queryParameters: payload,
    );
    return response.data;
  } on DioError catch (e) {
    statuscheker(e);
  }
}

statuscheker(e) async {
  if (e.response?.statusCode == 400) {
    showErrorToast(e.message);
  }
  if (e.response?.statusCode == 401) {
    showErrorToast('Неправильный логин или пароль');
  }
  if (e.response?.statusCode == 403) {}
  if (e.response?.statusCode == 404) {
    showErrorToast('Не найдено');
  }
  if (e.response?.statusCode == 415) {
    showErrorToast('Ошибка');
  }
  if (e.response?.statusCode == 500) {
    showErrorToast(e.message);
  }
}

Future lPost(String url, dynamic payload) async {
  controller.showLoading;
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('access_token') != null) {
      dio.options.headers["authorization"] = "";
      dio.options.headers["Accept"] = "application/json";
    }
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

showErrorToast(message) {
  return Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: red,
      textColor: white,
      fontSize: 16.0);
}
