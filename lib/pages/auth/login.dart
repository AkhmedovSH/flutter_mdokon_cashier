import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../../helpers/globals.dart';
import '../../helpers/api.dart';
import '../../helpers/controller.dart';
import '../../components/loading_layout.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  dynamic payload = {'username': 'united', 'password': '0777'};
  bool showPassword = false;
  bool loading = false;
  final Controller controller = Get.put(Controller());

  login() async {
    controller.showLoading();
    setState(() {});
    final data = await guestPost('/auth/login', payload, loading: false);
    if (data == null) {
      controller.hideLoading();
      setState(() {});
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('access_token', data['access_token']);
    prefs.setString('username', payload['username'].toString().toLowerCase());
    prefs.setString('password', payload['password']);

    final account = await get('/services/uaa/api/account');
    prefs.setString('account', jsonEncode(account));

    var checker = false;
    for (var i = 0; i < account['authorities'].length; i++) {
      if (account['authorities'][i] == "ROLE_CASHIER") {
        checker = true;
      }
    }
    if (checker == true) {
      prefs.setString('user_roles', account['authorities'].toString());
      getAccessPos();
    }
  }

  getAccessPos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await get('/services/desktop/api/get-access-pos', loading: false);
    if (response['openShift']) {
      prefs.remove('shift');
      prefs.setString('cashbox', jsonEncode(response['shift']));
      Get.offAllNamed('/');
    } else {
      Get.offAllNamed('/cashboxes', arguments: response['posList']);
    }
    controller.hideLoading();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LoadingLayout(
      body: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(0.0),
          child: AppBar(
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarIconBrightness: Brightness.dark,
              statusBarColor: Colors.white, // Status bar
            ),
            elevation: 0.0,
            bottomOpacity: 0.0,
            backgroundColor: Colors.transparent,
          ),
        ),
        body: SafeArea(
          child: Container(
            margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'images/login_bg.jpg',
                    height: 250,
                    width: 250,
                  ),
                ),
                Text(
                  'Авторизация',
                  style: TextStyle(
                    color: black,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
                Container(
                  height: 4,
                  width: 90,
                  color: blue,
                  margin: const EdgeInsets.only(bottom: 15),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Обязательное поле';
                            }
                          },
                          initialValue: payload['username'],
                          onChanged: (value) {
                            setState(() {
                              payload['username'] = value;
                            });
                          },
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              size: 30,
                              color: blue,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: lightGrey,
                                width: 1,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: blue),
                            ),
                            focusColor: blue,
                            labelText: 'Логин',
                            labelStyle: TextStyle(color: blue),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Обязательное поле';
                            }
                          },
                          initialValue: payload['password'],
                          onChanged: (value) {
                            setState(() {
                              payload['password'] = value;
                            });
                          },
                          // onFieldSubmitted: (val) {
                          //   if (_formKey.currentState!.validate()) {
                          //     login();
                          //   }
                          // },
                          obscureText: !showPassword,
                          decoration: InputDecoration(
                              contentPadding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                size: 30,
                                color: blue,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                                icon: showPassword
                                    ? Icon(
                                        Icons.visibility_outlined,
                                        size: 20,
                                        color: grey,
                                      )
                                    : Icon(
                                        Icons.visibility_off_outlined,
                                        size: 20,
                                        color: grey,
                                      ),
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: lightGrey,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: blue),
                              ),
                              focusColor: blue,
                              labelText: 'Пароль',
                              labelStyle: TextStyle(color: blue)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SizedBox(),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(150, 50),
                      primary: blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        login();
                      }
                    },
                    child: Text(
                      'ВОЙТИ',
                      style: TextStyle(color: white, fontSize: 18, letterSpacing: 2.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
