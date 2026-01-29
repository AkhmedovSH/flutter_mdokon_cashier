import 'dart:async';
import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_mdokon/helpers/helper.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image/image.dart' as img;

class PrinterModel extends ChangeNotifier {
  GetStorage storage = GetStorage();

  BluetoothDevice? selectedDevice;
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  StreamSubscription? scanSubscription;
  StreamSubscription? isScanningSubscription;

  String get selectedDeviceName => customIf(storage.read('printerName')) ? storage.read('printerName') : selectedDevice!.advName;
  String get printerSize => customIf(storage.read('printerSize')) ? storage.read('printerSize') : '576';

  PrinterModel() {
    isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      isScanning = state;
      notifyListeners();
    });
  }

  setPrinterSize(value) {
    storage.write('printerSize', value);
    notifyListeners();
  }

  void selectDevice(BluetoothDevice device) {
    selectedDevice = device;
    storage.write('printerId', selectedDevice!.remoteId.str);
    storage.write('printerName', selectedDevice!.advName);
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
    String? savedId = GetStorage().read('printerId');
    if (savedId == null) return;
    print(111);
    print(savedId);
    try {
      List<BluetoothDevice> devices = await FlutterBluePlus.systemDevices([]);
      print(devices);
      print(BluetoothDevice.fromId(savedId));

      for (var device in devices) {
        if (device.remoteId.str == savedId) {
          selectedDevice = device;
          debugPrint("Восстановлено системное устройство: ${device.platformName}");
          return;
        }
      }

      selectedDevice = BluetoothDevice.fromId(savedId);
    } catch (e) {
      debugPrint("Ошибка при автоподключении: $e");
    }
  }

  Future<void> printFullCheque(Map cheque, List itemsList) async {
    if (selectedDevice == null) return;

    final profile = await CapabilityProfile.load(name: 'default');
    PaperSize paperSize = PaperSize.mm80;
    if (printerSize == '384') {
      paperSize = PaperSize.mm58;
    } else if (printerSize == '512') {
      paperSize = PaperSize.mm72;
    }
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];
    final settings = storage.read('settings');
    final cashboxSettings = storage.read('cashboxSettings');
    print(cashboxSettings);
    bytes += generator.reset();
    bytes += generator.setGlobalCodeTable('CP866');

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
    // bytes += await textCyrillic(generator, 'Кассир: Иванов', styles: const PosStyles(align: PosAlign.left));
    bytes += _getChequeRow(generator, 'Kassir', '${cheque['cashierName'] ?? ''}');
    bytes += _getChequeRow(generator, '# Tekshirish', '${cheque['chequeNumber'] ?? ''}');
    bytes += _getChequeRow(generator, 'Sana', '${cheque['chequeDate'] ?? ''}');
    bytes += generator.hr(ch: '*');

    if (customIf(storage.read('showChequeProducts'))) {
      final cfg = tableConfigForPaper(int.parse(printerSize));
      bytes += await tableDivider(generator, cfg);

      // Шапка таблицы
      bytes += await tableLine(
        generator,
        cfg,
        'Товар',
        'Кол-во',
        'Сумма',
        bold: true,
      );
      bytes += await tableDivider(generator, cfg);

      // Товары
      for (int i = 0; i < itemsList.length; i++) {
        final item = itemsList[i];

        final name = '${i + 1}. ${item['productName']}';
        final qty = '${item['quantity']}x${formatMoney(item['salePrice'], decimalDigits: 0)}';
        final sum = formatMoney(
          customNumber(item['quantity']) * customNumber(item['salePrice']),
        );

        bytes += await tableLine(
          generator,
          cfg,
          name,
          qty,
          sum,
        );

        // Промокоды
        final promoCodes = item['promoCodes'];
        if (promoCodes is List && promoCodes.isNotEmpty) {
          for (final code in promoCodes) {
            bytes += await promoCodeLine(
              generator,
              cfg,
              code.toString(),
            );
          }
        }
      }

      bytes += await tableDivider(generator, cfg);
    }

    // 5. Итоги
    bytes += _getChequeRow(generator, 'Sotish miqdori', '${formatMoney(cheque['totalPrice'] ?? 0)}');
    bytes += _getChequeRow(generator, 'Chegirma', '${formatMoney(cheque['discountAmount'] ?? 0)}');

    bytes += _getChequeRow(
      generator,
      'Tolash uchun',
      '${formatMoney(cheque['to_pay'] ?? 0)}',
      bold: true,
    );

    bytes += _getChequeRow(generator, 'Tolangan', '${formatMoney(cheque['paid'] ?? 0)}');
    bytes += _getChequeRow(generator, 'QQS %', '${formatMoney(cheque['totalVatAmount'] ?? 0)}');
    bytes += generator.hr(ch: '*', linesAfter: 1);

    // 6. Подвал
    if (settings?['additionalInfo'] == true) {
      bytes += generator.text("Xaridingiz uchun rahmat", styles: const PosStyles(align: PosAlign.center));
    }

    bytes += generator.feed(1);
    bytes += generator.cut();

    await _sendBytesToDevice(bytes);
  }

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

  String padToTableWidth(String line, int totalWidth) {
    if (line.length < totalWidth) {
      return line + ' ' * (totalWidth - line.length);
    }
    return line;
  }

  Future<List<int>> tableLine(
    Generator generator,
    TableConfig cfg,
    String name,
    String qty,
    String sum, {
    bool bold = false,
  }) async {
    final nameLines = wrapText(name, cfg.name);
    final bytes = <int>[];

    for (int i = 0; i < nameLines.length; i++) {
      final rawLine =
          cell(nameLines[i], cfg.name) +
          '|' +
          cell(i == 0 ? qty : '', cfg.qty, align: 'center') +
          '|' +
          cell(i == 0 ? sum : '', cfg.sum, align: 'right');

      final line = padToTableWidth(rawLine, cfg.total);

      bytes.addAll(
        await textCyrillic(
          generator,
          line,
          bold: bold && i == 0,
        ),
      );
    }

    return bytes;
  }

  Future<List<int>> promoCodeLine(
    Generator generator,
    TableConfig cfg,
    String promoCode,
  ) async {
    final rawLine = cell('Промокод', cfg.name) + '|' + cell('', cfg.qty, align: 'center') + '|' + cell(promoCode, cfg.sum, align: 'right');

    final line = padToTableWidth(rawLine, cfg.total);

    return textCyrillic(generator, line);
  }

  Future<List<int>> tableDivider(
    Generator generator,
    TableConfig cfg,
  ) async {
    final line = ('-' * cfg.name) + ('-' * cfg.qty) + ('-' * cfg.sum);

    return textCyrillic(generator, line);
  }

  String cell(
    String text,
    int width, {
    String align = 'left',
  }) {
    if (text.length > width) {
      text = text.substring(0, width);
    }

    switch (align) {
      case 'right':
        return text.padLeft(width);
      case 'center':
        final pad = width - text.length;
        return ' ' * (pad ~/ 2) + text + ' ' * (pad - pad ~/ 2);
      default:
        return text.padRight(width);
    }
  }

  List<String> wrapText(String text, int width) {
    final result = <String>[];
    var line = '';

    for (final word in text.split(' ')) {
      if (line.isEmpty) {
        line = word;
      } else if ((line.length + 1 + word.length) <= width) {
        line += ' $word';
      } else {
        result.add(line);
        line = word;
      }
    }

    if (line.isNotEmpty) result.add(line);
    return result;
  }

  Future<List<int>> textCyrillic(
    Generator generator,
    String text, {
    bool bold = false,
  }) async {
    final encoded = await CharsetConverter.encode('CP866', text);

    return generator.textEncoded(
      Uint8List.fromList(encoded),
      styles: PosStyles(
        bold: bold,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );
  }

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

  Future<void> printXReport(
    Map report,
    Map cashbox,
    Map<String, String> labels,
  ) async {
    if (selectedDevice == null) return;

    final profile = await CapabilityProfile.load(name: 'default');
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.setGlobalCodeTable('CP866');

    // ---------- ШАПКА ----------
    bytes += await _text(
      generator,
      report['isZReport'] == true ? labels['z_report']! : labels['x_report']!,
      bold: true,
      align: PosAlign.center,
    );

    bytes += await _text(
      generator,
      report['posName'] ?? '',
      align: PosAlign.center,
    );

    bytes += await _text(
      generator,
      '${labels['phone']}: ${cashbox['posPhone'] ?? ''}',
      align: PosAlign.center,
    );

    bytes += generator.hr();

    // ---------- ОБЩАЯ ИНФА ----------
    bytes += await _row(generator, labels['cashier']!, '${report['cashierName'] ?? ''}');
    bytes += await _row(generator, labels['shift_ID']!, '${report['shiftId'] ?? ''}');
    bytes += await _row(generator, labels['cashbox_number']!, '${report['shiftNumber'] ?? ''}');

    if (report['tin'] != null) {
      bytes += await _row(generator, labels['inn']!, '${report['tin']}');
    }

    bytes += await _row(generator, labels['date']!, '${report['shiftOpenDate'] ?? ''}', align: RowAlign.rightWide);
    bytes += await _row(generator, labels['shift_duration']!, '${report['shiftDuration'] ?? ''}');

    bytes += generator.hr();

    // ---------- СЧЁТЧИКИ ----------
    bytes += await _row(generator, labels['number_of_receipts']!, '${report['totalCountCheque'] ?? 0}');
    bytes += await _row(generator, labels['number_of_returned_receipts']!, '${report['countReturnedCheque'] ?? 0}', align: RowAlign.leftWide);
    bytes += await _row(generator, labels['number_of_returned_products']!, '${report['countReturnedProducts'] ?? 0}', align: RowAlign.leftWide);

    if ((report['countDeletedCheque'] ?? 0) > 0) {
      bytes += await _row(
        generator,
        '${labels['number_of_receipts']} (${labels['deleted']})',
        '${report['countDeletedCheque']}',
      );
    }

    bytes += generator.hr();

    // ---------- ПРОДАЖИ ----------
    if (report['salesList'] != null) {
      for (final item in report['salesList']) {
        bytes += await _row(
          generator,
          '${labels['sales_amount']} (${item['currencyName']})',
          formatMoney(item['salesAmount']),
        );
        bytes += await _row(
          generator,
          '${labels['discount_amount']} (${item['currencyName']})',
          formatMoney(item['discountAmount']),
        );
        bytes += await _row(
          generator,
          '${labels['return_amount']} (${item['currencyName']})',
          formatMoney(item['returnAmount']),
        );
        bytes += generator.feed(1);
      }
    }

    bytes += generator.hr();

    // ---------- ПРИХОД ----------
    if (report['amountInList'] != null && report['amountInList'].isNotEmpty) {
      bytes += await _text(generator, labels['income']!, bold: true);
      for (final item in report['amountInList']) {
        bytes += await _row(
          generator,
          '${item['paymentTypeName'] ?? ''} ${item['paymentPurposeName'] ?? ''}',
          '${formatMoney(item['amountIn'])} ${item['currencyName']}',
        );
      }
    }

    // ---------- РАСХОД ----------
    if (report['amountOutList'] != null && report['amountOutList'].isNotEmpty) {
      bytes += await _text(generator, labels['expense']!, bold: true);
      for (final item in report['amountOutList']) {
        bytes += await _row(
          generator,
          '${item['paymentTypeName'] ?? ''} ${item['paymentPurposeName'] ?? ''}',
          '${formatMoney(item['amountOut'])} ${item['currencyName']}',
        );
      }
    }

    bytes += generator.hr();

    // ---------- БАЛАНС ----------
    if (report['balanceList'] != null) {
      for (final item in report['balanceList']) {
        bytes += await _row(
          generator,
          labels['cashbox_balance']!,
          '${formatMoney(item['balance'])} ${item['currencyName']}',
        );
      }
    }

    // ---------- ИТОГИ ----------
    if (report['totalList'] != null) {
      for (final item in report['totalList']) {
        if ((item['totalCash'] ?? 0) > 0) {
          bytes += await _row(
            generator,
            '${labels['total_cash']} (${item['currencyName']})',
            formatMoney(item['totalCash']),
          );
        }
        if ((item['totalBank'] ?? 0) > 0) {
          bytes += await _row(
            generator,
            '${labels['total_bank']} (${item['currencyName']})',
            formatMoney(item['totalBank']),
          );
        }
      }
    }

    if ((report['countRequest'] ?? 0) > 0) {
      bytes += await _row(
        generator,
        labels['number_of_x_reports']!,
        '${report['countRequest']}',
      );
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    await _sendBytesToDevice(bytes);
  }

  Future<List<int>> _row(
    Generator g,
    String left,
    String right, {
    RowAlign align = RowAlign.normal,
  }) async {
    int leftWidth;
    int rightWidth;

    switch (align) {
      case RowAlign.leftWide:
        leftWidth = 32;
        rightWidth = 16;
        break;
      case RowAlign.rightWide:
        leftWidth = 16;
        rightWidth = 32;
        break;
      default:
        leftWidth = 24;
        rightWidth = 24;
    }

    // Жёсткое ограничение
    if (left.length > leftWidth) {
      left = left.substring(0, leftWidth);
    }
    if (right.length > rightWidth) {
      right = right.substring(0, rightWidth);
    }

    final line = left.padRight(leftWidth) + right.padLeft(rightWidth);

    return _text(g, line);
  }

  Future<List<int>> _text(
    Generator g,
    String text, {
    bool bold = false,
    PosAlign align = PosAlign.left,
  }) async {
    final encoded = await CharsetConverter.encode('CP866', text);
    return g.textEncoded(
      Uint8List.fromList(encoded),
      styles: PosStyles(
        bold: bold,
        align: align,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );
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

class TableConfig {
  final int name;
  final int qty;
  final int sum;

  TableConfig({
    required this.name,
    required this.qty,
    required this.sum,
  });

  int get total => name + qty + sum + 2;
}

TableConfig tableConfigForPaper(int printerWidthPx) {
  if (printerWidthPx <= 400) {
    return TableConfig(
      name: 13,
      qty: 7,
      sum: 8,
    );
  } else {
    return TableConfig(
      name: 22,
      qty: 11,
      sum: 13,
    );
  }
}

enum RowAlign {
  normal, // 24 / 24
  leftWide, // 32 / 16
  rightWide, // 16 / 32
}
