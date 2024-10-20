import 'package:flutter/material.dart';

import '/helpers/helper.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        color: mainColor,
      ),
    );
  }
}
