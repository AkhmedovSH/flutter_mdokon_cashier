import 'package:flutter/material.dart';
import 'helper.dart';

// Light Theme
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: mainColor,
  primaryColorLight: mainColor,
  scaffoldBackgroundColor: Colors.white,
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: mainColor,
    selectionHandleColor: mainColor,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: white,
    border: inputBorder,
    enabledBorder: inputBorder,
    focusedErrorBorder: inputErrorBorder,
    focusedBorder: inputFocusBorder,
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: Colors.white,
    headerBackgroundColor: mainColor,
    headerForegroundColor: Colors.white,
    rangePickerBackgroundColor: Colors.grey[200],
    rangePickerHeaderBackgroundColor: mainColor,
    rangePickerHeaderForegroundColor: Colors.white,
  ),

  // Цвета для кнопок
  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.blue, // цвет кнопок
    textTheme: ButtonTextTheme.primary, // стиль текста кнопок
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: mainColor,
      foregroundColor: white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  dialogTheme: const DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(20),
      ),
    ),
  ),
  dataTableTheme: DataTableThemeData(
    columnSpacing: 10,
    headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
    headingTextStyle: TextStyle(
      color: black,
      fontWeight: FontWeight.bold,
    ),
    dataRowColor: WidgetStateProperty.all(white),
    dataTextStyle: TextStyle(
      color: black,
    ),
  ),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: mainColor,
  ),
  dialogBackgroundColor: white,

  // iconTheme: IconThemeData(
  //   color: white,
  // ),
  // iconButtonTheme: IconButtonThemeData(
  //   style: ButtonStyle(
  //     iconColor: WidgetStateProperty.all(Colors.white),
  //   ),
  // ),
);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Dark Theme
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: Colors.grey[900], // основной цвет
  fontFamily: 'SFPro',

  // Цвета для фона
  scaffoldBackgroundColor: const Color(0xFF0D0D0D), // цвет заднего фона

  // Цвета для инпутов
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[800], // цвет для заполненных инпутов
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
  ),

  // Цвета для кнопок
  buttonTheme: const ButtonThemeData(
    buttonColor: Colors.redAccent, // цвет кнопок
    textTheme: ButtonTextTheme.primary, // стиль текста кнопок
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: mainColor,
      foregroundColor: white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
);

class LightThemeColors {
  static const Color bgColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF000000);
  static const Color textColorSecond = Color(0xFF000000);
  static const Color cardColor = Color(0xFFF5F5F5);
  static const Color inputColor = Color(0xFFFFFFFF);
  static LinearGradient gradient = LinearGradient(
    colors: [
      const Color(0xFF004999).withOpacity(0.05),
      const Color(0xFF007AFF).withOpacity(0.25),
    ],
    stops: const [0.3, 1],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
  static LinearGradient secondGradient = LinearGradient(
    colors: [
      const Color(0xFF004999),
      const Color(0xFF007AFF).withOpacity(0.2),
    ],
    stops: const [0.2, 1],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
}

class DarkThemeColors {
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color textColorSecond = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFF171717);
  static const Color inputColor = Color(0xFF171717);
  static LinearGradient gradient = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.05),
      Colors.white.withOpacity(0.3),
    ],
    stops: const [0.3, 1],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
  static LinearGradient secondGradient = LinearGradient(
    colors: [
      Colors.white,
      Colors.white.withOpacity(0.2),
    ],
    stops: const [0.2, 1],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
}
