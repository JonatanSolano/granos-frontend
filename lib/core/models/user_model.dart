enum UserRole { admin, cliente }

class UserModel {
  final int? id;
  final String email;
  final String username;
  final UserRole role;
  final String name;
  final String phone;
  final String address;
  final int? ubicacionId;
  final bool totpEnabled;

  UserModel({
    this.id,
    required this.email,
    this.username = '',
    required this.role,
    this.name = '',
    this.phone = '',
    this.address = '',
    this.ubicacionId,
    this.totpEnabled = false,
  });

  UserModel copyWith({
    int? id,
    String? email,
    String? username,
    String? name,
    String? phone,
    String? address,
    int? ubicacionId,
    bool? totpEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      ubicacionId: ubicacionId ?? this.ubicacionId,
      totpEnabled: totpEnabled ?? this.totpEnabled,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'role': role.name,
      'name': name,
      'phone': phone,
      'address': address,
      'ubicacionId': ubicacionId,
      'totpEnabled': totpEnabled,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseInt(json['id']),
      email: (json['email'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.cliente,
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      ubicacionId: _parseInt(json['ubicacionId'] ?? json['ubicacion_id']),
      totpEnabled: json['totpEnabled'] == true || json['totp_enabled'] == 1,
    );
  }

  factory UserModel.fromSessionJson(Map<String, dynamic> json) {
    return UserModel.fromJson(json);
  }
}