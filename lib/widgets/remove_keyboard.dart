import 'package:flutter/material.dart';

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool consumeKeyboardToken() {
    return false; // Подавляет отображение клавиатуры
  }
}
