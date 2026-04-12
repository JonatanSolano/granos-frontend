import 'package:granos_la_tradicion/core/config/app_config.dart';

class Product {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final bool activo;
  final String? imagenUrl;

  Product({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.activo,
    this.imagenUrl,
  });

  static String? _normalizeImageUrl(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final uploadsBase = "${AppConfig.apiBaseUrl}/uploads/";

    if (raw.startsWith("http://") || raw.startsWith("https://")) {
      if (raw.startsWith("${uploadsBase}http://") ||
          raw.startsWith("${uploadsBase}https://")) {
        final fixed = raw.replaceFirst(uploadsBase, "");
        return fixed;
      }

      return raw;
    }

    if (raw.startsWith("/uploads/")) {
      return "${AppConfig.apiBaseUrl}$raw";
    }

    return "$uploadsBase$raw";
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    double parsePrice(value) {
      if (value == null) return 0.0;

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString()) ?? 0.0;
    }

    int parseInt(value) {
      if (value == null) return 0;

      if (value is int) return value;

      return int.tryParse(value.toString()) ?? 0;
    }

    bool parseBool(value) {
      if (value == true) return true;
      if (value == 1) return true;
      if (value == "1") return true;
      if (value == "true") return true;
      return false;
    }

    return Product(
      id: parseInt(json["id"]),
      nombre: json["name"] ?? "",
      descripcion: json["description"] ?? "",
      precio: parsePrice(json["price"]),
      stock: parseInt(json["stock"]),
      activo: parseBool(json["active"]),
      imagenUrl: _normalizeImageUrl(json["image_url"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": nombre,
      "description": descripcion,
      "price": precio,
      "stock": stock,
      "active": activo ? 1 : 0,
      "image_url": imagenUrl,
    };
  }

  Product copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    double? precio,
    int? stock,
    bool? activo,
    String? imagenUrl,
  }) {
    return Product(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      activo: activo ?? this.activo,
      imagenUrl: imagenUrl ?? this.imagenUrl,
    );
  }

  @override
  String toString() {
    return "Product(id: $id, nombre: $nombre, precio: $precio, stock: $stock, activo: $activo, imagenUrl: $imagenUrl)";
  }
}