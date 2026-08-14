import 'package:flutter/material.dart';

import 'package:flutter_mdokon/shared/widgets/ui/app_loader.dart';

/// Совместимость: обёртка над [AppLoader] из UI-кита.
class LoadingWidget extends StatelessWidget {
  final String? label;

  const LoadingWidget({super.key, this.label});

  @override
  Widget build(BuildContext context) => AppLoaderView(label: label);
}
