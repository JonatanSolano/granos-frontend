import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:granos_la_tradicion/core/providers/auth_provider.dart';
import 'package:granos_la_tradicion/core/router/app_router.dart';

import 'package:granos_la_tradicion/features/catalogo/providers/products_provider.dart';
import 'package:granos_la_tradicion/features/carrito/providers/cart_provider.dart';
import 'package:granos_la_tradicion/features/pedidos/providers/order_provider.dart';
import 'package:granos_la_tradicion/features/pedidos/providers/payment_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<ProductsProvider>(
          create: (_) => ProductsProvider(),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider<OrderProvider>(
          create: (_) => OrderProvider(),
        ),
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) => PaymentProvider(),
        ),
      ],
      child: const _AppBootstrap(),
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _router ??= appRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isInitialized || _router == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router!,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
      ),
    );
  }
}