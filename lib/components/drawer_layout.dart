import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/globals.dart';
import 'package:flutter/services.dart';

import '../components/drawer_app_bar.dart';

class DrawerLayout extends StatefulWidget {
  const DrawerLayout({Key? key, this.appBar, this.body}) : super(key: key);
  final AppBar? appBar;
  final Widget? body;

  @override
  State<DrawerLayout> createState() => _DrawerLayoutState();
}

class _DrawerLayoutState extends State<DrawerLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.70,
        child: const DrawerAppBar(),
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          if (details.delta.dx > 0) {
            _scaffoldKey.currentState!.openDrawer();
          }
        },
        child: widget.body,
      ),
    );
  }
}
