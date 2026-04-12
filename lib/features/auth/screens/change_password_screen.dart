import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/app_layout.dart';
import '../widgets/auth_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? message;

  bool isValidPassword(String password) {
    if (password.length < 8) return false;

    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSymbol = RegExp(r'[!@#\$%^&*]').hasMatch(password);

    return hasUpper && hasNumber && hasSymbol;
  }

  Future<void> changePassword() async {
    final auth = context.read<AuthProvider>();

    if (_passwordController.text.trim().isEmpty) {
      setState(() {
        message = "Debe ingresar una nueva contraseña.";
      });
      return;
    }

    if (!isValidPassword(_passwordController.text.trim())) {
      setState(() {
        message =
            "La contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un símbolo.";
      });
      return;
    }

    if (_confirmController.text.trim().isEmpty) {
      setState(() {
        message = "Debe confirmar la contraseña.";
      });
      return;
    }

    if (_passwordController.text.trim() != _confirmController.text.trim()) {
      setState(() {
        message = "Las contraseñas no coinciden.";
      });
      return;
    }

    setState(() {
      loading = true;
      message = null;
    });

    try {
      final response =
          await auth.changePassword(_passwordController.text.trim());

      if (!mounted) return;

      final success = response["success"] == true;

      setState(() {
        message = success
            ? (response["message"] ?? "Contraseña actualizada correctamente.")
            : (response["error"] ?? "Error cambiando contraseña.");
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response["message"] ?? "Contraseña actualizada correctamente.",
            ),
            backgroundColor: Colors.green,
          ),
        );

        context.go('/login');
      }
    } catch (e) {
      setState(() {
        message = "Error cambiando contraseña.";
      });
    }

    if (!mounted) return;

    setState(() => loading = false);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final horizontalPadding =
        screenWidth > 600 ? screenWidth * 0.30 : 24.0;

    return AppLayout(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Cambiar contraseña",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Su contraseña ha expirado. Debe actualizarla para continuar.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      AuthTextField(
                        controller: _passwordController,
                        label: "Nueva contraseña",
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      AuthTextField(
                        controller: _confirmController,
                        label: "Confirmar contraseña",
                        obscureText: _obscureConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.25),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Actualizar contraseña"),
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: message!.toLowerCase().contains("error") ||
                                    message!.toLowerCase().contains("debe") ||
                                    message!.toLowerCase().contains("no ")
                                ? Colors.red.shade400
                                : Colors.green.shade600,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
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
                      "Volver a Iniciar Sesión",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }
}