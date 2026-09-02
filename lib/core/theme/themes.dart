import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/theme/app_typography.dart';

/// Тема приложения, собранная из палитры.
///
/// Светлая и тёмная темы — один и тот же код с разными токенами: раньше это
/// были две независимые копии, и тёмная отставала от светлой на десяток
/// компонентов (не было `appBarTheme`, `cardTheme`, `chipTheme`, `switchTheme`).
///
/// Важно: [AppColors] должен уже указывать на ту же палитру — иначе виджеты,
/// которые читают токены напрямую, разойдутся с темой. За это отвечает
/// `ThemeModel`, он вызывает `AppColors.use()` перед сборкой темы.
ThemeData buildAppTheme(AppPalette palette) {
  final bool dark = palette.isDark;

  // Стили `AppText` берут цвет из активной палитры, а тема может собираться и
  // для другой (`MaterialApp` строит light и dark за один проход). Поэтому цвет
  // здесь всегда переопределяем явно — иначе тёмная тема получала бы чёрный
  // текст заголовков, пока активна светлая.
  TextStyle primaryText(TextStyle style) => style.copyWith(color: palette.textPrimary);
  TextStyle secondaryText(TextStyle style) => style.copyWith(color: palette.textSecondary);

  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: AppDimens.control,
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    primaryColor: palette.primary,
    primaryColorLight: palette.primarySoft,
    scaffoldBackgroundColor: palette.canvas,
    canvasColor: palette.canvas,
    dividerColor: palette.border,
    colorScheme: ColorScheme(
      brightness: palette.brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primarySoft,
      onPrimaryContainer: palette.primary,
      secondary: palette.primary,
      onSecondary: palette.onPrimary,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      surfaceContainerHighest: palette.canvas,
      error: palette.danger,
      onError: palette.onPrimary,
      outline: palette.border,
      outlineVariant: palette.divider,
    ),
    textTheme: TextTheme(
      displayLarge: primaryText(AppText.display),
      headlineMedium: primaryText(AppText.amount),
      titleLarge: primaryText(AppText.h1),
      titleMedium: primaryText(AppText.h2),
      bodyLarge: primaryText(AppText.body),
      bodyMedium: secondaryText(AppText.secondary),
      bodySmall: secondaryText(AppText.small),
      labelLarge: AppText.button.copyWith(color: palette.onPrimary),
      labelSmall: secondaryText(AppText.caption),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.primary,
      selectionColor: palette.selection,
      selectionHandleColor: palette.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      // В светлой теме поле утоплено в серую заливку на белой карточке;
      // в тёмной наоборот — поле светлее фона, иначе оно сливается.
      fillColor: dark ? palette.surface : palette.canvas,
      hintStyle: AppText.body.copyWith(color: palette.iconMuted),
      labelStyle: secondaryText(AppText.caption),
      errorStyle: AppText.small.copyWith(color: palette.dangerText),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.gap16,
        vertical: AppDimens.gap12,
      ),
      border: border(palette.border),
      enabledBorder: border(palette.border),
      disabledBorder: border(palette.border),
      errorBorder: border(palette.danger, 1.5),
      focusedErrorBorder: border(palette.danger, 1.5),
      focusedBorder: border(palette.primary, 1.5),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.surface,
      surfaceTintColor: palette.surface,
      foregroundColor: palette.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: primaryText(AppText.h1),
      iconTheme: IconThemeData(color: palette.textPrimary),
      actionsIconTheme: IconThemeData(color: palette.textPrimary),
      // Иконки статус-бара — под цвет шапки, иначе на тёмной теме они
      // остаются тёмными и сливаются с фоном.
      systemOverlayStyle: systemOverlayStyleFor(palette),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: palette.surface,
      headerBackgroundColor: palette.primary,
      headerForegroundColor: palette.onPrimary,
      rangePickerBackgroundColor: palette.canvas,
      rangePickerHeaderBackgroundColor: palette.primary,
      rangePickerHeaderForegroundColor: palette.onPrimary,
      cancelButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(palette.textSecondary),
      ),
      confirmButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(palette.primary),
      ),
      todayBackgroundColor: WidgetStateProperty.all(palette.primary),
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.card),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        disabledBackgroundColor: palette.primarySoft,
        disabledForegroundColor: palette.textSecondary,
        minimumSize: const Size(0, AppDimens.heightLarge),
        elevation: 0,
        textStyle: AppText.button.copyWith(color: palette.onPrimary),
        shape: const RoundedRectangleBorder(borderRadius: AppDimens.control),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        minimumSize: const Size(0, AppDimens.heightMedium),
        side: BorderSide(color: palette.border),
        textStyle: primaryText(AppText.secondaryBold),
        shape: const RoundedRectangleBorder(borderRadius: AppDimens.control),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.primary,
        iconColor: palette.primary,
        textStyle: AppText.secondaryBold.copyWith(color: palette.primary),
        minimumSize: const Size(0, AppDimens.tapTarget),
        shape: const RoundedRectangleBorder(borderRadius: AppDimens.control),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.textPrimary,
        minimumSize: const Size(AppDimens.tapTarget, AppDimens.tapTarget),
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      surfaceTintColor: palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppDimens.card,
        side: BorderSide(color: palette.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: palette.surface,
      elevation: 0,
      titleTextStyle: primaryText(AppText.h2),
      contentTextStyle: secondaryText(AppText.secondary),
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.card),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: palette.surface,
      modalBackgroundColor: palette.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.sheet),
    ),
    dataTableTheme: DataTableThemeData(
      columnSpacing: 10,
      horizontalMargin: 10,
      dividerThickness: 1,
      headingRowColor: WidgetStateProperty.all(palette.canvas),
      headingTextStyle: secondaryText(AppText.caption),
      dataRowColor: WidgetStateProperty.all(palette.surface),
      dataTextStyle: primaryText(AppText.secondaryBold),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surface,
      selectedColor: palette.primary,
      labelStyle: primaryText(AppText.secondaryBold),
      side: BorderSide(color: palette.border),
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.pill),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.primary,
      circularTrackColor: palette.primarySoft,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(palette.surface),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.primary : palette.border,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dividerTheme: DividerThemeData(
      color: palette.border,
      thickness: 1,
      space: 1,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: palette.surface,
      selectedItemColor: palette.primary,
      unselectedItemColor: palette.textSecondary,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}

/// Светлая тема. Собирается заново при каждом обращении — темы меняются редко,
/// а держать `ThemeData` в глобальной переменной нельзя: она бы запомнила
/// палитру, активную в момент запуска.
ThemeData get lightTheme => buildAppTheme(AppPalette.light);

/// Тёмная тема.
ThemeData get darkTheme => buildAppTheme(AppPalette.dark);


/// Стиль системных панелей (статус-бар и панель навигации) под палитру.
///
/// Android сам не подстраивает иконки: без этого на тёмной теме статус-бар
/// оставался с тёмными иконками на тёмном фоне, а панель навигации — белой.
SystemUiOverlayStyle systemOverlayStyleFor(AppPalette palette) {
  final Brightness icons = palette.isDark ? Brightness.light : Brightness.dark;

  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: icons,
    statusBarBrightness: palette.brightness,
    systemNavigationBarColor: palette.surface,
    systemNavigationBarDividerColor: palette.border,
    systemNavigationBarIconBrightness: icons,
  );
}
