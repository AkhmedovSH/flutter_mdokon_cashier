import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';

/// Типографика дизайн-системы.
///
/// Все суммы — [tabularFigures] (моноширинные цифры), разряды разделяются
/// тонким пробелом U+2009. Валюта в мобильном приложении — `So'm`.
class AppText {
  const AppText._();

  static const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

  /// 34/700 — крупная сумма («К оплате», «Сдача»).
  static const TextStyle display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.34,
    height: 1.2,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );

  /// 28/700 — итог в блоке «К оплате».
  static const TextStyle amount = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.28,
    height: 1.2,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );

  /// 22/600 — сумма в поле ввода.
  static const TextStyle money = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );

  /// 17/700 — цена товара в карточке.
  static const TextStyle price = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
    fontFeatures: tabularFigures,
  );

  /// 20/600 — заголовок экрана.
  static const TextStyle h1 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  /// 18/600 — заголовок модалки / пустого состояния.
  static const TextStyle h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  /// 15/400 — основной текст, название товара.
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  /// 15/500 — название позиции в чеке.
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  /// 15/600 — подпись кнопки.
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6, // 0.04em
    height: 1.2,
    color: AppColors.onPrimary,
  );

  /// 13/400 — вторичный текст, подсказки, остаток.
  static const TextStyle secondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  /// 13/600 — акцентный вторичный текст, чипы.
  static const TextStyle secondaryBold = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// 12/400 — расчёт строки чека, штрих-код.
  static const TextStyle small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// 11/600 caps 0.06em — лейблы полей и секций.
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.66, // 0.06em
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static TextStyle captionOn(Color color) => caption.copyWith(color: color);

  static TextStyle tabular(TextStyle style) => style.copyWith(fontFeatures: tabularFigures);
}
