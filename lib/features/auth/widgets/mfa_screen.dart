import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';

class MFAScreen extends StatefulWidget {
  const MFAScreen({super.key});

  @override
  State<MFAScreen> createState() => _MFAScreenState();
}

class _MFAScreenState extends State<MFAScreen> {
  final _codeController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.devMfaCode != null && auth.devMfaCode!.isNotEmpty) {
        _codeController.text = auth.devMfaCode!;
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) return;

    final auth = context.read<AuthProvider>();

    auth.clearLoginError();

    setState(() => _loading = true);

    final success = await auth.verifyMFA(code);

    if (!mounted) return;

    setState(() => _loading = false);

    if (!success) return;

    final role = auth.currentUser?.role;

    if (role == UserRole.admin) {
      context.go('/admin');
    } else {
      context.go('/cliente');
    }
  }

  String _subtitle(AuthProvider auth) {
    if (auth.mfaType == "totp") {
      return "Ingrese el código generado en Google Authenticator";
    }
    if (auth.devMfaCode != null && auth.devMfaCode!.isNotEmpty) {
      return "Modo de prueba activo: se autocompletó el código MFA simulado.";
    }
    return "Ingrese el código MFA para continuar";
  }

  String _label(AuthProvider auth) {
    if (auth.mfaType == "totp") {
      return "Código de Google Authenticator";
    }
    return "Código MFA";
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
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
                opacity: 0.18,
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
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Verificación de Seguridad",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _subtitle(auth),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (auth.devMfaCode != null &&
                              auth.devMfaCode!.isNotEmpty &&
                              auth.mfaType == "email")
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.45),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "Código MFA simulado",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    auth.devMfaCode!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: _label(auth),
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          if (auth.loginError != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      auth.loginError!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _verify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withOpacity(0.25),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text("Verificar código"),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.go('/login');
                              },
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Volver al login",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.4),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                        ],
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