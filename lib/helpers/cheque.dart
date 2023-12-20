import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
//
import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';

import '/helpers/globals.dart';

getChequeRow(generator, text1, text2, {heightSize = PosTextSize.size1, widthSize = PosTextSize.size1, bold = false}) {
  return generator.row(
    [
      PosColumn(
        text: '$text1',
        width: 6,
        styles: PosStyles(
          align: PosAlign.left,
          height: heightSize,
          width: widthSize,
          bold: bold,
          fontType: PosFontType.fontA,
        ),
      ),
      PosColumn(
        text: "${text2 ?? ''}",
        width: 6,
        styles: PosStyles(
          align: PosAlign.right,
          height: heightSize,
          width: widthSize,
          bold: bold,
          fontType: PosFontType.fontA,
        ),
      ),
    ],
  );
}

decodeImage(dynamicList) async {
  // final ByteData data = await rootBundle.load(url);
  // final Uint8List imageBytes = data.buffer.asUint8List();
  List<int> intList = dynamicList.cast<int>().toList();
  var imageBytes = Uint8List.fromList(intList);
  final img.Image? image = img.decodeImage(imageBytes);
  return img.copyResize(image!, width: 200, height: 200);
}

printCheque(cheque, itemsList) async {
  GetStorage storage = GetStorage();
  Map cashbox = jsonDecode(storage.read('cashbox')!);
  Map settings = jsonDecode(storage.read('settings'));
  List<int> bytes = [];

  try {
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(
      PaperSize.mm58,
      profile,
    );

    if (storage.read('printImage') != null) {
      var imageBytes = await decodeImage(storage.read('printImage'));
      bytes += generator.image(imageBytes);
    }
    // var imageBytes = await decodeImage('images/print_logo.png');
    // bytes += generator.image(imageBytes);
    bytes += generator.text(
      "${cashbox['posName']}",
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size3,
        fontType: PosFontType.fontA,
      ),
      linesAfter: 1,
    );
    bytes += generator.text(
      "Telefon: ${formatPhone(cashbox['posPhone'])}",
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
        fontType: PosFontType.fontA,
      ),
    );
    bytes += generator.text(
      "Manzil: ${cashbox['posAddress']}",
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
        fontType: PosFontType.fontA,
      ),
    );
    bytes += generator.text("", styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
    bytes += getChequeRow(generator, 'Kassir', '${cheque['cashierName']}');
    bytes += getChequeRow(generator, '# Tekshirish', '${cheque['chequeNumber']}');
    bytes += getChequeRow(generator, 'Sana', '${cheque['chequeDate']}');
    bytes += generator.hr(ch: '*');
    // generator.image(imgSrc)
    if (settings['showChequeProducts']) {
      // print(await screenshotController.capture());
      // final Uint8List? productBytes = await screenshotController.capture();
      final Uint8List? productBytes = await getProducts(itemsList);
      final img.Image? image = img.decodeImage(productBytes!);
      bytes += generator.image(img.copyResize(image!, width: 400));
    }
    bytes += generator.hr(ch: '*', linesAfter: 1);
    bytes += getChequeRow(generator, 'Sotish miqdori', '${formatMoney(cheque['totalPrice'])}');
    bytes += getChequeRow(generator, 'Chegirma', '${(formatMoney(cheque['totalPrice'] * cheque['discount'] / 100))}');
    bytes += getChequeRow(
      generator,
      'Tolash uchun',
      '${formatMoney(cheque['to_pay'])}',
      bold: true,
      heightSize: PosTextSize.size1,
      widthSize: PosTextSize.size1,
    );
    bytes += getChequeRow(generator, 'Tolangan', '${formatMoney(cheque['paid'])}');
    bytes += getChequeRow(generator, 'QQS %', '${formatMoney(cheque['totalVatAmount'])}');
    bytes += getChequeRow(generator, 'Qaytim', '${formatMoney(cheque['change'])}');
    bytes += generator.hr(ch: '*', linesAfter: 1);
    if (settings['additionalInfo']) {
      bytes += generator.text(
        "Xaridingiz uchun rahmat",
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      );
    }
    bytes += generator.cut();
    Get.back();
    await BluetoothThermalPrinter.writeBytes(bytes);
  } catch (e) {
    print(e);
    showDangerToast(e.toString());
  }
}

getProducts(List itemsList) async {
  ScreenshotController screenshotController = ScreenshotController();

  final List? bluetooths = await BluetoothThermalPrinter.getBluetooths;
  if (bluetooths != null && bluetooths.isEmpty) {
    return false;
  }

  return await screenshotController
      .captureFromWidget(Screenshot(
    controller: screenshotController,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '№ Товар',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: black,
                    fontSize: 20,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Кол-во',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: black,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Цена',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: black,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < itemsList.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 5, left: 16, right: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${i + 1} ${itemsList[i]['productName']}',
                    style: TextStyle(
                      color: black,
                      fontSize: 18,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      itemsList[i]['returnedQuantity'] != itemsList[i]['quantity']
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${formatMoney(itemsList[i]['quantity'])} * ${formatMoney(itemsList[i]['salePrice'])}',
                                style: TextStyle(
                                  color: black,
                                  fontSize: 20,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Container(),
                      itemsList[i]['returnedQuantity'] != 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${formatMoney(itemsList[i]['returnedQuantity'])}* ${formatMoney(itemsList[i]['salePrice'])}',
                                style: TextStyle(
                                  color: black,
                                  decoration: (itemsList[i]['returned'] != null && itemsList[i]['returned'] > 0) ? TextDecoration.lineThrough : null,
                                  fontSize: 20,
                                  decorationColor: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      itemsList[i]['returnedPrice'] != itemsList[i]['totalPrice']
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${formatMoney(itemsList[i]['totalPrice'])}',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: black,
                                  fontSize: 20,
                                ),
                              ),
                            )
                          : Container(),
                      itemsList[i]['returnedPrice'] != 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${formatMoney(itemsList[i]['returnedPrice'])}',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: black,
                                  decoration: (itemsList[i]['returned'] != null && itemsList[i]['returned'] > 0) ? TextDecoration.lineThrough : null,
                                  decorationColor: Colors.black,
                                  fontSize: 20,
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  ))
      .then((capturedImage) {
    return capturedImage;
  });
}

Future connectToPrinter() async {
  GetStorage storage = GetStorage();
  print(storage.read('defaultPrinter'));
  final String? result = await BluetoothThermalPrinter.connect(storage.read('defaultPrinter'));
  print(result);
  return result == 'true' ? true : false;
}
