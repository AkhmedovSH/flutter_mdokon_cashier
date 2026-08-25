import 'package:flutter/material.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/theme/app_typography.dart';
import 'package:flutter_mdokon/core/theme/responsive.dart';
import 'package:flutter_mdokon/shared/widgets/ui/app_button.dart';

enum AppModalTone { info, danger, warning, success }

extension _ModalToneStyle on AppModalTone {
  Color get iconBackground => switch (this) {
        AppModalTone.info => AppColors.primarySoft,
        AppModalTone.danger => AppColors.dangerSoft,
        AppModalTone.warning => AppColors.warningSoft,
        AppModalTone.success => AppColors.successSoft,
      };

  Color get iconColor => switch (this) {
        AppModalTone.info => AppColors.primary,
        AppModalTone.danger => AppColors.dangerText,
        AppModalTone.warning => AppColors.warningText,
        AppModalTone.success => AppColors.successText,
      };

  IconData get icon => switch (this) {
        AppModalTone.info => Icons.help_outline,
        AppModalTone.danger => Icons.error_outline,
        AppModalTone.warning => Icons.warning_amber_rounded,
        AppModalTone.success => Icons.check_circle_outline,
      };

  AppButtonVariant get confirmVariant => switch (this) {
        AppModalTone.danger => AppButtonVariant.dangerSolid,
        _ => AppButtonVariant.primary,
      };
}

/// Модальный лист дизайн-системы: прижат к низу, радиус 24 сверху,
/// подложка rgba(27,33,56,0.45), паддинги 24/16/16.
class AppModalSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const AppModalSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppDimens.gutter,
      AppDimens.gap24,
      AppDimens.gutter,
      AppDimens.gutter,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimens.sheet,
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Окно по центру экрана — планшетный вариант [AppModalSheet].
///
/// На 1024 и 1280 лист во всю ширину выглядит потерянным, а его содержимое
/// уезжает от глаз вниз. Окно 520–560 держит содержимое в центре, а чек или
/// каталог остаются видны по краям.
class AppModalWindow extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;

  const AppModalWindow({
    super.key,
    required this.child,
    required this.maxWidth,
    this.padding = const EdgeInsets.all(AppDimens.gap24),
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppDimens.gap24, AppDimens.gap24, AppDimens.gap24, AppDimens.gap24 + insets),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: screen.height - insets - AppDimens.gap24 * 2,
          ),
          child: Material(
            color: AppColors.surface,
            borderRadius: const BorderRadius.all(Radius.circular(AppDimens.radiusSheet)),
            clipBehavior: Clip.antiAlias,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Единая точка входа для модалок приложения.
class AppModal {
  const AppModal._();

  /// Модалка с произвольным содержимым: лист снизу на телефоне и окно по
  /// центру на планшете — вызывающий код об этом не знает.
  static Future<T?> sheet<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool dismissible = true,
    bool scrollControlled = true,
  }) {
    final layout = AppLayout.of(context);

    if (layout.useDialogInsteadOfSheet) {
      return showDialog<T>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: dismissible,
        barrierColor: AppColors.scrim,
        builder: (ctx) => AppModalWindow(
          maxWidth: layout.dialogMaxWidth,
          child: builder(ctx),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: scrollControlled,
      isDismissible: dismissible,
      enableDrag: dismissible,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      builder: (ctx) => AppModalSheet(child: builder(ctx)),
    );
  }

  /// Диалог подтверждения. Возвращает `true`, если нажали основную кнопку.
  ///
  /// ```dart
  /// final ok = await AppModal.confirm(
  ///   context,
  ///   title: 'Очистить чек?',
  ///   text: 'Все позиции будут удалены.',
  ///   confirmLabel: 'Очистить',
  ///   tone: AppModalTone.danger,
  /// );
  /// ```
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? text,
    String? note,
    String confirmLabel = 'Подтвердить',
    String cancelLabel = 'Отмена',
    AppModalTone tone = AppModalTone.info,
  }) async {
    final result = await sheet<bool>(
      context,
      builder: (ctx) => _AppModalBody(
        title: title,
        text: text,
        note: note,
        tone: tone,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    return result ?? false;
  }

  /// Модалка ошибки с одной кнопкой.
  static Future<void> error(
    BuildContext context, {
    required String title,
    String? text,
    String? note,
    String confirmLabel = 'Понятно',
  }) {
    return sheet<void>(
      context,
      builder: (ctx) => _AppModalBody(
        title: title,
        text: text,
        note: note,
        tone: AppModalTone.danger,
        confirmLabel: confirmLabel,
        cancelLabel: null,
        onConfirm: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  /// Меню действий («…» на экране продажи).
  static Future<T?> actions<T>(
    BuildContext context, {
    required String title,
    required List<AppModalAction<T>> actions,
    String cancelLabel = 'Отмена',
  }) {
    return sheet<T>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppText.h2),
          const SizedBox(height: AppDimens.gap12),
          // Список действий может не поместиться на экран — скроллим его.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final action in actions) ...[
                    AppButton(
                      label: action.label,
                      icon: action.icon,
                      variant: action.danger ? AppButtonVariant.danger : AppButtonVariant.secondary,
                      size: AppButtonSize.medium,
                      onPressed: () => Navigator.of(ctx).pop(action.value),
                    ),
                    const SizedBox(height: AppDimens.gap8),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.gap4),
          AppButton(
            label: cancelLabel,
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.medium,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}

/// Пункт меню действий.
class AppModalAction<T> {
  final String label;
  final T? value;
  final IconData? icon;
  final bool danger;

  const AppModalAction({
    required this.label,
    this.value,
    this.icon,
    this.danger = false,
  });
}

class _AppModalBody extends StatelessWidget {
  final String title;
  final String? text;
  final String? note;
  final AppModalTone tone;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const _AppModalBody({
    required this.title,
    required this.tone,
    required this.confirmLabel,
    required this.onConfirm,
    this.text,
    this.note,
    this.cancelLabel,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tone.iconBackground,
                borderRadius: AppDimens.control,
              ),
              child: Icon(tone.icon, size: 22, color: tone.iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h2),
                  if (text != null) ...[
                    const SizedBox(height: 6),
                    Text(text!, style: AppText.secondary.copyWith(fontSize: 14)),
                  ],
                  if (note != null) ...[
                    const SizedBox(height: 6),
                    Text(note!, style: AppText.small),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.gap16),
        AppButton(
          label: confirmLabel,
          variant: tone.confirmVariant,
          onPressed: onConfirm,
        ),
        if (cancelLabel != null) ...[
          const SizedBox(height: AppDimens.gap8),
          AppButton(
            label: cancelLabel!,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.medium,
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
          ),
        ],
      ],
    );
  }
}
