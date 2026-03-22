import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/ui/widgets/album_detalle.dart';
import 'package:pzplayer/ui/widgets/player_controls.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'genre_detalle.dart';

class ArtistDetailScreen extends StatelessWidget {
  final String artistName;
  final List<MediaItem> songs;

  const ArtistDetailScreen({
    super.key,
    required this.artistName,
    required this.songs,
  });

  // --- Utilidad para procesar bytes de carátula ---
  Uint8List? _parseCover(dynamic raw) {
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);
    if (raw is List<dynamic>) return Uint8List.fromList(List<int>.from(raw));
    return null;
  }

  // --- Menú de Opciones Completo ---
  void _showSongMenu(BuildContext context, MediaItem song) {
    final audio = context.read<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            _menuTile(Icons.play_arrow, "Reproducir ahora", () {
              Navigator.pop(context);
              audio.playItems([song]);
            }, isDark),
            _menuTile(Icons.queue_play_next, "Reproducir siguiente", () {
              Navigator.pop(context);
              audio.playNext(song);
            }, isDark),
            _menuTile(Icons.queue_music, "Añadir a la cola", () {
              Navigator.pop(context);
              audio.addToQueue(song);
            }, isDark),
            // 💿 IR A ÁLBUM
            _menuTile(Icons.album, "Ir a álbum", () {
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
            }, isDark),
            // 🎸 IR A GÉNERO
            _menuTile(Icons.library_music, "Ir a género", () {
              Navigator.pop(context);
              final genre = song.extras?['genre'] ?? 'Desconocido';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GenreDetailScreen(
                    genreName: genre,
                    songs: audio.genres[genre] ?? [],
                  ),
                ),
              );
            }, isDark),
            _menuTile(Icons.playlist_add, "Añadir a playlist", () {
              Navigator.pop(context);
              _showPlaylistSelector(context, song);
            }, isDark),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    IconData icon,
    String text,
    VoidCallback onTap,
    bool isDark,
  ) {
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.blueGrey : AppColors.primary),
      title: Text(
        text,
        style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
      ),
      onTap: onTap,
    );
  }

  void _showPlaylistSelector(BuildContext context, MediaItem song) {
    final audio = context.read<AudioProvider>();
    final playlists = audio.playlists.keys.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Selecciona playlist",
          style: isDark
              ? AppTextStyles.headingDark
              : AppTextStyles.headingLight,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: playlists.isEmpty
              ? const Text("No hay playlists")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final name = playlists[index];
                    return ListTile(
                      title: Text(name),
                      onTap: () {
                        Navigator.pop(context);
                        audio.addToPlaylist(name, song);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Agrupación de álbumes
    final Map<String, List<MediaItem>> albumsMap = {};
    for (var song in songs) {
      final album = song.album ?? 'Desconocido';
      albumsMap.putIfAbsent(album, () => []).add(song);
    }

    final firstSong = songs.isNotEmpty ? songs.first : null;
    final Uint8List? artistCover = _parseCover(
      firstSong?.extras?['coverBytes'],
    );

    return Scaffold(
      appBar: AppBar(title: Text(artistName)),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Encabezado Visual del Artista
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 85,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.black12,
                          backgroundImage: artistCover != null
                              ? MemoryImage(artistCover)
                              : null,
                          child: artistCover == null
                              ? const Icon(Icons.person, size: 80)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          artistName,
                          style: isDark
                              ? AppTextStyles.subheadingDark
                              : AppTextStyles.subheadingLight,
                        ),
                        Text(
                          "${albumsMap.length} álbumes • ${songs.length} canciones",
                          style: AppTextStyles.captionDark,
                        ),
                      ],
                    ),
                  ),
                ),
                // Sección de Álbumes
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final albumName = albumsMap.keys.elementAt(index);
                      final albumSongs = albumsMap.values.elementAt(index);
                      final Uint8List? albumImg = _parseCover(
                        albumSongs.first.extras?['coverBytes'],
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: albumImg != null
                                ? Image.memory(
                                    albumImg,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.album),
                          ),
                          title: Text(
                            albumName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text("${albumSongs.length} canciones"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(
                                albumName: albumName,
                                songs: albumSongs,
                              ),
                            ),
                          ),
                          onLongPress: () =>
                              _showSongMenu(context, albumSongs.first),
                        ),
                      );
                    }, childCount: albumsMap.length),
                  ),
                ),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
