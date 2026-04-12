class AuditLog {

  final int id;
  final String email;
  final String action;
  final String entity;
  final String details;
  final String? ipAddress;
  final String createdAt;

  AuditLog({
    required this.id,
    required this.email,
    required this.action,
    required this.entity,
    required this.details,
    this.ipAddress,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {

    return AuditLog(
      id: json["id"],
      email: json["email"] ?? "",
      action: json["action"] ?? "",
      entity: json["entity"] ?? "",
      details: json["details"] ?? "",
      ipAddress: json["ip_address"],
      createdAt: json["created_at"] ?? "",
    );

  }
}