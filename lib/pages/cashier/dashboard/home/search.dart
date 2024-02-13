import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/globals.dart';
import 'package:kassa/helpers/controller.dart';
import 'package:kassa/components/loading_layout.dart';
import 'package:unicons/unicons.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final Controller controller = Get.put(Controller());
  GetStorage storage = GetStorage();

  TextEditingController textEditingController = TextEditingController();
  Timer? _debounce;

  List products = [];
  List<Map> productsList = [];

  Map cashbox = {};
  Map arguments = {};

  addProductToList(i) {
    products[i]['selected'] = false;
    if (products[i]['quantity'] == null) {
      products[i]['quantity'] = '1';
    }
    if (double.parse(products[i]['quantity'].toString()) > double.parse(products[i]['balance'].toString())) {
      if (cashbox['saleMinus'] == null || !cashbox['saleMinus']) {
        showErrorToast('${products[i]['productName']} превышает остаток');
        return;
      }
    }
    dynamic index = productsList.indexWhere((item) => item['balanceId'] == products[i]['balanceId']);
    if (index >= 0) {
      productsList[index]['quantity'] = double.parse(productsList[index]['quantity'].toString()) + double.parse(products[i]['quantity'].toString());
      products[i]['balance'] = products[i]['originalBalance'] - productsList[index]['quantity'];
    } else {
      productsList.add(Map.from(products[i]));
      products[i]['originalBalance'] = products[i]['balance'];
      products[i]['balance'] = products[i]['balance'] - double.parse(products[i]['quantity'].toString());
      // Get.showSnackbar(
      //   GetSnackBar(
      //     animationDuration: const Duration(milliseconds: 300),
      //     duration: const Duration(milliseconds: 800),
      //     messageText: Text(
      //       products[i]['productName'] + ' - ' + products[i]['quantity'].toString() + ' добавлен',
      //       style: TextStyle(color: white),
      //     ),
      //     backgroundColor: mainColor,
      //   ),
      // );
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1200),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          content: Text(
            products[i]['productName'] + ' - ' + products[i]['quantity'].toString() + ' ' + 'added'.tr,
            style: TextStyle(
              color: white,
            ),
          ),
          backgroundColor: mainColor,
        ),
      );
    }
    setState(() {});
  }

  searchProducts(value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.length >= 1) {
        controller.showLoading();
        setState(() {});
        var arr = [];
        var response =
            await get('/services/desktop/api/get-balance-product-list-mobile/${cashbox['posId']}/${cashbox['defaultCurrency']}?search=$value');
        if (response != null && response.length > 0) {
          if (response.length > 50) {
            response = response.sublist(0, 50);
          }
          for (var i = 0; i < response.length; i++) {
            response[i]['quantity'] = 1;
            if (response[i]['balance'] == null || double.parse(response[i]['balance'].toString()) <= 0) {
              if (cashbox['saleMinus'] != null && cashbox['saleMinus']) {
                arr.add(response[i]);
              }
            } else {
              arr.add(response[i]);
            }
          }
          products = arr;
        } else if (response != null && response.length == 0) {
          products = [];
        }
        controller.hideLoading();
        setState(() {});
      } else {
        setState(() {
          products = [];
        });
      }
    });
  }

  getQrCode() async {
    await Permission.camera.request();
    var status = await Permission.camera.status;

    // final permission = await getCameraPermission();
    if (status == PermissionStatus.permanentlyDenied || status == PermissionStatus.denied) {
      return;
    }
    var result = await FlutterBarcodeScanner.scanBarcode("#5b73e8", "back".tr, false, ScanMode.BARCODE);
    if (result != '-1') {
      setState(() {
        searchProducts(result);
        textEditingController.text = result;
      });
    }
  }

  getProducts() async {
    controller.showLoading();
    setState(() {});

    final cashbox = jsonDecode(storage.read('cashbox')!);
    final response = await get('/services/desktop/api/get-balance-product-list/${cashbox['posId']}/${cashbox['defaultCurrency']}');
    controller.hideLoading();
    if (response != null && response.length > 0) {
      setState(() {
        products = response;
      });
    } else if (response != null && response.length == 0) {
      setState(() {
        products = [];
      });
    }
  }

  getCashbox() async {
    setState(() {
      cashbox = jsonDecode(storage.read('cashbox')!);
    });
  }

  @override
  void initState() {
    super.initState();
    //getProducts();
    getCashbox();
    arguments = Get.arguments ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).clearSnackBars();
        Get.back(result: productsList);
        return true;
      },
      child: LoadingLayout(
        body: Scaffold(
          appBar: AppBar(
            title: Text(
              'catalog'.tr,
            ),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                Get.back(result: productsList);
              },
              icon: Icon(
                UniconsLine.arrow_left,
                size: 32,
                color: black,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 10, right: 16, left: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 6,
                        child: SizedBox(
                          height: 45,
                          child: TextField(
                            controller: textEditingController,
                            onChanged: (value) {
                              searchProducts(value);
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(2),
                              isDense: true,
                              prefixIcon: Icon(
                                UniconsLine.search,
                                size: 18,
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: borderColor),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(24),
                                ),
                              ),
                              hintText: '${'search_by_name'.tr}, QR code ...',
                              hintStyle: TextStyle(
                                color: lightGrey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          getQrCode();
                        },
                        child: Container(
                          height: 45,
                          width: 45,
                          margin: EdgeInsets.only(left: 15),
                          decoration: BoxDecoration(
                            border: Border.all(width: 1, color: mainColor),
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          child: Icon(
                            UniconsLine.qrcode_scan,
                            color: mainColor,
                            size: 24,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                if (products.isEmpty && textEditingController.text != '' && !controller.loading.value)
                  Column(
                    children: [
                      SizedBox(height: 30),
                      SvgPicture.asset(
                        'images/icons/empty.svg',
                        height: 300,
                      ),
                      Text(
                        'NOT_FOUND'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'nothing_found_for'.trParams({
                          'value': textEditingController.text,
                        }),
                        style: context.theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                if (products.isEmpty && textEditingController.text == '')
                  Column(
                    children: [
                      SizedBox(height: 30),
                      SvgPicture.asset(
                        'images/icons/search.svg',
                        height: 300,
                      ),
                      Text(
                        'EMPTY_LIST'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'enter_name_to_search_for_products'.tr,
                        style: context.theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                for (var i = 0; i < products.length; i++)
                  GestureDetector(
                    onTap: () {
                      addProductToList(i);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
                      decoration: BoxDecoration(
                        color: context.theme.cardColor,
                        border: Border.all(color: borderColor),
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                        boxShadow: [boxShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${products[i]['productName']}',
                            style: TextStyle(
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
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.5,
                                    child: Text(
                                      '${formatMoney(arguments['activePrice'] == 1 ? products[i]['wholesalePrice'] : products[i]['salePrice']) ?? 0} ${cashbox['defaultCurrencyName']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${'balance'.tr}: ${formatMoney(products[i]['balance']) ?? 0}',
                                    style: TextStyle(color: grey),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.15,
                                        height: 28,
                                        child: TextFormField(
                                          enableInteractiveSelection: false,
                                          keyboardType: TextInputType.number,
                                          initialValue: '1',
                                          // initialValue: (products[i]['balance'] ?? 0).round().toString(),
                                          onChanged: (value) {
                                            if (value != '') {
                                              products[i]['quantity'] = value;
                                            }
                                          },
                                          cursorColor: mainColor,
                                          scrollPadding: EdgeInsets.only(bottom: 100),
                                          decoration: InputDecoration(
                                            enabledBorder: inputBorder,
                                            focusedBorder: inputFocusBorder,
                                            focusColor: mainColor,
                                          ),
                                          textAlign: TextAlign.center,
                                          textAlignVertical: TextAlignVertical.center,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      IconButton(
                                        constraints: BoxConstraints(),
                                        onPressed: () {
                                          addProductToList(i);
                                        },
                                        icon: Icon(
                                          Icons.check_circle_outline,
                                          color: mainColor,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
