class Order {
  final int id;
  final String userEmail;
  final List<OrderItem> items;
  final double total;
  final DateTime date;
  String status;
  String estadoEntrega;

  Order({
    required this.id,
    required this.userEmail,
    required this.items,
    required this.total,
    required this.date,
    required this.status,
    required this.estadoEntrega,
  });

  String get shortId {
    final idStr = id.toString();
    if (idStr.length <= 4) return idStr;
    return idStr.substring(idStr.length - 4);
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] is int
          ? json['id']
          : int.parse(json['id'].toString()),

      userEmail: json['userEmail'] ??
          json['user_email'] ??
          json['email'] ??
          "",

      items: (json['items'] != null)
          ? (json['items'] as List)
              .map((e) => OrderItem.fromJson(e))
              .toList()
          : [],

      total: json['total'] is num
          ? (json['total'] as num).toDouble()
          : double.parse(json['total'].toString()),

      date: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toString(),
      ),

      status: json['status'] ?? 'Pendiente',

      estadoEntrega: json['estado_entrega'] ??
          json['estadoEntrega'] ??
          'Pendiente',
    );
  }
}

class OrderItem {
  final int quantity;
  final OrderProduct product;

  OrderItem({
    required this.quantity,
    required this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      quantity: json['quantity'] ?? 0,
      product: OrderProduct.fromJson(
        json['product'] ?? {},
      ),
    );
  }
}

class OrderProduct {
  final int id;
  final String nombre;
  final double precio;
  final String? imagenUrl;

  OrderProduct({
    required this.id,
    required this.nombre,
    required this.precio,
    this.imagenUrl,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      id: json['id'] is int
          ? json['id']
          : int.parse(json['id'].toString()),

      nombre: json['nombre'] ??
          json['name'] ??
          "",

      precio: json['precio'] is num
          ? (json['precio'] as num).toDouble()
          : double.parse(json['precio'].toString()),

      imagenUrl: json['imagenUrl'] ??
          json['image_url'] ??
          json['image'],
    );
  }
}