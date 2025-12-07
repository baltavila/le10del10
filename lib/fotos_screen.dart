import 'package:flutter/material.dart';

/// Pantalla que muestra una galería de fotos cargadas desde URLs de
/// Firebase Storage. Las imágenes se muestran en una cuadrícula de dos
/// columnas; al pulsar una miniatura se abre en pantalla completa con
/// zoom y desplazamiento táctil. El fondo y estilo son coherentes con
/// el resto de la aplicación (imagen de menú con capa oscura).
class FotosScreen extends StatelessWidget {
  const FotosScreen({super.key});

  // Lista de URLs de imágenes en Firebase Storage. Estas fotos deben
  // haber sido configuradas como públicas en el bucket indicado. Puedes
  // añadir o quitar enlaces modificando esta lista.
  static const List<String> _imageUrls = [
    'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/fotos%2FWhatsApp%20Image%202025-10-27%20at%2016.22.47.jpeg?alt=media&token=690cf65c-9d66-4d3d-aca6-3d05da13f9ae',
    'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/fotos%2FWhatsApp%20Image%202025-10-27%20at%2016.22.48%20(1).jpeg?alt=media&token=70834da3-6e54-4b30-8a2e-b6bb30531d54',
    'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/fotos%2FWhatsApp%20Image%202025-10-27%20at%2016.22.48%20(3).jpeg?alt=media&token=f3548064-860e-427d-a6b0-3acd5a13e795',
    'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/fotos%2FWhatsApp%20Image%202025-10-27%20at%2016.22.48%20(2).jpeg?alt=media&token=686ccbb5-7b3d-4ce0-be2f-8f768ac562a5',
    'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/fotos%2FWhatsApp%20Image%202025-10-27%20at%2016.22.48.jpeg?alt=media&token=223eb905-e8e7-4e74-bc3b-0ea05226ca35',
    'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/fotos%2FWhatsApp%20Image%202025-10-27%20at%2016.25.43.jpeg?alt=media&token=abdee4c0-1a06-468e-86ed-d11ea14789c7',
    'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/fotos%2FWhatsApp%20Image%202025-10-27%20at%2016.27.15.jpeg?alt=media&token=c83868a7-cf06-4c58-965b-8016f4284ed8',
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
                        '📸 Galería de fotos',
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
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _imageUrls.length,
                    itemBuilder: (context, index) {
                      final url = _imageUrls[index];
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => _FullScreenImage(url: url, tag: 'foto$index'),
                            transitionsBuilder: (_, animation, __, child) => FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                        ),
                        child: Hero(
                          tag: 'foto$index',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.black26,
                                alignment: Alignment.center,
                                child: const Icon(Icons.image_not_supported, color: Colors.white54),
                              ),
                            ),
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

/// Widget auxiliar para mostrar una imagen en pantalla completa con
/// funcionalidad de zoom y desplazamiento. Se utiliza un [Hero] para
/// animar la transición desde la miniatura.
class _FullScreenImage extends StatelessWidget {
  final String url;
  final String tag;
  const _FullScreenImage({required this.url, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: tag,
            child: InteractiveViewer(
              child: Image.network(url),
            ),
          ),
        ),
      ),
    );
  }
}