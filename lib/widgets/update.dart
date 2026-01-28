import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/helpers/helper.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<Offset>? _offsetAnimation;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _offsetAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.05), // Диалог начинается снизу (1.0 по вертикали)
          end: const Offset(0, 0), // Диалог приходит в позицию (0.0 по вертикали)
        ).animate(
          CurvedAnimation(
            parent: _controller!,
            curve: Curves.easeOut,
          ),
        );

    _fadeAnimation =
        Tween<double>(
          begin: 0.0, // Начальная прозрачность (0.0 = полностью прозрачно)
          end: 1.0, // Конечная прозрачность (1.0 = полностью непрозрачно)
        ).animate(
          CurvedAnimation(
            parent: _controller!,
            curve: Curves.easeIn,
          ),
        );

    _controller!.forward(); // Запуск анимации при инициализации
  }

  void closeDialog() async {
    await _controller!.reverse();
    if (mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _controller!.reverse();
        await Future.delayed(const Duration(milliseconds: 150));
        return true;
      },
      child: SlideTransition(
        position: _offsetAnimation!,
        child: FadeTransition(
          opacity: _fadeAnimation!,
          child: Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(21),
            ),
            child: Container(
              padding: const EdgeInsets.only(
                top: 15,
                right: 15,
                left: 15,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                color: CustomTheme.of(context).bgColor,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('update_app'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('update_app_description'),
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {
                              closeDialog();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CustomTheme.of(context).cardColor,
                              foregroundColor: CustomTheme.of(context).textColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              context.tr('later'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (Platform.isIOS) {
                                await launchUrl(Uri.parse('https://apps.apple.com/us/app/mdokon-kassa/id6471837929'));
                              } else {
                                await launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.mdokon.cabinet'));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              context.tr('update'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// class UpdateDialog extends StatelessWidget {
//   const UpdateDialog({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: CustomTheme.of(context).bgColor,
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               context.tr('update_app'),
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 20,
//               ),
//             ),
//             const SizedBox(height: 15),
//             Text(context.tr('update_app_description')),
//           ],
//         ),
//       ),
//     );
//   }
// }
