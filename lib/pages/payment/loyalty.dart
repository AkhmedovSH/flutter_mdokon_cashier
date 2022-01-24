import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/globals.dart';

class Loyalty extends StatefulWidget {
  const Loyalty({Key? key, this.getPayload}) : super(key: key);
  final Function? getPayload;

  @override
  _LoyaltyState createState() => _LoyaltyState();
}

class _LoyaltyState extends State<Loyalty> {

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 20),
            child: Text('К ОПЛАТЕ',
                style: TextStyle(
                    color: darkGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          Container(
              margin: EdgeInsets.only(bottom: 10),
              child: Text('totalPrice сум',
                  style: TextStyle(
                      color: darkGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
