import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla que lista enlaces a las principales redes sociales y
/// plataformas de streaming del artista. Cada elemento lanza el
/// navegador o la app correspondiente al pulsar sobre él.
class RedesScreen extends StatelessWidget {
  const RedesScreen({super.key});

  // Define aquí las redes sociales y sus URLs oficiales. Si tienes
  // cuentas específicas, actualiza los valores de `url` para cada
  // entrada. Asegúrate de incluir los protocolos `https://`.
  static const List<_RedSocial> _redes = [
    _RedSocial(nombre: 'Instagram', icono: Icons.camera_alt, url: 'https://www.instagram.com/baltazar.avila'),
    _RedSocial(nombre: 'YouTube', icono: Icons.play_circle_fill, url: 'https://www.youtube.com/@baltazaravila'),
    _RedSocial(nombre: 'Spotify', icono: Icons.music_note, url: 'https://open.spotify.com/artist/your_artist_id'),
    _RedSocial(nombre: 'TikTok', icono: Icons.movie, url: 'https://www.tiktok.com/@baltazaravila'),
    _RedSocial(nombre: 'Bandcamp', icono: Icons.album, url: 'https://baltazaravila.bandcamp.com'),
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
                        '🌐 Redes y plataformas',
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
                  child: ListView.separated(
                    itemCount: _redes.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white24, indent: 20, endIndent: 20),
                    itemBuilder: (context, index) {
                      final red = _redes[index];
                      return ListTile(
                        leading: Icon(red.icono, color: Colors.amberAccent),
                        title: Text(
                          red.nombre,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        trailing: const Icon(Icons.launch, color: Colors.white54),
                        onTap: () async {
                          final uri = Uri.parse(red.url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No se pudo abrir el enlace.')),
                            );
                          }
                        },
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

/// Modelo simple para cada red social. Contiene un nombre, un icono y
/// una URL asociada.
class _RedSocial {
  final String nombre;
  final IconData icono;
  final String url;
  const _RedSocial({required this.nombre, required this.icono, required this.url});
}