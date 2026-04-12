import 'package:flutter/material.dart';

class AppLayout extends StatelessWidget {
  final Widget child;

  const AppLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// FONDO
          Positioned.fill(
            child: Image.asset(
              "assets/images/background_texture.jpg",
              fit: BoxFit.cover,
            ),
          ),

          /// OSCURECER BORDES
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.75),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),

          /// MARCA DE AGUA
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.28,
                child: Center(
                  child: Image.asset(
                    "assets/images/logo.png",
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                /// HEADER OFICIAL (NO SE TOCA MÁS)
                Container(
                  width: double.infinity,
                  height: 80,
                  color: Colors.white,
                  child: Center(
                    child: OverflowBox(
                      maxHeight: 200,
                      child: Image.asset(
                        "assets/images/logo_header.png",
                        height: 160,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                /// CONTENIDO DINÁMICO
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}