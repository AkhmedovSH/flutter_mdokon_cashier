import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mdokon/core/state/loading_model.dart';
import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/shared/widgets/ui/app_loader.dart';

/// Слой загрузки над контентом.
///
/// currentLoading == 1 — спиннер поверх пустого экрана;
/// currentLoading == 2 — блокирующий оверлей с карточкой лоадера.
class LoadingLayout extends StatelessWidget {
  final Widget body;
  final bool onlySecond;

  /// Подпись для блокирующего оверлея.
  final String? label;

  const LoadingLayout({
    super.key,
    required this.body,
    this.onlySecond = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        body,
        Consumer<LoadingModel>(
          builder: (context, loaderModel, child) {
            if (loaderModel.currentLoading == 1 && !onlySecond) {
              return const Positioned.fill(child: AppLoaderView());
            }
            if (loaderModel.currentLoading == 2) {
              return Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: AppColors.scrim.withValues(alpha: 0.35),
                    child: label == null ? const Center(child: AppLoader()) : AppLoaderCard(label: label!),
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }
}
