import 'package:flutter/material.dart';

/// Токены цвета дизайн-системы mDokon POS (mobile 390×844).
///
/// Контраст (WCAG AA, порог 4.5:1):
///   textPrimary   на surface — 15.9:1
///   textSecondary на surface — 5.40:1
///   primary       на surface — 4.90:1
///   dangerText    на surface — 5.74:1
///   successText   на surface — 5.05:1
///   warningText   на surface — 4.94:1
///
/// [iconMuted] (2.9:1) — только обводки иконок, разделители и disabled-плашки.
/// [danger] / [warning] / [success] — только заливки, иконки и точки статуса;
/// для текста той же семантики берём *Text-варианты.
class AppColors {
  const AppColors._();

  // Брендовые
  static const Color primary = Color(0xFF5B60E8);
  static const Color primaryDark = Color(0xFF4A4FD1);
  static const Color primarySoft = Color(0xFFEEF0FE);
  static const Color primaryTint = Color(0xFFDDE0FD);

  // Поверхности
  static const Color canvas = Color(0xFFF4F6FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3E8F3);
  static const Color divider = Color(0xFFF0F2F8);

  // Текст и иконки
  static const Color textPrimary = Color(0xFF1B2138);
  static const Color textSecondary = Color(0xFF5F6980);
  static const Color iconMuted = Color(0xFF8A93A8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Семантика
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerText = Color(0xFFC4262B);
  static const Color dangerSoft = Color(0xFFFDECEC);

  static const Color warning = Color(0xFFF97B22);
  static const Color warningText = Color(0xFFB0530C);
  static const Color warningSoft = Color(0xFFFFF3E9);

  static const Color success = Color(0xFF1E9E5A);
  static const Color successText = Color(0xFF157F47);
  static const Color successSoft = Color(0xFFE9F7EF);

  // Служебные
  static const Color toast = Color(0xFF1B2138);
  static const Color selection = Color(0xFFC9CDFA);
  static const Color scrim = Color(0x731B2138); // rgba(27,33,56,0.45)
  static const Color disabledSurface = primarySoft;
  static const Color disabledText = textSecondary;
}

/// Радиусы, отступы, тени и длительности анимаций.
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

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0F1C264A), // rgba(28,38,74,0.06)
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color(0x665B60E8),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> toastShadow = [
    BoxShadow(
      color: Color(0x471C2138),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const BorderRadius control = BorderRadius.all(Radius.circular(radiusControl));
  static const BorderRadius card = BorderRadius.all(Radius.circular(radiusCard));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(radiusPill));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(radiusSheet));
}
