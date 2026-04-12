import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:granos_la_tradicion/core/config/app_config.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final String baseUrl = "${AppConfig.apiBaseUrl}/api";

  bool _isAuthenticated = false;
  UserModel? _currentUser;
  String? _token;
  bool _isInitialized = false;

  bool requiresMFA = false;
  int? _mfaUserId;
  String _mfaType = "email";
  String? _devMfaCode;

  String? loginError;

  bool isLocked = false;
  int remainingAttempts = 3;
  DateTime? lockUntil;
  bool passwordExpired = false;

  bool get isAuthenticated => _isAuthenticated;
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isInitialized => _isInitialized;
  String get mfaType => _mfaType;
  String? get devMfaCode => _devMfaCode;

  AuthProvider() {
    _loadSession();
  }

  void clearLoginError() {
    loginError = null;
    notifyListeners();
  }

  void clearTemporaryLockIfExpired() {
    if (lockUntil != null && DateTime.now().isAfter(lockUntil!)) {
      isLocked = false;
      lockUntil = null;

      if (loginError != null &&
          (loginError!.toLowerCase().contains("demasiados intentos") ||
              loginError!.toLowerCase().contains("bloqueada"))) {
        loginError = null;
      }

      notifyListeners();
    }
  }

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

  List<Map<String, dynamic>> _normalizeSecurityAnswers(
    List<Map<String, dynamic>> raw,
  ) {
    return raw.map((item) {
      final dynamic rawQuestionId = item["questionId"] ?? item["id"];
      final int? questionId =
          rawQuestionId is int ? rawQuestionId : int.tryParse("$rawQuestionId");

      final String answer = (item["answer"] ?? "").toString().trim();

      return {
        "questionId": questionId,
        "answer": answer,
      };
    }).where((item) {
      final questionId = item["questionId"];
      final answer = (item["answer"] ?? "").toString().trim();
      return questionId != null && answer.isNotEmpty;
    }).toList();
  }

  String? _validateSecurityAnswers(
    List<Map<String, dynamic>> answers,
  ) {
    if (answers.length != 2) {
      return "Debe seleccionar y responder exactamente 2 preguntas de seguridad.";
    }

    final ids = answers
        .map((e) => e["questionId"])
        .where((id) => id != null)
        .toList();

    if (ids.length != 2 || ids.toSet().length != 2) {
      return "Las 2 preguntas de seguridad deben ser distintas.";
    }

    for (final item in answers) {
      final answer = (item["answer"] ?? "").toString().trim();
      if (answer.isEmpty) {
        return "Debe responder las 2 preguntas de seguridad.";
      }
    }

    return null;
  }

  int _extractRetryAfterSeconds(
    http.Response response,
    Map<String, dynamic> data,
  ) {
    final fromBody = data["retryAfterSeconds"];
    if (fromBody is int && fromBody > 0) return fromBody;

    final fromHeader = response.headers["retry-after"];
    if (fromHeader != null) {
      final parsed = int.tryParse(fromHeader);
      if (parsed != null && parsed > 0) return parsed;
    }

    return 15 * 60;
  }

  Future<http.Response> authorizedRequest({
    required String url,
    String method = "GET",
    Map<String, dynamic>? body,
  }) async {
    final headers = {
      "Content-Type": "application/json",
    };

    if (_token != null) {
      headers["Authorization"] = "Bearer $_token";
    }

    final uri = Uri.parse(url);

    if (method == "POST") {
      return await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 60));
    }

    if (method == "PUT") {
      return await http
          .put(
            uri,
            headers: headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 60));
    }

    if (method == "DELETE") {
      return await http
          .delete(
            uri,
            headers: headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 60));
    }

    return await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 60));
  }

  Future<List<Map<String, dynamic>>> getSecurityQuestions() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/auth/security-questions"),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        return data
            .map((e) => {
                  "id": e["id"],
                  "question": e["question"],
                })
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint("Error getSecurityQuestions: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecoverySecurityQuestions(
    String email,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/recovery-security-questions"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email}),
          )
          .timeout(const Duration(seconds: 60));

      final data = _safeDecode(response.body);

      if (response.statusCode == 200 && data["questions"] is List) {
        final List questions = data["questions"];
        return questions
            .map((e) => {
                  "id": e["id"],
                  "question": e["question"],
                })
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint("Error getRecoverySecurityQuestions: $e");
      return [];
    }
  }

  Future<bool> register({
    required String cedula,
    required String name,
    required String email,
    required String password,
    String phone = "",
    String address = "",
    int? ubicacionId,
    bool tseConsultado = false,
    bool tseEncontrado = false,
    List<Map<String, dynamic>>? securityQuestions,
  }) async {
    try {
      loginError = null;

      final normalizedCedula =
          cedula.replaceAll(RegExp(r'[^0-9]'), '').trim();

      if (normalizedCedula.isEmpty) {
        loginError = "La cédula es obligatoria.";
        notifyListeners();
        return false;
      }

      final normalizedSecurityQuestions =
          _normalizeSecurityAnswers(securityQuestions ?? []);

      final validationError =
          _validateSecurityAnswers(normalizedSecurityQuestions);

      if (validationError != null) {
        loginError = validationError;
        notifyListeners();
        return false;
      }

      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/register"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "cedula": normalizedCedula,
              "name": name,
              "email": email,
              "password": password,
              "phone": phone,
              "address": address,
              "ubicacionId": ubicacionId,
              "tseConsultado": tseConsultado,
              "tseEncontrado": tseEncontrado,
              "securityQuestions": normalizedSecurityQuestions,
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = _safeDecode(response.body);

      if (response.statusCode == 201) {
        loginError = null;
        notifyListeners();
        return true;
      }

      loginError = data['error'] ?? data['message'] ?? "Error en registro.";
      notifyListeners();
      return false;
    } catch (e) {
      loginError = "Error de conexión con el servidor: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      loginError = null;
      isLocked = false;
      passwordExpired = false;
      remainingAttempts = 3;
      lockUntil = null;
      requiresMFA = false;
      _mfaType = "email";
      _mfaUserId = null;
      _devMfaCode = null;

      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email,
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = _safeDecode(response.body);

      if (response.statusCode == 200 && data['mfaRequired'] == true) {
        requiresMFA = true;
        _mfaUserId = data['userId'];
        _mfaType = (data['mfaType'] ?? 'email').toString();
        _devMfaCode = data['devMfaCode']?.toString();

        loginError = null;
        notifyListeners();
        return true;
      }

      if (response.statusCode == 200 && data['token'] != null) {
        _token = data['token'];

        final userData = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : <String, dynamic>{};

        _currentUser = UserModel.fromJson(userData);

        _isAuthenticated = true;
        requiresMFA = false;
        _mfaUserId = null;
        _mfaType = "email";
        _devMfaCode = null;

        isLocked = false;
        passwordExpired = false;
        remainingAttempts = 3;
        lockUntil = null;
        loginError = null;

        await _saveSession();

        notifyListeners();
        return true;
      }

      if (response.statusCode == 429) {
        final retryAfterSeconds = _extractRetryAfterSeconds(response, data);

        isLocked = true;
        lockUntil = DateTime.now().add(
          Duration(seconds: retryAfterSeconds),
        );

        loginError = data['error'] ??
            data['message'] ??
            "Demasiados intentos de login. Intente nuevamente en 15 minutos.";

        notifyListeners();
        return false;
      }

      if (response.statusCode == 401) {
        remainingAttempts = data['remainingAttempts'] ?? 0;
        loginError =
            data['error'] ?? data['message'] ?? "Contraseña incorrecta.";
        notifyListeners();
        return false;
      }

      if (response.statusCode == 403) {
        if (data['passwordExpired'] == true) {
          passwordExpired = true;
          loginError = data['error'] ??
              data['message'] ??
              "Debe cambiar su contraseña.";
          notifyListeners();
          return false;
        }

        isLocked = true;

        if (data['lockUntil'] != null) {
          lockUntil = DateTime.tryParse(data['lockUntil'])?.toLocal();
        }

        loginError =
            data['error'] ?? data['message'] ?? "Cuenta bloqueada.";
        notifyListeners();
        return false;
      }

      loginError = data['error'] ?? data['message'] ?? "Error inesperado.";
      notifyListeners();
      return false;
    } catch (e) {
      loginError = "Error de conexión con el servidor: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyMFA(String code) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/verify-mfa"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "userId": _mfaUserId,
              "code": code,
              "method": _mfaType,
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = _safeDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];

        final userData = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : <String, dynamic>{};

        _currentUser = UserModel.fromJson(userData);

        _isAuthenticated = true;
        requiresMFA = false;
        _mfaUserId = null;
        _mfaType = "email";
        _devMfaCode = null;
        loginError = null;

        await _saveSession();

        notifyListeners();
        return true;
      }

      loginError = data['error'] ??
          data['message'] ??
          (_mfaType == "totp"
              ? "Código de Google Authenticator incorrecto."
              : "Código MFA incorrecto.");
      notifyListeners();
      return false;
    } catch (e) {
      loginError = "Error verificando el segundo factor: $e";
      notifyListeners();
      return false;
    }
  }

  Future<String> recoverUsername(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/recover-username"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email}),
          )
          .timeout(const Duration(seconds: 60));

      final data = _safeDecode(response.body);
      return data['message'] ?? "Solicitud procesada.";
    } catch (e) {
      return "Error conectando con el servidor.";
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/forgot-password"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email}),
          )
          .timeout(const Duration(seconds: 60));

      return _safeDecode(response.body);
    } catch (e) {
      return {"error": "Error conectando al servidor"};
    }
  }

  Future<Map<String, dynamic>> recoverPasswordWithSecurity({
    required String email,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final normalizedAnswers = _normalizeSecurityAnswers(answers);
      final validationError = _validateSecurityAnswers(normalizedAnswers);

      if (validationError != null) {
        return {"error": validationError};
      }

      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/recover-password-security"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email,
              "answers": normalizedAnswers,
            }),
          )
          .timeout(const Duration(seconds: 60));

      return _safeDecode(response.body);
    } catch (e) {
      return {"error": "Error conectando con el servidor"};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String token,
    String newPassword,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/reset-password"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "token": token,
              "newPassword": newPassword,
            }),
          )
          .timeout(const Duration(seconds: 60));

      return _safeDecode(response.body);
    } catch (e) {
      return {"error": "Error conectando con el servidor"};
    }
  }

  Future<bool> refreshProfile() async {
    try {
      final response = await authorizedRequest(
        url: "$baseUrl/users/profile",
        method: "GET",
      );

      final data = _safeDecode(response.body);

      if (response.statusCode == 200) {
        final profileData = data["user"] is Map<String, dynamic>
            ? data["user"] as Map<String, dynamic>
            : data["data"] is Map<String, dynamic>
                ? data["data"] as Map<String, dynamic>
                : data;

        _currentUser = UserModel.fromJson(profileData);
        await _saveSession();
        notifyListeners();
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
    required int ubicacionId,
  }) async {
    try {
      loginError = null;

      final response = await http
          .put(
            Uri.parse("$baseUrl/users/profile"),
            headers: {
              "Content-Type": "application/json",
              if (_token != null) "Authorization": "Bearer $_token",
            },
            body: jsonEncode({
              "name": name,
              "email": email,
              "phone": phone,
              "address": address,
              "ubicacionId": ubicacionId,
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = _safeDecode(response.body);

      if (response.statusCode == 200) {
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            name: name,
            email: email,
            phone: phone,
            address: address,
            ubicacionId: ubicacionId,
          );

          await _saveSession();
          notifyListeners();
        }

        return true;
      }

      loginError =
          data["message"] ?? data["error"] ?? "Error actualizando perfil";
      notifyListeners();
      return false;
    } catch (e) {
      loginError = "Error actualizando perfil: $e";
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> changePassword(String newPassword) async {
    try {
      final response = await http
          .put(
            Uri.parse("$baseUrl/auth/change-password"),
            headers: {
              "Content-Type": "application/json",
              if (_token != null) "Authorization": "Bearer $_token",
            },
            body: jsonEncode({
              "newPassword": newPassword,
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = _safeDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message":
              data["message"] ?? "Contraseña actualizada correctamente"
        };
      }

      return {
        "success": false,
        "error":
            data["error"] ?? data["message"] ?? "Error cambiando contraseña"
      };
    } catch (e) {
      return {
        "success": false,
        "error": "Error de conexión con el servidor: $e"
      };
    }
  }

  Future<Map<String, dynamic>> updateSecurityAnswers(
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      if (_currentUser?.id == null) {
        return {
          "success": false,
          "error": "Usuario no identificado"
        };
      }

      final normalizedAnswers = _normalizeSecurityAnswers(answers);
      final validationError = _validateSecurityAnswers(normalizedAnswers);

      if (validationError != null) {
        return {
          "success": false,
          "error": validationError,
        };
      }

      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/security-answers"),
            headers: {
              "Content-Type": "application/json",
              if (_token != null) "Authorization": "Bearer $_token",
            },
            body: jsonEncode({
              "answers": normalizedAnswers,
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = _safeDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"] ??
              "Preguntas de seguridad actualizadas correctamente"
        };
      }

      return {
        "success": false,
        "error":
            data["error"] ?? data["message"] ?? "Error actualizando preguntas"
      };
    } catch (e) {
      return {
        "success": false,
        "error": "Error de conexión con el servidor: $e"
      };
    }
  }

  Future<Map<String, dynamic>> getTotpStatus() async {
    try {
      final response = await authorizedRequest(
        url: "$baseUrl/auth/totp/status",
        method: "GET",
      );

      final data = _safeDecode(response.body);

      if (response.statusCode == 200) {
        final bool enabled = data["totpEnabled"] == true;

        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            totpEnabled: enabled,
          );
          await _saveSession();
          notifyListeners();
        }

        return {
          "success": true,
          "totpEnabled": enabled,
          "pendingSetup": data["pendingSetup"] == true,
          "totpEnabledAt": data["totpEnabledAt"],
        };
      }

      return {
        "success": false,
        "error": data["error"] ?? "Error consultando el estado TOTP",
      };
    } catch (e) {
      return {
        "success": false,
        "error": "Error de conexión con el servidor: $e",
      };
    }
  }

  Future<Map<String, dynamic>> setupTotp() async {
    try {
      final response = await authorizedRequest(
        url: "$baseUrl/auth/totp/setup",
        method: "POST",
      );

      final data = _safeDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"] ?? "Escanee el código QR",
          "qrDataUrl": data["qrDataUrl"],
          "manualKey": data["manualKey"],
          "otpauthUrl": data["otpauthUrl"],
          "totpEnabled": data["totpEnabled"] == true,
          "pendingSetup": data["pendingSetup"] == true,
        };
      }

      return {
        "success": false,
        "error": data["error"] ?? "Error iniciando configuración TOTP",
      };
    } catch (e) {
      return {
        "success": false,
        "error": "Error de conexión con el servidor: $e",
      };
    }
  }

  Future<Map<String, dynamic>> confirmTotp(String code) async {
    try {
      final response = await authorizedRequest(
        url: "$baseUrl/auth/totp/confirm",
        method: "POST",
        body: {
          "code": code,
        },
      );

      final data = _safeDecode(response.body);

      if (response.statusCode == 200) {
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            totpEnabled: true,
          );
          await _saveSession();
          notifyListeners();
        }

        return {
          "success": true,
          "message": data["message"] ?? "Google Authenticator activado",
          "totpEnabled": true,
        };
      }

      return {
        "success": false,
        "error": data["error"] ?? "Error confirmando Google Authenticator",
      };
    } catch (e) {
      return {
        "success": false,
        "error": "Error de conexión con el servidor: $e",
      };
    }
  }

  Future<Map<String, dynamic>> disableTotp(String code) async {
    try {
      final response = await authorizedRequest(
        url: "$baseUrl/auth/totp/disable",
        method: "POST",
        body: {
          "code": code,
        },
      );

      final data = _safeDecode(response.body);

      if (response.statusCode == 200) {
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            totpEnabled: false,
          );
          await _saveSession();
          notifyListeners();
        }

        return {
          "success": true,
          "message":
              data["message"] ?? "Google Authenticator desactivado",
          "totpEnabled": false,
        };
      }

      return {
        "success": false,
        "error": data["error"] ?? "Error desactivando Google Authenticator",
      };
    } catch (e) {
      return {
        "success": false,
        "error": "Error de conexión con el servidor: $e",
      };
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUser = null;
    _token = null;
    requiresMFA = false;
    _mfaUserId = null;
    _mfaType = "email";
    _devMfaCode = null;
    loginError = null;
    isLocked = false;
    remainingAttempts = 3;
    lockUntil = null;
    passwordExpired = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isAuthenticated', _isAuthenticated);

    if (_currentUser != null) {
      await prefs.setString(
        'user',
        jsonEncode(_currentUser!.toJson()),
      );
    }

    if (_token != null) {
      await prefs.setString('token', _token!);
    }
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedAuth = prefs.getBool('isAuthenticated');
      final savedUser = prefs.getString('user');
      final savedToken = prefs.getString('token');

      if (savedAuth == true && savedUser != null && savedToken != null) {
        _isAuthenticated = true;
        _currentUser = UserModel.fromJson(jsonDecode(savedUser));
        _token = savedToken;
      }
    } catch (e) {
      debugPrint("ERROR cargando sesión: $e");
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }
}