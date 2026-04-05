import 'package:flutter/material.dart';

class MobileContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const MobileContainer({super.key, required this.child, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SizedBox(
          width: 390, // Размер фрейма из вашего дизайна
          height: 844,
          child: child,
        ),
      ),
    );
  }
}
