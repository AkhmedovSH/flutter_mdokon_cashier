import 'package:flutter/material.dart';
import 'package:flutter_mdokon/helpers/helper.dart';
import 'package:go_router/go_router.dart';

class AnimatedDialog extends StatefulWidget {
  final Widget child;
  const AnimatedDialog({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedDialog> createState() => _AnimatedDialogState();
}

class _AnimatedDialogState extends State<AnimatedDialog> with SingleTickerProviderStateMixin {
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

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05), // Диалог начинается снизу (1.0 по вертикали)
      end: const Offset(0, 0), // Диалог приходит в позицию (0.0 по вертикали)
    ).animate(CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0, // Начальная прозрачность (0.0 = полностью прозрачно)
      end: 1.0, // Конечная прозрачность (1.0 = полностью непрозрачно)
    ).animate(CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeIn,
    ));

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
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
