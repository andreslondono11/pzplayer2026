import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/core/theme/app_colors.dart';
import 'package:pzplayer/core/theme/app_text_styles.dart';
import 'package:pzplayer/ui/widgets/album_detalle.dart';
import 'package:pzplayer/ui/widgets/artista_detalle.dart';
import 'package:pzplayer/ui/widgets/favorite.dart';
import 'package:pzplayer/ui/widgets/folder_detalle.dart';
import 'package:pzplayer/ui/widgets/genre_detalle.dart';

// --- WIDGET DE RESULTADOS DE BÚSQUEDA ---
class SearchResultsWidget extends StatefulWidget {
  final String query;
  final AudioProvider audio;

  const SearchResultsWidget({
    super.key,
    required this.query,
    required this.audio,
  });

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget> {
  final Map<int, Uint8List?> _artworkCache = {};

  @override
  Widget build(BuildContext context) {
    final q = widget.query.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // 🔎 FILTRADO (Usamos la lista completa del provider para asegurar consistencia)
    final allLibraryItems = widget.audio.items;

    final songs = allLibraryItems.where((i) {
      return i.title.toLowerCase().contains(q) ||
          (i.artist ?? "").toLowerCase().contains(q) ||
          (i.album ?? "").toLowerCase().contains(q);
    }).toList();

    final albums = allLibraryItems
        .where((s) => (s.album ?? "").toLowerCase().contains(q))
        .map((s) => s.album ?? "")
        .toSet()
        .toList();

    final artists = allLibraryItems
        .where((s) => (s.artist ?? "").toLowerCase().contains(q))
        .map((s) => s.artist ?? "")
        .toSet()
        .toList();

    final genres = allLibraryItems
        .where((s) => (s.genre ?? "").toString().toLowerCase().contains(q))
        .map((s) => s.genre ?? "") // Usamos la propiedad directa
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    // Carpetas: Buscamos por nombre de carpeta en la ruta
    final folders = allLibraryItems
        .where((s) {
          final path = s.id;
          final lastSlash = path.lastIndexOf('/');
          String folderName = "Root";
          if (lastSlash != -1) {
            folderName = path.substring(0, lastSlash);
            // Tomamos solo el nombre de la carpeta final para comparar con la búsqueda
            final justName = folderName.substring(
              folderName.lastIndexOf('/') + 1,
            );
            return justName.toLowerCase().contains(q);
          }
          return false;
        })
        .map((s) {
          final path = s.id;
          final lastSlash = path.lastIndexOf('/');
          return lastSlash != -1 ? path.substring(0, lastSlash) : "Root";
        })
        .toSet()
        .toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      children: [
        // Canciones
        if (songs.isNotEmpty)
          _sectionHeader(
            context,
            "Canciones",
            songs.length,
            Icons.library_music,
          ),

        ...songs.map((item) {
          final dynamic rawId = item.extras?['dbId'];
          final int songId = (rawId is int)
              ? rawId
              : int.tryParse(rawId?.toString() ?? '0') ?? 0;
          return _SongListTile(
            key: ValueKey(item.id),
            item: item,
            songId: songId,
            isDark: isDark,
            artworkCache: _artworkCache,
            onTap: () {
              widget.audio.registrarReproduccionUniversal(item);
              widget.audio.play(item);
            },
            onMenuPressed: () => _showSongMenu(context, item, isLandscape),
          );
        }),

        // Álbumes
        if (albums.isNotEmpty)
          _sectionHeader(context, "Álbumes", albums.length, Icons.album),

        ...albums.map(
          (a) => _GenericImageTile(
            key: ValueKey("album_$a"),
            title: a,
            subtitle: "Álbum",
            icon: Icons.album,
            iconColor: isDark ? Colors.blueGrey : AppColors.accent,
            isDark: isDark,
            allItems: allLibraryItems, // Pasamos la lista completa
            filterType: 'album',
            onTap: () {
              final filtered = allLibraryItems
                  .where((s) => s.album == a)
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AlbumDetailScreen(albumName: a, songs: filtered),
                ),
              );
            },
          ),
        ),

        // Artistas
        if (artists.isNotEmpty)
          _sectionHeader(context, "Artistas", artists.length, Icons.person),

        ...artists.map(
          (art) => _GenericImageTile(
            key: ValueKey("artist_$art"),
            title: art,
            subtitle: "Artista",
            icon: Icons.person,
            iconColor: isDark ? Colors.blueGrey : AppColors.accent,
            isDark: isDark,
            allItems: allLibraryItems, // Pasamos la lista completa
            filterType: 'artist',
            onTap: () {
              final filtered = allLibraryItems
                  .where((s) => s.artist == art)
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ArtistDetailScreen(artistName: art, songs: filtered),
                ),
              );
            },
          ),
        ),

        // Géneros
        if (genres.isNotEmpty)
          _sectionHeader(context, "Géneros", genres.length, Icons.category),

        ...genres.map(
          (g) => _GenericImageTile(
            key: ValueKey("genre_$g"),
            title: g,
            subtitle: "Género",
            icon: Icons.category,
            iconColor: isDark ? Colors.blueGrey : AppColors.accent,
            isDark: isDark,
            allItems: allLibraryItems,
            filterType: 'genre',
            onTap: () {
              final filtered = allLibraryItems
                  .where((s) => s.extras?['genre'] == g)
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GenreDetailScreen(genreName: g, songs: filtered),
                ),
              );
            },
          ),
        ),

        // Carpetas
        if (folders.isNotEmpty)
          _sectionHeader(context, "Carpetas", folders.length, Icons.folder),

        ...folders.map(
          (f) => _GenericImageTile(
            key: ValueKey("folder_$f"),
            title: f.split('/').last, // Mostrar solo el nombre de la carpeta
            subtitle: "Carpeta",
            icon: Icons.folder,
            iconColor: isDark ? Colors.blueGrey : AppColors.accent,
            isDark: isDark,
            allItems: allLibraryItems,
            filterType: 'folder',
            onTap: () {
              // Lógica robusta para filtrar por ruta exacta
              final filtered = allLibraryItems.where((s) {
                final path = s.id;
                final lastSlash = path.lastIndexOf('/');
                final folderPath = lastSlash != -1
                    ? path.substring(0, lastSlash)
                    : "Root";
                return folderPath == f;
              }).toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FolderDetailScreen(
                    folderName: f.split('/').last,
                    songs: filtered,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSongMenu(BuildContext context, MediaItem song, bool isLandscape) {
    final audio = context.read<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isFav = audio.isSongFavorite(song);

    showModalBottomSheet(
      context: context,
      isScrollControlled: isLandscape,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Wrap(
            children: [
              _menuTile(Icons.play_arrow, "Reproducir ahora", () {
                Navigator.pop(context);
                audio.registrarReproduccionUniversal(song);
                audio.play(song);
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
                  setState(() {}); // Refrescar icono
                  Navigator.pop(context);
                },
                isDark,
              ),
              _menuTile(Icons.favorite_sharp, "Ir a favoritos", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FavoriteSongsScreen(),
                  ),
                );
              }, isDark),
              _menuTile(Icons.album, "Ir a álbum", () {
                Navigator.pop(context);
                final filtered = audio.items
                    .where((s) => s.album == song.album)
                    .toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlbumDetailScreen(
                      albumName: song.album ?? '',
                      songs: filtered,
                    ),
                  ),
                );
              }, isDark),
              _menuTile(Icons.person, "Ir a artista", () {
                Navigator.pop(context);
                final filtered = audio.items
                    .where((s) => s.artist == song.artist)
                    .toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArtistDetailScreen(
                      artistName: song.artist ?? '',
                      songs: filtered,
                    ),
                  ),
                );
              }, isDark),
              _menuTile(Icons.library_music, "Ir a género", () {
                Navigator.pop(context);
                final genreName = song.extras?['genre'] ?? 'Desconocido';
                final genreSongs = audio.genres[genreName] ?? [];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GenreDetailScreen(
                      genreName: genreName,
                      songs: genreSongs,
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

  void _showPlaylistSelector(BuildContext context, MediaItem song) {
    final audio = context.read<AudioProvider>();
    final playlists = audio.playlists.keys.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          "Selecciona playlist",
          style: isDark
              ? AppTextStyles.subheadingDark
              : AppTextStyles.subheadingLight,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final name = playlists[index];
              return ListTile(
                leading: Icon(
                  Icons.queue_music,
                  color: isDark ? Colors.blueGrey : AppColors.secondary,
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

  Widget _sectionHeader(
    BuildContext context,
    String title,
    int count,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        "$count disponibles",
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SongListTile extends StatelessWidget {
  final MediaItem item;
  final int songId;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onMenuPressed;
  final Map<int, Uint8List?> artworkCache;

  const _SongListTile({
    super.key,
    required this.item,
    required this.songId,
    required this.isDark,
    required this.onTap,
    required this.onMenuPressed,
    required this.artworkCache,
  });

  @override
  Widget build(BuildContext context) {
    // Intentar usar caché
    if (artworkCache.containsKey(songId)) {
      return _buildTile(artworkCache[songId]);
    }

    return FutureBuilder<Uint8List?>(
      future: songId == 0
          ? Future.value(null)
          : OnAudioQuery().queryArtwork(
              songId,
              ArtworkType.AUDIO,
              format: ArtworkFormat.JPEG,
              size: 150,
            ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          artworkCache[songId] = snapshot.data;
          return _buildTile(snapshot.data);
        }
        return _buildTile(null);
      },
    );
  }

  Widget _buildTile(Uint8List? imageBytes) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDark
            ? Colors.white10
            : AppColors.primary.withOpacity(0.05),
        backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
        child: imageBytes == null
            ? Icon(
                Icons.music_note,
                color: isDark ? Colors.blueGrey : AppColors.primary,
              )
            : null,
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
      ),
      subtitle: Text(
        item.artist ?? 'Desconocido',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isDark ? AppTextStyles.captionDark : AppTextStyles.captionLight,
      ),
      onTap: onTap,
      trailing: IconButton(
        icon: Icon(
          Icons.more_vert,
          color: isDark ? Colors.blueGrey : AppColors.secondary,
        ),
        onPressed: onMenuPressed,
      ),
    );
  }
}

// ✅ WIDGET TILE MEJORADO Y ROBUSTO
class _GenericImageTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final VoidCallback onTap;
  final List<MediaItem> allItems;
  final String filterType;

  const _GenericImageTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.onTap,
    required this.allItems,
    required this.filterType,
    required ValueKey<String> key,
  });

  @override
  State<_GenericImageTile> createState() => _GenericImageTileState();
}

class _GenericImageTileState extends State<_GenericImageTile> {
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadCoverArt();
  }

  Future<void> _loadCoverArt() async {
    // 1. Filtrar los items que coinciden con este Tile (Álbum, Artista, Género, Carpeta)
    List<MediaItem> filteredItems = [];

    if (widget.filterType == 'folder') {
      // ✅ LÓGICA CARPETA (Restaurada y corregida)
      filteredItems = widget.allItems.where((s) {
        final path = s.id;
        final lastSlash = path.lastIndexOf('/');
        // Obtenemos la ruta de la carpeta padre de la canción
        final folderPath = lastSlash != -1
            ? path.substring(0, lastSlash)
            : "Root";
        // Comparamos con el título del widget (que es la ruta de la carpeta)
        return folderPath == widget.title;
      }).toList();
    } else if (widget.filterType == 'album') {
      filteredItems = widget.allItems
          .where((s) => s.album == widget.title)
          .toList();
    } else if (widget.filterType == 'artist') {
      filteredItems = widget.allItems
          .where((s) => s.artist == widget.title)
          .toList();
    } else if (widget.filterType == 'genre') {
      filteredItems = widget.allItems
          .where((s) => s.genre == widget.title)
          .toList();
    }

    if (filteredItems.isEmpty) return;

    // 2. Buscar la primera canción en esa lista que tenga una carátula válida
    for (var item in filteredItems) {
      final dynamic rawId = item.extras?['dbId'];
      final int songId = (rawId is int)
          ? rawId
          : int.tryParse(rawId?.toString() ?? '0') ?? 0;

      if (songId > 0) {
        try {
          final bytes = await OnAudioQuery().queryArtwork(
            songId,
            ArtworkType.AUDIO,
            format: ArtworkFormat.JPEG,
            size: 200,
          );

          if (bytes != null && bytes.isNotEmpty) {
            if (mounted) {
              setState(() {
                _imageBytes = bytes;
              });
            }
            return; // Encontramos una, paramos el bucle
          }
        } catch (e) {
          continue;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: widget.isDark
            ? Colors.white10
            : AppColors.primary.withOpacity(0.05),
        backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
        child: _imageBytes == null
            ? Icon(widget.icon, color: widget.iconColor)
            : null,
      ),
      title: Text(
        widget.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
      ),
      subtitle: Text(
        widget.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.isDark
            ? AppTextStyles.captionDark
            : AppTextStyles.captionLight,
      ),
      onTap: widget.onTap,
    );
  }
}
