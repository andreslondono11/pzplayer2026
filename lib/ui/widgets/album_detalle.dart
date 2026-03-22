import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/ui/widgets/artista_detalle.dart';
import 'package:pzplayer/ui/widgets/player_controls.dart';
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'genre_detalle.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String albumName;
  final List<MediaItem> songs;

  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    required this.songs,
  });

  // --- Lógica de Utilidad ---

  Uint8List? _parseCover(dynamic raw) {
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);
    if (raw is List<dynamic>) return Uint8List.fromList(List<int>.from(raw));
    return null;
  }

  // --- Menús y Diálogos ---

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
            _menuTile(Icons.person, "Ir a artista", () {
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
            }, isDark),
            _menuTile(Icons.library_music, "Ir a género", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GenreDetailScreen(
                    genreName: song.extras?['genre'] ?? 'Desconocido',
                    songs:
                        audio.genres[song.extras?['genre'] ?? 'Desconocido'] ??
                        [],
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
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("No hay playlists creadas"),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final name = playlists[index];
                    return ListTile(
                      leading: Icon(
                        Icons.queue_music,
                        color: isDark ? Colors.blueGrey : AppColors.primary,
                      ),
                      title: Text(
                        name,
                        style: isDark
                            ? AppTextStyles.bodyDark
                            : AppTextStyles.bodyLight,
                      ),
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
            child: Text(
              "Cancelar",
              style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // --- Build Principal ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstSong = songs.isNotEmpty ? songs.first : null;
    final Uint8List? albumCover = _parseCover(firstSong?.extras?['coverBytes']);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          albumName,
          style: isDark
              ? AppTextStyles.headingDark
              : AppTextStyles.headingLight,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Encabezado del Álbum
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        _buildCoverArt(albumCover, isDark),
                        const SizedBox(height: 16),
                        Text(
                          albumName,
                          style: isDark
                              ? AppTextStyles.subheadingDark
                              : AppTextStyles.subheadingLight,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${songs.length} canciones",
                          style: isDark
                              ? AppTextStyles.captionDark
                              : AppTextStyles.captionLight,
                        ),
                      ],
                    ),
                  ),
                ),
                // Lista de canciones
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final song = songs[index];
                      final Uint8List? songCover = _parseCover(
                        song.extras?['coverBytes'],
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: isDark
                              ? Colors.blueGrey.withOpacity(0.05)
                              : AppColors.background.withOpacity(0.5),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 48,
                              height: 48,
                              color: isDark
                                  ? Colors.blueGrey.withOpacity(0.2)
                                  : AppColors.primary.withOpacity(0.1),
                              child: songCover != null
                                  ? Image.memory(songCover, fit: BoxFit.cover)
                                  : Icon(
                                      Icons.music_note,
                                      color: isDark
                                          ? Colors.white70
                                          : AppColors.primary,
                                    ),
                            ),
                          ),
                          title: Text(
                            song.title,
                            style: isDark
                                ? AppTextStyles.bodyDark
                                : AppTextStyles.bodyLight,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist ?? 'Desconocido',
                            style: isDark
                                ? AppTextStyles.captionDark
                                : AppTextStyles.captionLight,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showSongMenu(context, song),
                          ),
                          onTap: () => context.read<AudioProvider>().playItems(
                            songs,
                            startIndex: index,
                          ),
                          onLongPress: () => _showSongMenu(context, song),
                        ),
                      );
                    }, childCount: songs.length),
                  ),
                ),
                // Espacio extra al final para que la última canción no quede tapada por el miniplayer si fuera necesario
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildCoverArt(Uint8List? cover, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: cover != null
            ? Image.memory(cover, width: 200, height: 200, fit: BoxFit.cover)
            : Container(
                width: 200,
                height: 200,
                color: isDark
                    ? Colors.blueGrey
                    : AppColors.primary.withOpacity(0.2),
                child: Icon(
                  Icons.album,
                  size: 100,
                  color: isDark ? Colors.white24 : AppColors.primary,
                ),
              ),
      ),
    );
  }
}
