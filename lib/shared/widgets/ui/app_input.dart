import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/theme/app_typography.dart';

/// Единое поле ввода дизайн-системы.
///
/// Покой: фон #F4F6FB + бордер 1px #E3E8F3.
/// Фокус: фон #FFFFFF + бордер 1.5px #5B60E8.
/// Ошибка: бордер 1.5px #E5484D, подпись лейбла и текст ошибки — #C4262B.
///
/// ```dart
/// AppInput(
///   label: 'Логин',
///   controller: loginController,
///   hint: 'ID кассира или логин',
/// )
/// AppInput.money(label: 'Naqd', controller: cashController)
/// ```
class AppInput extends StatefulWidget {
  /// Лейбл 11/600 caps над полем.
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final bool obscureText;

  /// Показать переключатель видимости пароля.
  final bool togglePassword;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int maxLines;
  final IconData? prefixIcon;
  final Widget? suffix;
  final FocusNode? focusNode;

  /// Крупный шрифт 22/600 с моноширинными цифрами — для сумм.
  final bool moneyStyle;

  /// Высота поля: 56 по умолчанию, 48 — для поиска.
  final double height;

  const AppInput({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.obscureText = false,
    this.togglePassword = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffix,
    this.focusNode,
    this.moneyStyle = false,
    this.height = AppDimens.heightLarge,
  });

  /// Поле суммы: числовая клавиатура, крупный tabular-шрифт.
  const AppInput.money({
    super.key,
    this.label,
    this.hint = '0',
    this.errorText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.textInputAction,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.prefixIcon,
    this.suffix,
    this.focusNode,
    this.height = 52,
  })  : keyboardType = TextInputType.number,
        obscureText = false,
        togglePassword = false,
        maxLines = 1,
        moneyStyle = true;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _focused = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final bool obscure = widget.obscureText && (!widget.togglePassword || _obscured);

    final Color borderColor = hasError
        ? AppColors.danger
        : _focused
            ? AppColors.primary
            : AppColors.border;
    final double borderWidth = hasError || _focused ? 1.5 : 1;
    final Color fill = !widget.enabled
        ? AppColors.disabledSurface
        : (_focused || hasError)
            ? AppColors.surface
            : AppColors.canvas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: AppText.caption.copyWith(
              color: hasError ? AppColors.dangerText : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: AppDimens.fast,
          constraints: BoxConstraints(minHeight: widget.maxLines > 1 ? widget.height : 0),
          height: widget.maxLines > 1 ? null : widget.height,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppDimens.control,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppDimens.gap12),
                  child: Icon(widget.prefixIcon, size: 20, color: AppColors.iconMuted),
                ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  onTap: widget.onTap,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  textInputAction: widget.textInputAction,
                  obscureText: obscure,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  autofocus: widget.autofocus,
                  maxLines: obscure ? 1 : widget.maxLines,
                  cursorColor: AppColors.primary,
                  style: widget.moneyStyle
                      ? AppText.money
                      : AppText.body.copyWith(
                          color: widget.enabled ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    // Подсказку держим на размере основного текста даже в
                    // денежном поле: 22px плейсхолдер не помещается в поле
                    // и читается как введённое значение.
                    hintStyle: AppText.body.copyWith(color: AppColors.iconMuted),
                    filled: false,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.prefixIcon != null ? AppDimens.gap8 : AppDimens.gap16,
                      vertical: widget.maxLines > 1 ? AppDimens.gap12 : 0,
                    ),
                  ),
                ),
              ),
              if (widget.togglePassword)
                _SuffixButton(
                  label: _obscured ? 'Показать' : 'Скрыть',
                  onTap: () => setState(() => _obscured = !_obscured),
                )
              else if (widget.suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppDimens.gap4),
                  child: widget.suffix,
                ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: AppColors.dangerText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: AppText.small.copyWith(color: AppColors.dangerText),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SuffixButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuffixButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.gap4),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppDimens.control,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDimens.control,
          child: Container(
            height: AppDimens.heightMedium,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppText.small.copyWith(
                color: AppColors.iconMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Строка поиска: высота 48, иконка лупы слева, крестик очистки справа.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  const AppSearchField({
    super.key,
    required this.controller,
    this.hint = 'Название или штрих-код',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return AppInput(
          controller: controller,
          hint: hint,
          height: AppDimens.heightMedium,
          autofocus: autofocus,
          onChanged: onChanged,
          prefixIcon: Icons.search,
          textInputAction: TextInputAction.search,
          suffix: value.text.isEmpty
              ? null
              : AppIconClear(
                  onTap: () {
                    controller.clear();
                    onChanged?.call('');
                    onClear?.call();
                  },
                ),
        );
      },
    );
  }
}

class AppIconClear extends StatelessWidget {
  final VoidCallback onTap;

  const AppIconClear({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppDimens.control,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.control,
        child: const SizedBox(
          width: AppDimens.heightSmall,
          height: AppDimens.heightSmall,
          child: Icon(Icons.close, size: 18, color: AppColors.iconMuted),
        ),
      ),
    );
  }
}

/// Степпер количества: −  n  + , тач-таргеты 44×44.
class AppStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;
  final double height;

  const AppStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
    this.height = AppDimens.tapTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.control,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            enabled: value > min,
            onTap: () => onChanged(value - 1),
            height: height,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 34),
            height: height,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border.symmetric(vertical: BorderSide(color: AppColors.border)),
            ),
            child: Text(
              '$value',
              style: AppText.price.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            enabled: max == null || value < max!,
            onTap: () => onChanged(value + 1),
            height: height,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final double height;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 40,
        height: height,
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.primary : AppColors.iconMuted,
        ),
      ),
    );
  }
}
