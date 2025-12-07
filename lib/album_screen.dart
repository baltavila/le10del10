import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:le10del10/songs.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  late final ConcatenatingAudioSource _playlist;
  late AnimationController _controller;

  bool _isPlaying = false;
  bool _isLoading = true;
  int _currentIndex = 0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..stop();

    _initPlaylist();
    _listenToStreams();
  }

  Future<void> _initPlaylist() async {
    try {
      _playlist = ConcatenatingAudioSource(
        useLazyPreparation: true, // 🔥 ExoPlayer precarga la siguiente automáticamente
        children: songs
            .map(
              (song) => AudioSource.uri(
                Uri.parse(song.url),
                tag: song.title,
              ),
            )
            .toList(),
      );

      await _player.setAudioSource(_playlist, initialIndex: 0, preload: true);
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error inicializando playlist: $e');
      setState(() => _isLoading = false);
    }
  }

  void _listenToStreams() {
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        _isLoading = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
      });
      if (state.processingState == ProcessingState.completed) {
        _controller.stop();
      } else if (_isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && mounted) {
        setState(() => _currentIndex = index);
      }
    });

    _player.durationStream.listen((d) {
      if (d != null && mounted) setState(() => _duration = d);
    });

    _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  Future<void> _playSong() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint('❌ Error al reproducir: $e');
    }
  }

  Future<void> _pauseSong() async => _player.pause();

  Future<void> _nextSong() async => _player.seekToNext();
  Future<void> _prevSong() async => _player.seekToPrevious();

  Future<void> _downloadSong() async {
    final url = songs[_currentIndex].download;
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('❌ Error abriendo descarga: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final song = songs[_currentIndex];
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/menu_bg.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.35)),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  RotationTransition(
                    turns: _controller,
                    child: Image.asset(
                      'assets/vinilo.png',
                      height: MediaQuery.of(context).size.width * 0.45,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        )
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.amberAccent),
                          SizedBox(height: 10),
                          Text(
                            "Cargando canción...",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 10),
                      child: Column(
                        children: [
                          Slider(
                            activeColor: Colors.amberAccent,
                            inactiveColor: Colors.white24,
                            value: _position.inSeconds
                                .toDouble()
                                .clamp(0.0, _duration.inSeconds.toDouble()),
                            max: _duration.inSeconds > 0
                                ? _duration.inSeconds.toDouble()
                                : 1.0,
                            onChanged: (value) async {
                              final newPos = Duration(seconds: value.toInt());
                              await _player.seek(newPos);
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous,
                            size: 36, color: Colors.white),
                        onPressed: _prevSong,
                      ),
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: Colors.amberAccent,
                          size: 70,
                        ),
                        onPressed: _isPlaying ? _pauseSong : _playSong,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next,
                            size: 36, color: Colors.white),
                        onPressed: _nextSong,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: _downloadSong,
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar WAV HQ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 40),
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    iconSize: 36,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
