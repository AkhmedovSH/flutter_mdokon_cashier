import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:unicons/unicons.dart';

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
  final storage = GetStorage();

  Map payload = {'username': '', 'password': '', 'rememberMe': false};
  Map data = {
    'username': TextEditingController(),
    'password': TextEditingController(),
  };

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
    storage.write('access_token', data['access_token']);
    storage.write('username', payload['username'].toString().toLowerCase());
    storage.write('password', payload['password']);
    storage.write('user', jsonEncode(payload));

    final account = await get('/services/uaa/api/account');
    storage.write('account', jsonEncode(account));

    var checker = '';
    for (var i = 0; i < account['authorities'].length; i++) {
      if (account['authorities'][i] == "ROLE_CASHIER") {
        checker = 'ROLE_CASHIER';
      }
      if (account['authorities'][i] == "ROLE_AGENT") {
        checker = 'ROLE_AGENT';
      }
    }
    if (checker == 'ROLE_CASHIER') {
      storage.write('user_roles', jsonEncode(account['authorities']));
      await getAccessPos();
    } else if (checker == 'ROLE_AGENT') {
      storage.write('user_roles', jsonEncode(account['authorities']));
      await getAgentPosId();
    } else {
      showErrorToast('Нет доступа');
    }
    controller.hideLoading();
    setState(() {});
  }

  getAgentPosId() async {
    final response = await get('/services/desktop/api/get-access-pos', loading: false);
    response['isAgent'] = true;
    response['defaultCurrencyName'] = response['defaultCurrency'] == 2 ? 'USD' : 'So\'m';
    storage.write('cashbox', jsonEncode(response));
    Get.offAllNamed('/agent');
    controller.hideLoading();
    setState(() {});
  }

  getAccessPos() async {
    final response = await get('/services/desktop/api/get-access-pos', loading: false);
    if (response['openShift']) {
      storage.remove('shift');
      response['shift']['defaultCurrencyName'] = response['shift']['defaultCurrency'] == 2 ? 'USD' : 'So\'m';
      storage.write('cashbox', jsonEncode(response['shift']));
      Get.offAllNamed('/');
    } else {
      Get.toNamed('/cashboxes', arguments: response['posList']);
    }
    controller.hideLoading();
    setState(() {});
  }

  getData() async {
    if (storage.read('user') != null) {
      var user = jsonDecode(storage.read('user')!);
      print(user);
      if (user['rememberMe'] != null && user['rememberMe']) {
        payload = user;
        data['username'].text = user['username'];
        data['password'].text = user['password'];
        setState(() {});
      }
    }
    print(storage.read('settings'));
    if (storage.read('settings') == null) {
      storage.write(
        'settings',
        jsonEncode({
          'showChequeProducts': false,
          'printAfterSale': false,
          'searchGroupProducts': false,
          'selectUserAftersale': false,
          'offlineDeferment': false,
          'additionalInfo': false,
          'language': false,
          'theme': false,
        }),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingLayout(
      body: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          bottomOpacity: 0.0,
          backgroundColor: Colors.transparent,
        ),
        extendBodyBehindAppBar: true,
        body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: SvgPicture.asset(
                    'images/icons/login_bg.svg',
                    height: 270,
                    width: MediaQuery.of(context).size.width,
                  ),
                ),
                Text(
                  'Авторизация',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(height: 2),
                Container(
                  height: 4,
                  width: 130,
                  color: mainColor,
                  margin: const EdgeInsets.only(bottom: 15),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                controller: data['username'],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'required_field'.tr;
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    payload['username'] = value;
                                  });
                                },
                                textInputAction: TextInputAction.next,
                                scrollPadding: EdgeInsets.only(bottom: 200),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.all(16),
                                  prefixIcon: Icon(
                                    payload['username'].length > 0 ? UniconsLine.user_check : UniconsLine.user,
                                    size: 24,
                                    color: mainColor,
                                  ),
                                  border: inputBorder,
                                  enabledBorder: inputBorder,
                                  focusedBorder: inputFocusBorder,
                                  errorBorder: inputErrorBorder,
                                  focusedErrorBorder: inputErrorBorder,
                                  hintText: 'Логин',
                                  hintStyle: TextStyle(color: mainColor),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                controller: data['password'],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'required_field'.tr;
                                  }
                                  return null;
                                },
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
                                scrollPadding: EdgeInsets.only(bottom: 200),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 15),
                                  prefixIcon: Icon(
                                    showPassword ? UniconsLine.unlock_alt : UniconsLine.lock_alt,
                                    size: 30,
                                    color: mainColor,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        showPassword = !showPassword;
                                      });
                                    },
                                    icon: Icon(
                                      showPassword ? UniconsLine.eye : UniconsLine.eye_slash,
                                      size: 24,
                                      color: grey,
                                    ),
                                  ),
                                  border: inputBorder,
                                  enabledBorder: inputBorder,
                                  focusedBorder: inputFocusBorder,
                                  errorBorder: inputErrorBorder,
                                  focusedErrorBorder: inputErrorBorder,
                                  focusColor: mainColor,
                                  hintText: 'Пароль',
                                  hintStyle: TextStyle(color: mainColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: payload['rememberMe'],
                              activeColor: mainColor,
                              onChanged: (value) {
                                setState(() {
                                  payload['rememberMe'] = !payload['rememberMe'];
                                });
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                payload['rememberMe'] = !payload['rememberMe'];
                              });
                            },
                            child: Text(
                              'Запомнить меня',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 100,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.only(left: 32),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(150, 50),
              backgroundColor: mainColor,
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
      ),
    );
  }
}
