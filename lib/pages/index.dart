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
  dynamic products = [];

  @override
  void initState() {
    super.initState();
  }

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
          child: Column(
            children: [
              for (var i = 0; i < products.length; i++)
                Dismissible(
                    key: ValueKey(products[i]['productName']),
                    onDismissed: (DismissDirection direction) {
                      setState(() {
                        products.removeAt(i);
                      });
                    },
                    background: Container(
                      color: white,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.delete,
                        color: red,
                      ),
                    ),
                    direction: DismissDirection.endToStart,
                    child: GestureDetector(
                      onTap: () {
                        Get.toNamed('/calculator');
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Color(0xFFF5F3F5), width: 1))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${products[i]['productName']}',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      'Ostatok: 81',
                                      style: TextStyle(color: lightGrey),
                                    ),
                                  ],
                                ),
                                Container(
                                  child: Text(
                                    '${products[i]['price']} So\'m',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: blue,
                                        fontSize: 16),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ))
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: blue,
          onPressed: () async {
            final result = await Get.toNamed('/search');
            setState(() {
              products.add(result);
            });
            print(products);
          },
          child: const Icon(
            Icons.add,
            size: 28,
          ),
        ));
  }
}
