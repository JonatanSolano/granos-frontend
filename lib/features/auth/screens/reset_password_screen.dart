import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';

import 'package:granos_la_tradicion/core/config/app_config.dart';
import '../../../core/widgets/app_layout.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _isValidatingToken = true;
  bool _tokenValid = false;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final String baseUrl = "${AppConfig.apiBaseUrl}/api";

  Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  bool isValidPassword(String password) {
    if (password.length < 8) return false;

    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSymbol = RegExp(r'[!@#\$%^&*]').hasMatch(password);

    return hasUpper && hasNumber && hasSymbol;
  }

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  Future<void> _validateToken() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/validate-reset-token"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "token": widget.token,
        }),
      );

      final data = _safeDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data["valid"] == true) {
        setState(() {
          _tokenValid = true;
          _isValidatingToken = false;
        });
      } else {
        setState(() {
          _tokenValid = false;
          _isValidatingToken = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["error"] ?? "El token no es válido o ha expirado.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _tokenValid = false;
        _isValidatingToken = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error validando el token."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();

    if (!_tokenValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El token no es válido o ya expiró."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe ingresar una contraseña"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!isValidPassword(_passwordController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "La contraseña debe tener mínimo 8 caracteres, una mayúscula, un número y un símbolo",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_confirmController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe confirmar la contraseña"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Las contraseñas no coinciden"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/reset-password"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "token": widget.token,
          "newPassword": _passwordController.text.trim(),
        }),
      );

      final data = _safeDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ??
                  "Contraseña restablecida correctamente",
            ),
            backgroundColor: Colors.green,
          ),
        );

        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["error"] ??
                  "No se pudo restablecer la contraseña",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Error conectando con el servidor",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final horizontalPadding =
        screenWidth > 600 ? screenWidth * 0.30 : 24.0;

    return AppLayout(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Restablecer contraseña",
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
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                  child: _isValidatingToken
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 30,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        )
                      : !_tokenValid
                          ? Column(
                              children: [
                                const Text(
                                  "El enlace de recuperación no es válido o ha expirado.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      context.go('/forgot-password');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white
                                          .withOpacity(0.25),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding:
                                          const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: const Text(
                                      "Solicitar nuevo enlace",
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                const Text(
                                  "Ingrese y confirme su nueva contraseña para continuar.",
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
                                        _obscurePassword =
                                            !_obscurePassword;
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
                                        _obscureConfirm =
                                            !_obscureConfirm;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _resetPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white
                                          .withOpacity(0.25),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding:
                                          const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child:
                                                CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            "Cambiar contraseña",
                                          ),
                                  ),
                                ),
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
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color:
                            Colors.white.withOpacity(0.4),
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30),
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