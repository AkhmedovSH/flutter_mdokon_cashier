import 'package:flutter/material.dart';

/// Адаптер для API dropdown_button2 3.x, где `value` заменён на `valueListenable`.
/// Позволяет по-прежнему передавать обычное значение из setState/provider.
class DropdownValue<T> extends StatefulWidget {
  final T? value;
  final Widget Function(BuildContext context, ValueNotifier<T?> notifier) builder;

  const DropdownValue({
    super.key,
    required this.value,
    required this.builder,
  });

  @override
  State<DropdownValue<T>> createState() => _DropdownValueState<T>();
}

class _DropdownValueState<T> extends State<DropdownValue<T>> {
  late final ValueNotifier<T?> _notifier = ValueNotifier<T?>(widget.value);

  @override
  void didUpdateWidget(covariant DropdownValue<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _notifier.value) {
      _notifier.value = widget.value;
    }
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _notifier);
}
