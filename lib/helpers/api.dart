import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

const host_url = "https://cabinet.mdokon.uz";
var dio = Dio();

Future get(String url) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final response = await dio.get(host_url + url,
      options: Options(headers: {
        "authorization": "Bearer ${prefs.getString('access_token')}",
      }));
  print(response.data);
  return response.data;
}

Future post(String url, dynamic payload) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  try {
    final response = await dio.post(host_url + url,
        data: payload,
        options: Options(headers: {
          "authorization": "Bearer ${prefs.getString('access_token')}",
        }));
    return response.data;
  } on DioError catch (e) {
    print(e.response?.statusCode);
    if (e.response?.statusCode == 400) {
      return;
    }
  }
}

Future guestPost(String url, dynamic payload) async {
  try {
    final response = await dio.post(host_url + url, data: payload);
    return response.data;
  } on DioError catch (e) {
    if (e.response?.statusCode == 400) {
      return;
    }
    if (e.response?.statusCode == 401) {
      print(111);
    }
  }
}
