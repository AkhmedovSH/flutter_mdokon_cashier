import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kassa/helpers/globals.dart';
import '../components/drawer_app_bar.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            'Каталог товаров',
            style: TextStyle(color: black),
          ),
          backgroundColor: white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
              onPressed: () {
              },
              icon: Icon(
                Icons.arrow_back_ios,
                color: black,
              ))),
      body: Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(2),
                        isDense: true,
                        prefixIcon: Icon(
                          Icons.search,
                          color: grey,
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: borderColor,
                            ),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(24))),
                        hintText: 'Поиск по названию, QR code ...',
                        hintStyle: TextStyle(color: lightGrey, fontSize: 14)),
                  ),
                ),
                for (var i = 0; i < 7; i++)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: white,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          spreadRadius: -5,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Test',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  'Ostatok: 81',
                                  style: TextStyle(color: lightGrey),
                                ),
                              ],
                            )),
                          ],
                        ),
                        Container(
                          child: Text('2000 So\'m'),
                        )
                      ],
                    ),
                  )
              ],
            ),
          )),
    );
  }
}
