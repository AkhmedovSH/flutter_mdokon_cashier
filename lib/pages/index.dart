import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import 'package:kassa/helpers/globals.dart';
import 'package:kassa/helpers/controller.dart';

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
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarColor: blue, // Status bar
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
          SizedBox(
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.person),
            ),
          ),
          SizedBox(
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.search),
            ),
          ),
          SizedBox(
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.qr_code_2_outlined),
            ),
          ),
          SizedBox(
            child: IconButton(
              onPressed: () {
                if (products.length > 0) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Вы уверены?'),
                      // content: const Text('AlertDialog description'),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.33,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                    primary: red,
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10)),
                                child: const Text('Отмена'),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.33,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    products = [];
                                  });
                                  Get.back();
                                },
                                style: ElevatedButton.styleFrom(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 10)),
                                child: const Text('Продолжить'),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  );
                }
              },
              icon: Icon(Icons.delete),
            ),
          ),
        ],
      ),
      drawerEnableOpenDragGesture: false,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.70,
        child: const DrawerAppBar(),
      ),
      body: Column(
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
                child: Icon(Icons.delete, color: red),
              ),
              direction: DismissDirection.endToStart,
              child: GestureDetector(
                onTap: () async {
                  final result =
                      await Get.toNamed('/calculator', arguments: products[i]);
                  print(result);
                  var arr = products;
                  for (var i = 0; i < arr.length; i++) {
                    if (arr[i]['productId'] == result['productId']) {
                      arr[i]['total_amount'] =
                          double.parse(arr[i]['quantity']) *
                              (arr[i]['salePrice'].round());
                      arr[i] = result;
                    }
                  }
                  setState(() {
                    products = arr;
                  });
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF5F3F5), width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${products[i]['productName']}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
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
                              const SizedBox(height: 5),
                              Text(
                                '${products[i]['salePrice']} x ${products[i]['quantity']}',
                                style: TextStyle(color: lightGrey),
                              ),
                            ],
                          ),
                          Text(
                            '${products[i]['total_amount']} So\'m',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: blue,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: EdgeInsets.only(left: 32),
            child: ElevatedButton(
              onPressed: () {
                if (products.length > 0) {
                  Get.toNamed('/payment', arguments: products);
                }
              },
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  primary: products.length > 0 ? blue : lightGrey),
              child: Text('Продать'),
            ),
          ),
          FloatingActionButton(
            backgroundColor: blue,
            onPressed: () async {
              final result = await Get.toNamed('/search');
              if (result != null) {
                var found = false;
                for (var i = 0; i < products.length; i++) {
                  if (products[i]['productId'] == result['productId']) {
                    found = true;
                    dynamic arr = products;
                    if (arr[i]['quantity'].runtimeType == String) {
                      arr[i]['quantity'] = int.parse(arr[i]['quantity']) + 1;
                    } else {
                      arr[i]['quantity'] = (arr[i]['quantity']) + 1;
                    }

                    arr[i]['discount'] = 0;
                    arr[i]['total_amount'] =
                        (arr[i]['quantity']) * (arr[i]['salePrice']);
                    setState(() {
                      products = arr;
                    });
                    print(products[i]['discount']);
                  }
                }
                if (!found) {
                  result['quantity'] = 1;
                  result['discount'] = 0;
                  result['discount'] = 0;
                  result['total_amount'] = result['quantity'] * result['salePrice'];
                  result['totalPrice'] = result['total_amount'];
                  setState(() {
                    products.add(result);
                  });
                }
              }
            },
            child: const Icon(Icons.add, size: 28),
          )
        ],
      ),
    );
  }
}
