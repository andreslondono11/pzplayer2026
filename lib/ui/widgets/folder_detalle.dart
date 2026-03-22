import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/ui/widgets/artista_detalle.dart';
import 'package:pzplayer/ui/widgets/player_controls.dart';
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'album_detalle.dart';
import 'genre_detalle.dart';

class FolderDetailScreen extends StatelessWidget {
  final String folderName;
  final List<MediaItem> songs;

  const FolderDetailScreen({
    super.key,
    required this.folderName,
    required this.songs,
  });

  // --- Lógica de Utilidad para Imágenes (Mantenida) ---
  Uint8List? _parseCover(dynamic raw) {
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);
    if (raw is List<dynamic>) return Uint8List.fromList(List<int>.from(raw));
    return null;
  }

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
              final album = song.album ?? 'Desconocido';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumDetailScreen(
                    albumName: album,
                    songs: audio.albums[album] ?? [],
                  ),
                ),
              );
            }, isDark),
            _menuTile(Icons.person, "Ir a artista", () {
              Navigator.pop(context);
              final artist = song.artist ?? 'Desconocido';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistDetailScreen(
                    artistName: artist,
                    songs: audio.artists[artist] ?? [],
                  ),
                ),
              );
            }, isDark),
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
              style: isDark ? AppTextStyles.button : AppTextStyles.button2,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final folderDisplayName = folderName.split('/').last;

    // Carátula de la carpeta
    final firstSong = songs.isNotEmpty ? songs.first : null;
    final Uint8List? folderCover = _parseCover(
      firstSong?.extras?['coverBytes'],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          folderDisplayName,
          style: isDark
              ? AppTextStyles.headingDark
              : AppTextStyles.headingLight,
          overflow: TextOverflow.ellipsis, // Evita desborde en el AppBar
        ),
      ),
      body: Column(
        children: [
          // Encabezado con Scroll para evitar errores en pantallas pequeñas
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeaderImage(folderCover, isDark),
                  const SizedBox(height: 12),
                  Text(
                    folderDisplayName,
                    style: isDark
                        ? AppTextStyles.subheadingDark
                        : AppTextStyles.subheadingLight,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    maxLines: 2, // Permite hasta 2 líneas antes de cortar
                  ),
                  const SizedBox(height: 6),
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

          // Listado de canciones
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final Uint8List? coverBytes = _parseCover(
                  song.extras?['coverBytes'],
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isDark
                        ? Colors.blueGrey.withOpacity(0.1)
                        : AppColors.background.withOpacity(0.5),
                    leading: CircleAvatar(
                      backgroundColor: isDark
                          ? Colors.blueGrey
                          : AppColors.primary,
                      backgroundImage: coverBytes != null
                          ? MemoryImage(coverBytes)
                          : null,
                      child: coverBytes == null
                          ? const Icon(Icons.music_note, color: Colors.white)
                          : null,
                    ),
                    title: Text(
                      song.title,
                      style: isDark
                          ? AppTextStyles.bodyDark
                          : AppTextStyles.bodyLight,
                      overflow: TextOverflow
                          .ellipsis, // ✅ CRÍTICO: Evita desborde horizontal
                      maxLines: 1,
                    ),
                    subtitle: Text(
                      song.artist ?? 'Desconocido',
                      style: isDark
                          ? AppTextStyles.captionDark
                          : AppTextStyles.captionLight,
                      overflow: TextOverflow
                          .ellipsis, // ✅ CRÍTICO: Evita desborde horizontal
                      maxLines: 1,
                    ),
                    onTap: () => context.read<AudioProvider>().playItems(
                      songs,
                      startIndex: index,
                    ),
                    onLongPress: () => _showSongMenu(context, song),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: isDark ? Colors.blueGrey : AppColors.secondary,
                      ),
                      onPressed: () => _showSongMenu(context, song),
                    ),
                  ),
                );
              },
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildHeaderImage(Uint8List? cover, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: cover != null
            ? Image.memory(
                cover,
                width: 180,
                height: 180,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              )
            : Icon(
                Icons.folder,
                size: 180,
                color: isDark ? Colors.blueGrey : AppColors.primary,
              ),
      ),
    );
  }
}
