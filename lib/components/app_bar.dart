import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/globals.dart';
import '../components/drawer_app_bar.dart';
import 'package:flutter/services.dart';

class SimpleAppBar extends StatefulWidget {
  SimpleAppBar({Key? key}) : super(key: key);

  @override
  SimpleAppBarState createState() => SimpleAppBarState();
}

class SimpleAppBarState extends State<SimpleAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar();
  }
}