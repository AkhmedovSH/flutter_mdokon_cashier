import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import '/models/data_model.dart';
import '/models/loading_model.dart';
import '/widgets/custom_app_bar.dart';
import '/widgets/loading.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '/helpers/api.dart';
import '/helpers/helper.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class Search extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const Search({
    Key? key,
    required this.arguments,
  }) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  GetStorage storage = GetStorage();

  TextEditingController textEditingController = TextEditingController();
  Timer? _debounce;

  List products = [];
  List<Map<String, dynamic>> productsList = [];

  Map cashbox = {};
  // Map arguments = {};

  addProductToList(i) {
    products[i]['selected'] = false;
    if (products[i]['quantity'] == null) {
      products[i]['quantity'] = '1';
    }
    if (double.parse(products[i]['quantity'].toString()) > double.parse(products[i]['balance'].toString())) {
      if (cashbox['saleMinus'] == null || !cashbox['saleMinus']) {
        showDangerToast('${products[i]['productName']} превышает остаток');
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
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        content: Text(
          products[i]['productName'] + ' - ' + products[i]['quantity'].toString() + ' ' + context.tr('added'),
          style: TextStyle(
            color: white,
          ),
        ),
        backgroundColor: mainColor,
      ),
    );
    Vibration.vibrate(amplitude: 10, duration: 30);
    Provider.of<DataModel>(context, listen: false).setProductList(productsList);
    setState(() {});
  }

  searchProducts(value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        products = [];
      });
      Provider.of<LoadingModel>(context, listen: false).showLoader(num: 1);
      if (value.length >= 1) {
        var arr = [];
        var response = await get(
          '/services/desktop/api/get-balance-product-list-mobile/${cashbox['posId']}/${widget.arguments!['currencyId']}?search=$value',
        );
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
        setState(() {});
      } else {
        setState(() {
          products = [];
        });
      }
      Provider.of<LoadingModel>(context, listen: false).hideLoader();
    });
  }

  getQrCode() async {
    await Permission.camera.request();
    var status = await Permission.camera.status;

    if (status == PermissionStatus.permanentlyDenied || status == PermissionStatus.denied) {
      return;
    }
    if (mounted) {
      String? result = await SimpleBarcodeScanner.scanBarcode(
        context,
        barcodeAppBar: const BarcodeAppBar(
          appBarTitle: '',
          centerTitle: false,
          enableBackButton: true,
          backButtonIcon: Icon(Icons.arrow_back_ios),
        ),
        cancelButtonText: context.tr('back'),
        isShowFlashIcon: false,
        delayMillis: 500,
        cameraFace: CameraFace.back,
        scanFormat: ScanFormat.ONLY_BARCODE,
      );
      if (result != null && result != '-1') {
        setState(() {
          searchProducts(result);
          textEditingController.text = result;
        });
      }
    }
  }

  getCashbox() async {}

  @override
  void initState() {
    super.initState();
    cashbox = (storage.read('cashbox')!);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).clearSnackBars();
        context.pop();
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'catalog',
          leading: true,
        ),
        body: Column(
          children: [
            SizedBox(height: 10),
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
                        cursorColor: mainColor,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(2),
                          isDense: true,
                          prefixIcon: Icon(
                            UniconsLine.search,
                            size: 18,
                          ),
                          border: inputBorder,
                          focusedBorder: inputFocusBorder,
                          hintText: '${context.tr('search_by_name')}, QR code ...',
                          hintStyle: TextStyle(
                            color: lightGrey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 45,
                    width: 45,
                    margin: EdgeInsets.only(left: 15),
                    decoration: BoxDecoration(),
                    child: TextButton(
                      onPressed: () {
                        getQrCode();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: mainColor),
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                      ),
                      child: Icon(
                        UniconsLine.qrcode_scan,
                        color: mainColor,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Consumer<LoadingModel>(
              builder: (context, loadingModel, child) {
                if (loadingModel.currentLoading == 1) {
                  return Column(
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: LoadingWidget(),
                      ),
                    ],
                  );
                }
                if (products.isEmpty && textEditingController.text != '' && loadingModel.currentLoading == 0) {
                  return Column(
                    children: [
                      SizedBox(height: 30),
                      SvgPicture.asset(
                        'images/icons/empty.svg',
                        height: 300,
                      ),
                      Text(
                        context.tr('NOT_FOUND'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        context.tr('nothing_found_for', args: [textEditingController.text]),
                      ),
                    ],
                  );
                }
                if (products.isEmpty && textEditingController.text == '') {
                  return Column(
                    children: [
                      SizedBox(height: 30),
                      SvgPicture.asset(
                        'images/icons/search.svg',
                        height: 300,
                      ),
                      Text(
                        context.tr('EMPTY_LIST'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        context.tr('enter_name_to_search_for_products'),
                      ),
                    ],
                  );
                }
                return SizedBox();
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final item = products[i];

                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                        boxShadow: [boxShadow],
                      ),
                      child: TextButton(
                        onPressed: () {
                          addProductToList(i);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          backgroundColor: CustomTheme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: borderColor),
                            borderRadius: const BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item['productName']}',
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
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 5),
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.5,
                                        child: Text(
                                          '${formatMoney(widget.arguments!['activePrice'] == 1
                                                  ? item['wholesalePrice']
                                                  : widget.arguments!['activePrice'] == 2
                                                  ? item['bankPrice']
                                                  : item['salePrice']) ?? 0} ${widget.arguments!['currencyName']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${context.tr('balance')}: ${formatMoney(item['balance']) ?? 0}',
                                        style: TextStyle(color: grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          SizedBox(
                                            width: 50,
                                            height: 28,
                                            child: TextFormField(
                                              enableInteractiveSelection: false,
                                              keyboardType: TextInputType.number,
                                              initialValue: '1',
                                              // initialValue: (products[i]['balance'] ?? 0).round().toString(),
                                              onChanged: (value) {
                                                if (value != '') {
                                                  item['quantity'] = value;
                                                }
                                              },
                                              cursorColor: mainColor,
                                              scrollPadding: EdgeInsets.only(bottom: 100),
                                              decoration: InputDecoration(
                                                contentPadding: EdgeInsets.zero,
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
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
