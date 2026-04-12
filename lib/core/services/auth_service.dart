import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:granos_la_tradicion/core/config/app_config.dart';
import '../models/user_model.dart';

class AuthService {
  final String baseUrl = "${AppConfig.apiBaseUrl}/api";

  String? _token;
  UserModel? _currentUser;
  int? _mfaUserId;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  int? get mfaUserId => _mfaUserId;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["mfaRequired"] == true) {
      _mfaUserId = data["userId"];
      return true;
    }

    return false;
  }

  Future<UserModel?> verifyMFA(String code) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/verify-mfa"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": _mfaUserId,
        "code": code
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      _token = data["token"];
      _currentUser = UserModel.fromJson(data["user"]);
      return _currentUser;
    }

    return null;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password
      }),
    );

    return response.statusCode == 201;
  }

  Future<bool> recoverUsername(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/recover-username"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    return response.statusCode == 200;
  }

  Future<String?> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["token"];
    }

    return null;
  }

  Future<bool> validateResetToken(String token) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/validate-reset-token"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"token": token}),
    );

    return response.statusCode == 200;
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "token": token,
        "newPassword": newPassword
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> changePassword(String newPassword) async {
    final response = await http.put(
      Uri.parse("$baseUrl/auth/change-password"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_token"
      },
      body: jsonEncode({
        "newPassword": newPassword
      }),
    );

    return response.statusCode == 200;
  }

  Future<String?> verifySecurityAnswers({
    required String email,
    required String answer1,
    required String answer2,
    required String answer3,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/verify-security-answers"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "answer1": answer1,
        "answer2": answer2,
        "answer3": answer3
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["resetToken"];
    }

    return null;
  }

  void logout() {
    _token = null;
    _currentUser = null;
    _mfaUserId = null;
  }
}