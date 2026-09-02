import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/theme/app_typography.dart';
import 'package:flutter_mdokon/core/theme/themes.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';

/// Контраст по WCAG 2.1 — тот же расчёт, которым подбиралась палитра.
///
/// `Color.computeLuminance()` считает то же самое, но нам нужна формула на
/// виду: она документирована в комментарии к [AppPalette], и тест сторожит
/// именно её.
double _contrast(Color a, Color b) {
  double channel(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);

  final l1 = luminance(a);
  final l2 = luminance(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  // Палитра статическая: чтобы один тест не влиял на другой, после каждого
  // возвращаем светлую — с ней приложение стартует по умолчанию.
  tearDown(() => AppColors.use(false));

  group('переключение палитры', () {
    test('AppColors отдаёт цвета активной палитры', () {
      AppColors.use(false);
      expect(AppColors.surface, AppPalette.light.surface);
      expect(AppColors.isDark, isFalse);

      AppColors.use(true);
      expect(AppColors.surface, AppPalette.dark.surface);
      expect(AppColors.isDark, isTrue);
    });

    test('тёмная поверхность темнее светлой', () {
      AppColors.use(false);
      final light = AppColors.surface;
      AppColors.use(true);
      expect(AppColors.surface.computeLuminance(), lessThan(light.computeLuminance()));
    });

    test('текстовые стили следуют за палитрой', () {
      AppColors.use(false);
      final lightBody = AppText.body.color;
      AppColors.use(true);
      expect(AppText.body.color, isNot(lightBody));
      expect(AppText.body.color, AppPalette.dark.textPrimary);
    });

    test('тени берут цвет из палитры', () {
      AppColors.use(false);
      final lightShadow = AppDimens.cardShadow.first.color;
      AppColors.use(true);
      expect(AppDimens.cardShadow.first.color, isNot(lightShadow));
    });
  });

  group('темы собираются из палитры', () {
    test('lightTheme и darkTheme не зависят от активной палитры', () {
      // Оба геттера строят тему из своей палитры, а не из глобальной, —
      // иначе MaterialApp получил бы две одинаковые темы.
      AppColors.use(true);
      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);
      expect(lightTheme.scaffoldBackgroundColor, AppPalette.light.canvas);
      expect(darkTheme.scaffoldBackgroundColor, AppPalette.dark.canvas);
    });

    test('в обеих темах заполнены одни и те же компоненты', () {
      // Раньше тёмная тема была отдельной копией и отставала от светлой.
      for (final theme in [lightTheme, darkTheme]) {
        expect(theme.appBarTheme.backgroundColor, isNotNull);
        expect(theme.cardTheme.color, isNotNull);
        expect(theme.chipTheme.backgroundColor, isNotNull);
        expect(theme.switchTheme.trackColor, isNotNull);
        expect(theme.bottomNavigationBarTheme.backgroundColor, isNotNull);
        expect(theme.dataTableTheme.headingRowColor, isNotNull);
      }
    });
  });

  group('контраст WCAG AA', () {
    const threshold = 4.5;

    for (final entry in {
      'light': AppPalette.light,
      'dark': AppPalette.dark,
    }.entries) {
      final name = entry.key;
      final p = entry.value;

      test('$name: текст и акценты на surface проходят 4.5:1', () {
        expect(_contrast(p.textPrimary, p.surface), greaterThanOrEqualTo(threshold));
        expect(_contrast(p.textSecondary, p.surface), greaterThanOrEqualTo(threshold));
        expect(_contrast(p.primary, p.surface), greaterThanOrEqualTo(threshold));
        expect(_contrast(p.dangerText, p.surface), greaterThanOrEqualTo(threshold));
        expect(_contrast(p.successText, p.surface), greaterThanOrEqualTo(threshold));
        expect(_contrast(p.warningText, p.surface), greaterThanOrEqualTo(threshold));
      });

      test('$name: подпись кнопки читается на заливке', () {
        expect(_contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(threshold));
      });

      test('$name: текст на фирменной заливке читается, а сама она тёмная', () {
        expect(_contrast(p.onBrandSurface, p.brandSurface), greaterThanOrEqualTo(threshold));
        // Шапка продажи и блок «К оплате» занимают полэкрана: они должны быть
        // темнее текста на них в обеих темах, иначе в тёмной теме это светлое
        // пятно (regression: там стоял осветлённый primary).
        expect(p.brandSurface.computeLuminance(), lessThan(0.3));
      });

      test('$name: семантический текст читается на своей плашке', () {
        expect(_contrast(p.dangerText, p.dangerSoft), greaterThanOrEqualTo(threshold));
        expect(_contrast(p.successText, p.successSoft), greaterThanOrEqualTo(threshold));
        expect(_contrast(p.warningText, p.warningSoft), greaterThanOrEqualTo(threshold));
      });

      test('$name: текст тоста читается на всех вариантах плашки', () {
        for (final background in [p.toast, p.dangerText, p.warningText]) {
          expect(
            _contrast(toastForeground(background), background),
            greaterThanOrEqualTo(threshold),
          );
        }
      });
    }
  });

  group('чипы на фирменной плашке', () {
    // Регрессия: активная вкладка «Оплата» красилась в `surface`, а он в тёмной
    // теме тёмный — тёмный текст на тёмном чипе поверх тёмной плашки.
    for (final dark in [false, true]) {
      test('светлый чип и читаемый текст при isDark=$dark', () {
        AppColors.use(dark);

        expect(_contrast(AppColors.onBrandChip, AppColors.brandChip), greaterThanOrEqualTo(4.5));
        expect(_contrast(AppColors.brandChipSuccess, AppColors.brandChip), greaterThanOrEqualTo(4.5));
        expect(_contrast(AppColors.brandChip, AppColors.brandSurface), greaterThanOrEqualTo(4.5));
      });
    }
  });

  group('тема не зависит от активной палитры', () {
    // Регрессия: стили `AppText` берут цвет из активной палитры, а `MaterialApp`
    // собирает light и dark за один проход — тёмная тема получала чёрный текст
    // заголовков, пока активной оставалась светлая.
    test('заголовок AppBar тёмной темы светлый даже при активной светлой', () {
      AppColors.use(false);
      final theme = buildAppTheme(AppPalette.dark);

      expect(theme.appBarTheme.titleTextStyle?.color, AppPalette.dark.textPrimary);
      expect(theme.textTheme.bodyLarge?.color, AppPalette.dark.textPrimary);
    });

    test('заголовок AppBar светлой темы тёмный даже при активной тёмной', () {
      AppColors.use(true);
      final theme = buildAppTheme(AppPalette.light);

      expect(theme.appBarTheme.titleTextStyle?.color, AppPalette.light.textPrimary);
      expect(theme.textTheme.bodyLarge?.color, AppPalette.light.textPrimary);
    });
  });

  group('системные панели', () {
    test('иконки статус-бара инвертированы относительно фона', () {
      expect(
        systemOverlayStyleFor(AppPalette.dark).statusBarIconBrightness,
        Brightness.light,
      );
      expect(
        systemOverlayStyleFor(AppPalette.light).statusBarIconBrightness,
        Brightness.dark,
      );
    });

    test('панель навигации красится в поверхность палитры', () {
      expect(
        systemOverlayStyleFor(AppPalette.dark).systemNavigationBarColor,
        AppPalette.dark.surface,
      );
    });
  });
}
