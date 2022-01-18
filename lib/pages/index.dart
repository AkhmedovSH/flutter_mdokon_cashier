import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/globals.dart';
import '../components/drawer_app_bar.dart';

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
              icon: Icon(
                Icons.menu,
                color: white,
              )),
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
              child: const Icon(Icons.search),
            ),
            Container(
              margin: const EdgeInsets.only(right: 15),
              child: const Icon(Icons.delete),
            ),
          ],
        ),
        drawer: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: const DrawerAppBar(),
        ),
        body: Container(
          margin: EdgeInsets.symmetric(horizontal: 48),
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
