import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/app_layout.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();

  bool loading = false;
  String? message;

  bool _questionsLoaded = false;
  List<Map<String, dynamic>> recoveryQuestions = [];

  bool isValidEmail(String email) {
    return RegExp(
      r'^[\w\-\.]+@([\w\-]+\.)+[\w]{2,4}$',
    ).hasMatch(email);
  }

  Future<void> requestResetByEmail() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        message = "Debe ingresar su correo electrónico.";
      });
      return;
    }

    if (!isValidEmail(_emailController.text.trim())) {
      setState(() {
        message = "El formato del correo no es válido.";
      });
      return;
    }

    setState(() {
      loading = true;
      message = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final data = await auth.requestPasswordReset(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      if (data["token"] != null) {
        final token = data["token"].toString();
        context.go("/reset-password/$token");
        return;
      }

      setState(() {
        message = data['message'] ??
            data['error'] ??
            "No fue posible procesar la solicitud.";
      });
    } catch (e) {
      setState(() {
        message = "Error conectando al servidor.";
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> loadRecoveryQuestions() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        message = "Debe ingresar su correo electrónico.";
      });
      return;
    }

    if (!isValidEmail(_emailController.text.trim())) {
      setState(() {
        message = "El formato del correo no es válido.";
      });
      return;
    }

    setState(() {
      loading = true;
      message = null;
      _questionsLoaded = false;
      recoveryQuestions = [];
    });

    try {
      final auth = context.read<AuthProvider>();
      final questions =
          await auth.getRecoverySecurityQuestions(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      if (questions.length != 2) {
        setState(() {
          message =
              "No se pudieron cargar las 2 preguntas de seguridad del usuario.";
        });
        return;
      }

      setState(() {
        recoveryQuestions = questions;
        _questionsLoaded = true;
        message =
            "Responda correctamente las 2 preguntas de seguridad.";
      });
    } catch (e) {
      setState(() {
        message = "Error cargando preguntas de seguridad.";
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> recoverBySecurityQuestions() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        message = "Debe ingresar su correo electrónico.";
      });
      return;
    }

    if (recoveryQuestions.length != 2) {
      setState(() {
        message =
            "Primero debe cargar las preguntas de seguridad.";
      });
      return;
    }

    if (_answer1Controller.text.trim().isEmpty ||
        _answer2Controller.text.trim().isEmpty) {
      setState(() {
        message =
            "Debe responder las 2 preguntas de seguridad.";
      });
      return;
    }

    setState(() {
      loading = true;
      message = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      final data = await auth.recoverPasswordWithSecurity(
        email: _emailController.text.trim(),
        answers: [
          {
            "questionId": recoveryQuestions[0]["id"],
            "answer": _answer1Controller.text.trim(),
          },
          {
            "questionId": recoveryQuestions[1]["id"],
            "answer": _answer2Controller.text.trim(),
          },
        ],
      );

      if (!mounted) return;

      if (data["resetToken"] != null) {
        final token = data["resetToken"].toString();
        context.go("/reset-password/$token");
        return;
      }

      setState(() {
        message = data["message"] ??
            data["error"] ??
            "No fue posible validar las respuestas.";
      });
    } catch (e) {
      setState(() {
        message = "Error conectando al servidor.";
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _answer1Controller.dispose();
    _answer2Controller.dispose();
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
                  "Recuperar contraseña",
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
                        "Ingrese su correo electrónico para recuperar su contraseña por correo o por preguntas de seguridad.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      AuthTextField(
                        controller: _emailController,
                        label: "Correo electrónico",
                        keyboardType:
                            TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              loading ? null : requestResetByEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.white.withOpacity(0.25),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(30),
                            ),
                          ),
                          child: loading
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
                                  "Recuperar por correo",
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed:
                              loading ? null : loadRecoveryQuestions,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white
                                  .withOpacity(0.4),
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
                          child: const Text(
                            "Usar preguntas de seguridad",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (_questionsLoaded &&
                          recoveryQuestions.length == 2) ...[
                        const SizedBox(height: 28),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Preguntas de seguridad",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildQuestionBox(
                          recoveryQuestions[0]["question"]
                              .toString(),
                        ),
                        const SizedBox(height: 12),
                        AuthTextField(
                          controller: _answer1Controller,
                          label: "Respuesta 1",
                        ),
                        const SizedBox(height: 20),
                        _buildQuestionBox(
                          recoveryQuestions[1]["question"]
                              .toString(),
                        ),
                        const SizedBox(height: 12),
                        AuthTextField(
                          controller: _answer2Controller,
                          label: "Respuesta 2",
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading
                                ? null
                                : recoverBySecurityQuestions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withOpacity(0.25),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "Validar respuestas",
                            ),
                          ),
                        ),
                      ],
                      if (message != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: message!
                                    .toLowerCase()
                                    .contains("error")
                                ? Colors.red.shade400
                                : Colors.green.shade600,
                            borderRadius:
                                BorderRadius.circular(16),
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
                      padding: const EdgeInsets.symmetric(
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

  Widget _buildQuestionBox(String question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
        ),
      ),
      child: Text(
        question,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}