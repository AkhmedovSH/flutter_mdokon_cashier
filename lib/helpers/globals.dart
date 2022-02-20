import 'dart:math';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

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

Color a2 = Color(0xFFA2A2A2);
Color b8 = Color(0xFF7b8190);

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

formatUnixTime(unixTime) {
  var dt = DateTime.fromMillisecondsSinceEpoch(unixTime);
  return DateFormat('dd.MM.yyyy HH:mm').format(dt);
}

formatMoney(amount) {
  if (amount != null) {
    amount = double.parse(amount.toString());
    return NumberFormat.currency(symbol: '', decimalDigits: 2, locale: 'UZ').format(amount);
  } else {
    return NumberFormat.currency(symbol: '', decimalDigits: 2, locale: 'UZ').format(0);
  }
}

showSuccessToast(message) {
  return Get.snackbar(
    'Успешно',
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
    'Ошибка',
    message,
    colorText: white,
    onTap: (_) => Get.back(),
    duration: Duration(milliseconds: 2000),
    animationDuration: Duration(milliseconds: 300),
    snackPosition: SnackPosition.TOP,
    backgroundColor: red,
  );
}
