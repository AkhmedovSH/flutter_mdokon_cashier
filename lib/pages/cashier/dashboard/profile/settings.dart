import 'dart:async';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mdokon/models/cashier/print_model.dart';
import 'package:flutter_mdokon/models/locale_model.dart';
import 'package:flutter_mdokon/widgets/dialogs.dart';

import 'package:get_storage/get_storage.dart';
import '/helpers/themes.dart';
import '/models/settings_model.dart';
import '/models/theme_model.dart';

import '/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:unicons/unicons.dart';
// import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../helpers/helper.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  GetStorage storage = GetStorage();

  Uint8List? image;
  final List<Map<String, dynamic>> sizes = [
    {
      "id": '576',
      "name": '80mm',
    },
    {
      "id": '512',
      "name": '72mm',
    },
    {
      "id": '384',
      "name": '58mm',
    },
  ];

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

  // uploadImage() async {
  //   XFile? img = await ImagePicker().pickImage(source: ImageSource.gallery);
  //   if (img == null) return;
  //   var imageBytes = (await img.readAsBytes());
  //   print(imageBytes);
  //   storage.write("printImage", imageBytes);
  //   getData();
  // }

  getData() {
    if (storage.read('settings') != null) {
      settings = {...settings, ...(storage.read('settings') ?? {})};
    }
    if (storage.read('printImage') != null) {
      List<int> intList = storage.read('printImage').cast<int>().toList();
      image = Uint8List.fromList(intList);
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

  @override
  Widget build(BuildContext context) {
    final settingsModel = Provider.of<SettingsModel>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'settings',
        leading: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            spacing: 15,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Title(title: 'general'),

              CardItem(
                title: 'settings_title_1',
                description: 'settings_description_1',
                value: settingsModel.theme,
                onChanged: (value) {
                  if (value) {
                    Provider.of<ThemeModel>(context, listen: false).setTheme(darkTheme);
                  } else {
                    Provider.of<ThemeModel>(context, listen: false).setTheme(lightTheme);
                  }

                  settingsModel.updateSetting('theme', value);
                },
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                decoration: BoxDecoration(
                  color: CustomTheme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        context.tr('language'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 115,
                      child: Consumer<LocaleModel>(
                        builder: (context, localeModel, chilld) {
                          return DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              value: localeModel.localeName,
                              buttonStyleData: const ButtonStyleData(width: 125),
                              dropdownStyleData: DropdownStyleData(
                                width: 125,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: CustomTheme.of(context).cardColor,
                                ),
                                offset: const Offset(-10, -10),
                              ),
                              isDense: true,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  Locale locale = const Locale('ru', '');
                                  if (newValue == 'ru') {
                                    locale = const Locale('ru', '');
                                  }
                                  if (newValue == 'uz') {
                                    locale = const Locale('uz', 'Latn');
                                  }
                                  context.setLocale(locale);
                                  localeModel.setLocale(locale);
                                }
                              },
                              items: languages.map(
                                (Map<String, dynamic> language) {
                                  return DropdownMenuItem<String>(
                                    value: language['locale'],
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      child: Text(language['name']!),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Title(title: 'cashbox'),

              CardItem(
                title: 'settings_title_12',
                description: 'settings_description_12',
                value: settingsModel.changeCurrencyOnSale,
                onChanged: (value) {
                  settingsModel.updateSetting('changeCurrencyOnSale', value);
                },
              ),

              Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: CustomTheme.of(context).cardColor,
                  boxShadow: [boxShadow],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('settings_title_11'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      context.tr('settings_description_11', args: ['${formatMoney(500.99999)}']),
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    SfSlider(
                      min: 0,
                      max: 5,
                      value: settingsModel.decimalDigits,
                      interval: 1,
                      showTicks: true,
                      showLabels: true,
                      enableTooltip: false,
                      showDividers: true,
                      minorTicksPerInterval: 0,
                      stepSize: 1,
                      activeColor: mainColor,
                      inactiveColor: Colors.grey.shade200,
                      onChanged: (dynamic value) {
                        settingsModel.updateSetting('decimalDigits', value);
                      },
                    ),
                  ],
                ),
              ),

              Title(title: 'print'),

              GestureDetector(
                onTap: () async {
                  PrinterModel printerModel = Provider.of<PrinterModel>(context, listen: false);
                  printerModel.startScan();
                  await showPrinterPicker(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: CustomTheme.of(context).cardColor,
                    boxShadow: [boxShadow],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('settings_title_7'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              context.tr('settings_description_7'),
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Consumer<PrinterModel>(
                        builder: (context, model, child) {
                          if (customIf(model.selectedDevice)) {
                            return SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3,
                              child: Text(model.selectedDeviceName),
                            );
                          } else {
                            return Icon(
                              UniconsLine.print_slash,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                decoration: BoxDecoration(
                  color: CustomTheme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        context.tr('receipt_print_width'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 115,
                      child: Consumer<PrinterModel>(
                        builder: (context, model, chilld) {
                          return DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              value: model.printerSize,
                              buttonStyleData: const ButtonStyleData(width: 125),
                              dropdownStyleData: DropdownStyleData(
                                width: 125,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: CustomTheme.of(context).cardColor,
                                ),
                                offset: const Offset(-10, -10),
                              ),
                              isDense: true,
                              onChanged: (String? newValue) {
                                model.setPrinterSize(newValue);
                              },
                              items: sizes.map(
                                (Map<String, dynamic> item) {
                                  return DropdownMenuItem<String>(
                                    value: item['id'],
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      child: Text(item['name']!),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              //
              // GestureDetector(
              //   onTap: () {},
              //   child: Container(
              //     margin: EdgeInsets.symmetric(horizontal: 12),
              //     padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              //     decoration: BoxDecoration(
              //       color: CustomTheme.of(context).cardColor,
              //       boxShadow: [boxShadow],
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     child: Row(
              //       crossAxisAlignment: CrossAxisAlignment.center,
              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //       children: [
              //         SizedBox(
              //           width: MediaQuery.of(context).size.width * 0.6,
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               Text(
              //                 context.tr('settings_title_6'),
              //                 style: TextStyle(
              //                   fontSize: 18,
              //                   fontWeight: FontWeight.w500,
              //                 ),
              //               ),
              //               SizedBox(height: 5),
              //               Text(
              //                 context.tr('settings_description_6'),
              //                 style: TextStyle(
              //                   fontSize: 12,
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //         if (storage.read('printImage') == null)
              //           Icon(
              //             UniconsLine.image_download,
              //           )
              //         else if (image != null)
              //           SizedBox(
              //             child: Image.memory(
              //               image!,
              //               height: 64,
              //               width: 64,
              //             ),
              //           ),
              //       ],
              //     ),
              //   ),
              // ),
              CardItem(
                title: 'settings_title_8',
                description: 'settings_description_8',
                value: settingsModel.printAfterSale,
                onChanged: (value) {
                  settingsModel.updateSetting('printAfterSale', value);
                },
              ),

              CardItem(
                title: 'settings_title_9',
                description: 'settings_description_9',
                value: settingsModel.showChequeProducts,
                onChanged: (value) {
                  settingsModel.updateSetting('showChequeProducts', value);
                },
              ),

              CardItem(
                title: 'settings_title_10',
                description: 'settings_description_10',
                value: settingsModel.additionalInfo,
                onChanged: (value) {
                  settingsModel.updateSetting('additionalInfo', value);
                },
              ),
            ],
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
    // final List? bluetooths = await BluetoothThermalPrinter.getBluetooths;
    // if (bluetooths != null) {
    //   for (var i = 0; i < bluetooths.length; i++) {
    //     var item = bluetooths[i].split("#")[1];
    //     if (storage.read('defaultPrinter') == item) {
    //       activeIndex = i;
    //     }
    //   }
    //   availableBluetoothDevices = bluetooths;

    //   var status = await BluetoothThermalPrinter.connectionStatus;
    //   if (status == 'true') {
    //     connected = true;
    //   } else {
    //     connected = false;
    //   }
    //   setState(() {});
    //   if (availableBluetoothDevices.isNotEmpty) {
    //     openBluetoothDevices();
    //   } else {
    //     showDangerToast('there_are_no_active_devices_bluetooth_is_disabled'.tr);
    //   }
    // }
  }

  // Future<void> setConnect(String mac, newSetState) async {
  //   if (timer != null) {
  //     Get.closeCurrentSnackbar();
  //     timer!.cancel();
  //   }
  //   Get.showSnackbar(
  //     GetSnackBar(
  //       messageText: Row(
  //         children: [
  //           Text(
  //             'connection'.tr,
  //             style: TextStyle(color: white),
  //           ),
  //           const SizedBox(width: 10),
  //           SizedBox(
  //             height: 16,
  //             width: 16,
  //             child: CircularProgressIndicator(
  //               color: white,
  //               strokeWidth: 2,
  //             ),
  //           ),
  //         ],
  //       ),
  //       backgroundColor: mainColor,
  //     ),
  //   );
  //   try {
  //     timer = Timer(const Duration(seconds: 5), () {
  //       if (!connected) {
  //         Get.closeAllSnackbars();
  //         showDangerToast('failed_to_connect'.tr);
  //         newSetState(() {});
  //         return;
  //       }
  //     });
  //     final String? result = await BluetoothThermalPrinter.connect(mac);
  //     print(mac);
  //     storage.write('defaultPrinter', mac);
  //     Get.closeAllSnackbars();
  //     if (result == "true") {
  //       Get.back();
  //     } else {
  //       if (timer != null) {
  //         timer!.cancel();
  //       }
  //       showDangerToast('no_connection'.tr);

  //       connected = false;
  //       newSetState(() {});
  //     }
  //   } catch (e) {
  //     Get.closeAllSnackbars();
  //     print(e);
  //     showDangerToast(e);
  //   }
  // }

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
        return StatefulBuilder(
          builder: (context, newSetState) {
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
                                  // String select = availableBluetoothDevices[index];
                                  // List list = select.split("#");
                                  // String mac = list[1];

                                  // setConnect(mac, newSetState);
                                },
                                title: Text(
                                  '${availableBluetoothDevices[index]}',
                                  style: TextStyle(
                                    color: activeIndex == index ? mainColor : black,
                                  ),
                                ),
                                subtitle: Text(activeIndex == index ? context.tr("connected_device") : context.tr("click_to_connect")),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    setState(() {
      availableBluetoothDevices = [];
    });
  }
}

class Title extends StatelessWidget {
  final String title;

  const Title({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr(title),
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class CardItem extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final bool soon;
  final ValueChanged<bool> onChanged;

  const CardItem({
    super.key,
    required this.title,
    this.description = '',
    required this.value,
    this.soon = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: CustomTheme.of(context).cardColor,
          boxShadow: [boxShadow],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Row(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(title),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        context.tr(description),
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: value,
                  activeColor: mainColor,
                  onChanged: onChanged,
                ),
              ],
            ),
            if (soon)
              Positioned.fill(
                top: 0,
                child: Container(
                  color: CustomTheme.of(context).cardColor.withOpacity(0.8),
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.center,
                  height: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(UniconsLine.clock),
                      SizedBox(width: 10),
                      Text(
                        context.tr('soon'),
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
}
