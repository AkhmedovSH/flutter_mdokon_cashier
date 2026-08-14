import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/theme/app_typography.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';

// Light Theme — базовая тема дизайн-системы mDokon POS.
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: AppColors.primary,
  primaryColorLight: AppColors.primarySoft,
  scaffoldBackgroundColor: AppColors.canvas,
  canvasColor: AppColors.canvas,
  dividerColor: AppColors.border,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.primary,
    secondary: AppColors.primary,
    onSecondary: AppColors.onPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.canvas,
    error: AppColors.danger,
    onError: AppColors.onPrimary,
    outline: AppColors.border,
    outlineVariant: AppColors.divider,
  ),
  textTheme: const TextTheme(
    displayLarge: AppText.display,
    headlineMedium: AppText.amount,
    titleLarge: AppText.h1,
    titleMedium: AppText.h2,
    bodyLarge: AppText.body,
    bodyMedium: AppText.secondary,
    bodySmall: AppText.small,
    labelLarge: AppText.button,
    labelSmall: AppText.caption,
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: AppColors.primary,
    selectionColor: AppColors.selection,
    selectionHandleColor: AppColors.primary,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.canvas,
    hintStyle: AppText.body.copyWith(color: AppColors.iconMuted),
    labelStyle: AppText.caption,
    errorStyle: AppText.small.copyWith(color: AppColors.dangerText),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppDimens.gap16,
      vertical: AppDimens.gap12,
    ),
    border: inputBorder,
    enabledBorder: inputBorder,
    disabledBorder: inputBorder,
    errorBorder: inputErrorBorder,
    focusedErrorBorder: inputErrorBorder,
    focusedBorder: inputFocusBorder,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    surfaceTintColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: AppText.h1,
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: AppColors.surface,
    headerBackgroundColor: AppColors.primary,
    headerForegroundColor: AppColors.onPrimary,
    rangePickerBackgroundColor: AppColors.canvas,
    rangePickerHeaderBackgroundColor: AppColors.primary,
    rangePickerHeaderForegroundColor: AppColors.onPrimary,
    cancelButtonStyle: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(AppColors.textSecondary),
    ),
    confirmButtonStyle: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(AppColors.primary),
    ),
    todayBackgroundColor: WidgetStateProperty.all(AppColors.primary),
    shape: const RoundedRectangleBorder(borderRadius: AppDimens.card),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      disabledBackgroundColor: AppColors.disabledSurface,
      disabledForegroundColor: AppColors.disabledText,
      minimumSize: const Size(0, AppDimens.heightLarge),
      elevation: 0,
      textStyle: AppText.button,
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.control),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      minimumSize: const Size(0, AppDimens.heightMedium),
      side: const BorderSide(color: AppColors.border),
      textStyle: AppText.secondaryBold,
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.control),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      iconColor: AppColors.primary,
      textStyle: AppText.secondaryBold,
      minimumSize: const Size(0, AppDimens.tapTarget),
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.control),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      minimumSize: const Size(AppDimens.tapTarget, AppDimens.tapTarget),
    ),
  ),
  cardTheme: const CardThemeData(
    color: AppColors.surface,
    surfaceTintColor: AppColors.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: AppDimens.card,
      side: BorderSide(color: AppColors.border),
    ),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: AppColors.surface,
    elevation: 0,
    titleTextStyle: AppText.h2,
    contentTextStyle: AppText.secondary,
    shape: RoundedRectangleBorder(borderRadius: AppDimens.card),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: AppColors.surface,
    modalBackgroundColor: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: AppDimens.sheet),
  ),
  dataTableTheme: DataTableThemeData(
    columnSpacing: 10,
    horizontalMargin: 10,
    dividerThickness: 1,
    headingRowColor: WidgetStateProperty.all(AppColors.canvas),
    headingTextStyle: AppText.caption,
    dataRowColor: WidgetStateProperty.all(AppColors.surface),
    dataTextStyle: AppText.secondaryBold,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.surface,
    selectedColor: AppColors.primary,
    labelStyle: AppText.secondaryBold,
    side: const BorderSide(color: AppColors.border),
    shape: const RoundedRectangleBorder(borderRadius: AppDimens.pill),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
    circularTrackColor: AppColors.primarySoft,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.all(AppColors.surface),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.border,
    ),
    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.border,
    thickness: 1,
    space: 1,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Dark Theme — тёмная инверсия тех же токенов.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: AppColors.primary,
  fontFamily: 'SFPro',
  scaffoldBackgroundColor: DarkThemeColors.bgColor,
  canvasColor: DarkThemeColors.bgColor,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    surface: DarkThemeColors.cardColor,
    onSurface: DarkThemeColors.textColor,
    error: AppColors.danger,
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: AppColors.primary,
    selectionHandleColor: AppColors.primary,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: DarkThemeColors.inputColor,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppDimens.gap16,
      vertical: AppDimens.gap12,
    ),
    border: const OutlineInputBorder(
      borderRadius: AppDimens.control,
      borderSide: BorderSide.none,
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: AppDimens.control,
      borderSide: BorderSide.none,
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: AppDimens.control,
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: AppDimens.control,
      borderSide: BorderSide(color: AppColors.danger, width: 1.5),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: AppDimens.control,
      borderSide: BorderSide(color: AppColors.danger, width: 1.5),
    ),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: DarkThemeColors.cardColor,
    surfaceTintColor: DarkThemeColors.cardColor,
    shape: RoundedRectangleBorder(borderRadius: AppDimens.card),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      disabledBackgroundColor: DarkThemeColors.cardColor,
      disabledForegroundColor: AppColors.textSecondary,
      minimumSize: const Size(0, AppDimens.heightLarge),
      elevation: 0,
      textStyle: AppText.button,
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.control),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: DarkThemeColors.cardColor,
    surfaceTintColor: DarkThemeColors.cardColor,
    modalBackgroundColor: DarkThemeColors.cardColor,
    shape: RoundedRectangleBorder(borderRadius: AppDimens.sheet),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
  ),
);

class LightThemeColors {
  static const Color bgColor = AppColors.surface;
  static const Color textColor = AppColors.textPrimary;
  static const Color textColorSecond = AppColors.textSecondary;
  static const Color cardColor = AppColors.canvas;
  static const Color inputColor = AppColors.surface;
  static LinearGradient gradient = LinearGradient(
    colors: [
      AppColors.primary.withValues(alpha: 0.05),
      AppColors.primary.withValues(alpha: 0.25),
    ],
    stops: const [0.3, 1],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
  static LinearGradient secondGradient = LinearGradient(
    colors: [
      AppColors.primaryDark,
      AppColors.primary.withValues(alpha: 0.2),
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
      Colors.white.withValues(alpha: 0.05),
      Colors.white.withValues(alpha: 0.3),
    ],
    stops: const [0.3, 1],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
  static LinearGradient secondGradient = LinearGradient(
    colors: [
      Colors.white,
      Colors.white.withValues(alpha: 0.2),
    ],
    stops: const [0.2, 1],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
}
