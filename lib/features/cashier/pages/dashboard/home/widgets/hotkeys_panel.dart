import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:flutter_mdokon/features/cashier/domain/hotkeys.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Панель-подсказка «Горячие клавиши» (`src/components/cashbox/HotkeysPanel.js`).
///
/// Нужна там же, где сами клавиши, — на планшете с внешней клавиатурой.
/// Раскладку кассир держать в голове не обязан, а искать её в инструкции у
/// кассы некогда.
class HotkeysPanel extends StatelessWidget {
  const HotkeysPanel({super.key});

  static Future<void> show(BuildContext context) {
    return AppModal.sheet<void>(context, builder: (_) => const HotkeysPanel());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.tr('hotkeys'), style: AppText.h2),
        const SizedBox(height: AppDimens.gap4),
        Text(context.tr('hotkeys_hint'), style: AppText.secondary),
        const SizedBox(height: AppDimens.gap12),
        for (final hint in hotkeyHints) ...[
          Row(
            children: [
              for (final key in hint.keys) ...[
                _KeyChip(label: key),
                const SizedBox(width: AppDimens.gap4),
              ],
              const SizedBox(width: AppDimens.gap8),
              Expanded(
                child: Text(context.tr(hint.labelKey), style: AppText.body),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap8),
        ],
      ],
    );
  }
}

class _KeyChip extends StatelessWidget {
  final String label;

  const _KeyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimens.radiusControl),
      ),
      child: Text(label, style: AppText.tabular(AppText.secondaryBold)),
    );
  }
}
