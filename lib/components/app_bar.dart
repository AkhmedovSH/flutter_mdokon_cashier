import 'package:flutter/material.dart';


class SimpleAppBar extends StatefulWidget {
  const SimpleAppBar({Key? key}) : super(key: key);

  @override
  SimpleAppBarState createState() => SimpleAppBarState();
}

class SimpleAppBarState extends State<SimpleAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar();
  }
}