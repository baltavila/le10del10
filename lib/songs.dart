import 'package:equatable/equatable.dart';

/// Modelo de canción, compatible con el sistema de precarga y tu lista real.
class Song extends Equatable {
  const Song({
    required this.id,
    required this.title,
    required this.url,
    this.download,
    this.duration,
    this.artworkUrl,
  });

  final String id;
  final String title;
  final String url;
  final String? download;
  final Duration? duration;
  final String? artworkUrl;

  /// Getter que transforma la URL en un objeto URI, para JustAudio
  Uri get uri => Uri.parse(url);

  @override
  List<Object?> get props => [id, title, url];
}

/// Lista real de canciones de "Le 10 del 10"
const List<Song> songs = [
  Song(
    id: '01',
    title: 'Maradó',
    url:
        'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/songs%2F01_marado.mp3?alt=media&token=c9f727e9-6997-4689-8f2d-206ad755fd6d',
    download:
        'https://drive.google.com/uc?export=download&id=16xB7sk847UGolipQxOl5oPKYbWynePNZ',
  ),
  Song(
    id: '02',
    title: 'La vida tómbola',
    url:
        'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/songs%2F02_la_vida_tombola.mp3?alt=media&token=4a74cde3-b36e-4c8c-97e1-3f1a79295e90',
    download:
        'https://drive.google.com/uc?export=download&id=1TPGsZ74APQUvmBCAMU0e5BfJYjDlCMLa',
  ),
  Song(
    id: '03',
    title: 'Capitán Pelusa',
    url:
        'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/songs%2F03_capitan_pelusa.mp3?alt=media&token=3a7b3e93-1e3c-4cc1-b967-5e8b0a09f7ac',
    download:
        'https://drive.google.com/uc?export=download&id=1_9E6ygb3WmlZbMkrAvUHHrEqmV_ozSrQ',
  ),
  Song(
    id: '04',
    title: 'El sueño del pibe',
    url:
        'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/songs%2F04_el_sueno_del_pibe.mp3?alt=media&token=90999c91-8b36-4b31-8c7d-c7217b3790aa',
    download:
        'https://drive.google.com/uc?export=download&id=1yyRJfkvG3c7jbrmL-bkERoE0-giKpbcr',
  ),
  Song(
    id: '05',
    title: 'La mano de Dios',
    url:
        'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/songs%2F05_la_mano_de_dios.mp3?alt=media&token=a1ac3d45-8122-47c5-b8b8-18b4e548b536',
    download:
        'https://drive.google.com/uc?export=download&id=1aRWpSyQpALN3h3Ze6ceoYccT4BFJSqRg',
  ),
  Song(
    id: '06',
    title: 'Ho visto Maradona',
    url:
        'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/songs%2F06_ho_visto_maradona.mp3?alt=media&token=f16a4b5a-5103-44ac-91b9-326c8f4b0b4d',
    download:
        'https://drive.google.com/uc?export=download&id=1OUbD6gIutl4xyg-G2M1bD-W4zGWnO0Cz',
  ),
  Song(
    id: '07',
    title: 'Cumbia de la suerte',
    url:
        'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/songs%2F07_cumbia_de_la_suerte.mp3?alt=media&token=a1059388-076b-4108-b017-9060796e518d',
    download:
        'https://drive.google.com/uc?export=download&id=1tWf0c5A5vTH_p5s9pD3y8uKfL7EByK6F',
  ),
  Song(
    id: '08',
    title: 'Maradona (by Calamaro)',
    url:
        'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/songs%2F08_maradona_by_calamaro.mp3?alt=media&token=b26ff6f9d-3770-40ce-a46a-e8b75d58c330',
    download:
        'https://drive.google.com/uc?export=download&id=1jhuzLgHZbGyd4hR7Vq1gGJUPvTqRXlbY',
  ),
  Song(
    id: '09',
    title: 'Para siempre',
    url:
        'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/songs%2F09_para_siempre.mp3?alt=media&token=763b5d5f-ec1b-4b4e-9a5a-dcbb2b2d3587',
    download:
        'https://drive.google.com/uc?export=download&id=1eWZhlNVsRhGxsy3iGdT99I1XlILQblsO',
  ),
  Song(
    id: '10',
    title: 'Maradona ML y Pelé',
    url:
        'https://firebasestorage.googleapis.com/v0/b/le10del10.firebasestorage.app/o/songs%2F10_maradona_ml_y_pele.mp3?alt=media&token=cb33c42e-ef41-4da2-a61d-3efba3384a97',
    download:
        'https://drive.google.com/uc?export=download&id=1PguylDwo73vONmVlbNHtDNq55CzQ-2XP',
  ),
];
