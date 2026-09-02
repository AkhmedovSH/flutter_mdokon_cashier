import 'package:flutter/widgets.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';

/// Класс ширины экрана.
///
/// Дизайн-система нарисована под телефон 390×844 ([compact]); всё, что шире,
/// раскладывается по двум ступеням: узкий планшет / телефон в альбоме
/// ([medium]) и планшет 1024×768 и шире ([expanded]).
enum AppScreenSize {
  /// < 600 — телефон.
  compact,

  /// 600–1023 — планшет в портрете, телефон в альбоме, split view.
  medium,

  /// ≥ 1024 — планшет в альбоме.
  expanded;

  bool operator >=(AppScreenSize other) => index >= other.index;
  bool operator >(AppScreenSize other) => index > other.index;
  bool operator <=(AppScreenSize other) => index <= other.index;
  bool operator <(AppScreenSize other) => index < other.index;
}

/// Адаптивные размеры раскладки.
///
/// [AppDimens] остаётся мобильными токенами и не меняется — [AppLayout] лишь
/// подбирает под ширину экрана то, что обязано расти: поля, высоты тач-целей,
/// ширину боковых колонок и число колонок в сетке товаров.
///
/// ```dart
/// final layout = context.layout;
/// if (layout.hasSideRail) ... // трёхколоночная раскладка
/// ```
class AppLayout {
  final AppScreenSize size;

  /// Ширина и высота окна — нужны, когда решение зависит от обеих сторон
  /// (например, хватает ли высоты на боковую колонку с итогами).
  final Size screen;

  const AppLayout({required this.size, required this.screen});

  factory AppLayout.of(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return AppLayout(size: sizeOf(screen.width), screen: screen);
  }

  static AppScreenSize sizeOf(double width) {
    if (width >= 1024) return AppScreenSize.expanded;
    if (width >= 600) return AppScreenSize.medium;
    return AppScreenSize.compact;
  }

  /// Значение под текущую ширину. Пропущенная ступень наследует предыдущую.
  T pick<T>({required T compact, T? medium, T? expanded}) {
    final m = medium ?? compact;
    return switch (size) {
      AppScreenSize.compact => compact,
      AppScreenSize.medium => m,
      AppScreenSize.expanded => expanded ?? m,
    };
  }

  // --- Признаки раскладки -------------------------------------------------

  bool get isCompact => size == AppScreenSize.compact;

  /// Любой экран шире телефона: планшет или телефон в альбоме.
  bool get isTablet => size >= AppScreenSize.medium;

  /// Навигация разделами переезжает из нижней панели в шапку.
  bool get useTopNav => isTablet;

  /// Хватает ширины на постоянную колонку оплаты/чека справа.
  ///
  /// Требуем и высоту: в альбоме телефона (844×390) ширина «планшетная»,
  /// а колонка с итогами там не помещается.
  bool get hasSideRail => size >= AppScreenSize.expanded && screen.height >= 600;

  /// Постоянная колонка с чеком в каталоге.
  bool get hasCartRail => hasSideRail;

  /// Список и карточка на одном экране (чеки, возврат).
  bool get hasMasterDetail => hasSideRail;

  // --- Отступы ------------------------------------------------------------

  double get gutter => pick(compact: 16, medium: 20, expanded: 24);
  double get gap => pick(compact: 8, medium: 12, expanded: 12);
  double get sectionGap => pick(compact: 12, medium: 16, expanded: 20);

  EdgeInsets get pagePadding => EdgeInsets.symmetric(horizontal: gutter);

  /// Ширина колонки с текстом/списком, когда экран заметно шире неё.
  double get contentMaxWidth => pick(
        compact: double.infinity,
        medium: 640,
        expanded: 760,
      );

  // --- Тач-цели -----------------------------------------------------------

  /// Минимальный тач-таргет: на планшете — от 48 до 52.
  double get tapTarget => pick(compact: 44, medium: 48, expanded: 52);

  /// Высота основной кнопки («Продать», «Принять»).
  double get primaryButtonHeight => pick(compact: 56, medium: 56, expanded: 64);

  /// Высота вторичной кнопки и поля ввода.
  double get controlHeight => pick(compact: 48, medium: 52, expanded: 56);

  /// Сторона клавиши цифровой клавиатуры оплаты.
  double get keypadKey => pick(compact: 52, medium: 60, expanded: 68);

  /// Высота верхней навигации.
  double get topNavHeight => pick(compact: 56, medium: 60, expanded: 64);

  // --- Колонки ------------------------------------------------------------

  /// Ширина правой колонки оплаты на экране продажи.
  double get railWidth => pick(compact: 0, medium: 0, expanded: 320);

  /// Ширина колонки со списком в мастер-детейле (чеки, возврат).
  double get masterWidth => pick(compact: 0, medium: 0, expanded: 380);

  /// Предельная ширина карточки товара в сетке каталога.
  ///
  /// Держим её большой намеренно: в карточке рядом стоят цена, остаток и
  /// кнопка «Добавить», и в колонке уже 300 px цена начинает обрезаться.
  double get productTileMaxWidth => pick(compact: 560, medium: 460, expanded: 520);

  /// Высота карточки товара в сетке: название в две строки, цена, остаток
  /// и штрих-код умещаются без обрезки.
  double get productTileHeight => pick(compact: 116, medium: 116, expanded: 118);

  // --- Модалки ------------------------------------------------------------

  /// На планшете лист снизу превращается в окно по центру.
  bool get useDialogInsteadOfSheet => isTablet;

  double get dialogMaxWidth => pick(compact: 480, medium: 480, expanded: 520);

  /// Ширина окна оплаты (на телефоне — весь экран).
  double get paymentWindowWidth => pick(compact: double.infinity, medium: 640, expanded: 720);

  /// Высота окна оплаты.
  double get paymentWindowHeight => pick(compact: double.infinity, medium: 720, expanded: 700);

  /// Ширина колонки с суммой и клавиатурой внутри окна оплаты.
  double get paymentPadWidth => pick(compact: 0, medium: 0, expanded: 320);

  // --- Типографика --------------------------------------------------------

  /// Множитель для крупных сумм и заголовков: на планшете кассир смотрит
  /// на экран с расстояния вытянутой руки.
  double get textScale => pick(compact: 1, medium: 1, expanded: 1.05);

  double scaled(double fontSize) => fontSize * textScale;

  /// Радиус карточек и панелей.
  double get radiusPanel => pick(compact: 16, medium: 16, expanded: 20);

  /// Разделитель между колонками.
  BorderSide get columnBorder => BorderSide(color: AppColors.border);
}

extension AppLayoutX on BuildContext {
  /// Адаптивные размеры текущего экрана.
  AppLayout get layout => AppLayout.of(this);

  /// Экран шире телефона (планшет или телефон в альбоме).
  bool get isTablet => AppLayout.of(this).isTablet;
}
