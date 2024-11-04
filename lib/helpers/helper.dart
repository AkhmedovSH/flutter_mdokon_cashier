import 'dart:math';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/models/filter_model.dart';
import '../widgets/custom_app_bar.dart';
import 'themes.dart';
import '/models/theme_model.dart';
import 'package:provider/provider.dart';

import 'package:toastification/toastification.dart';
import 'package:unicons/unicons.dart';

class CustomTheme {
  final BuildContext context;

  CustomTheme(this.context);

  static CustomTheme of(BuildContext context) => CustomTheme(context);

  bool get isDarkMode => Provider.of<ThemeModel>(context).themeData == darkTheme;

  Color get bgColor => isDarkMode ? DarkThemeColors.bgColor : LightThemeColors.bgColor;
  Color get textColor => isDarkMode ? DarkThemeColors.textColor : LightThemeColors.textColor;
  Color get textColorSecond => isDarkMode ? DarkThemeColors.textColor : LightThemeColors.textColor;
  Color get cardColor => isDarkMode ? DarkThemeColors.cardColor : LightThemeColors.cardColor;
  Color get inputColor => isDarkMode ? DarkThemeColors.inputColor : LightThemeColors.inputColor;
  //
  LinearGradient get gradient => isDarkMode ? DarkThemeColors.gradient : LightThemeColors.gradient;
  LinearGradient get secondGradient => isDarkMode ? DarkThemeColors.secondGradient : LightThemeColors.secondGradient;
}

Color mainColor = const Color(0xFF5b73e8);

Color bgColor = const Color(0xFFF3F8FE);

Color blue = const Color(0xFF5b73e8);
Color grey = const Color(0xFF999999);
Color black = const Color(0xFF000000);
Color darkGrey = const Color(0xFF626262);
Color lightGrey = const Color(0xFF9C9C9C);
Color green = const Color(0xFF28C56F);
Color red = const Color(0xFFE32F45);
Color orange = const Color(0xFFFE9D42);
Color white = const Color(0xFFFFFFFF);
Color inputColor = const Color(0xFFF3F7FA);
Color yellow = const Color(0xFFF3A919);
Color borderColor = const Color(0xFFF8F8F8);

Color tableBorderColor = const Color(0xFFDADADa);
Color disabledColor = const Color(0xFFd3d3d3);

Color success = const Color(0xFF34c38f);
Color warning = const Color(0xFFf1b44c);
Color danger = const Color(0xFFf46a6a);

Color a2 = const Color(0xFFA2A2A2);
Color b8 = const Color(0xFF7b8190);

const systemOverlayStyleLight = SystemUiOverlayStyle(
  statusBarIconBrightness: Brightness.light,
  statusBarColor: Colors.transparent,
);

const systemOverlayStyleDark = SystemUiOverlayStyle(
  statusBarIconBrightness: Brightness.dark,
  statusBarColor: Colors.transparent,
);

BoxShadow boxShadow = BoxShadow(
  color: Colors.black.withOpacity(0.15),
  spreadRadius: 0,
  blurRadius: 3,
  offset: const Offset(0, 0),
);

BoxDecoration border = BoxDecoration(
  border: Border.all(
    color: const Color.fromARGB(255, 209, 209, 209),
  ),
  borderRadius: BorderRadius.circular(16),
);

OutlineInputBorder inputBorder = OutlineInputBorder(
  borderSide: const BorderSide(color: Color(0xFFdddddd)),
  borderRadius: BorderRadius.circular(16),
);

OutlineInputBorder inputFocusBorder = OutlineInputBorder(
  borderSide: BorderSide(color: mainColor),
  borderRadius: BorderRadius.circular(16),
);

OutlineInputBorder inputErrorBorder = OutlineInputBorder(
  borderSide: BorderSide(color: danger),
  borderRadius: BorderRadius.circular(16),
);

getUnixTime() {
  return DateTime.now().toUtc().millisecondsSinceEpoch;
}

generateChequeNumber() {
  return getUnixTime().toString().substring(getUnixTime().toString().length - 8);
}

generateTransactionId(posId, cashboxId, shiftId) {
  var random = Random();
  return posId.toString() + cashboxId.toString() + shiftId.toString() + getUnixTime().toString() + (random.nextInt(999999).floor().toString());
}

int daysBetween(from, DateTime to) {
  from = DateTime(from['year'], from['month'], from['day']);
  to = DateTime(to.year, to.month, to.day);
  return (to.difference(from).inHours / 24).round();
}

int minutesBetween(from, DateTime to) {
  from = DateTime(from['year'], from['month'], from['day'], from['hour'], from['minute']);
  to = DateTime(to.year, to.month, to.day, to.hour, to.minute);
  return to.difference(from).inMinutes;
}

String formatDateTime(date, {format = "yyyy-MM-dd"}) {
  return DateFormat(format).format(date);
}

formatDate(date) {
  if (date == null) {
    return '';
  }
  DateTime rawDate = DateTime.parse(date);
  return DateFormat("dd.MM.yy HH:mm").format(rawDate);
}

String formatDateBackend(date, {format = "yyyy-MM-dd"}) {
  return DateFormat(format).format(date);
}

formatDateMonth(date, {format = "dd.MM.yyyy"}) {
  DateTime rawDate = DateTime.parse(date);
  return DateFormat(format).format(rawDate);
}

formatDateHour(date) {
  DateTime rawDate = DateTime.parse(date);
  return DateFormat("HH:mm").format(rawDate);
}

formatUnixTime(unixTime) {
  if (unixTime == null) {
    return '';
  }
  var dt = DateTime.fromMillisecondsSinceEpoch(unixTime);
  return DateFormat('dd.MM.yyyy HH:mm').format(dt);
}

formatPhone(phone) {
  if (phone.length >= 12) {
    var x = phone.substring(0, 3);
    var y = phone.substring(3, 5);
    var z = phone.substring(5, 8);
    var d = phone.substring(8, 10);
    var q = phone.substring(10, 12);
    return '+' + x + ' ' + y + ' ' + z + ' ' + d + ' ' + q;
  } else {
    return phone;
  }
}

formatMoney(amount, {decimalDigits = 0}) {
  GetStorage storage = GetStorage();

  if (decimalDigits == 0 && storage.read('decimalDigits') != null) {
    decimalDigits = storage.read('decimalDigits').round();
  }
  if (amount != null && amount != "") {
    amount = double.parse(amount.toString());
    return NumberFormat.currency(symbol: '', decimalDigits: decimalDigits).format(amount);
  } else {
    return NumberFormat.currency(symbol: '', decimalDigits: decimalDigits).format(0);
  }
}

Future<bool> hasInternetConnection() async {
  final dio = Dio();
  const url = 'https://backend.mison.uz';

  try {
    final response = await dio.get(url);
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

String findFromArrayById(List<Map<String, dynamic>> array, dynamic id) {
  if (array.isNotEmpty && id != null) {
    return array.firstWhere(
      (item) => item['id'].toString() == id.toString(),
      orElse: () => {},
    )['name'];
  }
  return '';
}

showSuccessToast(message, {String description = ""}) {
  toastification.show(
    title: Text(
      '$message',
      style: TextStyle(color: black),
    ),
    description: description.isNotEmpty
        ? Text(
            description,
            style: TextStyle(color: black),
          )
        : null,
    icon: Icon(
      UniconsLine.check_circle,
      color: success,
    ),
    animationDuration: const Duration(milliseconds: 200),
    autoCloseDuration: const Duration(seconds: 20),
    type: ToastificationType.success,
    style: ToastificationStyle.flatColored,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.bottomCenter,
    borderRadius: BorderRadius.circular(12),
    closeOnClick: true,
    showProgressBar: false,
  );
}

showDangerToast(message, {String description = ""}) {
  toastification.show(
    title: Text(
      '$message',
      style: TextStyle(color: black),
    ),
    description: description.isNotEmpty
        ? Text(
            description,
            style: TextStyle(color: black),
          )
        : null,
    icon: Icon(
      UniconsLine.exclamation_triangle,
      color: danger,
    ),
    animationDuration: const Duration(milliseconds: 200),
    autoCloseDuration: const Duration(seconds: 20),
    type: ToastificationType.error,
    style: ToastificationStyle.flatColored,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.bottomCenter,
    borderRadius: BorderRadius.circular(21),
    closeOnClick: true,
    showProgressBar: false,
  );
}

showFilterModal(BuildContext context, {required List<Widget> children}) async {
  return await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(
          title: 'filter',
          leading: true,
        ),
        body: Container(
          color: CustomTheme.of(context).bgColor,
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...children,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: TextButton(
                      onPressed: () {
                        Provider.of<FilterModel>(context, listen: false).resetFilterData();
                        context.pop(true);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: black,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            UniconsLine.times,
                            color: CustomTheme.of(context).textColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            context.tr('reset_filter'),
                            style: TextStyle(
                              color: CustomTheme.of(context).textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        context.pop(true);
                      },
                      child: Text(context.tr('confirm')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
