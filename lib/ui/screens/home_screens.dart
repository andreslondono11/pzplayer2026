import 'package:flutter/material.dart';
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
import 'package:pzplayer/ui/widgets/playlist_detalle.dart';
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

class SearchResultsWidget extends StatelessWidget {
  final String query;
  final AudioProvider audio;

  const SearchResultsWidget({
    super.key,
    required this.query,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();

    // 🔎 Canciones
    final songs = audio.items
        .where(
          (i) =>
              i.title.toLowerCase().contains(q) ||
              (i.artist ?? "").toLowerCase().contains(q) ||
              (i.album ?? "").toLowerCase().contains(q) ||
              (i.extras?['genre'] ?? "").toString().toLowerCase().contains(q),
        )
        .toList();

    // 🔎 Álbumes
    final albums = audio.items
        .where((s) => (s.album ?? "").toLowerCase().contains(q))
        .map((s) => s.album ?? "")
        .toSet()
        .toList();

    // 🔎 Artistas
    final artists = audio.items
        .where((s) => (s.artist ?? "").toLowerCase().contains(q))
        .map((s) => s.artist ?? "")
        .toSet()
        .toList();

    // 🔎 Géneros
    final genres = audio.items
        .where(
          (s) =>
              (s.extras?['genre'] ?? "").toString().toLowerCase().contains(q),
        )
        .map((s) => s.extras?['genre'] ?? "")
        .toSet()
        .toList();

    // 🔎 Carpetas
    final folders = audio.items
        .where(
          (s) =>
              (s.extras?['folder'] ?? "").toString().toLowerCase().contains(q),
        )
        .map((s) => s.extras?['folder'] ?? "")
        .toSet()
        .toList();

    // 🔎 Playlists
    final playlists = audio.playlists.keys
        .where((p) => p.toLowerCase().contains(q))
        .toList();

    return ListView(
      shrinkWrap: true, // evita desbordes
      children: [
        // 🔹 Sección Canciones
        if (songs.isNotEmpty)
          _sectionHeader(
            context,
            "Canciones (${songs.length})",
            Icons.library_music,
          ),
        ...songs.map(
          (s) => ListTile(
            leading: const Icon(Icons.music_note, color: AppColors.accent),
            title: Text(s.title, style: _bodyStyle(context)),
            subtitle: Text(s.artist ?? '', style: _captionStyle(context)),
            onTap: () => audio.play(s),
          ),
        ),

        // 🔹 Sección Álbumes
        if (albums.isNotEmpty)
          _sectionHeader(context, "Álbumes (${albums.length})", Icons.album),
        ...albums.map(
          (a) => ListTile(
            leading: const Icon(Icons.album, color: AppColors.accent),
            title: Text(a, style: _bodyStyle(context)),
            onTap: () {
              final filteredSongs = audio.items
                  .where(
                    (s) => (s.album ?? '').toLowerCase() == a.toLowerCase(),
                  )
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AlbumDetailScreen(albumName: a, songs: filteredSongs),
                ),
              );
            },
          ),
        ),

        // 🔹 Sección Artistas
        if (artists.isNotEmpty)
          _sectionHeader(context, "Artistas (${artists.length})", Icons.person),
        ...artists.map(
          (artist) => ListTile(
            leading: const Icon(Icons.person, color: AppColors.accent),
            title: Text(artist, style: _bodyStyle(context)),
            onTap: () {
              final filteredSongs = audio.items
                  .where(
                    (s) =>
                        (s.artist ?? '').toLowerCase() == artist.toLowerCase(),
                  )
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistDetailScreen(
                    artistName: artist,
                    songs: filteredSongs,
                  ),
                ),
              );
            },
          ),
        ),

        // 🔹 Sección Géneros
        if (genres.isNotEmpty)
          _sectionHeader(context, "Géneros (${genres.length})", Icons.category),
        ...genres.map(
          (g) => ListTile(
            leading: const Icon(Icons.category, color: AppColors.accent),
            title: Text(g, style: _bodyStyle(context)),
            onTap: () {
              final filteredSongs = audio.items
                  .where(
                    (s) =>
                        (s.extras?['genre'] ?? '').toString().toLowerCase() ==
                        g.toLowerCase(),
                  )
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GenreDetailScreen(genreName: g, songs: filteredSongs),
                ),
              );
            },
          ),
        ),

        // 🔹 Sección Carpetas
        if (folders.isNotEmpty)
          _sectionHeader(context, "Carpetas (${folders.length})", Icons.folder),
        ...folders.map(
          (f) => ListTile(
            leading: const Icon(Icons.folder, color: AppColors.accent),
            title: Text(f, style: _bodyStyle(context)),
            onTap: () {
              final filteredSongs = audio.items
                  .where(
                    (s) =>
                        (s.extras?['folder'] ?? '').toLowerCase() ==
                        f.toLowerCase(),
                  )
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FolderDetailScreen(folderName: f, songs: filteredSongs),
                ),
              );
            },
          ),
        ),

        // 🔹 Sección Playlists
        if (playlists.isNotEmpty)
          _sectionHeader(
            context,
            "Playlists (${playlists.length})",
            Icons.playlist_play,
          ),
        ...playlists.map(
          (p) => ListTile(
            leading: const Icon(Icons.playlist_play, color: AppColors.accent),
            title: Text(p, style: _bodyStyle(context)),
            onTap: () {
              final filteredSongs = audio.playlists[p] ?? [];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(
                    playlistName: p,
                    songs: filteredSongs,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 🔹 Helpers para estilos y encabezados
  Widget _sectionHeader(BuildContext context, String text, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(
        text,
        style: Theme.of(context).brightness == Brightness.light
            ? AppTextStyles.subheadingLight
            : AppTextStyles.subheadingDark,
      ),
    );
  }

  TextStyle _bodyStyle(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppTextStyles.bodyLight
        : AppTextStyles.bodyDark;
  }

  TextStyle _captionStyle(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppTextStyles.captionLight
        : AppTextStyles.captionDark;
  }
}
