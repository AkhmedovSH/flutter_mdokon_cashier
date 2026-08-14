import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  final String text;
  const Label({super.key, this.text = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Text(
        context.tr(text),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
