import 'dart:math';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

Color mainColor = const Color(0xFF5b73e8);

Color bgColor = const Color(0xFFF3F8FE);

Color blue = const Color(0xFF5b73e8);
Color grey = const Color(0xFF838488);
Color black = const Color(0xFF525355);
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

Color a2 = Color(0xFFA2A2A2);
Color b8 = Color(0xFF7b8190);

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

OutlineInputBorder inputBorder = OutlineInputBorder(
  borderSide: BorderSide(color: Color(0xFFdddddd)),
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

formatDate(date) {
  DateTime rawDate = DateTime.parse(date);
  return DateFormat("dd-MM-yyyy HH:mm").format(rawDate);
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

formatMoney(amount, {decimalDigits = 2}) {
  if (amount != null && amount != "") {
    amount = double.parse(amount.toString());
    return NumberFormat.currency(symbol: '', decimalDigits: decimalDigits, locale: 'UZ').format(amount);
  } else {
    return NumberFormat.currency(symbol: '', decimalDigits: decimalDigits, locale: 'UZ').format(0);
  }
}

showSuccessToast(message) {
  return Get.snackbar(
    'success'.tr,
    message,
    colorText: white,
    onTap: (_) => Get.back(),
    duration: Duration(milliseconds: 1500),
    animationDuration: Duration(milliseconds: 300),
    snackPosition: SnackPosition.TOP,
    backgroundColor: green,
  );
}

showDangerToast(message) {
  return Get.snackbar(
    'error'.tr,
    message,
    colorText: white,
    onTap: (_) => Get.back(),
    duration: Duration(milliseconds: 2000),
    animationDuration: Duration(milliseconds: 300),
    snackPosition: SnackPosition.TOP,
    backgroundColor: red,
  );
}
