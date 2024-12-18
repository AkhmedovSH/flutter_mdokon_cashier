import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:kassa/models/data_model.dart';
import 'package:kassa/models/loading_model.dart';
import 'package:kassa/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:unicons/unicons.dart';

import '../../helpers/helper.dart';
import '../../helpers/api.dart';
import '../../widgets/loading_layout.dart';

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

  login() async {
    FocusScope.of(context).unfocus();
    Provider.of<LoadingModel>(context, listen: false).showLoader(num: 2);
    try {
      final data = await post('/auth/login', payload, isGuest: true);
      if (data == null) {
        Provider.of<LoadingModel>(context, listen: false).hideLoader();
        return;
      }
      print(data);
      print(data['access_token']);
      storage.write('access_token', data['access_token']);

      var lastLogin = {
        'year': DateTime.now().year,
        'month': DateTime.now().month,
        'day': DateTime.now().day,
        'hour': DateTime.now().hour,
        'minute': DateTime.now().minute,
      };
      storage.write('lastLogin', (lastLogin));

      final Map account = await get('/services/uaa/api/account');
      Provider.of<UserModel>(context, listen: false).setUser({...payload, ...account});

      var checker = '';
      for (var i = 0; i < account['authorities'].length; i++) {
        if (account['authorities'][i] == "ROLE_CASHIER") {
          checker = 'ROLE_CASHIER';
        }
        if (account['authorities'][i] == "ROLE_AGENT") {
          checker = 'ROLE_AGENT';
        }
        if (account['authorities'][i] == "ROLE_OWNER") {
          checker = 'ROLE_OWNER';
        }
        if (account['authorities'][i] == "ROLE_MERCHANDISER") {
          checker = 'ROLE_MERCHANDISER';
        }
      }
      storage.write('user_roles', (account['authorities']));
      storage.write('role', checker);

      if (checker == 'ROLE_CASHIER') {
        await getAccessPos();
      } else if (checker == 'ROLE_AGENT') {
        await getAgentPosId();
      } else if (checker == 'ROLE_OWNER' || checker == 'ROLE_MERCHANDISER') {
        final userSettings = await get("/services/web/api/user-settings");
        final posBalance = await get("/services/web/api/pos-balance");
        if (userSettings != null && userSettings['settings'] != null) {
          Provider.of<UserModel>(context, listen: false).setUser({
            ...storage.read('user'),
            'posId': data['posId'],
            'posBalance': posBalance,
          });
        }
        Provider.of<DataModel>(context, listen: false).getData();
        context.pushReplacement('/director');
      } else {
        showDangerToast('error', description: 'Нет доступа');
      }
    } catch (e) {
      print(e);
    }
    Provider.of<LoadingModel>(context, listen: false).hideLoader();
  }

  void openPhoneCall() async {
    if (!await launchUrl(Uri.parse("tel://+998555000089"))) throw 'Could not launch';
  }

  getAgentPosId() async {
    final response = await get('/services/desktop/api/get-access-pos');
    response['isAgent'] = true;
    response['defaultCurrencyName'] = response['defaultCurrency'] == 2 ? 'USD' : 'So\'m';
    Provider.of<UserModel>(context, listen: false).setCashbox(response);
    context.go('/agent');
  }

  getAccessPos() async {
    final response = await get('/services/desktop/api/get-access-pos');
    if (response['openShift']) {
      storage.remove('shift');
      response['shift']['defaultCurrencyName'] = response['shift']['defaultCurrency'] == 2 ? 'USD' : 'So\'m';
      Provider.of<UserModel>(context, listen: false).setCashbox(response['shift']);
      context.go('/cashier');
    } else {
      context.go('/auth/cashboxes', extra: {'posList': response['posList']});
    }
  }

  getData() async {
    if (storage.read('user') != null) {
      var user = storage.read('user');
      if (user['rememberMe'] != null && user['rememberMe']) {
        payload['username'] = user['username'];
        payload['password'] = user['password'];
        payload['rememberMe'] = user['rememberMe'];
        data['username'].text = user['username'];
        data['password'].text = user['password'];
        setState(() {});
      }
    }
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
        body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (MediaQuery.of(context).size.width > 320)
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
                                    return context.tr('required_field');
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    payload['username'] = value;
                                  });
                                },
                                onTapOutside: (PointerDownEvent event) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                cursorColor: mainColor,
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
                                    return context.tr('required_field');
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    payload['password'] = value;
                                  });
                                },
                                onTapOutside: (PointerDownEvent event) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                // onFieldSubmitted: (val) {
                                //   if (_formKey.currentState!.validate()) {
                                //     login();
                                //   }
                                // },
                                cursorColor: mainColor,
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
          color: CustomTheme.of(context).bgColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${context.tr('no_account')}?',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      openPhoneCall();
                    },
                    child: Text(
                      context.tr('contact_us'),
                      style: TextStyle(
                        color: mainColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Container(
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
            ],
          ),
        ),
      ),
    );
  }
}
