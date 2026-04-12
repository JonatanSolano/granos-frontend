import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/app_layout.dart';
import '../widgets/auth_text_field.dart';

class RecoverUsernameScreen extends StatefulWidget {
  const RecoverUsernameScreen({super.key});

  @override
  State<RecoverUsernameScreen> createState() => _RecoverUsernameScreenState();
}

class _RecoverUsernameScreenState extends State<RecoverUsernameScreen> {
  final _emailController = TextEditingController();

  bool loading = false;
  String? message;

  bool isValidEmail(String email) {
    return RegExp(
      r'^[\w\-\.]+@([\w\-]+\.)+[\w]{2,4}$',
    ).hasMatch(email);
  }

  Future<void> recover() async {
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

    final auth = context.read<AuthProvider>();
    final result =
        await auth.recoverUsername(_emailController.text.trim());

    setState(() {
      loading = false;
      message = result;
    });
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
                  "Recuperar usuario",
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
                        "Ingrese su correo electrónico y le enviaremos su usuario.",
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
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : recover,
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
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Recuperar usuario"),
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: message!.toLowerCase().contains("error")
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