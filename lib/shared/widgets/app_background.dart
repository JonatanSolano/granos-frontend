import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        /// Marca de agua centrada
        Positioned.fill(
          child: Opacity(
            opacity: 0.05, // 🔥 Ajusta intensidad aquí
            child: Center(
              child: Image.asset(
                "assets/images/logo_marca.png",
                width: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        /// Contenido real encima
        child,
      ],
    );
  }
}