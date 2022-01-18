import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/globals.dart';

class DrawerAppBar extends StatefulWidget {
  const DrawerAppBar({Key? key}) : super(key: key);

  @override
  _DrawerAppBarState createState() => _DrawerAppBarState();
}

class _DrawerAppBarState extends State<DrawerAppBar> {
  Widget buildListTile(
    String title,
    IconData icon,
    String routeName,
  ) {
    return GestureDetector(
      onTap: () {
        Get.offAllNamed(routeName);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: 15),
              child: Icon(
                icon,
                color: grey,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: blue,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 10),
                      height: 64,
                      width: 64,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Тивал',
                          style: TextStyle(fontSize: 16, color: white),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Мобильна касса и склад',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: white),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 15, left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 15),
                      child: Text(
                        'Операции',
                        style: TextStyle(fontSize: 18, color: lightGrey),
                      ),
                    ),
                    buildListTile('Долг клиента', Icons.shopping_cart_outlined,
                        '/client-debt'),
                    buildListTile('Продажи в долг',
                        Icons.shopping_cart_outlined, '/sales-on-credit'),
                    buildListTile(
                        'Калькулятор', Icons.calculate, '/calculator'),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
