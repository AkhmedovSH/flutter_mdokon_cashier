import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_mdokon/helpers/helper.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';

class PrinterModel extends ChangeNotifier {
  GetStorage storage = GetStorage();

  BluetoothDevice? selectedDevice;
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  StreamSubscription? scanSubscription;
  StreamSubscription? isScanningSubscription;

  PrinterModel() {
    isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      isScanning = state;
      notifyListeners();
    });
  }

  void selectDevice(BluetoothDevice device) {
    selectedDevice = device;
    storage.write('printer_id', selectedDevice!.remoteId.str);
    notifyListeners();
  }

  Future<void> startScan() async {
    if (await FlutterBluePlus.isSupported == false) return;
    scanResults.clear();
    scanSubscription?.cancel();
    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    scanSubscription?.cancel();
  }

  Future<void> autoConnectSavedPrinter() async {
    String? savedId = GetStorage().read('printer_id');
    if (savedId == null) return;

    try {
      List<BluetoothDevice> devices = await FlutterBluePlus.systemDevices([]);

      for (var device in devices) {
        if (device.remoteId.str == savedId) {
          selectedDevice = device;
          notifyListeners();
          debugPrint("Восстановлено системное устройство: ${device.platformName}");
          return;
        }
      }

      selectedDevice = BluetoothDevice.fromId(savedId);
      notifyListeners();
    } catch (e) {
      debugPrint("Ошибка при автоподключении: $e");
    }
  }

  Future<void> printFullCheque(Map cheque, List itemsList) async {
    if (selectedDevice == null) return;

    final profile = await CapabilityProfile.load(name: 'default');
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];
    final settings = jsonDecode(storage.read('settings'));
    print(settings);
    bytes += generator.reset();

    // 1. Логотип (если есть в хранилище)
    if (storage.read('printImage') != null) {
      final img.Image? logo = await _decodeImage(storage.read('printImage'));
      if (logo != null) {
        bytes += generator.image(logo);
      }
    }

    // 2. Шапка чека
    bytes += generator.text(
      "${cheque['posName'] ?? ''}",
      styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
      linesAfter: 1,
    );

    if (cheque['posPhone'] != null) {
      bytes += generator.text("Telefon: ${cheque['posPhone']}", styles: const PosStyles(align: PosAlign.center));
    }
    if (cheque['posAddress'] != null) {
      bytes += generator.text("Manzil: ${cheque['posAddress']}", styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
    }

    // 3. Инфо о чеке
    bytes += _getChequeRow(generator, 'Kassir', '${cheque['cashierName'] ?? ''}');
    bytes += _getChequeRow(generator, '# Tekshirish', '${cheque['chequeNumber'] ?? ''}');
    bytes += _getChequeRow(generator, 'Sana', '${cheque['chequeDate'] ?? ''}');
    bytes += generator.hr(ch: '*');

    if (customIf(storage.read('showChequeProducts'))) {
      final Uint8List? productBytes = await _generateProductsTable(itemsList);
      if (productBytes != null) {
        final img.Image? image = img.decodeImage(productBytes);
        if (image != null) {
          bytes += generator.image(img.copyResize(image, width: 576)); // 384px - стандарт для 58mm
        }
      }
      bytes += generator.hr(ch: '*');
    }

    // 5. Итоги
    bytes += _getChequeRow(generator, 'Sotish miqdori', '${cheque['totalPrice'] ?? 0}');
    bytes += _getChequeRow(generator, 'Chegirma', '${cheque['discountAmount']}');

    bytes += _getChequeRow(
      generator,
      'Tolash uchun',
      '${cheque['to_pay'] ?? 0}',
      bold: true,
    );

    bytes += _getChequeRow(generator, 'Tolangan', '${cheque['paid'] ?? 0}');
    bytes += _getChequeRow(generator, 'QQS %', '${cheque['totalVatAmount'] ?? 0}');
    bytes += generator.hr(ch: '*', linesAfter: 1);

    // 6. Подвал
    if (settings?['additionalInfo'] == true) {
      bytes += generator.text("Xaridingiz uchun rahmat", styles: const PosStyles(align: PosAlign.center));
    }

    bytes += generator.feed(1);
    bytes += generator.cut();

    await _sendBytesToDevice(bytes);
  }

  // Декодирование логотипа из старого кода
  Future<img.Image?> _decodeImage(dynamic dynamicList) async {
    try {
      List<int> intList = dynamicList.cast<int>().toList();
      var imageBytes = Uint8List.fromList(intList);
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;
      return img.copyResize(image, width: 200, height: 200);
    } catch (e) {
      return null;
    }
  }

  // Улучшенная генерация таблицы товаров (как в старом коде)
  Future<Uint8List?> _generateProductsTable(List itemsList) async {
    final screenshotController = ScreenshotController();
    return await screenshotController.captureFromWidget(
      Container(
        color: Colors.white,
        width: 576, // Фиксированная ширина для стабильности рендера
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовки
            Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    '№ Товар',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Кол-во',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Цена',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.black),
            // Список
            for (var i = 0; i < itemsList.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text('${i + 1}. ${itemsList[i]['productName']}', style: const TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${itemsList[i]['quantity']} x',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${itemsList[i]['salePrice']}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Вспомогательный метод для строк чека
  List<int> _getChequeRow(Generator generator, String left, String right, {bool bold = false}) {
    return generator.row([
      PosColumn(
        text: left,
        width: 6,
        styles: PosStyles(align: PosAlign.left, bold: bold),
      ),
      PosColumn(
        text: right,
        width: 6,
        styles: PosStyles(align: PosAlign.right, bold: bold),
      ),
    ]);
  }

  Future<void> _sendBytesToDevice(List<int> bytes) async {
    if (selectedDevice == null) return;

    // 1. Подключаемся, если еще не подключены
    await selectedDevice!.connect(license: License.free);

    // 2. MTU уже настроен в логах, но для уверенности оставим
    try {
      await selectedDevice!.requestMtu(247);
    } catch (_) {}

    final services = await selectedDevice!.discoverServices();
    for (var service in services) {
      for (var char in service.characteristics) {
        if (char.properties.write || char.properties.writeWithoutResponse) {
          // --- РЕШЕНИЕ ПРОБЛЕМЫ: Нарезка на чанки ---
          const int chunkSize = 200; // Берем чуть меньше MTU для стабильности
          for (int i = 0; i < bytes.length; i += chunkSize) {
            int end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;

            // Отправляем кусочек данных
            await char.write(bytes.sublist(i, end), withoutResponse: true);

            // Маленькая пауза, чтобы принтер успел обработать пакет
            await Future.delayed(const Duration(milliseconds: 50));
          }

          debugPrint("Печать завершена успешно");
          return;
        }
      }
    }
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    isScanningSubscription?.cancel();
    super.dispose();
  }
}
