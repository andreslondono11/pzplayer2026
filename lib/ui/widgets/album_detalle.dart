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

  int _getSongId(MediaItem? item) {
    final dynamic rawId = item?.extras?['dbId'];
    if (rawId is int) return rawId;
    return int.tryParse(rawId?.toString() ?? '0') ?? 0;
  }

  // --- Menús y Diálogos ---

  void _showSongMenu(BuildContext context, MediaItem song) {
    final audio = context.read<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isFav = audio.isSongFavorite(song);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: isLandscape ? 0.8 : 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            children: [
              _menuTile(Icons.play_arrow, "Reproducir ahora", () {
                Navigator.pop(context);
                // ✅ REGISTRO EN EL MENÚ
                audio.registrarReproduccionUniversal(song);
                audio.playItems([song]);
              }, isDark),
              _menuTile(Icons.queue_play_next, "Reproducir siguiente", () {
                Navigator.pop(context);
                audio.playNext(song);
              }, isDark),

              _menuTile(
                isFav ? Icons.favorite : Icons.favorite_border,
                isFav ? "Quitar de favoritos" : "Añadir a favoritos",
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
                          audio.genres[song.extras?['genre'] ??
                              'Desconocido'] ??
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Obtenemos el ID de la primera canción para la portada
    final int albumSongId = songs.isNotEmpty ? _getSongId(songs.first) : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detalles del Album',
          style: isDark
              ? AppTextStyles.headingDark
              : AppTextStyles.headingLight,
        ),
        actions: [
          // ✅ NUEVO: Botón para reproducir todo el álbum
          if (songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () {
                final audio = context.read<AudioProvider>();
                audio.registrarReproduccionUniversal(songs.first);
                audio.playItems(songs);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Portada Principal
                        _buildCoverArt(
                          albumSongId,
                          isDark,
                          size: isLandscape ? 120 : 160,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                albumName,
                                style: isDark
                                    ? AppTextStyles.subheadingDark
                                    : AppTextStyles.subheadingLight,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final song = songs[index];
                      final int songId = _getSongId(song);
                      final audio = context.read<AudioProvider>();

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
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: _buildDiskArt(songId, 48, isDark),
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
                          // ✅ TAP EN LA LISTA: Registra y reproduce
                          onTap: () {
                            audio.registrarReproduccionUniversal(song);
                            audio.playItems(songs, startIndex: index);
                          },
                          onLongPress: () => _showSongMenu(context, song),
                        ),
                      );
                    }, childCount: songs.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildDiskArt(int songId, double size, bool isDark) {
    return QueryArtworkWidget(
      id: songId,
      type: ArtworkType.AUDIO,
      artworkBorder: BorderRadius.zero,
      artworkFit: BoxFit.cover,
      nullArtworkWidget: Container(
        color: isDark
            ? Colors.blueGrey.withOpacity(0.2)
            : AppColors.primary.withOpacity(0.1),
        child: Icon(
          Icons.music_note,
          color: isDark ? Colors.white70 : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildCoverArt(int songId, bool isDark, {double size = 200}) {
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
        child: QueryArtworkWidget(
          id: songId,
          type: ArtworkType.AUDIO,
          artworkWidth: size,
          artworkHeight: size,
          artworkFit: BoxFit.cover,
          nullArtworkWidget: Container(
            width: size,
            height: size,
            color: isDark
                ? Colors.blueGrey
                : AppColors.primary.withOpacity(0.2),
            child: Icon(
              Icons.album,
              size: size / 2,
              color: isDark ? Colors.white24 : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
