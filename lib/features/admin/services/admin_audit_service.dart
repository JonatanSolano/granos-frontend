import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/audit_log_model.dart';

class AdminAuditService {

  static const String baseUrl = "http://localhost:4000/api";

  static Future<List<AuditLog>> getAuditLogs(String token) async {

    final response = await http.get(
      Uri.parse("$baseUrl/audit/logs"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {

      final List data = jsonDecode(response.body);

      return data.map((e) => AuditLog.fromJson(e)).toList();

    } else {

      throw Exception("Error obteniendo auditoría");

    }

  }
}