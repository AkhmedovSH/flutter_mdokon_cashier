import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../globals.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
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
                      color: black, fontSize: 24, fontWeight: FontWeight.bold)),
              Container(
                height: 4,
                width: 68,
                color: blue,
                margin: const EdgeInsets.only(bottom: 15),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  decoration: InputDecoration(
                      contentPadding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        size: 18,
                        color: blue,
                      ),
                      border: UnderlineInputBorder(
                          borderSide: BorderSide(color: lightGrey, width: 1)),
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
                  decoration: InputDecoration(
                      contentPadding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: blue,
                      ),
                      suffixIcon: Icon(
                        Icons.visibility_off_outlined,
                        size: 18,
                        color: grey,
                      ),
                      border: UnderlineInputBorder(
                          borderSide: BorderSide(color: lightGrey, width: 1)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: blue)),
                      focusColor: blue,
                      labelText: 'Пароль',
                      labelStyle: TextStyle(color: blue)),
                ),
              ),
            ],
          ),
        )),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.only(left: 48, right: 32, bottom: 20),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Get.offAllNamed('/');
                    },
                    child: Text(
                      'ВОЙТИ',
                      style: TextStyle(color: white),
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
                      style: TextStyle(color: blue),
                    ))),
          ],
        ));
  }
}
