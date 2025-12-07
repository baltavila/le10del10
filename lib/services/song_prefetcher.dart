import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../songs.dart';

/// Servicio que precarga los primeros segundos de cada canción
/// para reducir la espera cuando el usuario presiona "play".
class SongPrefetcher {
  SongPrefetcher({
    this.segmentDuration = const Duration(seconds: 30),
    AudioPlayer? warmupPlayer,
  }) : _warmupPlayer = warmupPlayer ?? AudioPlayer();

  /// Duración de la parte precargada (por defecto 30 s)
  final Duration segmentDuration;

  final AudioPlayer _warmupPlayer;
  final Set<String> _prefetchedSongIds = <String>{};
  Future<void> _prefetchQueue = Future<void>.value();

  /// Comienza la precarga secuencial de todas las canciones.
  Future<void> prefetchAll(Iterable<Song> songs) {
    for (final song in songs) {
      _enqueuePrefetch(song);
    }
    return _prefetchQueue;
  }

  /// Devuelve un [AudioSource] que reutiliza el audio ya cacheado.
  Future<AudioSource> audioSourceFor(Song song) async {
    await _enqueuePrefetch(song);
    return ProgressiveAudioSource(song.uri);
  }

  /// Libera recursos internos.
  Future<void> dispose() async {
    await _prefetchQueue;
    await _warmupPlayer.stop();
    await _warmupPlayer.dispose();
  }

  /// Precarga un fragmento de la canción en memoria o disco.
  Future<void> _prefetchSong(Song song) async {
    // Evita duplicar descargas
    if (_prefetchedSongIds.contains(song.id)) return;

    final Duration clipEnd =
        segmentDuration < (song.duration ?? const Duration(seconds: 30))
            ? segmentDuration
            : (song.duration ?? const Duration(seconds: 30));

    if (clipEnd == Duration.zero) {
      _prefetchedSongIds.add(song.id);
      return;
    }

    try {
      // Crea una fuente temporal para precargar los primeros segundos
      await _warmupPlayer.setAudioSource(
        ConcatenatingAudioSource(children: [
          ClippingAudioSource(
            start: Duration.zero,
            end: clipEnd,
            child: ProgressiveAudioSource(song.uri),
          ),
        ]),
        preload: true,
      );

      await _warmupPlayer.load();
      _prefetchedSongIds.add(song.id);
    } catch (error, stackTrace) {
      debugPrint(
        'Error precargando "${song.title}" (${song.id}): $error\n$stackTrace',
      );
    } finally {
      try {
        await _warmupPlayer.stop();
      } catch (_) {
        // Ignorar, intento de parada best-effort
      }
    }
  }

  /// Encola la tarea de precarga de forma secuencial.
  Future<void> _enqueuePrefetch(Song song) {
    _prefetchQueue = _prefetchQueue.then((_) => _prefetchSong(song));
    return _prefetchQueue;
  }
}
