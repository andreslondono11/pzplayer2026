import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/ui/widgets/artista_detalle.dart';
import '../../core/audio/audio_provider.dart';
import 'album_detalle.dart';

import 'genre_detalle.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistName;
  final List<MediaItem> songs;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistName,
    required this.songs,
  });

  void _showSongMenu(BuildContext context, MediaItem song) {
    final audio = context.read<AudioProvider>();

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlbumDetailScreen(
                      albumName: song.album ?? 'Desconocido',
                      songs: audio.albums[song.album ?? 'Desconocido'] ?? [],
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArtistDetailScreen(
                      artistName: song.artist ?? 'Desconocido',
                      songs: audio.artists[song.artist ?? 'Desconocido'] ?? [],
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GenreDetailScreen(
                      genreName: song.extras?['genre'] ?? 'Desconocido',
                      songs:
                          audio.genres[song.extras?['genre'] ??
                              'Desconocido'] ??
                          [],
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
                _showPlaylistSelector(context, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text("Eliminar de esta playlist"),
              onTap: () {
                Navigator.pop(context);
                audio.removeFromPlaylist(playlistName, song);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaylistSelector(BuildContext context, MediaItem song) {
    final audio = context.read<AudioProvider>();
    final playlists = audio.playlists.keys.toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Selecciona playlist"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final name = playlists[index];
              return ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(name),
                onTap: () {
                  Navigator.pop(context);
                  audio.addToPlaylist(name, song);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(playlistName)),
      body: songs.isEmpty
          ? const Center(child: Text("Playlist vacía"))
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final dynamic rawCover = song.extras?['coverBytes'];

                Uint8List? coverBytes;
                if (rawCover is Uint8List) {
                  coverBytes = rawCover;
                } else if (rawCover is List<int>) {
                  coverBytes = Uint8List.fromList(rawCover);
                } else if (rawCover is List<dynamic>) {
                  coverBytes = Uint8List.fromList(List<int>.from(rawCover));
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: coverBytes != null
                        ? MemoryImage(coverBytes)
                        : null,
                    child: coverBytes == null
                        ? const Icon(Icons.music_note)
                        : null,
                  ),
                  title: Text(song.title),
                  subtitle: Text(song.artist ?? 'Desconocido'),
                  onTap: () => context.read<AudioProvider>().playItems(
                    songs,
                    startIndex: index,
                  ),
                  onLongPress: () => _showSongMenu(context, song),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showSongMenu(context, song),
                  ),
                );
              },
            ),
    );
  }
}
