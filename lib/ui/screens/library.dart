import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/ui/widgets/album_detalle.dart';
import 'package:pzplayer/ui/widgets/artista_detalle.dart'
    show ArtistDetailScreen;
import 'package:pzplayer/ui/widgets/favorite.dart';
import 'package:pzplayer/ui/widgets/genre_detalle.dart';
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import 'package:pzplayer/core/theme/app_text_styles.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _currentLetterOverlay;
  String? _currentScrollLetter;

  final ScrollController _scrollController = ScrollController();

  // Optimizaciones de datos
  List<MediaItem> _sortedItems = [];
  final Map<String, int> _letterIndexMap = {};
  final Map<int, Uint8List?> _artworkCache = {};

  // Lista de letras
  final List<String> _alphabet = [
    '#',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_sortedItems.isEmpty) return;
    if (_currentLetterOverlay != null) return;

    final double itemExtent = 72.0;
    final int currentIndex = (_scrollController.offset / itemExtent).round();

    if (currentIndex >= 0 && currentIndex < _sortedItems.length) {
      final item = _sortedItems[currentIndex];
      String letter = '#';

      // 👇 CORRECCIÓN SEGURA
      if (item.title.isNotEmpty && item.title.isNotEmpty) {
        letter = item.title[0].toUpperCase();
        if (!RegExp(r'[A-Z]').hasMatch(letter)) {
          letter = '#';
        }
      }

      if (_currentScrollLetter != letter) {
        setState(() {
          _currentScrollLetter = letter;
        });
      }
    }
  }

  void _buildIndexMap() {
    _letterIndexMap.clear();
    for (int i = 0; i < _sortedItems.length; i++) {
      final title = _sortedItems[i].title;
      // 👇 CORRECCIÓN SEGURA
      if (title.isNotEmpty && title.isNotEmpty) {
        String letter = title[0].toUpperCase();
        if (!RegExp(r'[A-Z]').hasMatch(letter)) {
          letter = '#';
        }
        if (!_letterIndexMap.containsKey(letter)) {
          _letterIndexMap[letter] = i;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 👇 MEJORA INTELIGENTE: Detección de cambios automática
    bool needsUpdate = false;

    if (_sortedItems.length != audio.items.length) {
      needsUpdate = true;
    } else if (_sortedItems.isNotEmpty && audio.items.isNotEmpty) {
      if (_sortedItems.first.id != audio.items.first.id ||
          _sortedItems.last.id != audio.items.last.id) {
        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      _sortedItems = List<MediaItem>.from(
        audio.items,
      )..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      _buildIndexMap();
    }

    if (_sortedItems.isEmpty) return _buildEmptyState(isDark);

    return Stack(
      children: [
        // 👇 ListView simple
        ListView.builder(
          controller: _scrollController,
          itemCount: _sortedItems.length,
          itemExtent: 72.0,
          cacheExtent: 1500,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final item = _sortedItems[index];
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
              onTap: () => _playSongFromLibrary(context, audio, item, index),
              onMenuPressed: () => _showSongMenu(context, item),
            );
          },
        ),

        // Barra lateral de navegación
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 40,
          child: _AlphabetScrollbar(
            alphabet: _alphabet,
            letterIndexMap: _letterIndexMap,
            currentActiveLetter: _currentScrollLetter,
            onLetterSelected: (letter) {
              setState(() => _currentLetterOverlay = letter);
              if (_letterIndexMap.containsKey(letter)) {
                _scrollController.animateTo(
                  _letterIndexMap[letter]! * 72.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
            },
            onDragEnd: () {
              setState(() => _currentLetterOverlay = null);
              _onScroll();
            },
          ),
        ),

        // Overlay
        if (_currentLetterOverlay != null)
          _buildLetterOverlay(_currentLetterOverlay!),
      ],
    );
  }

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

  Widget _buildLetterOverlay(String letter) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _playSongFromLibrary(
    BuildContext context,
    AudioProvider audio,
    MediaItem item,
    int index,
  ) {
    audio.registrarReproduccionUniversal(item);
    audio.playItems(_sortedItems, startIndex: index);
  }

  void _showSongMenu(BuildContext context, MediaItem song) {
    final audio = context.read<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isFav = audio.isSongFavorite(song);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permitir scroll en el menú si es necesario
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Wrap(
            children: [
              _menuTile(Icons.play_arrow, "Reproducir ahora", () {
                Navigator.pop(context);
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

// --- WIDGETS AUXILIARES ---

class _AlphabetScrollbar extends StatefulWidget {
  final List<String> alphabet;
  final Map<String, int> letterIndexMap;
  final String? currentActiveLetter;
  final Function(String) onLetterSelected;
  final VoidCallback onDragEnd;

  const _AlphabetScrollbar({
    required this.alphabet,
    required this.letterIndexMap,
    required this.currentActiveLetter,
    required this.onLetterSelected,
    required this.onDragEnd,
  });

  @override
  State<_AlphabetScrollbar> createState() => _AlphabetScrollbarState();
}

class _AlphabetScrollbarState extends State<_AlphabetScrollbar> {
  String? _lastSelectedLetter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ ELIMINADA LA LÓGICA RESPONSIVE
    // El sidebar se comporta igual en vertical y horizontal

    return GestureDetector(
      onVerticalDragStart: (details) =>
          _handleDrag(context, details.globalPosition),
      onVerticalDragUpdate: (details) =>
          _handleDrag(context, details.globalPosition),
      onVerticalDragEnd: (_) => widget.onDragEnd(),
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.centerRight,
        // ✅ MÁRGENES FIJOS (Verticales estándar)
        padding: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height, // Altura completa
          ),
          child: Column(
            // ✅ SIEMPRE SPACEBETWEEN (Distribución normal vertical)
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: widget.alphabet.map((letter) {
              bool hasItems = widget.letterIndexMap.containsKey(letter);
              bool isActive =
                  _lastSelectedLetter == letter ||
                  widget.currentActiveLetter == letter;

              return Flexible(
                child: Container(
                  // ✅ PADDING VERTICAL FIJO
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark ? Colors.white24 : Colors.black12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      // ✅ TAMAÑO DE LETRA FIJO (Estándar legible)
                      fontSize: 11,
                      height: 1.0,
                      fontWeight: FontWeight.bold,
                      color: hasItems
                          ? (isActive
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? Colors.white70 : Colors.black87))
                          : (isDark ? Colors.white12 : Colors.black12),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _handleDrag(BuildContext context, Offset globalPosition) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);
    final double itemHeight = box.size.height / widget.alphabet.length;
    int index = (localPosition.dy / itemHeight).floor();

    if (index >= 0 && index < widget.alphabet.length) {
      final selectedLetter = widget.alphabet[index];
      if (_lastSelectedLetter != selectedLetter) {
        setState(() => _lastSelectedLetter = selectedLetter);
        widget.onLetterSelected(selectedLetter);
      }
    }
  }
}

class _SongListTile extends StatelessWidget {
  final MediaItem item;
  final int songId;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onMenuPressed;

  const _SongListTile({
    super.key,
    required this.item,
    required this.songId,
    required this.isDark,
    required this.onTap,
    required this.onMenuPressed,
    required Map<int, Uint8List?> artworkCache,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: QueryArtworkWidget(
        id: songId,
        type: ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 150,
        keepOldArtwork: true,
        nullArtworkWidget: CircleAvatar(
          backgroundColor: isDark
              ? Colors.white.withOpacity(0.05)
              : AppColors.primary.withOpacity(0.05),
          child: Icon(
            Icons.music_note,
            color: isDark ? Colors.blueGrey : AppColors.primary,
          ),
        ),
        artworkBorder: BorderRadius.circular(25),
        artworkFit: BoxFit.cover,
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
