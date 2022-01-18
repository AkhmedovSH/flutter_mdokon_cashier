import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/globals.dart';
import '../../helpers/api.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  dynamic payload = {'username': '', 'password': ''};
  bool showPassword = false;

  login() async {
    final data = await guestPost('/auth/login', payload);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('access_token', data['access_token']);
    prefs.setString('username', payload['username'].toString().toLowerCase());
    prefs.setString('password', payload['password']);
    final account = await get('/services/uaa/api/account');
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
    final response = await get('/services/desktop/api/get-access-pos');
    if (response['openShift']) {
      Get.offAllNamed('/');
    } else {
      Get.offAllNamed('/cashboxes', arguments: response['posList']);
    }
    print(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Авторизация',
                  style: TextStyle(
                      color: black, fontSize: 32, fontWeight: FontWeight.bold)),
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
                          onChanged: (value) {
                            setState(() {
                              payload['username'] = value;
                            });
                          },
                          decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.fromLTRB(10, 5, 10, 10),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                size: 18,
                                color: blue,
                              ),
                              border: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: lightGrey, width: 1)),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: blue)),
                              focusColor: blue,
                              labelText: 'Логин',
                              labelStyle: TextStyle(color: blue)),
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
                          onChanged: (value) {
                            setState(() {
                              payload['password'] = value;
                            });
                          },
                          onFieldSubmitted: (val) {
                            if (_formKey.currentState!.validate()) {
                              login();
                            }
                          },
                          obscureText: !showPassword,
                          decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.fromLTRB(10, 5, 10, 10),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                size: 18,
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
                                  borderSide:
                                      BorderSide(color: lightGrey, width: 1)),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: blue)),
                              focusColor: blue,
                              labelText: 'Пароль',
                              labelStyle: TextStyle(color: blue)),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        )),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.only(left: 48, right: 32, bottom: 25),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
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
                      style: TextStyle(color: white, fontSize: 18),
                    ))),
            Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.only(left: 48, right: 32),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: blue,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      'ВОЙТИ АДМИНИСТРАТОРОМ',
                      style: TextStyle(color: blue, fontSize: 16),
                    ))),
          ],
        ));
  }
}
