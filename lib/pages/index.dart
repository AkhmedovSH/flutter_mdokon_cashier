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
                  //print(result);
                  var arr = products;
                  for (var i = 0; i < arr.length; i++) {
                    if (arr[i]['productId'] == result['productId']) {
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
                                '${products[i]['price']} x ${products[i]['quantity']}',
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
                    arr[i]['quantity'] += 1;
                    arr[i]['total_amount'] =
                        (arr[i]['quantity']) * (arr[i]['price']);
                    setState(() {
                      products = arr;
                    });
                  }
                }
                if (!found) {
                  result['quantity'] = 1;
                  result['total_amount'] = result['quantity'] * result['price'];
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
