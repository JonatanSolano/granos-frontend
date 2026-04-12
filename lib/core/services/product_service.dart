import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:granos_la_tradicion/core/config/app_config.dart';
import '../../features/catalogo/models/product_model.dart';

class ProductService {
  final String baseUrl = "${AppConfig.apiBaseUrl}/api";

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse("$baseUrl/products"));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data
          .map((e) => Product(
                id: e['id'],
                nombre: e['name'],
                descripcion: e['description'],
                precio: double.parse(e['price'].toString()),
                imagenUrl: e['image_url'] ?? "",
                stock: e['stock'],
                activo: e['active'] == 1 || e['active'] == true,
              ))
          .toList();
    } else {
      throw Exception("Error cargando productos");
    }
  }
}