import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';

import 'package:pzplayer/ui/widgets/album_detalle.dart';
import 'package:pzplayer/ui/widgets/artista_detalle.dart';
import 'package:pzplayer/ui/widgets/genre_detalle.dart';

class SongSubMenu extends StatelessWidget {
  final MediaItem song;

  const SongSubMenu({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioProvider>();

    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text("Reproducir ahora"),
            onTap: () {
              Navigator.pop(context);
              audio.playItems([song]);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_play_next),
            title: const Text("Reproducir siguiente"),
            onTap: () {
              Navigator.pop(context);
              audio.playNext(song); // 🔑 usa el método nuevo
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: const Text("Añadir a la cola"),
            onTap: () {
              Navigator.pop(context);
              audio.addToQueue(song); // 🔑 usa el método nuevo
            },
          ),
          ListTile(
            leading: const Icon(Icons.album),
            title: const Text("Ir a álbum"),
            onTap: () {
              Navigator.pop(context);
              final albumSongs =
                  audio.albums[song.album ?? 'Desconocido'] ?? [];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumDetailScreen(
                    albumName: song.album ?? 'Desconocido',
                    songs: albumSongs,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Ir a artista"),
            onTap: () {
              Navigator.pop(context);
              final artistSongs =
                  audio.artists[song.artist ?? 'Desconocido'] ?? [];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistDetailScreen(
                    artistName: song.artist ?? 'Desconocido',
                    songs: artistSongs,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.library_music),
            title: const Text("Ir a género"),
            onTap: () {
              Navigator.pop(context);
              final genreSongs =
                  audio.genres[song.extras?['genre'] ?? 'Desconocido'] ?? [];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GenreDetailScreen(
                    genreName: song.extras?['genre'] ?? 'Desconocido',
                    songs: genreSongs,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text("Añadir a playlist"),
            onTap: () {
              Navigator.pop(context);
              audio.addToPlaylist("Favoritos", song);
            },
          ),
        ],
      ),
    );
  }
}
