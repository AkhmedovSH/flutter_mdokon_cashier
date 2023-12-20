import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:image_picker/image_picker.dart';
import 'package:unicons/unicons.dart';
import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';

import '/helpers/globals.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  GetStorage storage = GetStorage();

  Uint8List? image;
  String? printer;

  Map settings = {
    'showChequeProducts': false,
    'printAfterSale': false,
    'searchGroupProducts': false,
    'selectUserAftersale': false,
    'offlineDeferment': false,
    'additionalInfo': false,
    'language': false,
    'theme': false,
  };

  save() {
    storage.write('settings', jsonEncode(settings));
    showSuccessToast('Настройки сохранены');
  }

  uploadImage() async {
    XFile? img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;
    var imageBytes = (await img.readAsBytes());
    print(imageBytes);
    storage.write("printImage", imageBytes);
    getData();
  }

  getData() {
    print(storage.read('settings'));
    if (storage.read('settings') != null) {
      settings = {...settings, ...jsonDecode(storage.read('settings'))};
    }
    if (storage.read('printImage') != null) {
      // print(storage.read('printImage'));
      List<int> intList = storage.read('printImage').cast<int>().toList();
      image = Uint8List.fromList(intList);
    }
    print(storage.read('defaultPrinter'));
    if (storage.read('defaultPrinter') != null) {
      printer = storage.read('defaultPrinter');
    }
    setState(() {});
  }

  checkStatus() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    if (statuses[Permission.bluetooth] == PermissionStatus.permanentlyDenied || statuses[Permission.bluetooth] == PermissionStatus.denied) {
      return;
    }
    if (statuses[Permission.bluetoothConnect] == PermissionStatus.permanentlyDenied ||
        statuses[Permission.bluetoothConnect] == PermissionStatus.denied) {
      return;
    }
    if (statuses[Permission.location] == PermissionStatus.permanentlyDenied || statuses[Permission.location] == PermissionStatus.denied) {
      return;
    }
    setState(() {
      bluetoothPermission = true;
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
    checkStatus();
  }

  buildCheckBoxRow(String title, String description, String value, {soon = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          settings[value] = !settings[value];
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: white,
          boxShadow: [boxShadow],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        description,
                        style: TextStyle(
                          color: black,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: settings[value],
                  activeColor: mainColor,
                  onChanged: (value) {
                    setState(() {
                      settings[value] = !settings[value];
                    });
                  },
                )
              ],
            ),
            if (soon)
              Positioned.fill(
                top: 0,
                child: Container(
                  color: white.withOpacity(0.8),
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.center,
                  height: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(UniconsLine.clock),
                      SizedBox(width: 10),
                      Text(
                        'Скоро',
                        style: TextStyle(
                          color: grey,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarColor: white, // Status bar
        ),
        bottomOpacity: 0.0,
        backgroundColor: white,
        elevation: 0,
        // centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(
            UniconsLine.arrow_left,
            color: black,
            size: 32,
          ),
        ),
        title: Text(
          'Настройки',
          style: TextStyle(
            color: black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Общее',
                style: TextStyle(
                  color: black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              buildCheckBoxRow('Тема', 'Меняет цветовую гамму', 'theme', soon: true),
              SizedBox(height: 15),
              buildCheckBoxRow('Язык', 'Меняет язык приложения', 'language', soon: true),
              SizedBox(height: 15),
              Text(
                'Касса',
                style: TextStyle(
                  color: black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              buildCheckBoxRow('Выбрать клиента при продаже товара', 'Выбрать клиента при продаже товара', 'selectUserAftersale'),
              SizedBox(height: 15),
              buildCheckBoxRow('Группировка товаров', 'Поиск по группировочным товарам', 'searchGroupProducts', soon: true),
              SizedBox(height: 15),
              buildCheckBoxRow('Отложка оффлайн', 'Отложка оффлайн', 'offlineDeferment', soon: true),
              SizedBox(height: 15),
              Text(
                'Печать',
                style: TextStyle(
                  color: black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  uploadImage();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: white,
                    boxShadow: [boxShadow],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Загрузить изображение',
                              style: TextStyle(
                                color: black,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Изображение будет отображатся в чеках (черно-белый формат)',
                              style: TextStyle(
                                color: black,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (storage.read('printImage') == null)
                        Icon(
                          UniconsLine.image_download,
                        )
                      else if (image != null)
                        SizedBox(
                          child: Image.memory(
                            image!,
                            height: 64,
                            width: 64,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  getBluetooth();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: white,
                    boxShadow: [boxShadow],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Принтер по умолчанию',
                              style: TextStyle(
                                color: black,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Подключитесь к своему принтеру',
                              style: TextStyle(
                                color: black,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (printer == null)
                        Icon(
                          UniconsLine.print_slash,
                        )
                      else if (printer != null)
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.3,
                          child: Text(
                            '$printer',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15),
              buildCheckBoxRow('Автоматическая печать', 'Печатать чек после оплаты', 'printAfterSale'),
              SizedBox(height: 15),
              buildCheckBoxRow('Продукты в чеках', 'Отображать продукты в чеках (влияет на скорость печати)', 'showChequeProducts'),
              SizedBox(height: 15),
              buildCheckBoxRow('Дополнительная информация в чеке', 'Дополнительная информация в чеке', 'additionalInfo'),
              SizedBox(height: 70),
            ],
          ),
        ),
      ),
      bottomSheet: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              save();
            },
            child: Text('Сохранить'),
          ),
        ),
      ),
    );
  }

  Timer? timer;
  bool bluetoothPermission = false;
  bool connected = false;

  int activeIndex = 1000;
  List availableBluetoothDevices = [];

  dynamic tips;
  dynamic device;

  Future<void> getBluetooth() async {
    final List? bluetooths = await BluetoothThermalPrinter.getBluetooths;
    if (bluetooths != null) {
      for (var i = 0; i < bluetooths.length; i++) {
        var item = bluetooths[i].split("#")[1];
        print(storage.read('defaultPrinter'));
        print(item);
        print(storage.read('defaultPrinter') == item);
        if (storage.read('defaultPrinter') == item) {
          activeIndex = i;
        }
      }
      availableBluetoothDevices = bluetooths;

      var status = await BluetoothThermalPrinter.connectionStatus;
      if (status == 'true') {
        connected = true;
      } else {
        connected = false;
      }
      setState(() {});
      if (availableBluetoothDevices.isNotEmpty) {
        openBluetoothDevices();
      } else {
        showDangerToast('Нет активных устройств или отключен блютуз');
      }
    }
  }

  Future<void> setConnect(String mac, newSetState) async {
    if (timer != null) {
      Get.closeCurrentSnackbar();
      timer!.cancel();
    }
    Get.showSnackbar(
      GetSnackBar(
        messageText: Row(
          children: [
            Text(
              'Подключение',
              style: TextStyle(color: white),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                color: white,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
        backgroundColor: mainColor,
      ),
    );
    try {
      timer = Timer(const Duration(seconds: 5), () {
        if (!connected) {
          Get.closeAllSnackbars();
          showDangerToast('Не удалось подключиться');
          newSetState(() {});
          return;
        }
      });
      final String? result = await BluetoothThermalPrinter.connect(mac);
      print(mac);
      storage.write('defaultPrinter', mac);
      Get.closeAllSnackbars();
      if (result == "true") {
        Get.back();
      } else {
        if (timer != null) {
          timer!.cancel();
        }
        showDangerToast('Нет подключения');

        connected = false;
        newSetState(() {});
      }
    } catch (e) {
      Get.closeAllSnackbars();
      print(e);
      showDangerToast(e);
    }
  }

  saveDefaultPrinter() {}

  openBluetoothDevices() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, newSetState) {
          return Container(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxHeight: 500),
                        child: ListView.builder(
                          itemCount: availableBluetoothDevices.isNotEmpty ? availableBluetoothDevices.length : 0,
                          itemBuilder: (context, index) {
                            return ListTile(
                              onTap: () {
                                String select = availableBluetoothDevices[index];
                                List list = select.split("#");
                                String mac = list[1];

                                setConnect(mac, newSetState);
                              },
                              title: Text(
                                '${availableBluetoothDevices[index]}',
                                style: TextStyle(
                                  color: activeIndex == index ? mainColor : black,
                                ),
                              ),
                              subtitle: Text(activeIndex == index ? "Подключенное устройство" : "Нажмите чтобы подключиться"),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
    setState(() {
      availableBluetoothDevices = [];
    });
  }
}
