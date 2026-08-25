import 'package:flutter/material.dart';

/// Палитра дизайн-системы mDokon POS — светлая и тёмная.
///
/// Токены живут парами: экраны обращаются к ним через [AppColors], а [AppColors]
/// отдаёт значения активной палитры. Поэтому смена темы не требует правок в
/// экранах — переключается один объект.
///
/// Контраст (WCAG AA, порог 4.5:1) для обеих палитр:
///
/// |                | light | dark  |
/// |----------------|-------|-------|
/// | textPrimary    | 15.9  | 15.8  |
/// | textSecondary  | 5.40  | 7.46  |
/// | primary        | 4.90  | 6.13  |
/// | onPrimary      | 4.90  | 6.59  |
/// | dangerText     | 5.74  | 7.68  |
/// | successText    | 5.05  | 10.4  |
/// | warningText    | 4.94  | 10.2  |
///
/// [iconMuted] (2.9 / 3.8) — только обводки иконок, разделители и disabled-плашки.
/// [danger] / [warning] / [success] — только заливки, иконки и точки статуса;
/// для текста той же семантики берём *Text-варианты.
@immutable
class AppPalette {
  /// Светлая или тёмная — от неё зависят `Brightness` темы и стиль статус-бара.
  final Brightness brightness;

  // Брендовые
  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color primaryTint;

  // Поверхности
  final Color canvas;
  final Color surface;
  final Color border;
  final Color divider;

  // Текст и иконки
  final Color textPrimary;
  final Color textSecondary;
  final Color iconMuted;
  final Color onPrimary;

  // Семантика
  final Color danger;
  final Color dangerText;
  final Color dangerSoft;

  final Color warning;
  final Color warningText;
  final Color warningSoft;

  final Color success;
  final Color successText;
  final Color successSoft;

  // Служебные
  final Color toast;

  /// Текст на плашке тоста: в светлой теме тост тёмный, в тёмной — светлый.
  final Color onToast;
  final Color selection;
  final Color scrim;

  /// Цвет тени карточек. На тёмном фоне тень почти не читается, поэтому там
  /// она глубже, а роль разделителя берёт на себя [border].
  final Color shadow;

  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.primaryTint,
    required this.canvas,
    required this.surface,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconMuted,
    required this.onPrimary,
    required this.danger,
    required this.dangerText,
    required this.dangerSoft,
    required this.warning,
    required this.warningText,
    required this.warningSoft,
    required this.success,
    required this.successText,
    required this.successSoft,
    required this.toast,
    required this.onToast,
    required this.selection,
    required this.scrim,
    required this.shadow,
  });

  bool get isDark => brightness == Brightness.dark;

  /// Светлая палитра — исходная, под неё нарисован макет 390×844.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF5B60E8),
    primaryDark: Color(0xFF4A4FD1),
    primarySoft: Color(0xFFEEF0FE),
    primaryTint: Color(0xFFDDE0FD),
    canvas: Color(0xFFF4F6FB),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE3E8F3),
    divider: Color(0xFFF0F2F8),
    textPrimary: Color(0xFF1B2138),
    textSecondary: Color(0xFF5F6980),
    iconMuted: Color(0xFF8A93A8),
    onPrimary: Color(0xFFFFFFFF),
    danger: Color(0xFFE5484D),
    dangerText: Color(0xFFC4262B),
    dangerSoft: Color(0xFFFDECEC),
    warning: Color(0xFFF97B22),
    warningText: Color(0xFFB0530C),
    warningSoft: Color(0xFFFFF3E9),
    success: Color(0xFF1E9E5A),
    successText: Color(0xFF157F47),
    successSoft: Color(0xFFE9F7EF),
    toast: Color(0xFF1B2138),
    onToast: Color(0xFFFFFFFF),
    selection: Color(0xFFC9CDFA),
    scrim: Color(0x731B2138), // rgba(27,33,56,0.45)
    shadow: Color(0x0F1C264A), // rgba(28,38,74,0.06)
  );

  /// Тёмная палитра.
  ///
  /// Фон синеватый, а не чёрный, — иначе брендовый фиолетовый на нём выглядит
  /// грязным. Акцент осветлён с #5B60E8 до #8B90F5: исходный на тёмной
  /// поверхности даёт 2.4:1 и не читается. Как следствие [onPrimary] здесь
  /// тёмный: белый текст на осветлённом акценте — всего 2.8:1.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF8B90F5),
    primaryDark: Color(0xFF7C82F2),
    primarySoft: Color(0xFF1F2337),
    primaryTint: Color(0xFF2B3050),
    canvas: Color(0xFF0F1117),
    surface: Color(0xFF171A23),
    border: Color(0xFF262B38),
    divider: Color(0xFF1F232E),
    textPrimary: Color(0xFFF2F4F8),
    textSecondary: Color(0xFFA2AABD),
    iconMuted: Color(0xFF6E7688),
    onPrimary: Color(0xFF10121A),
    danger: Color(0xFFFF6369),
    dangerText: Color(0xFFFF8A8E),
    dangerSoft: Color(0xFF2C1618),
    warning: Color(0xFFFFA057),
    warningText: Color(0xFFFFB877),
    warningSoft: Color(0xFF2E1D10),
    success: Color(0xFF3DD68C),
    successText: Color(0xFF5AE0A0),
    successSoft: Color(0xFF10241A),
    toast: Color(0xFF262B38),
    onToast: Color(0xFFF2F4F8),
    selection: Color(0xFF3A3F6B),
    scrim: Color(0x99000000), // rgba(0,0,0,0.6)
    shadow: Color(0x66000000), // rgba(0,0,0,0.4)
  );
}

/// Токены цвета дизайн-системы mDokon POS.
///
/// Не константы, а геттеры активной палитры: экран пишет `AppColors.surface`,
/// а какая это поверхность — решает [use]. Тему переключает [ThemeModel], он же
/// вызывает [use] перед `notifyListeners()`, после чего `MaterialApp`
/// пересобирается целиком.
///
/// Из-за этого цвет нельзя ставить внутрь `const`-выражения: `const` вычисляется
/// на этапе компиляции и переживёт смену темы. Пишите
/// `Icon(Icons.check, color: AppColors.primary)` без `const`.
class AppColors {
  const AppColors._();

  static AppPalette _palette = AppPalette.light;

  /// Активная палитра — нужна там, где цвет выбирается целым набором.
  static AppPalette get palette => _palette;

  static bool get isDark => _palette.isDark;

  /// Переключить палитру. Вызывается только из [ThemeModel] и при старте.
  static void use(bool dark) {
    _palette = dark ? AppPalette.dark : AppPalette.light;
  }

  // Брендовые
  static Color get primary => _palette.primary;
  static Color get primaryDark => _palette.primaryDark;
  static Color get primarySoft => _palette.primarySoft;
  static Color get primaryTint => _palette.primaryTint;

  // Поверхности
  static Color get canvas => _palette.canvas;
  static Color get surface => _palette.surface;
  static Color get border => _palette.border;
  static Color get divider => _palette.divider;

  // Текст и иконки
  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get iconMuted => _palette.iconMuted;
  static Color get onPrimary => _palette.onPrimary;

  // Семантика
  static Color get danger => _palette.danger;
  static Color get dangerText => _palette.dangerText;
  static Color get dangerSoft => _palette.dangerSoft;

  static Color get warning => _palette.warning;
  static Color get warningText => _palette.warningText;
  static Color get warningSoft => _palette.warningSoft;

  static Color get success => _palette.success;
  static Color get successText => _palette.successText;
  static Color get successSoft => _palette.successSoft;

  // Служебные
  static Color get toast => _palette.toast;
  static Color get onToast => _palette.onToast;
  static Color get selection => _palette.selection;
  static Color get scrim => _palette.scrim;
  static Color get disabledSurface => _palette.primarySoft;
  static Color get disabledText => _palette.textSecondary;
}

/// Радиусы, отступы, тени и длительности анимаций.
///
/// Размеры от темы не зависят и остаются константами — меняются только тени,
/// потому что их цвет берётся из палитры.
class AppDimens {
  const AppDimens._();

  /// Сетка 4px, боковые поля экрана 16px.
  static const double gutter = 16;
  static const double gap4 = 4;
  static const double gap8 = 8;
  static const double gap12 = 12;
  static const double gap16 = 16;
  static const double gap24 = 24;

  static const double radiusControl = 12; // кнопки, поля ввода
  static const double radiusCard = 16; // карточки товара, блок итогов
  static const double radiusSheet = 24; // модальный лист
  static const double radiusPill = 999;

  /// Тач-таргет: минимум 44, основные действия — 48+.
  static const double tapTarget = 44;
  static const double heightSmall = 40;
  static const double heightMedium = 48;
  static const double heightLarge = 56;

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 250);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.palette.shadow,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Свечение под плавающей кнопкой — всегда брендовое, в обеих темах.
  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.4),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get toastShadow => [
        BoxShadow(
          color: AppColors.palette.shadow,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static const BorderRadius control = BorderRadius.all(Radius.circular(radiusControl));
  static const BorderRadius card = BorderRadius.all(Radius.circular(radiusCard));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(radiusPill));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(radiusSheet));
}
