import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/widgets/app_layout.dart';
import 'auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  Timer? _timer;

  static const TextStyle _authLinkStyle = TextStyle(
    color: Colors.white70,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      context.read<AuthProvider>().clearTemporaryLockIfExpired();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();

    if (_shouldDisableLogin(auth)) return;

    setState(() => _isLoading = true);

    auth.clearLoginError();

    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (auth.passwordExpired) {
      context.go('/change-password');
      return;
    }

    if (!success) {
      if (GoRouterState.of(context).uri.path != '/login') {
        context.go('/login');
      }
      return;
    }

    if (auth.requiresMFA) {
      context.go('/mfa');
      return;
    }

    final role = auth.currentUser?.role;

    if (role == UserRole.admin) {
      context.go('/admin');
    } else {
      context.go('/cliente');
    }
  }

  bool _isTemporaryLockActive(AuthProvider auth) {
    return auth.lockUntil != null &&
        DateTime.now().isBefore(auth.lockUntil!);
  }

  bool _shouldDisableLogin(AuthProvider auth) {
    if (auth.isLocked && auth.lockUntil == null) {
      return true;
    }

    if (_isTemporaryLockActive(auth)) {
      return true;
    }

    return false;
  }

  String _formatRemainingTime(DateTime target) {
    final diff = target.difference(DateTime.now());

    if (diff.inSeconds <= 0) {
      return "00:00";
    }

    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    return "$mm:$ss";
  }

  String _lockMessage(AuthProvider auth) {
    if (auth.lockUntil == null) {
      return auth.loginError ?? "Cuenta bloqueada.";
    }

    final remaining = _formatRemainingTime(auth.lockUntil!);

    if (auth.loginError != null &&
        auth.loginError!.toLowerCase().contains("demasiados intentos")) {
      return "${auth.loginError!}\nTiempo restante: $remaining";
    }

    return "Cuenta bloqueada por seguridad.\nTiempo restante: $remaining";
  }

  String? _remainingAttemptsMessage(AuthProvider auth) {
    if (_shouldDisableLogin(auth)) return null;
    if (auth.loginError == null) return null;

    if (auth.remainingAttempts > 0 && auth.remainingAttempts < 3) {
      return "Intentos restantes: ${auth.remainingAttempts}";
    }

    return null;
  }

  Widget _buildAuthLink({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, 0),
        ),
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: _authLinkStyle,
        ),
      ),
    );
  }

  String _mfaHint(AuthProvider auth) {
    if (!auth.requiresMFA) return "";
    return auth.mfaType == "totp"
        ? "Se pedirá un código de Google Authenticator."
        : "Se pedirá un código MFA para continuar.";
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    final horizontalPadding =
        screenWidth > 600 ? screenWidth * 0.30 : 24.0;

    final remainingAttemptsText = _remainingAttemptsMessage(auth);

    return AppLayout(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Iniciar Sesión",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                AuthTextField(
                  controller: _emailController,
                  label: "Correo electrónico",
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _passwordController,
                  label: "Contraseña",
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildAuthLink(
                      text: "¿Olvidaste tu contraseña?",
                      onPressed: () {
                        context.go('/forgot-password');
                      },
                    ),
                    _buildAuthLink(
                      text: "¿Olvidaste tu usuario?",
                      onPressed: () {
                        context.go('/recover-username');
                      },
                    ),
                    _buildAuthLink(
                      text: "¿No tienes cuenta? Regístrate",
                      onPressed: () {
                        context.go('/register');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (auth.loginError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.error,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _shouldDisableLogin(auth)
                                    ? _lockMessage(auth)
                                    : auth.loginError!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                              if (remainingAttemptsText != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  remainingAttemptsText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (auth.requiresMFA)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      _mfaHint(auth),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || _shouldDisableLogin(auth)
                        ? null
                        : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.25),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Ingresar"),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.go('/');
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Volver al inicio",
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}