import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../carrito/providers/cart_provider.dart';
import '../../carrito/models/cart_item.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {

    final auth = context.read<AuthProvider>();
    final cart = context.watch<CartProvider>();

    // 🔍 Buscar producto en carrito
    CartItem? cartItem;

    try {
      cartItem = cart.items.firstWhere(
        (item) => item.product.id == product.id,
      );
    } catch (_) {
      cartItem = null;
    }

    final currentQuantity = cartItem?.quantity ?? 0;
    final remainingStock = product.stock - currentQuantity;
    final isOutOfStock = remainingStock <= 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔥 IMAGEN (CORREGIDO PARA NULL)
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: product.imagenUrl != null &&
                      product.imagenUrl!.isNotEmpty
                  ? Image.network(
                      product.imagenUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) =>
                          const Center(
                            child: Icon(
                              Icons.image,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.image,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// NOMBRE
                Text(
                  product.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                /// PRECIO
                Text(
                  "₡${product.precio.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                /// STOCK
                Text(
                  isOutOfStock
                      ? "Agotado"
                      : "Stock disponible: $remainingStock",
                  style: TextStyle(
                    color: isOutOfStock
                        ? Colors.red
                        : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                /// BOTÓN AGREGAR
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isOutOfStock
                        ? null
                        : () {

                            if (!auth.isAuthenticated) {
                              _showLoginDialog(context);
                              return;
                            }

                            final success =
                                context.read<CartProvider>()
                                    .addProduct(product);

                            if (!success) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content:
                                      Text("Stock insuficiente"),
                                ),
                              );
                              return;
                            }

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                    "${product.nombre} agregado"),
                                duration:
                                    const Duration(seconds: 1),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF2E7D32),
                    ),
                    child: const Text("Agregar"),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title:
              const Text("Iniciar sesión requerido"),
          content: const Text(
            "Debes iniciar sesión para agregar productos.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/register');
              },
              child: const Text("Registrarme"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/login');
              },
              child: const Text("Iniciar sesión"),
            ),
          ],
        );
      },
    );
  }
}