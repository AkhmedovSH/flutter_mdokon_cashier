import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

import '../helpers/globals.dart';
import '../helpers/controller.dart';

class LoadingLayout extends StatefulWidget {
  const LoadingLayout({Key? key, this.body}) : super(key: key);
  final Widget? body;

  @override
  State<LoadingLayout> createState() => _LoadingLayoutState();
}

class _LoadingLayoutState extends State<LoadingLayout>
    with TickerProviderStateMixin {
  AnimationController? animationController;
  final Controller controller = Get.put(Controller());

  @override
  void initState() {
    super.initState();
    setState(() {
      animationController = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 1200));
    });
  }

  @override
  dispose() {
    animationController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.body!,
        controller.loading.value
            ? Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.black.withOpacity(0.4),
                child: SpinKitThreeBounce(
                  color: blue,
                  size: 35.0,
                  controller: animationController,
                ),
              )
            : Container(),
      ],
    );
  }
}
