import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '/models/loading_model.dart';

import '/helpers/helper.dart';

class LoadingLayout extends StatelessWidget {
  final Widget body;
  const LoadingLayout({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        body,
        Consumer<LoadingModel>(
          builder: (context, loaderModel, child) {
            if (loaderModel.currentLoading == 1) {
              return Positioned.fill(
                child: Container(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    color: mainColor,
                  ),
                ),
              );
            }
            if (loaderModel.currentLoading == 2) {
              return Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.black.withOpacity(0.4),
                child: SpinKitThreeBounce(
                  color: blue,
                  size: 35.0,
                ),
              );
            }
            return const SizedBox();
          },
        )
      ],
    );
  }
}
