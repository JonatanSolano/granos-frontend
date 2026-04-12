import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding =
        screenWidth > 600 ? screenWidth * 0.25 : 24.0;

    return Scaffold(
      body: Stack(
        children: [

          /// FONDO TEXTURA
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
                opacity: 0.20,
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

                /// HEADER BLANCO
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

                /// CONTENIDO
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding),
                        child: Column(
                          children: [

                            const SizedBox(height: 20),

                            const Text(
                              "Bienvenido a Granos La Tradición",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              "Calidad y tradición en cada grano.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),

                            const SizedBox(height: 50),

                            /// BOTÓN VER CATÁLOGO (GLASS)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  context.go('/catalogo');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.25),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(30),
                                    side: BorderSide(
                                      color: Colors.white
                                          .withOpacity(0.4),
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 18),
                                ),
                                child: const Text(
                                  "Ver Catálogo",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// BOTÓN INGRESAR (GLASS OUTLINE)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  context.go('/login');
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.white
                                        .withOpacity(0.4),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  "Ingresar",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            TextButton(
                              onPressed: () {
                                context.go('/register');
                              },
                              child: const Text(
                                "¿No tienes cuenta? Regístrate",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            GestureDetector(
                              onTap: () {
                                context.go('/login');
                              },
                              child: const Text(
                                "Acceso administrador",
                                style: TextStyle(
                                  color: Colors.white60,
                                  decoration:
                                      TextDecoration.underline,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}