import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientBaseLayout extends StatefulWidget {
  final String title;
  final Widget child;
  final bool showBackButton;
  final String backRoute;

  const ClientBaseLayout({
    super.key,
    required this.title,
    required this.child,
    this.showBackButton = true,
    this.backRoute = '/cliente',
  });

  @override
  State<ClientBaseLayout> createState() => _ClientBaseLayoutState();
}

class _ClientBaseLayoutState extends State<ClientBaseLayout> {
  bool _backButtonEnabled = false;
  Timer? _backButtonTimer;

  @override
  void initState() {
    super.initState();

    _backButtonTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;

      setState(() {
        _backButtonEnabled = true;
      });
    });
  }

  @override
  void dispose() {
    _backButtonTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            "assets/images/background_texture.jpg",
            fit: BoxFit.cover,
          ),
        ),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: widget.child,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.showBackButton)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            label: const Text("Volver al Panel"),
                            onPressed: _backButtonEnabled
                                ? () => context.go(widget.backRoute)
                                : null,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                              foregroundColor: Colors.white,
                              disabledForegroundColor:
                                  Colors.white.withOpacity(0.45),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}