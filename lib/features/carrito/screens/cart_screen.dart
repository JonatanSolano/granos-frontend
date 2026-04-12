import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:granos_la_tradicion/features/carrito/providers/cart_provider.dart';
import 'package:granos_la_tradicion/features/pedidos/providers/order_provider.dart';
import 'package:granos_la_tradicion/core/widgets/app_layout.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final orderProvider = context.read<OrderProvider>();

    return AppLayout(
      child: Column(
        children: [

          const SizedBox(height: 10),

          /// TÍTULO
          const Text(
            "Carrito",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: cartProvider.items.isEmpty
                ? _buildEmptyCart()
                : _buildCartContent(context, cartProvider, orderProvider),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                ),
                onPressed: () => context.go('/cliente'),
                child: const Text(
                  "Volver al Panel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.white70),
          SizedBox(height: 20),
          Text(
            "Tu carrito está vacío",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(
    BuildContext context,
    CartProvider cartProvider,
    OrderProvider orderProvider,
  ) {
    return Column(
      children: [

        /// LISTA DE PRODUCTOS
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartProvider.items.length,
            itemBuilder: (context, index) {

              final item = cartProvider.items[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [

                    /// IMAGEN
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: item.product.imagenUrl != null
                          ? Image.network(
                              item.product.imagenUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [

                              Expanded(
                                child: Text(
                                  item.product.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  cartProvider.removeProduct(
                                      item.product.id);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [

                              IconButton(
                                icon: const Icon(Icons.remove,
                                    color: Colors.white),
                                onPressed: () {
                                  cartProvider.decreaseQuantity(
                                      item.product.id);
                                },
                              ),

                              SizedBox(
                                width: 70,
                                child: TextFormField(
                                  key: ValueKey(item.product.id),
                                  initialValue:
                                      item.quantity.toString(),
                                  textAlign: TextAlign.center,
                                  keyboardType:
                                      TextInputType.number,
                                  style: const TextStyle(
                                      color: Colors.white),
                                  decoration:
                                      const InputDecoration(
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(
                                            vertical: 8),
                                    border:
                                        OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {

                                    final qty =
                                        int.tryParse(value);

                                    if (qty == null ||
                                        qty <= 0) return;

                                    if (qty >
                                        item.product.stock) {
                                      ScaffoldMessenger.of(
                                              context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Supera el stock disponible"),
                                        ),
                                      );
                                      return;
                                    }

                                    while (item.quantity <
                                        qty) {
                                      cartProvider
                                          .increaseQuantity(
                                              item.product
                                                  .id);
                                    }

                                    while (item.quantity >
                                        qty) {
                                      cartProvider
                                          .decreaseQuantity(
                                              item.product
                                                  .id);
                                    }
                                  },
                                ),
                              ),

                              IconButton(
                                icon: const Icon(Icons.add,
                                    color: Colors.white),
                                onPressed: () {
                                  final added =
                                      cartProvider
                                          .increaseQuantity(
                                              item.product
                                                  .id);

                                  if (!added) {
                                    ScaffoldMessenger.of(
                                            context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "Stock máximo alcanzado"),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "₡${item.product.precio.toStringAsFixed(0)} c/u",
                            style: const TextStyle(color: Colors.white70),
                          ),

                          Text(
                            "Subtotal: ₡${(item.product.precio * item.quantity).toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        /// TOTAL
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total:",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(
                "₡${cartProvider.total.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        /// CONFIRMAR COMPRA
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(
                    vertical: 16),
              ),
              onPressed: () async {

                final confirm =
                    await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text(
                        "Confirmar compra"),
                    content: const Text(
                        "¿Deseas confirmar el pedido?"),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(
                                context, false),
                        child:
                            const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(
                                context, true),
                        child:
                            const Text("Confirmar"),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                await orderProvider
                    .createOrder(cartProvider);

                context.go('/orders');
              },
              child:
                  const Text("Confirmar Compra"),
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}