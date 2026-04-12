import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/app_layout.dart';
import '../../carrito/providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../../../core/models/user_model.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<ProductsProvider>().loadProducts();
    });
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Iniciar sesión requerido"),
        content: const Text(
          "Debes iniciar sesión o registrarte para agregar productos al carrito.",
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
      ),
    );
  }

  void _showProductDetail(BuildContext context, product) {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: product.imagenUrl != null
                    ? Image.network(
                        product.imagenUrl!,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 60),
                        ),
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 60),
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                product.nombre,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "₡${product.precio.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.descripcion.isNotEmpty
                    ? product.descripcion
                    : "Sin descripción disponible",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Stock disponible: ${product.stock}",
                style: TextStyle(
                  color: product.stock > 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: product.stock > 0
                      ? () {
                          if (!auth.isAuthenticated) {
                            Navigator.pop(context);
                            _showLoginRequiredDialog(context);
                            return;
                          }

                          final added = cart.addProduct(product);
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? "Producto agregado al carrito"
                                    : "Stock máximo alcanzado",
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Agregar al Carrito"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();
    final products = productsProvider.products;
    final auth = context.watch<AuthProvider>();

    return AppLayout(
      child: productsProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : products.isEmpty
              ? const Center(
                  child: Text(
                    "No hay productos disponibles",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16, top: 10),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Consumer<CartProvider>(
                          builder: (context, cart, _) {
                            return Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.shopping_cart,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    if (!auth.isAuthenticated) {
                                      _showLoginRequiredDialog(context);
                                      return;
                                    }
                                    context.go('/cart');
                                  },
                                ),
                                if (cart.itemCount > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        cart.itemCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          itemCount: products.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemBuilder: (context, index) {
                            final product = products[index];

                            return GestureDetector(
                              onTap: () => _showProductDetail(context, product),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                        child: product.imagenUrl != null
                                            ? Image.network(
                                                product.imagenUrl!,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.image,
                                                    size: 40,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 40,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            product.nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "₡${product.precio.toStringAsFixed(0)}",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Volver al Panel",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            if (!auth.isAuthenticated) {
                              context.go('/');
                              return;
                            }

                            if (auth.currentUser?.role == UserRole.admin) {
                              context.go('/admin');
                            } else {
                              context.go('/cliente');
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}