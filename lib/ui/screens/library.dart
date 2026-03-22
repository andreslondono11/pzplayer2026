import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:pzplayer/ui/widgets/album_detalle.dart';
import 'package:pzplayer/ui/widgets/artista_detalle.dart'
    show ArtistDetailScreen;
import 'package:pzplayer/ui/widgets/genre_detalle.dart';
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _currentLetter;
  final ScrollController _scrollController = ScrollController();

  // Optimizaciones de datos
  List<MediaItem> _sortedItems = [];
  final Map<String, Uint8List?> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    _scrollController.addListener(_updateCurrentLetter);
  }

  void _updateCurrentLetter() {
    if (_sortedItems.isEmpty) return;
    const itemHeight = 72.0;
    final index = (_scrollController.offset / itemHeight).floor();

    if (index >= 0 && index < _sortedItems.length) {
      final letter = _sortedItems[index].title.isNotEmpty
          ? _sortedItems[index].title[0].toUpperCase()
          : '#';
      if (_currentLetter != letter) {
        setState(() => _currentLetter = letter);
      }
    }
  }

  Uint8List? _getAndCacheImage(MediaItem item) {
    if (_imageCache.containsKey(item.id)) return _imageCache[item.id];
    final coverBytes = item.extras?['coverBytes'];
    Uint8List? bytes;
    if (coverBytes is Uint8List) {
      bytes = coverBytes;
    } else if (coverBytes is List) {
      bytes = Uint8List.fromList(List<int>.from(coverBytes));
    }
    _imageCache[item.id] = bytes;
    return bytes;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (_sortedItems.length != audio.items.length) {
      _sortedItems = List<MediaItem>.from(
        audio.items,
      )..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }

    if (_sortedItems.isEmpty) return _buildEmptyState(isDark);

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          itemCount: _sortedItems.length,
          itemExtent: 72.0, // Altura fija para optimizar 1000+ items
          cacheExtent: 1500,
          itemBuilder: (context, index) {
            final item = _sortedItems[index];
            return _SongListTile(
              key: ValueKey(item.id),
              item: item,
              imageBytes: _getAndCacheImage(item),
              isDark: isDark,
              onTap: () => audio.playItems(_sortedItems, startIndex: index),
              onMenuPressed: () => _showSongMenu(context, item, isLandscape),
            );
          },
        ),
        if (_currentLetter != null) _buildLetterOverlay(),
      ],
    );
  }

  // --- UI Components ---

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isDark
                ? AppColors.redGradientDark
                : AppColors.redGradientLight,
            boxShadow: const [AppColors.softShadow],
          ),
          child: const Icon(Icons.album, size: 60, color: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildLetterOverlay() {
    return Positioned(
      right: 20,
      top: MediaQuery.of(context).size.height / 2 - 40,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(_currentLetter!, style: AppTextStyles.overlay),
        ),
      ),
    );
  }

  // --- Menús y Navegación ---

  void _showSongMenu(BuildContext context, MediaItem song, bool isLandscape) {
    final audio = context.read<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          isLandscape, // Permite que el menú se vea bien en horizontal
      constraints: isLandscape
          ? BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8)
          : null,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          // Necesario para landscape
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
              }, isDark),
              _menuTile(Icons.person, "Ir a artista", () {
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
          style: isDark ? AppTextStyles.darkto : AppTextStyles.darkti,
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
                  style: isDark ? AppTextStyles.darkto : AppTextStyles.darkti,
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
}

// Celda de alto rendimiento
class _SongListTile extends StatelessWidget {
  final MediaItem item;
  final Uint8List? imageBytes;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onMenuPressed;

  const _SongListTile({
    super.key,
    required this.item,
    this.imageBytes,
    required this.isDark,
    required this.onTap,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDark ? Colors.blueGrey : AppColors.primary,
        backgroundImage: imageBytes != null ? MemoryImage(imageBytes!) : null,
        child: imageBytes == null
            ? const Icon(Icons.music_note, color: AppColors.white)
            : null,
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
      ),
      subtitle: Text(
        item.artist ?? '',
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
