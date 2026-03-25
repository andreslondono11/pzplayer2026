import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Importaciones de tu proyecto
import 'package:pzplayer/core/theme/app_colors.dart';
import 'package:pzplayer/core/theme/app_text_styles.dart';
import 'package:pzplayer/ui/screens/album.dart';
import 'package:pzplayer/ui/screens/artista.dart';
import 'package:pzplayer/ui/screens/folder.dart';
import 'package:pzplayer/ui/screens/genre.dart';
import 'package:pzplayer/ui/screens/library.dart';
import 'package:pzplayer/ui/screens/playlist.dart';
import 'package:pzplayer/ui/widgets/album_detalle.dart';
import 'package:pzplayer/ui/widgets/artista_detalle.dart';
import 'package:pzplayer/ui/widgets/folder_detalle.dart';
import 'package:pzplayer/ui/widgets/genre_detalle.dart';
import 'package:pzplayer/ui/widgets/lateral.dart';
import 'package:pzplayer/ui/widgets/player_controls.dart';
// import 'package:pzplayer/ui/widgets/playlist_detalle.dart';
import '../../core/audio/audio_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = "";
  bool _isSearching = false;
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _navItems = [
    {
      'label': "Biblioteca",
      'icon': Icons.library_music,
      'widget': const LibraryScreen(),
    },
    {
      'label': "Álbum",
      'icon': Icons.album,
      'widget': const AlbumScreen(albumName: '', songs: []),
    },
    {
      'label': "Artista",
      'icon': Icons.person,
      'widget': const ArtistScreen(artistName: '', songs: []),
    },
    {
      'label': "Género",
      'icon': Icons.style,
      'widget': const GenreScreen(genreName: '', songs: []),
    },
    {
      'label': "Playlist",
      'icon': Icons.playlist_play,
      'widget': const PlaylistScreen(playlistName: '', songs: []),
    },
    {
      'label': "Carpeta",
      'icon': Icons.folder,
      'widget': const FolderScreen(folderName: '', songs: []),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _navItems.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedIndex = _tabController.index);
      }
    });
    _initApp();
  }

  void _initApp() async {
    await [
      Permission.audio,
      Permission.storage,
      Permission.notification,
    ].request();
    if (mounted) context.read<AudioProvider>().loadLibrary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth > 600;

        return Scaffold(
          // 1. Drawer asignado aquí
          drawer: const MainDrawer(),
          appBar: _buildAppBar(context, isDark, isTablet),
          body: Row(
            children: [
              if (isTablet && !_isSearching)
                SizedBox(
                  width: constraints.maxWidth > 900 ? 240 : 85,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black12,
                          width: 0.5,
                        ),
                      ),
                      color: isDark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey[50],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          extended: constraints.maxWidth > 900,
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (index) {
                            setState(() => _selectedIndex = index);
                            _tabController.animateTo(index);
                          },
                          backgroundColor: Colors.transparent,
                          indicatorColor: isDark
                              ? Colors.white.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1),
                          selectedIconTheme: IconThemeData(
                            color: isDark ? Colors.white : AppColors.primary,
                            size: 28,
                          ),
                          unselectedIconTheme: const IconThemeData(
                            color: Colors.grey,
                            size: 24,
                          ),
                          selectedLabelTextStyle: TextStyle(
                            color: isDark ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          unselectedLabelTextStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          destinations: _navItems
                              .map(
                                (item) => NavigationRailDestination(
                                  icon: Icon(item['icon']),
                                  label: Text(item['label']),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _isSearching && _query.isNotEmpty
                    ? SearchResultsWidget(
                        query: _query,
                        audio: context.read<AudioProvider>(),
                      )
                    : TabBarView(
                        controller: _tabController,
                        physics: isTablet
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        children: _navItems
                            .map<Widget>((item) => item['widget'])
                            .toList(),
                      ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? constraints.maxWidth * 0.1 : 0,
                vertical: 6,
              ),
              child: const MiniPlayer(),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    bool isTablet,
  ) {
    return AppBar(
      elevation: 0,
      // 2. MODIFICACIÓN AQUÍ: Cambiamos el leading para que pueda abrir el drawer
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            _isSearching
                ? Icons.music_note
                : Icons.menu, // Icono de menú si no busca
            color: isDark ? Colors.blueGrey : AppColors.primary,
          ),
          onPressed: () {
            if (!_isSearching) {
              Scaffold.of(context).openDrawer(); // Abre el drawer
            }
          },
        ),
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
              decoration: const InputDecoration(
                hintText: "Buscar música...",
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => _query = val),
            )
          : Text(
              "Music Player",
              style: isDark ? AppTextStyles.darkto : AppTextStyles.darkti,
            ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: isDark ? Colors.blueGrey : AppColors.accent,
          ),
          onPressed: () => setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _query = "";
              _searchController.clear();
            }
          }),
        ),
      ],
      bottom: (!isTablet && !_isSearching)
          ? TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: isDark ? Colors.white : AppColors.primary,
              labelColor: isDark ? Colors.white : AppColors.primary,
              unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              tabs: _navItems.map((item) => Tab(text: item['label'])).toList(),
            )
          : null,
    );
  }
}

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

    // 🔎 1. FILTRADO DE CANCIONES
    final songs = widget.audio.items.where((i) {
      return i.title.toLowerCase().contains(q) ||
          (i.artist ?? "").toLowerCase().contains(q) ||
          (i.album ?? "").toLowerCase().contains(q);
    }).toList();

    // 🔎 2. FILTRADO DE ÁLBUMES
    final albums = widget.audio.items
        .where((s) => (s.album ?? "").toLowerCase().contains(q))
        .map((s) => s.album ?? "")
        .toSet()
        .toList();

    // 🔎 3. FILTRADO DE ARTISTAS
    final artists = widget.audio.items
        .where((s) => (s.artist ?? "").toLowerCase().contains(q))
        .map((s) => s.artist ?? "")
        .toSet()
        .toList();

    // 🔎 4. FILTRADO DE GÉNEROS
    final genres = widget.audio.items
        .where(
          (s) =>
              (s.extras?['genre'] ?? "").toString().toLowerCase().contains(q),
        )
        .map((s) => (s.extras?['genre'] ?? "").toString())
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();

    // 🔎 5. FILTRADO DE CARPETAS (NUEVO)
    final folders = widget.audio.items
        .where(
          (s) =>
              (s.extras?['folder'] ?? "").toString().toLowerCase().contains(q),
        )
        .map((s) => (s.extras?['folder'] ?? "").toString())
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // --- SECCIÓN CANCIONES ---
        if (songs.isNotEmpty) ...[
          _sectionHeader(
            context,
            "Canciones (${songs.length})",
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
              onTap: () => widget.audio.play(item),
              onMenuPressed: () => _showSongMenu(context, item, isLandscape),
            );
          }),
        ],

        // --- SECCIÓN ÁLBUMES ---
        if (albums.isNotEmpty) ...[
          _sectionHeader(context, "Álbumes (${albums.length})", Icons.album),
          ...albums.map(
            (a) => ListTile(
              leading: Icon(
                Icons.album,
                color: isDark ? Colors.blueGrey : AppColors.accent,
              ),
              title: Text(a, style: _bodyStyle(context)),
              onTap: () {
                final filtered = widget.audio.items
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
        ],

        // --- SECCIÓN ARTISTAS ---
        if (artists.isNotEmpty) ...[
          _sectionHeader(context, "Artistas (${artists.length})", Icons.person),
          ...artists.map(
            (art) => ListTile(
              leading: Icon(
                Icons.person,
                color: isDark ? Colors.blueGrey : AppColors.accent,
              ),
              title: Text(art, style: _bodyStyle(context)),
              onTap: () {
                final filtered = widget.audio.items
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
        ],

        // --- SECCIÓN GÉNEROS ---
        if (genres.isNotEmpty) ...[
          _sectionHeader(context, "Géneros (${genres.length})", Icons.category),
          ...genres.map(
            (g) => ListTile(
              leading: Icon(
                Icons.category,
                color: isDark ? Colors.blueGrey : AppColors.accent,
              ),
              title: Text(g, style: _bodyStyle(context)),
              onTap: () {
                final filtered = widget.audio.items
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
        ],

        // --- SECCIÓN CARPETAS (NUEVO) ---
        if (folders.isNotEmpty) ...[
          _sectionHeader(context, "Carpetas (${folders.length})", Icons.folder),
          ...folders.map(
            (f) => ListTile(
              leading: Icon(
                Icons.folder,
                color: isDark ? Colors.blueGrey : AppColors.accent,
              ),
              title: Text(f, style: _bodyStyle(context)),
              onTap: () {
                final filtered = widget.audio.items
                    .where((s) => s.extras?['folder'] == f)
                    .toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FolderDetailScreen(folderName: f, songs: filtered),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  // --- MANTENIENDO TU LÓGICA DE MENÚ Y ESTILOS ---
  void _showSongMenu(BuildContext context, MediaItem song, bool isLandscape) {
    final audio = context.read<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: isLandscape,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Wrap(
            children: [
              _menuTile(Icons.play_arrow, "Reproducir ahora", () {
                Navigator.pop(context);
                audio.play(song);
              }, isDark),
              _menuTile(Icons.queue_play_next, "Reproducir siguiente", () {
                Navigator.pop(context);
                audio.playNext(song);
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
              _menuTile(Icons.folder, "Ir a carpeta", () {
                Navigator.pop(context);
                final folder = song.extras?['folder'] ?? '';
                final filtered = audio.items
                    .where((s) => s.extras?['folder'] == folder)
                    .toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FolderDetailScreen(folderName: folder, songs: filtered),
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

  // (El resto de helpers: _showPlaylistSelector, _menuTile, _sectionHeader, _bodyStyle permanecen igual)
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

  Widget _sectionHeader(BuildContext context, String text, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.blueGrey : AppColors.accent),
      title: Text(
        text,
        style: Theme.of(context).brightness == Brightness.light
            ? AppTextStyles.subheadingLight
            : AppTextStyles.subheadingDark,
      ),
    );
  }

  TextStyle _bodyStyle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? AppTextStyles.bodyLight
      : AppTextStyles.bodyDark;
}

// (La clase _SongListTile permanece igual para el rendimiento)
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
    if (artworkCache.containsKey(songId))
      return _buildTile(artworkCache[songId]);

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
