import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/ui/widgets/artista_detalle.dart';
import 'package:pzplayer/ui/widgets/favorite.dart';
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

  // --- Lógica de Utilidad para obtener ID ---
  int _getSongId(MediaItem? item) {
    final dynamic rawId = item?.extras?['dbId'];
    if (rawId is int) return rawId;
    return int.tryParse(rawId?.toString() ?? '0') ?? 0;
  }

  // --- SUBMENÚ ADAPTATIVO REFORZADO ---
  void _showSongMenu(BuildContext context, MediaItem song) {
    final audio = context.read<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isFav = audio.isSongFavorite(song);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final screenHeight = MediaQuery.of(context).size.height;

          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: isLandscape ? constraints.maxWidth * 0.2 : 0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * (isLandscape ? 0.8 : 0.85),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _menuTile(Icons.play_arrow, "Reproducir ahora", () {
                            Navigator.pop(context);
                            // ✅ REGISTRO AÑADIDO
                            audio.registrarReproduccionUniversal(song);
                            audio.playItems([song]);
                          }, isDark),
                          _menuTile(
                            Icons.queue_play_next,
                            "Reproducir siguiente",
                            () {
                              Navigator.pop(context);
                              audio.playNext(song);
                            },
                            isDark,
                          ),

                          _menuTile(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            isFav
                                ? "Quitar de favoritos"
                                : "Añadir a favoritos",
                            () {
                              audio.toggleFavoriteSong(song);
                              // Si tu _menuTile está dentro de un StatefulWidget,
                              // probablemente necesites llamar a setState(() {}) aquí
                              // para que el icono cambie visualmente antes de cerrar.
                              Navigator.pop(context);
                            },
                            isDark,
                          ),

                          _menuTile(Icons.favorite, "Ir a favoritos", () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FavoriteSongsScreen(),
                              ),
                            );
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
                            final genre =
                                song.extras?['genre'] ?? 'Desconocido';
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
                          _menuTile(
                            Icons.playlist_add,
                            "Añadir a playlist",
                            () {
                              Navigator.pop(context);
                              _showPlaylistSelector(context, song);
                            },
                            isDark,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
          width: 400,
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
    final audio = Provider.of<AudioProvider>(context);
    final folderDisplayName = folderName.split('/').last;

    final int folderSongId = songs.isNotEmpty ? _getSongId(songs.first) : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detalles de la Carpeta',
          style: isDark
              ? AppTextStyles.headingDark
              : AppTextStyles.headingLight,
          overflow: TextOverflow.ellipsis,
        ),
        // ✅ NUEVO: Botón Play en AppBar
        actions: [
          if (songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () {
                audio.registrarReproduccionUniversal(songs.first);
                audio.playItems(songs);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.portrait) {
                  return Column(
                    children: [
                      _buildFolderHeader(
                        folderSongId,
                        folderDisplayName,
                        isDark,
                        orientation,
                      ),
                      Expanded(child: _buildSongList(isDark)),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: SingleChildScrollView(
                            child: _buildFolderHeader(
                              folderSongId,
                              folderDisplayName,
                              isDark,
                              orientation,
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(flex: 3, child: _buildSongList(isDark)),
                    ],
                  );
                }
              },
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildFolderHeader(
    int songId,
    String name,
    bool isDark,
    Orientation orientation,
  ) {
    bool isLandscape = orientation == Orientation.landscape;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHeaderImage(songId, isDark, isLandscape),
          const SizedBox(height: 16),
          Text(
            name,
            style: isDark
                ? AppTextStyles.subheadingDark
                : AppTextStyles.subheadingLight,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text(
            "${songs.length} canciones",
            style: isDark
                ? AppTextStyles.captionDark
                : AppTextStyles.captionLight,
          ),
        ],
      ),
    );
  }

  Widget _buildSongList(bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final int songId = _getSongId(song);
        final audio = context.read<AudioProvider>();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: isDark
                ? Colors.blueGrey.withOpacity(0.1)
                : AppColors.background.withOpacity(0.5),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: SizedBox(
                width: 40,
                height: 40,
                child: QueryArtworkWidget(
                  id: songId,
                  type: ArtworkType.AUDIO,
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: Container(
                    color: isDark ? Colors.blueGrey : AppColors.primary,
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              song.title,
              style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Text(
              song.artist ?? 'Desconocido',
              style: isDark
                  ? AppTextStyles.captionDark
                  : AppTextStyles.captionLight,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            // ✅ REGISTRO AL TAP
            onTap: () {
              audio.registrarReproduccionUniversal(song);
              audio.playItems(songs, startIndex: index);
            },
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
    );
  }

  Widget _buildHeaderImage(int songId, bool isDark, bool isLandscape) {
    double imageSize = isLandscape ? 160 : 200;
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
        child: QueryArtworkWidget(
          id: songId,
          type: ArtworkType.AUDIO,
          artworkWidth: imageSize,
          artworkHeight: imageSize,
          artworkFit: BoxFit.cover,
          nullArtworkWidget: Container(
            width: imageSize,
            height: imageSize,
            color: isDark
                ? Colors.blueGrey.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.1),
            child: Icon(
              Icons.folder,
              size: imageSize * 0.6,
              color: isDark ? Colors.blueGrey : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
