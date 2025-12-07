import 'package:flutter/material.dart';

/// Pantalla de créditos. Muestra un texto estático con información
/// acerca de la producción, músicos y agradecimientos del proyecto. El
/// contenido se muestra dentro de un `SingleChildScrollView` para
/// permitir desplazamiento en caso de textos largos.
class CreditosScreen extends StatelessWidget {
  const CreditosScreen({super.key});

  // Contenido de los créditos. Puedes personalizar este texto para
  // incluir los nombres reales de los músicos, productores, estudios,
  // diseñadores, etc. Asegúrate de mantener los saltos de línea para
  // mejorar la legibilidad.
  static const String _creditos = '''
Producido por Baltazar Avila

Músicos:
- Baltazar Avila – Voz, guitarras y arreglos
- Band – Instrumentos varios

Grabado en Estudios Le10, Milán, Italia
Ingeniero de sonido: Juan Pérez
Mezclado y masterizado por: María López

Arte y diseño:
Portada original y gráficos por Baltazar Avila
Adaptación digital y animaciones por el equipo de diseño

Agradecimientos especiales:
Gracias a la familia, amigos y fans por su apoyo incondicional.

''';

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
                        '📃 Créditos',
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        _creditos,
                        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                      ),
                    ),
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