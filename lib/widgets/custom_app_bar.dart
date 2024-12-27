import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:unicons/unicons.dart';

import '/helpers/helper.dart';

const list = [];

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int titleCount;
  final TextStyle titleStyle;
  final List<Widget>? actions;
  final bool leading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.titleCount = 0,
    this.titleStyle = const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 24,
    ),
    this.leading = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.3),
            width: 0.33,
          ),
        ),
      ),
      child: AppBar(
        title: Text(
          '${context.tr(title)} ${titleCount > 0 ? '[$titleCount]' : ''}',
          style: titleStyle,
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
        backgroundColor: CustomTheme.of(context).bgColor,
        surfaceTintColor: CustomTheme.of(context).bgColor,
        elevation: 0,
        actions: actions ?? [],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
