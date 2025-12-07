import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de tienda. Muestra una lista de productos con un botón
/// para abrir un enlace de compra externo. Esta sección es un ejemplo;
/// puedes modificar la lista `_productos` para añadir tus propios
/// artículos con sus URLs.
class TiendaScreen extends StatelessWidget {
  const TiendaScreen({super.key});

  // Lista de productos en la tienda, cada uno con nombre y enlace. Los
  // enlaces son de ejemplo y deberían reemplazarse por tus URLs
  // oficiales (por ejemplo, hacia tu página de merchandising o tienda en
  // línea). Asegúrate de que los enlaces comiencen con `https://`.
  static const List<_Producto> _productos = [
    _Producto(nombre: 'Camiseta oficial', url: 'https://ejemplo.com/camiseta'),
    _Producto(nombre: 'Vinilo edición limitada', url: 'https://ejemplo.com/vinilo'),
    _Producto(nombre: 'Poster firmado', url: 'https://ejemplo.com/poster'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/menu_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.35),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '🛍️ Tienda',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.amberAccent,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black, offset: Offset(2, 2))],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _productos.length,
                    itemBuilder: (context, index) {
                      final producto = _productos[index];
                      return Card(
                        color: Colors.black54,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(Icons.shopping_bag, color: Colors.amberAccent.shade200),
                          title: Text(
                            producto.nombre,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              final uri = Uri.parse(producto.url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No se pudo abrir el enlace.')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Comprar'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modelo simple de producto con nombre y URL.
class _Producto {
  final String nombre;
  final String url;
  const _Producto({required this.nombre, required this.url});
}