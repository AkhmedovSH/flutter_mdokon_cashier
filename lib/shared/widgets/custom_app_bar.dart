import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:unicons/unicons.dart';

import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/theme/app_typography.dart';

const list = [];

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int titleCount;

  /// Если не задан — берётся стиль заголовка активной темы. Раньше здесь стоял
  /// `const TextStyle` без цвета: на тёмной теме заголовок оставался чёрным.
  final TextStyle? titleStyle;
  final List<Widget>? actions;
  final bool leading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.titleCount = 0,
    this.titleStyle,
    this.leading = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.33),
        ),
      ),
      child: AppBar(
        title: Text(
          '${context.tr(title)} ${titleCount > 0 ? '[$titleCount]' : ''}',
          style: titleStyle ??
              AppText.h1.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        leading: leading
            ? IconButton(
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(
                  UniconsLine.arrow_left,
                  size: 32,
                ),
              )
            : null,
        automaticallyImplyLeading: leading,
        leadingWidth: 50,
        titleSpacing: leading ? 0 : 16,
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        actions: actions ?? [],
        centerTitle: false,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
