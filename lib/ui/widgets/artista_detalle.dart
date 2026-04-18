import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/core/theme/app_colors.dart';
import 'package:pzplayer/core/theme/app_text_styles.dart';
import 'package:pzplayer/ui/widgets/album_detalle.dart';
import 'package:pzplayer/ui/widgets/favorite.dart';
import 'package:pzplayer/ui/widgets/player_controls.dart';
import 'genre_detalle.dart';

class ArtistDetailScreen extends StatelessWidget {
  final String artistName;
  final List<MediaItem>? songs;

  const ArtistDetailScreen({super.key, required this.artistName, this.songs});

  Uint8List? _parseCover(dynamic raw) {
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);
    if (raw is List<dynamic>) return Uint8List.fromList(List<int>.from(raw));
    return null;
  }

  // ✅ MÉTODO ROBUSTO PARA CARGAR IMAGEN DE ÁLBUM
  Future<Uint8List?> _fetchAlbumArt(int albumId, int songId) async {
    final audioQuery = OnAudioQuery();

    if (albumId > 0) {
      try {
        final art = await audioQuery.queryArtwork(
          albumId,
          ArtworkType.ALBUM,
          format: ArtworkFormat.JPEG,
          size: 500,
        );
        if (art != null && art.isNotEmpty) return art;
      } catch (e) {}
    }

    if (songId > 0) {
      try {
        final art = await audioQuery.queryArtwork(
          songId,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: 500,
        );
        if (art != null && art.isNotEmpty) return art;
      } catch (e) {}
    }
    return null;
  }

  // --- EL MENÚ QUE SÍ PASA DE AHÍ (DRAGGABLE) ---
  void _showSongMenu(BuildContext context, MediaItem song) {
    final audio = context.read<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isFav = audio.isSongFavorite(song);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape =
                    constraints.maxWidth > constraints.maxHeight;

                return Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isLandscape ? constraints.maxWidth * 0.15 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 30),
                          children: [
                            _menuTile(
                              Icons.play_arrow,
                              "Reproducir ahora",
                              () {
                                Navigator.pop(context);
                                audio.registrarReproduccionUniversal(song);
                                audio.playItems([song]);
                              },
                              isDark,
                              isLandscape,
                            ),
                            _menuTile(
                              Icons.queue_play_next,
                              "Reproducir siguiente",
                              () {
                                Navigator.pop(context);
                                audio.playNext(song);
                              },
                              isDark,
                              isLandscape,
                            ),
                            _menuTile(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              isFav
                                  ? "Quitar de favoritos"
                                  : "Añadir a favoritos",
                              () {
                                audio.toggleFavoriteSong(song);
                                Navigator.pop(context);
                              },
                              isDark,
                              isLandscape,
                            ),
                            _menuTile(
                              Icons.favorite,
                              "Ir a favoritos",
                              () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FavoriteSongsScreen(),
                                  ),
                                );
                              },
                              isDark,
                              isLandscape,
                            ),
                            _menuTile(
                              Icons.queue_music,
                              "Añadir a la cola",
                              () {
                                Navigator.pop(context);
                                audio.addToQueue(song);
                              },
                              isDark,
                              isLandscape,
                            ),
                            _menuTile(
                              Icons.album,
                              "Ir a álbum",
                              () {
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
                              },
                              isDark,
                              isLandscape,
                            ),
                            _menuTile(
                              Icons.library_music,
                              "Ir a género",
                              () {
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
                              },
                              isDark,
                              isLandscape,
                            ),
                            _menuTile(
                              Icons.playlist_add,
                              "Añadir a playlist",
                              () {
                                Navigator.pop(context);
                                _showPlaylistSelector(context, song);
                              },
                              isDark,
                              isLandscape,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _menuTile(
    IconData icon,
    String text,
    VoidCallback onTap,
    bool isDark,
    bool isLandscape,
  ) {
    return ListTile(
      visualDensity: isLandscape
          ? VisualDensity.compact
          : VisualDensity.standard,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "No hay playlists disponibles",
                    textAlign: TextAlign.center,
                  ),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final name = playlists[index];
                      return ListTile(
                        leading: Icon(
                          Icons.queue_music,
                          color: isDark ? Colors.blueGrey : AppColors.primary,
                        ),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cerrar",
              style: isDark ? AppTextStyles.button : AppTextStyles.button2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final audio = Provider.of<AudioProvider>(context);

    // ✅ OBTENCIÓN DE CANCIONES CORREGIDA
    // Si no se pasan canciones, filtramos por nombre de artista
    List<MediaItem> songsList = [];
    if (songs != null && songs!.isNotEmpty) {
      songsList = songs!;
    } else {
      songsList = audio.items
          .where((item) => item.artist == artistName)
          .toList();
    }

    // ✅ AGRUPACIÓN DE ÁLBUMES CORREGIDA
    final Map<String, List<MediaItem>> albumsMap = {};
    for (var song in songsList) {
      final album = song.album ?? 'Desconocido';
      // CORRECCIÓN: Usamos [] en lugar de () para la lista inicial
      if (!albumsMap.containsKey(album)) {
        albumsMap[album] = [];
      }
      albumsMap[album]!.add(song);
    }

    final firstSong = songsList.isNotEmpty ? songsList.first : null;
    final Uint8List? artistCover = _parseCover(
      firstSong?.extras?['coverBytes'],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Album del Artista', // Mantenido tu título
          style: isDark
              ? AppTextStyles.headingDark
              : AppTextStyles.headingLight,
        ),
        actions: [
          if (songsList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () {
                audio.registrarReproduccionUniversal(songsList.first);
                audio.playItems(songsList);
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
                          "${albumsMap.length} álbumes • ${songsList.length} canciones",
                          style: AppTextStyles.captionDark,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final albumName = albumsMap.keys.elementAt(index);
                      final albumSongs = albumsMap.values.elementAt(index);

                      // ✅ USO DEL MÉTODO ROBUSTO PARA IMAGEN
                      final firstAlbumSong = albumSongs.isNotEmpty
                          ? albumSongs.first
                          : null;
                      final Uint8List? albumImgFromCache = _parseCover(
                        firstAlbumSong?.extras?['coverBytes'],
                      );

                      // Intentamos obtener IDs para buscar si no hay caché
                      final dynamic rawAlbumId =
                          firstAlbumSong?.extras?['albumId'];
                      final dynamic rawSongId = firstAlbumSong?.extras?['dbId'];
                      final int albumId = (rawAlbumId is int)
                          ? rawAlbumId
                          : int.tryParse(rawAlbumId?.toString() ?? '0') ?? 0;
                      final int songId = (rawSongId is int)
                          ? rawSongId
                          : int.tryParse(rawSongId?.toString() ?? '0') ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: isDark
                            // ignore: deprecated_member_use
                            ? Colors.white.withOpacity(0.05)
                            // ignore: deprecated_member_use
                            : Colors.black.withOpacity(0.03),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: albumImgFromCache != null
                                ? Image.memory(
                                    albumImgFromCache,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : FutureBuilder<Uint8List?>(
                                    future: _fetchAlbumArt(albumId, songId),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data != null &&
                                          snapshot.data!.isNotEmpty) {
                                        return Image.memory(
                                          snapshot.data!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return const Icon(Icons.album, size: 40);
                                    },
                                  ),
                          ),
                          title: Text(
                            albumName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text("${albumSongs.length} canciones"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            audio.registrarReproduccionUniversal(
                              albumSongs.first,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AlbumDetailScreen(
                                  albumName: albumName,
                                  songs: albumSongs,
                                ),
                              ),
                            );
                          },
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
