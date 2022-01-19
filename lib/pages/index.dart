import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/globals.dart';
import '../components/drawer_app_bar.dart';
import 'package:flutter/services.dart';

class Index extends StatefulWidget {
  const Index({Key? key}) : super(key: key);

  @override
  _IndexState createState() => _IndexState();
}

class _IndexState extends State<Index> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Color(0xFF5b73e8), // Status bar
          ),
          bottomOpacity: 0.0,
          title: Text(
            'Продажа',
            style: TextStyle(color: white),
          ),
          backgroundColor: blue,
          elevation: 0,
          // centerTitle: true,
          leading: IconButton(
            onPressed: () {
              _scaffoldKey.currentState!.openDrawer();
            },
            icon: Icon(Icons.menu, color: white),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 15),
              child: const Icon(Icons.person),
            ),
            Container(
              margin: const EdgeInsets.only(right: 15),
              child: const Icon(Icons.search),
            ),
            Container(
              margin: const EdgeInsets.only(right: 15),
              child: const Icon(Icons.qr_code_2_outlined),
            ),
            Container(
              margin: const EdgeInsets.only(right: 15),
              child: const Icon(Icons.delete),
            ),
          ],
        ),
        drawer: SizedBox(
          width: MediaQuery.of(context).size.width * 0.70,
          child: const DrawerAppBar(),
        ),
        body: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: blue,
          onPressed: () {
            Get.toNamed('/search');
          },
          child: const Icon(
            Icons.add,
            size: 28,
          ),
        ));
  }
}
