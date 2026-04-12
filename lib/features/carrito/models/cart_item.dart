import '../../catalogo/models/product_model.dart';

class CartItem {

  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  // ======================================================
  // 🔄 Convertir a JSON
  // ======================================================

  Map<String, dynamic> toJson() {

    return {

      'product': product.toJson(),

      'quantity': quantity,

    };

  }

  // ======================================================
  // 🔄 Crear desde JSON (ROBUSTO)
  // ======================================================

  factory CartItem.fromJson(Map<String, dynamic> json) {

    int parseQuantity(value) {

      if (value == null) return 1;

      if (value is int) return value;

      return int.tryParse(value.toString()) ?? 1;

    }

    final qty = parseQuantity(json['quantity']);

    return CartItem(

      product: Product.fromJson(json['product']),

      quantity: qty <= 0 ? 1 : qty,

    );

  }

  // ======================================================
  // COPY WITH (ÚTIL PARA PROVIDERS)
  // ======================================================

  CartItem copyWith({

    Product? product,
    int? quantity,

  }) {

    return CartItem(

      product: product ?? this.product,

      quantity: quantity ?? this.quantity,

    );

  }

  // ======================================================
  // DEBUG
  // ======================================================

  @override
  String toString() {

    return "CartItem(product: ${product.nombre}, quantity: $quantity)";

  }

}