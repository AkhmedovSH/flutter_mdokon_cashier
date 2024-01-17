import 'package:flutter/material.dart';

import './globals.dart';

class Themes {
  static final light = ThemeData(
    brightness: Brightness.light,
    cardColor: white,
    colorScheme: ColorScheme.fromSwatch(
      backgroundColor: white,
      accentColor: mainColor.withOpacity(0.5),
    ),
    appBarTheme: AppBarTheme(
      titleTextStyle: TextStyle(
        color: black,
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: white,
      systemOverlayStyle: systemOverlayStyleDark,
      elevation: 0,
      centerTitle: true,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: mainColor,
      selectionColor: mainColor.withOpacity(0.3),
      selectionHandleColor: mainColor,
    ),
    iconTheme: IconThemeData(
      color: black,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        iconColor: MaterialStateProperty.all<Color>(black),
        
      ),
    ),
    scaffoldBackgroundColor: white,
    primaryColor: mainColor,
    platform: TargetPlatform.android,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: mainColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(white), //button color
        foregroundColor: MaterialStateProperty.all<Color>(black),
      ),
    ),
  );
  static final dark = ThemeData(
    colorScheme: ColorScheme.fromSwatch(
      backgroundColor: mainColor,
      accentColor: mainColor.withOpacity(0.5),
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.transparent,
      systemOverlayStyle: systemOverlayStyleLight,
      elevation: 0,
      centerTitle: true,
    ),
    cardColor: const Color(0xFF161617),
    cardTheme: CardTheme(
      color: black,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: mainColor,
      selectionColor: mainColor.withOpacity(0.3),
      selectionHandleColor: mainColor,
    ),
    iconTheme: IconThemeData(
      color: white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: black,
      filled: true,
    ),
    scaffoldBackgroundColor: const Color(0xFF1F2225),
    primaryColor: mainColor,
    platform: TargetPlatform.android,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: mainColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(black),
        foregroundColor: MaterialStateProperty.all<Color>(white),
      ),
    ),
  );
}

// getDarkTheme(context) {
//   return ThemeData.dark().copyWith(
//     useMaterial3: true,
//     colorScheme: ColorScheme.fromSwatch(
//       backgroundColor: mainColor,
//       accentColor: mainColor.withOpacity(0.5),
//       cardColor: mainColor,
//     ),
//     dividerColor: lightBlack,
//     cardColor: mainColor,
//     cardTheme: CardTheme(
//       color: black,
//     ),
//     appBarTheme: Theme.of(context).appBarTheme.copyWith(
//           systemOverlayStyle: const SystemUiOverlayStyle(
//               statusBarColor: Colors.white, statusBarBrightness: Brightness.dark, statusBarIconBrightness: Brightness.dark),
//         ),
//     textSelectionTheme: TextSelectionThemeData(
//       cursorColor: mainColor,
//       selectionColor: mainColor.withOpacity(0.3),
//       selectionHandleColor: mainColor,
//     ),
//     iconTheme: IconThemeData(
//       color: white,
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       fillColor: black,
//       filled: true,
//     ),
//     scaffoldBackgroundColor: mainColor,
//     brightness: Brightness.light,
//     primaryColor: mainColor,
//     platform: TargetPlatform.android,
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: mainColor,
//       ),
//     ),
//   );
// }

// getLightTheme(context) {
//   return ThemeData.light().copyWith(
//     useMaterial3: true,
//     colorScheme: ColorScheme.fromSwatch(
//       backgroundColor: white,
//       accentColor: mainColor.withOpacity(0.5),
//     ),
//     cardColor: black,
//     appBarTheme: Theme.of(context).appBarTheme.copyWith(
//           systemOverlayStyle: const SystemUiOverlayStyle(
//             statusBarColor: Colors.white,
//             statusBarBrightness: Brightness.dark,
//             statusBarIconBrightness: Brightness.dark,
//           ),
//         ),
//     textSelectionTheme: TextSelectionThemeData(
//       cursorColor: mainColor,
//       selectionColor: mainColor.withOpacity(0.3),
//       selectionHandleColor: mainColor,
//     ),
//     iconTheme: IconThemeData(
//       color: black,
//     ),
//     inputDecorationTheme: InputDecorationTheme(
//       fillColor: black,
//       filled: true,
//     ),
//     scaffoldBackgroundColor: white,
//     brightness: Brightness.light,
//     primaryColor: mainColor,
//     platform: TargetPlatform.android,
//     textTheme: TextTheme(
//         // bodyLarge: TextStyle(
//         //   color: black,
//         // ),
//         // bodyMedium: TextStyle(
//         //   color: black,
//         // ),
//         // bodyColor: black,
//         // displayColor: black,
//         // fontFamily: 'Arial',
//         // decorationColor: Colors.transparent,
//         ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: mainColor,
//       ),
//     ),
//   );
// }


// theme: ThemeData(
//   colorScheme: ColorScheme.fromSwatch(
//     backgroundColor: white,
//     accentColor: mainColor.withOpacity(0.5), // but now it should be declared like this
//   ),
//   appBarTheme: Theme.of(context).appBarTheme.copyWith(
//         systemOverlayStyle: const SystemUiOverlayStyle(
//             statusBarColor: Colors.white, statusBarBrightness: Brightness.dark, statusBarIconBrightness: Brightness.dark),
//       ),
//   textSelectionTheme: TextSelectionThemeData(
//     cursorColor: mainColor,
//     selectionColor: mainColor.withOpacity(0.3),
//     selectionHandleColor: mainColor,
//   ),
//   iconTheme: IconThemeData(
//     color: black,
//   ),
//   inputDecorationTheme: InputDecorationTheme(
//     fillColor: black,
//   ),
//   scaffoldBackgroundColor: white,
//   brightness: Brightness.light,
//   primaryColor: mainColor,
//   platform: TargetPlatform.android,
//   textTheme: Theme.of(context).textTheme.apply(
//         bodyColor: black,
//         displayColor: black,
//         fontFamily: 'Arial',
//       ),
//   elevatedButtonTheme: ElevatedButtonThemeData(
//     style: ElevatedButton.styleFrom(
//       backgroundColor: mainColor,
//     ),
//   ),
// ),