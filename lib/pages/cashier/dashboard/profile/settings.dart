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
    if (settings['language']) {
      Get.updateLocale(const Locale('uz-Latn-UZ', ''));
    } else {
      Get.updateLocale(const Locale('ru', ''));
    }
    print(settings['theme']);
    if (settings['theme']) {
      Get.changeTheme(ThemeData.dark());
      setState(() {});
    } else {
      Get.changeTheme(ThemeData.light());
    }
    storage.write('settings', jsonEncode(settings));
    showSuccessToast('settings_saved'.tr);
    setState(() {});
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

  buildTitle(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text.tr,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  buildCheckBoxRow(String title, String description, String value, {soon = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          settings[value] = !settings[value];
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
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
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        description.tr,
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: settings[value],
                  activeColor: mainColor,
                  onChanged: (newValue) {
                    settings[value] = !settings[value];
                    setState(() {});
                  },
                )
              ],
            ),
            if (soon)
              Positioned.fill(
                top: 0,
                child: Container(
                  color: context.theme.cardColor.withOpacity(0.8),
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.center,
                  height: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(UniconsLine.clock),
                      SizedBox(width: 10),
                      Text(
                        'soon'.tr,
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
        bottomOpacity: 0.0,
        elevation: 0,
        // centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(
            UniconsLine.arrow_left,
            size: 32,
            color: context.theme.iconTheme.color,
          ),
        ),
        title: Text(
          'settings'.tr,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTitle('general'),
              SizedBox(height: 15),
              buildCheckBoxRow('settings_title_1', 'settings_description_1', 'theme'),
              SizedBox(height: 15),
              buildCheckBoxRow('settings_title_2', 'settings_description_2', 'language'),
              SizedBox(height: 15),
              buildTitle('cashbox'),
              SizedBox(height: 15),
              buildCheckBoxRow('settings_title_3', 'settings_description_3', 'selectUserAftersale'),
              SizedBox(height: 15),
              buildCheckBoxRow('settings_title_4', 'settings_description_4', 'searchGroupProducts', soon: true),
              SizedBox(height: 15),
              buildCheckBoxRow('settings_title_5', 'settings_description_5', 'offlineDeferment', soon: true),
              SizedBox(height: 15),
              buildTitle('print'),
              SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  uploadImage();
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
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
                              'settings_title_6'.tr,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'settings_description_6'.tr,
                              style: TextStyle(
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
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
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
                              'settings_title_7'.tr,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'settings_description_7'.tr,
                              style: TextStyle(
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
              buildCheckBoxRow('settings_title_8', 'settings_description_8', 'printAfterSale'),
              SizedBox(height: 15),
              buildCheckBoxRow('settings_title_9', 'settings_description_9', 'showChequeProducts'),
              SizedBox(height: 15),
              buildCheckBoxRow('settings_title_10', 'settings_description_10', 'additionalInfo'),
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
            child: Text('save'.tr),
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
        showDangerToast('there_are_no_active_devices_bluetooth_is_disabled'.tr);
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
              'connection'.tr,
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
          showDangerToast('failed_to_connect'.tr);
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
        showDangerToast('no_connection'.tr);

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
                              subtitle: Text(activeIndex == index ? "connected_device".tr : "click_to_connect".tr),
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
