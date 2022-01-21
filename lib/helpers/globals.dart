import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

getUnixTime() {
  return DateTime.now().toUtc().millisecondsSinceEpoch;
}

generateChequeNumber() {
  return getUnixTime()
      .toString()
      .substring(getUnixTime().toString().length - 8);
}

generateTransactionId(posId, cashboxId, shiftId) {
  var rng = Random();
  return posId.toString() +
      cashboxId.toString() +
      shiftId.toString() +
      getUnixTime().toString() +
      (rng.nextInt(999999).floor().toString());
}
