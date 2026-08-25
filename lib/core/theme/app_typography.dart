import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';

/// Типографика дизайн-системы.
///
/// Все суммы — [tabularFigures] (моноширинные цифры), разряды разделяются
/// тонким пробелом U+2009. Валюта в мобильном приложении — `So'm`.
///
/// Стили — геттеры, а не константы: цвет берётся из активной палитры
/// ([AppColors]), которая меняется вместе с темой. Размеры и начертания от темы
/// не зависят.
class AppText {
  const AppText._();

  static const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

  /// 34/700 — крупная сумма («К оплате», «Сдача»).
  static TextStyle get display => TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.34,
        height: 1.2,
        color: AppColors.textPrimary,
        fontFeatures: tabularFigures,
      );

  /// 28/700 — итог в блоке «К оплате».
  static TextStyle get amount => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.28,
        height: 1.2,
        color: AppColors.textPrimary,
        fontFeatures: tabularFigures,
      );

  /// 22/600 — сумма в поле ввода.
  static TextStyle get money => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: AppColors.textPrimary,
        fontFeatures: tabularFigures,
      );

  /// 17/700 — цена товара в карточке.
  static TextStyle get price => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textPrimary,
        fontFeatures: tabularFigures,
      );

  /// 20/600 — заголовок экрана.
  static TextStyle get h1 => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  /// 18/600 — заголовок модалки / пустого состояния.
  static TextStyle get h2 => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.textPrimary,
      );

  /// 15/400 — основной текст, название товара.
  static TextStyle get body => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: AppColors.textPrimary,
      );

  /// 15/500 — название позиции в чеке.
  static TextStyle get bodyMedium => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: AppColors.textPrimary,
      );

  /// 15/600 — подпись кнопки.
  static TextStyle get button => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6, // 0.04em
        height: 1.2,
        color: AppColors.onPrimary,
      );

  /// 13/400 — вторичный текст, подсказки, остаток.
  static TextStyle get secondary => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  /// 13/600 — акцентный вторичный текст, чипы.
  static TextStyle get secondaryBold => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  /// 12/400 — расчёт строки чека, штрих-код.
  static TextStyle get small => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  /// 11/600 caps 0.06em — лейблы полей и секций.
  static TextStyle get caption => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.66, // 0.06em
        height: 1.4,
        color: AppColors.textSecondary,
      );

  static TextStyle captionOn(Color color) => caption.copyWith(color: color);

  static TextStyle tabular(TextStyle style) => style.copyWith(fontFeatures: tabularFigures);
}
