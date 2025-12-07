import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Pantalla de videos oficiales. En plataformas móviles se reproducen
/// mediante `youtube_player_flutter`; en web se muestra un botón que
/// abre el enlace en una nueva pestaña. El fondo y estilo se mantienen
/// coherentes con el resto de la aplicación.
class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  late List<YoutubePlayerController> _controllers;

  // Lista de URLs de videos de YouTube. Modifica esta lista para añadir
  // más videos oficiales.
  static const List<String> _videoUrls = [
    'https://www.youtube.com/watch?v=32_BQPBBRXU',
    'https://www.youtube.com/watch?v=W-NNeNvV6Ws',
  ];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controllers = _videoUrls.map((url) {
        final videoId = YoutubePlayer.convertUrlToId(url)!;
        return YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            disableDragSeek: false,
            mute: false,
          ),
        );
      }).toList();
    } else {
      _controllers = [];
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

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
                        '🎥 Videos oficiales',
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _videoUrls.length,
                    itemBuilder: (context, index) {
                      final url = _videoUrls[index];
                      if (kIsWeb) {
                        // En web, mostrar un recuadro con un botón para abrir el enlace.
                        return _WebVideoCard(url: url);
                      } else {
                        final controller = _controllers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: YoutubePlayer(
                              controller: controller,
                              showVideoProgressIndicator: true,
                              progressIndicatorColor: Colors.amberAccent,
                            ),
                          ),
                        );
                      }
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

/// Tarjeta de video para la versión web: al pulsar se abre la URL
/// correspondiente en una nueva pestaña del navegador.
class _WebVideoCard extends StatelessWidget {
  final String url;
  const _WebVideoCard({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el enlace.')),
          );
        }
      },
      child: Container(
        height: 200,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_fill, color: Colors.amberAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                'Abrir video',
                style: TextStyle(color: Colors.amberAccent.shade100, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}