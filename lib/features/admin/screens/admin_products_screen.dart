import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../catalogo/providers/products_provider.dart';
import '../../catalogo/models/product_model.dart';
import 'package:granos_la_tradicion/features/admin/widgets/admin_base_layout.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState
    extends State<AdminProductsScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<ProductsProvider>().loadAllProducts());
  }

  @override
  Widget build(BuildContext context) {

    final productsProvider =
        context.watch<ProductsProvider>();
    final products =
        productsProvider.allProducts;

    return Scaffold(

      /// FAB SE MANTIENE
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () =>
            _showProductDialog(context),
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),

      body: AdminBaseLayout(
        title: "Gestión de Productos",
        showBackButton: true,
        child: products.isEmpty
            ? const Text(
                "No hay productos registrados",
                style: TextStyle(color: Colors.white),
              )
            : Column(
                children: products.map((product) {
                  return _glassProductCard(
                    context,
                    product,
                    productsProvider,
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _glassProductCard(
    BuildContext context,
    Product product,
    ProductsProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            /// IMAGEN
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(12),
              child: product.imagenUrl !=
                          null &&
                      product.imagenUrl!
                          .isNotEmpty
                  ? Image.network(
                      product.imagenUrl!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              const Icon(
                        Icons.image,
                        color: Colors.white,
                        size: 60,
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      size: 60,
                      color: Colors.white,
                    ),
            ),

            const SizedBox(width: 14),

            /// INFO
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    product.nombre,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Precio: ₡${product.precio.toStringAsFixed(0)}",
                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                    ),
                  ),

                  Text(
                    "Stock: ${product.stock}",
                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                    ),
                  ),

                  Text(
                    product.activo
                        ? "Activo"
                        : "Inactivo",
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            /// BOTONES
            Column(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white,
                  ),
                  onPressed: () =>
                      _showProductDialog(
                          context,
                          product: product),
                ),
                IconButton(
                  icon: Icon(
                    product.activo
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    await provider
                        .toggleActive(
                            product.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// DIALOGO
  void _showProductDialog(BuildContext context,
      {Product? product}) {

    final provider =
        context.read<ProductsProvider>();

    final nombreController =
        TextEditingController(
            text: product?.nombre ?? "");

    final descripcionController =
        TextEditingController(
            text:
                product?.descripcion ?? "");

    final precioController =
        TextEditingController(
            text: product?.precio
                    .toString() ??
                "");

    final stockController =
        TextEditingController(
            text:
                product?.stock
                        .toString() ??
                    "");

    final imagenController =
        TextEditingController(
            text:
                product?.imagenUrl ?? "");

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor:
              Colors.grey[900],
          title: Text(
            product == null
                ? "Agregar Producto"
                : "Editar Producto",
            style: const TextStyle(
                color: Colors.white),
          ),
          content:
              SingleChildScrollView(
            child: Column(
              children: [
                _input(nombreController,
                    "Nombre"),
                _input(
                    descripcionController,
                    "Descripción"),
                _input(
                    precioController,
                    "Precio",
                    isNumber: true),
                _input(
                    stockController,
                    "Stock",
                    isNumber: true),
                _input(
                    imagenController,
                    "URL Imagen"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(
                    color: Colors.white),
              ),
            ),
            ElevatedButton(
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    Colors.white,
                foregroundColor:
                    Colors.black,
              ),
              onPressed: () async {

                final precio =
                    double.tryParse(
                            precioController
                                .text) ??
                        0;

                final stock =
                    int.tryParse(
                            stockController
                                .text) ??
                        0;

                final newProduct =
                    Product(
                  id: product?.id ?? 0,
                  nombre:
                      nombreController
                          .text,
                  descripcion:
                      descripcionController
                          .text,
                  precio: precio,
                  stock: stock,
                  activo:
                      product?.activo ??
                          true,
                  imagenUrl:
                      imagenController
                          .text,
                );

                if (product ==
                    null) {
                  await provider
                      .addProduct(
                          newProduct);
                } else {
                  await provider
                      .updateProduct(
                          newProduct);
                }

                Navigator.pop(context);
              },
              child:
                  const Text(
                      "Guardar"),
            ),
          ],
        );
      },
    );
  }

  Widget _input(
      TextEditingController controller,
      String label,
      {bool isNumber = false}) {
    return Padding(
      padding:
          const EdgeInsets.only(
              bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber
            ? TextInputType.number
            : TextInputType.text,
        style: const TextStyle(
            color: Colors.white),
        decoration:
            InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(
                  color:
                      Colors.white70),
          enabledBorder:
              const OutlineInputBorder(
            borderSide: BorderSide(
                color:
                    Colors.white),
          ),
          focusedBorder:
              const OutlineInputBorder(
            borderSide: BorderSide(
                color:
                    Colors.white),
          ),
        ),
      ),
    );
  }
}