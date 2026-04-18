// // import 'dart:typed_data';

// // import 'package:audio_service/audio_service.dart';
// // import 'package:flutter/material.dart';
// // import 'package:on_audio_query/on_audio_query.dart';
// // import 'package:provider/provider.dart';
// // import 'package:permission_handler/permission_handler.dart';

// // // Importaciones de tu proyecto
// // import 'package:pzplayer/core/theme/app_colors.dart';
// // import 'package:pzplayer/core/theme/app_text_styles.dart';
// // import 'package:pzplayer/ui/screens/album.dart';
// // import 'package:pzplayer/ui/screens/artista.dart';
// // import 'package:pzplayer/ui/screens/folder.dart';
// // import 'package:pzplayer/ui/screens/genre.dart';
// // import 'package:pzplayer/ui/screens/library.dart';
// // import 'package:pzplayer/ui/screens/playlist.dart';
// // import 'package:pzplayer/ui/widgets/album_detalle.dart';
// // import 'package:pzplayer/ui/widgets/artista_detalle.dart';
// // import 'package:pzplayer/ui/widgets/folder_detalle.dart';
// // import 'package:pzplayer/ui/widgets/genre_detalle.dart';
// // import 'package:pzplayer/ui/widgets/lateral.dart';
// // import 'package:pzplayer/ui/widgets/player_controls.dart';
// // // import 'package:pzplayer/ui/widgets/playlist_detalle.dart';
// // import '../../core/audio/audio_provider.dart';

// // import 'package:shared_preferences/shared_preferences.dart';

// // class HomeScreen extends StatefulWidget {
// //   const HomeScreen({super.key});

// //   @override
// //   State<HomeScreen> createState() => _HomeScreenState();
// // }

// // class _HomeScreenState extends State<HomeScreen>
// //     with SingleTickerProviderStateMixin {
// //   late TabController _tabController;
// //   final TextEditingController _searchController = TextEditingController();
// //   String _query = "";
// //   bool _isSearching = false;
// //   int _selectedIndex = 0;

// //   // ESTADOS DE CONTROL
// //   bool _isLoading = true;
// //   bool _permissionsGranted = false;

// //   final List<Map<String, dynamic>> _navItems = [
// //     {
// //       'label': "Biblioteca",
// //       'icon': Icons.library_music,
// //       'widget': const LibraryScreen(),
// //     },
// //     {
// //       'label': "Álbum",
// //       'icon': Icons.album,
// //       'widget': const AlbumScreen(albumName: '', songs: []),
// //     },
// //     {
// //       'label': "Artista",
// //       'icon': Icons.person,
// //       'widget': const ArtistScreen(artistName: '', songs: []),
// //     },
// //     {
// //       'label': "Género",
// //       'icon': Icons.style,
// //       'widget': const GenreScreen(genreName: '', songs: []),
// //     },
// //     {
// //       'label': "Playlist",
// //       'icon': Icons.playlist_play,
// //       'widget': const PlaylistScreen(playlistName: '', songs: []),
// //     },
// //     {
// //       'label': "Carpeta",
// //       'icon': Icons.folder,
// //       'widget': const FolderScreen(folderName: '', songs: []),
// //     },
// //   ];

// //   @override
// //   void initState() {
// //     super.initState();
// //     _tabController = TabController(length: _navItems.length, vsync: this);
// //     _tabController.addListener(() {
// //       if (!_tabController.indexIsChanging) {
// //         setState(() => _selectedIndex = _tabController.index);
// //       }
// //     });

// //     // El flujo inicia verificando la política interna
// //     _checkPrivacyStatus();
// //   }

// //   // 1. Verificamos si ya aceptó la política en el pasado
// //   Future<void> _checkPrivacyStatus() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     bool accepted = prefs.getBool('privacy_accepted') ?? false;

// //     if (!accepted) {
// //       // Si no ha aceptado, quitamos el loading para mostrar el diálogo sobre el fondo
// //       setState(() => _isLoading = false);
// //       WidgetsBinding.instance.addPostFrameCallback((_) => _showPrivacyDialog());
// //     } else {
// //       _initAppPermissions();
// //     }
// //   }

// //   // 2. Diálogo con el texto de la política (Sin redirecciones externas)
// //   void _showPrivacyDialog() {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false, // Obligatorio aceptar
// //       builder: (context) => AlertDialog(
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //         title: const Row(
// //           children: [
// //             Icon(Icons.privacy_tip, color: Colors.blue),
// //             SizedBox(width: 10),
// //             Text("Aviso de Privacidad"),
// //           ],
// //         ),
// //         content: const SingleChildScrollView(
// //           child: Text(
// //             "PZ Player valora tu privacidad. Para ofrecerte la mejor experiencia, "
// //             "necesitamos acceder a tus archivos de audio locales. \n\n"
// //             "• No recolectamos datos personales.\n"
// //             "• Tus archivos no se suben a ningún servidor.\n"
// //             "• Los permisos de notificaciones son solo para el control de reproducción.\n\n"
// //             "Al presionar 'Aceptar', confirmas que estás de acuerdo con el tratamiento de datos local.",
// //             style: TextStyle(fontSize: 14),
// //           ),
// //         ),
// //         actions: [
// //           ElevatedButton(
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: Colors.blue,
// //               shape: RoundedRectangleBorder(
// //                 borderRadius: BorderRadius.circular(10),
// //               ),
// //             ),
// //             onPressed: () async {
// //               final prefs = await SharedPreferences.getInstance();
// //               await prefs.setBool('privacy_accepted', true);
// //               Navigator.pop(context); // Cerramos diálogo
// //               _initAppPermissions(); // Procedemos a los permisos de Android
// //             },
// //             child: const Text(
// //               "ACEPTAR Y CONTINUAR",
// //               style: TextStyle(color: Colors.white),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // 3. Flujo de permisos de sistema
// //   Future<void> _initAppPermissions() async {
// //     setState(() => _isLoading = true);

// //     Map<Permission, PermissionStatus> statuses = await [
// //       Permission.audio,
// //       Permission.storage,
// //       Permission.notification,
// //     ].request();

// //     bool granted =
// //         (statuses[Permission.audio]!.isGranted ||
// //         statuses[Permission.storage]!.isGranted);

// //     if (mounted) {
// //       if (granted) {
// //         await context.read<AudioProvider>().loadLibrary();
// //         setState(() {
// //           _permissionsGranted = true;
// //           _isLoading = false;
// //         });
// //       } else {
// //         setState(() {
// //           _permissionsGranted = false;
// //           _isLoading = false;
// //         });
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     // Mientras verifica o carga la librería
// //     if (_isLoading) {
// //       return const Scaffold(body: Center(child: CircularProgressIndicator()));
// //     }

// //     // Si el usuario rechazó los permisos de sistema (Audio/Storage)
// //     if (!_permissionsGranted) {
// //       return _buildPermissionErrorScreen();
// //     }

// //     final isDark = Theme.of(context).brightness == Brightness.dark;

// //     return LayoutBuilder(
// //       builder: (context, constraints) {
// //         final bool isTablet = constraints.maxWidth > 600;

// //         return Scaffold(
// //           drawer: const MainDrawer(),
// //           appBar: _buildAppBar(context, isDark, isTablet),
// //           body: Row(
// //             children: [
// //               if (isTablet && !_isSearching)
// //                 _buildNavigationRail(isDark, constraints),
// //               Expanded(
// //                 child: _isSearching && _query.isNotEmpty
// //                     ? SearchResultsWidget(
// //                         query: _query,
// //                         audio: context.read<AudioProvider>(),
// //                       )
// //                     : TabBarView(
// //                         controller: _tabController,
// //                         physics: isTablet
// //                             ? const NeverScrollableScrollPhysics()
// //                             : const BouncingScrollPhysics(),
// //                         children: _navItems
// //                             .map<Widget>((item) => item['widget'])
// //                             .toList(),
// //                       ),
// //               ),
// //             ],
// //           ),
// //           bottomNavigationBar: const SafeArea(child: MiniPlayer()),
// //         );
// //       },
// //     );
// //   }

// //   // --- Pantalla de error si no hay permisos de almacenamiento ---
// //   Widget _buildPermissionErrorScreen() {
// //     return Scaffold(
// //       body: Center(
// //         child: Padding(
// //           padding: const EdgeInsets.all(30.0),
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               const Icon(
// //                 Icons.music_off_outlined,
// //                 size: 80,
// //                 color: Colors.orangeAccent,
// //               ),
// //               const SizedBox(height: 20),
// //               const Text(
// //                 "Sin acceso a la música",
// //                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //               ),
// //               const SizedBox(height: 10),
// //               const Text(
// //                 "Debes permitir el acceso a tus archivos para que PZ Player pueda reproducir tus canciones.",
// //                 textAlign: TextAlign.center,
// //               ),
// //               const SizedBox(height: 30),
// //               ElevatedButton(
// //                 onPressed: _initAppPermissions,
// //                 child: const Text("INTENTAR DE NUEVO"),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildNavigationRail(bool isDark, BoxConstraints constraints) {
// //     return SizedBox(
// //       width: constraints.maxWidth > 900 ? 240 : 85,
// //       child: NavigationRail(
// //         extended: constraints.maxWidth > 900,
// //         selectedIndex: _selectedIndex,
// //         onDestinationSelected: (index) {
// //           setState(() => _selectedIndex = index);
// //           _tabController.animateTo(index);
// //         },
// //         destinations: _navItems
// //             .map(
// //               (item) => NavigationRailDestination(
// //                 icon: Icon(item['icon']),
// //                 label: Text(item['label']),
// //               ),
// //             )
// //             .toList(),
// //       ),
// //     );
// //   }

// //   PreferredSizeWidget _buildAppBar(
// //     BuildContext context,
// //     bool isDark,
// //     bool isTablet,
// //   ) {
// //     return AppBar(
// //       leading: Builder(
// //         builder: (context) => IconButton(
// //           icon: Icon(_isSearching ? Icons.music_note : Icons.menu),
// //           onPressed: () =>
// //               _isSearching ? null : Scaffold.of(context).openDrawer(),
// //         ),
// //       ),
// //       title: _isSearching
// //           ? TextField(
// //               autofocus: true,
// //               onChanged: (val) => setState(() => _query = val),
// //               decoration: const InputDecoration(
// //                 hintText: "Buscar...",
// //                 border: InputBorder.none,
// //               ),
// //             )
// //           : const Text("PZ Player"),
// //       actions: [
// //         IconButton(
// //           icon: Icon(_isSearching ? Icons.close : Icons.search),
// //           onPressed: () => setState(() {
// //             _isSearching = !_isSearching;
// //             if (!_isSearching) _query = "";
// //           }),
// //         ),
// //       ],
// //       bottom: (!isTablet && !_isSearching)
// //           ? TabBar(
// //               controller: _tabController,
// //               isScrollable: true,
// //               tabs: _navItems.map((item) => Tab(text: item['label'])).toList(),
// //             )
// //           : null,
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _tabController.dispose();
// //     _searchController.dispose();
// //     super.dispose();
// //   }
// // }

// // class SearchResultsWidget extends StatefulWidget {
// //   final String query;
// //   final AudioProvider audio;

// //   const SearchResultsWidget({
// //     super.key,
// //     required this.query,
// //     required this.audio,
// //   });

// //   @override
// //   State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
// // }

// // class _SearchResultsWidgetState extends State<SearchResultsWidget> {
// //   final Map<int, Uint8List?> _artworkCache = {};

// //   @override
// //   Widget build(BuildContext context) {
// //     final q = widget.query.toLowerCase();
// //     final isDark = Theme.of(context).brightness == Brightness.dark;
// //     final isLandscape =
// //         MediaQuery.of(context).orientation == Orientation.landscape;

// //     // 🔎 1. FILTRADO DE CANCIONES
// //     final songs = widget.audio.items.where((i) {
// //       return i.title.toLowerCase().contains(q) ||
// //           (i.artist ?? "").toLowerCase().contains(q) ||
// //           (i.album ?? "").toLowerCase().contains(q);
// //     }).toList();

// //     // 🔎 2. FILTRADO DE ÁLBUMES
// //     final albums = widget.audio.items
// //         .where((s) => (s.album ?? "").toLowerCase().contains(q))
// //         .map((s) => s.album ?? "")
// //         .toSet()
// //         .toList();

// //     // 🔎 3. FILTRADO DE ARTISTAS
// //     final artists = widget.audio.items
// //         .where((s) => (s.artist ?? "").toLowerCase().contains(q))
// //         .map((s) => s.artist ?? "")
// //         .toSet()
// //         .toList();

// //     // 🔎 4. FILTRADO DE GÉNEROS
// //     final genres = widget.audio.items
// //         .where(
// //           (s) =>
// //               (s.extras?['genre'] ?? "").toString().toLowerCase().contains(q),
// //         )
// //         .map((s) => (s.extras?['genre'] ?? "").toString())
// //         .where((g) => g.isNotEmpty)
// //         .toSet()
// //         .toList();

// //     // 🔎 5. FILTRADO DE CARPETAS (NUEVO)
// //     final folders = widget.audio.items
// //         .where(
// //           (s) =>
// //               (s.extras?['folder'] ?? "").toString().toLowerCase().contains(q),
// //         )
// //         .map((s) => (s.extras?['folder'] ?? "").toString())
// //         .where((f) => f.isNotEmpty)
// //         .toSet()
// //         .toList();

// //     return ListView(
// //       physics: const BouncingScrollPhysics(),
// //       children: [
// //         // --- SECCIÓN CANCIONES ---
// //         if (songs.isNotEmpty) ...[
// //           _sectionHeader(
// //             context,
// //             "Canciones (${songs.length})",
// //             Icons.library_music,
// //           ),
// //           ...songs.map((item) {
// //             final dynamic rawId = item.extras?['dbId'];
// //             final int songId = (rawId is int)
// //                 ? rawId
// //                 : int.tryParse(rawId?.toString() ?? '0') ?? 0;
// //             return _SongListTile(
// //               key: ValueKey(item.id),
// //               item: item,
// //               songId: songId,
// //               isDark: isDark,
// //               artworkCache: _artworkCache,
// //               onTap: () => widget.audio.play(item),
// //               onMenuPressed: () => _showSongMenu(context, item, isLandscape),
// //             );
// //           }),
// //         ],

// //         // --- SECCIÓN ÁLBUMES ---
// //         if (albums.isNotEmpty) ...[
// //           _sectionHeader(context, "Álbumes (${albums.length})", Icons.album),
// //           ...albums.map(
// //             (a) => ListTile(
// //               leading: Icon(
// //                 Icons.album,
// //                 color: isDark ? Colors.blueGrey : AppColors.accent,
// //               ),
// //               title: Text(a, style: _bodyStyle(context)),
// //               onTap: () {
// //                 final filtered = widget.audio.items
// //                     .where((s) => s.album == a)
// //                     .toList();
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (_) =>
// //                         AlbumDetailScreen(albumName: a, songs: filtered),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //         ],

// //         // --- SECCIÓN ARTISTAS ---
// //         if (artists.isNotEmpty) ...[
// //           _sectionHeader(context, "Artistas (${artists.length})", Icons.person),
// //           ...artists.map(
// //             (art) => ListTile(
// //               leading: Icon(
// //                 Icons.person,
// //                 color: isDark ? Colors.blueGrey : AppColors.accent,
// //               ),
// //               title: Text(art, style: _bodyStyle(context)),
// //               onTap: () {
// //                 final filtered = widget.audio.items
// //                     .where((s) => s.artist == art)
// //                     .toList();
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (_) =>
// //                         ArtistDetailScreen(artistName: art, songs: filtered),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //         ],

// //         // --- SECCIÓN GÉNEROS ---
// //         if (genres.isNotEmpty) ...[
// //           _sectionHeader(context, "Géneros (${genres.length})", Icons.category),
// //           ...genres.map(
// //             (g) => ListTile(
// //               leading: Icon(
// //                 Icons.category,
// //                 color: isDark ? Colors.blueGrey : AppColors.accent,
// //               ),
// //               title: Text(g, style: _bodyStyle(context)),
// //               onTap: () {
// //                 final filtered = widget.audio.items
// //                     .where((s) => s.extras?['genre'] == g)
// //                     .toList();
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (_) =>
// //                         GenreDetailScreen(genreName: g, songs: filtered),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //         ],

// //         // --- SECCIÓN CARPETAS (NUEVO) ---
// //         if (folders.isNotEmpty) ...[
// //           _sectionHeader(context, "Carpetas (${folders.length})", Icons.folder),
// //           ...folders.map(
// //             (f) => ListTile(
// //               leading: Icon(
// //                 Icons.folder,
// //                 color: isDark ? Colors.blueGrey : AppColors.accent,
// //               ),
// //               title: Text(f, style: _bodyStyle(context)),
// //               onTap: () {
// //                 final filtered = widget.audio.items
// //                     .where((s) => s.extras?['folder'] == f)
// //                     .toList();
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (_) =>
// //                         FolderDetailScreen(folderName: f, songs: filtered),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //         ],

// //         const SizedBox(height: 100),
// //       ],
// //     );
// //   }

// //   // --- MANTENIENDO TU LÓGICA DE MENÚ Y ESTILOS ---
// //   void _showSongMenu(BuildContext context, MediaItem song, bool isLandscape) {
// //     final audio = context.read<AudioProvider>();
// //     final isDark = Theme.of(context).brightness == Brightness.dark;

// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: isLandscape,
// //       builder: (_) => SafeArea(
// //         child: SingleChildScrollView(
// //           child: Wrap(
// //             children: [
// //               _menuTile(Icons.play_arrow, "Reproducir ahora", () {
// //                 Navigator.pop(context);
// //                 audio.play(song);
// //               }, isDark),
// //               _menuTile(Icons.queue_play_next, "Reproducir siguiente", () {
// //                 Navigator.pop(context);
// //                 audio.playNext(song);
// //               }, isDark),
// //               _menuTile(Icons.album, "Ir a álbum", () {
// //                 Navigator.pop(context);
// //                 final filtered = audio.items
// //                     .where((s) => s.album == song.album)
// //                     .toList();
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (_) => AlbumDetailScreen(
// //                       albumName: song.album ?? '',
// //                       songs: filtered,
// //                     ),
// //                   ),
// //                 );
// //               }, isDark),
// //               _menuTile(Icons.person, "Ir a artista", () {
// //                 Navigator.pop(context);
// //                 final filtered = audio.items
// //                     .where((s) => s.artist == song.artist)
// //                     .toList();
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (_) => ArtistDetailScreen(
// //                       artistName: song.artist ?? '',
// //                       songs: filtered,
// //                     ),
// //                   ),
// //                 );
// //               }, isDark),
// //               _menuTile(Icons.folder, "Ir a carpeta", () {
// //                 Navigator.pop(context);
// //                 final folder = song.extras?['folder'] ?? '';
// //                 final filtered = audio.items
// //                     .where((s) => s.extras?['folder'] == folder)
// //                     .toList();
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (_) =>
// //                         FolderDetailScreen(folderName: folder, songs: filtered),
// //                   ),
// //                 );
// //               }, isDark),
// //               _menuTile(Icons.playlist_add, "Añadir a playlist", () {
// //                 Navigator.pop(context);
// //                 _showPlaylistSelector(context, song);
// //               }, isDark),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   // (El resto de helpers: _showPlaylistSelector, _menuTile, _sectionHeader, _bodyStyle permanecen igual)
// //   void _showPlaylistSelector(BuildContext context, MediaItem song) {
// //     final audio = context.read<AudioProvider>();
// //     final playlists = audio.playlists.keys.toList();
// //     final isDark = Theme.of(context).brightness == Brightness.dark;

// //     showDialog(
// //       context: context,
// //       builder: (_) => AlertDialog(
// //         title: Text(
// //           "Selecciona playlist",
// //           style: isDark ? AppTextStyles.darkto : AppTextStyles.darkti,
// //         ),
// //         content: SizedBox(
// //           width: double.maxFinite,
// //           child: ListView.builder(
// //             shrinkWrap: true,
// //             itemCount: playlists.length,
// //             itemBuilder: (context, index) {
// //               final name = playlists[index];
// //               return ListTile(
// //                 leading: Icon(
// //                   Icons.queue_music,
// //                   color: isDark ? Colors.blueGrey : AppColors.secondary,
// //                 ),
// //                 title: Text(
// //                   name,
// //                   style: isDark ? AppTextStyles.darkto : AppTextStyles.darkti,
// //                 ),
// //                 onTap: () {
// //                   Navigator.pop(context);
// //                   audio.addToPlaylist(name, song);
// //                 },
// //               );
// //             },
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _menuTile(
// //     IconData icon,
// //     String text,
// //     VoidCallback onTap,
// //     bool isDark,
// //   ) {
// //     return ListTile(
// //       leading: Icon(icon, color: isDark ? Colors.blueGrey : AppColors.primary),
// //       title: Text(
// //         text,
// //         style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
// //       ),
// //       onTap: onTap,
// //     );
// //   }

// //   Widget _sectionHeader(BuildContext context, String text, IconData icon) {
// //     final isDark = Theme.of(context).brightness == Brightness.dark;
// //     return ListTile(
// //       leading: Icon(icon, color: isDark ? Colors.blueGrey : AppColors.accent),
// //       title: Text(
// //         text,
// //         style: Theme.of(context).brightness == Brightness.light
// //             ? AppTextStyles.subheadingLight
// //             : AppTextStyles.subheadingDark,
// //       ),
// //     );
// //   }

// //   TextStyle _bodyStyle(BuildContext context) =>
// //       Theme.of(context).brightness == Brightness.light
// //       ? AppTextStyles.bodyLight
// //       : AppTextStyles.bodyDark;
// // }

// // // (La clase _SongListTile permanece igual para el rendimiento)
// // class _SongListTile extends StatelessWidget {
// //   final MediaItem item;
// //   final int songId;
// //   final bool isDark;
// //   final VoidCallback onTap;
// //   final VoidCallback onMenuPressed;
// //   final Map<int, Uint8List?> artworkCache;

// //   const _SongListTile({
// //     super.key,
// //     required this.item,
// //     required this.songId,
// //     required this.isDark,
// //     required this.onTap,
// //     required this.onMenuPressed,
// //     required this.artworkCache,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     if (artworkCache.containsKey(songId))
// //       return _buildTile(artworkCache[songId]);

// //     return FutureBuilder<Uint8List?>(
// //       future: songId == 0
// //           ? Future.value(null)
// //           : OnAudioQuery().queryArtwork(
// //               songId,
// //               ArtworkType.AUDIO,
// //               format: ArtworkFormat.JPEG,
// //               size: 150,
// //             ),
// //       builder: (context, snapshot) {
// //         if (snapshot.connectionState == ConnectionState.done) {
// //           artworkCache[songId] = snapshot.data;
// //           return _buildTile(snapshot.data);
// //         }
// //         return _buildTile(null);
// //       },
// //     );
// //   }

// //   Widget _buildTile(Uint8List? imageBytes) {
// //     return ListTile(
// //       leading: CircleAvatar(
// //         backgroundColor: isDark
// //             ? Colors.white10
// //             : AppColors.primary.withOpacity(0.05),
// //         backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
// //         child: imageBytes == null
// //             ? Icon(
// //                 Icons.music_note,
// //                 color: isDark ? Colors.blueGrey : AppColors.primary,
// //               )
// //             : null,
// //       ),
// //       title: Text(
// //         item.title,
// //         maxLines: 1,
// //         overflow: TextOverflow.ellipsis,
// //         style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
// //       ),
// //       subtitle: Text(
// //         item.artist ?? 'Desconocido',
// //         maxLines: 1,
// //         overflow: TextOverflow.ellipsis,
// //         style: isDark ? AppTextStyles.captionDark : AppTextStyles.captionLight,
// //       ),
// //       onTap: onTap,
// //       trailing: IconButton(
// //         icon: Icon(
// //           Icons.more_vert,
// //           color: isDark ? Colors.blueGrey : AppColors.secondary,
// //         ),
// //         onPressed: onMenuPressed,
// //       ),
// //     );
// //   }
// // }
// import 'dart:typed_data';

// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:provider/provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:pzplayer/core/audio/audio_provider.dart';

// // Importaciones de tu proyecto
// import 'package:pzplayer/core/theme/app_colors.dart';
// import 'package:pzplayer/core/theme/app_text_styles.dart';
// import 'package:pzplayer/ui/screens/album.dart';
// import 'package:pzplayer/ui/screens/artista.dart';
// import 'package:pzplayer/ui/screens/folder.dart';
// import 'package:pzplayer/ui/screens/genre.dart';
// import 'package:pzplayer/ui/screens/library.dart';
// import 'package:pzplayer/ui/screens/playlist.dart';
// import 'package:pzplayer/ui/widgets/album_detalle.dart';
// import 'package:pzplayer/ui/widgets/artista_detalle.dart';
// import 'package:pzplayer/ui/widgets/folder_detalle.dart';
// import 'package:pzplayer/ui/widgets/genre_detalle.dart';
// import 'package:pzplayer/ui/widgets/lateral.dart';
// import 'package:pzplayer/ui/widgets/player_controls.dart';

// import 'package:shared_preferences/shared_preferences.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final TextEditingController _searchController = TextEditingController();
//   String _query = "";
//   bool _isSearching = false;
//   int _selectedIndex = 0;

//   // ESTADOS DE CONTROL
//   bool _isLoading = true;
//   bool _permissionsGranted = false;
//   bool _tutorialSeen = false;

//   final List<Map<String, dynamic>> _navItems = [
//     {
//       'label': "Biblioteca",
//       'icon': Icons.library_music,
//       'widget': const LibraryScreen(),
//     },
//     {
//       'label': "Álbum",
//       'icon': Icons.album,
//       'widget': const AlbumScreen(albumName: '', songs: []),
//     },
//     {
//       'label': "Artista",
//       'icon': Icons.person,
//       'widget': const ArtistScreen(artistName: '', songs: []),
//     },
//     {
//       'label': "Género",
//       'icon': Icons.style,
//       'widget': const GenreScreen(genreName: '', songs: []),
//     },
//     {
//       'label': "Playlist",
//       'icon': Icons.playlist_play,
//       'widget': const PlaylistScreen(playlistName: '', songs: []),
//     },
//     {
//       'label': "Carpeta",
//       'icon': Icons.folder,
//       'widget': const FolderScreen(folderName: '', songs: []),
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: _navItems.length, vsync: this);
//     _tabController.addListener(() {
//       if (!_tabController.indexIsChanging) {
//         setState(() => _selectedIndex = _tabController.index);
//       }
//     });

//     _checkPrivacyStatus();
//   }

//   Future<void> _checkTutorialStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     bool seen = prefs.getBool('tutorial_seen') ?? false;
//     if (!seen) {
//       await Future.delayed(const Duration(milliseconds: 500));
//       if (mounted) {
//         _showTutorialSteps().then((_) {
//           prefs.setBool('tutorial_seen', true);
//         });
//       }
//     }
//   }

//   Future<void> _showTutorialSteps() async {
//     final steps = [
//       {
//         "icon": Icons.menu,
//         "title": "Navegación",
//         "desc":
//             "Desliza el dedo o usa el menú lateral para cambiar entre Biblioteca, Álbumes, Artistas, etc.",
//       },
//       {
//         "icon": Icons.play_circle_fill,
//         "title": "Reproducción",
//         "desc":
//             "Toca cualquier canción para reproducirla. Usa el menú (tres puntos) para añadir a la cola o ver detalles.",
//       },
//       {
//         "icon": Icons.headphones,
//         "title": "Mini-Reproductor",
//         "desc":
//             "Cuando suena música, toca la barra inferior para abrir el reproductor completo y el ecualizador.",
//       },
//     ];

//     for (int i = 0; i < steps.length; i++) {
//       if (!mounted) return;
//       bool shouldContinue =
//           await showDialog<bool>(
//             context: context,
//             barrierDismissible: false,
//             builder: (context) => _TutorialStepDialog(
//               step: steps[i],
//               currentStep: i + 1,
//               totalSteps: steps.length,
//               isLast: i == steps.length - 1,
//             ),
//           ) ??
//           false;

//       if (!shouldContinue) break;
//     }
//   }

//   Future<void> _checkPrivacyStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     bool accepted = prefs.getBool('privacy_accepted') ?? false;

//     if (!accepted) {
//       setState(() => _isLoading = false);
//       WidgetsBinding.instance.addPostFrameCallback((_) => _showPrivacyDialog());
//     } else {
//       _initAppPermissions();
//     }
//   }

//   void _showPrivacyDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Row(
//           children: [
//             Icon(Icons.privacy_tip, color: Colors.blue),
//             SizedBox(width: 10),
//             Text("Aviso de Privacidad"),
//           ],
//         ),
//         content: const SingleChildScrollView(
//           child: Text(
//             "PZ Player valora tu privacidad. Para ofrecerte la mejor experiencia, "
//             "necesitamos acceder a tus archivos de audio locales. \n\n"
//             "• No recolectamos datos personales.\n"
//             "• Tus archivos no se suben a ningún servidor.\n"
//             "• Los permisos de notificaciones son solo para el control de reproducción.\n\n"
//             "Al presionar 'Aceptar', confirmas que estás de acuerdo con el tratamiento de datos local.",
//             style: TextStyle(fontSize: 14),
//           ),
//         ),
//         actions: [
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             onPressed: () async {
//               final prefs = await SharedPreferences.getInstance();
//               await prefs.setBool('privacy_accepted', true);
//               Navigator.pop(context);
//               _initAppPermissions();
//             },
//             child: const Text(
//               "ACEPTAR Y CONTINUAR",
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _initAppPermissions() async {
//     setState(() => _isLoading = true);

//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.audio,
//       Permission.storage,
//       Permission.notification,
//     ].request();

//     bool granted =
//         (statuses[Permission.audio]!.isGranted ||
//         statuses[Permission.storage]!.isGranted);

//     if (mounted) {
//       if (granted) {
//         await context.read<AudioProvider>().loadLibrary();
//         setState(() {
//           _permissionsGranted = true;
//           _isLoading = false;
//         });
//         _checkTutorialStatus();
//       } else {
//         setState(() {
//           _permissionsGranted = false;
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     if (!_permissionsGranted) {
//       return _buildPermissionErrorScreen();
//     }

//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final bool isTablet = constraints.maxWidth > 600;
//         final bool isLandscape = constraints.maxWidth > constraints.maxHeight;

//         return Scaffold(
//           drawer: const MainDrawer(),
//           appBar: _buildAppBar(context, isDark, isTablet, isLandscape),
//           body: Row(
//             children: [
//               if (isTablet && !_isSearching)
//                 _buildNavigationRail(isDark, constraints, isLandscape),
//               Expanded(
//                 child: _isSearching && _query.isNotEmpty
//                     ? SearchResultsWidget(
//                         query: _query,
//                         audio: context.read<AudioProvider>(),
//                       )
//                     : TabBarView(
//                         controller: _tabController,
//                         physics: isTablet
//                             ? const NeverScrollableScrollPhysics()
//                             : const BouncingScrollPhysics(),
//                         children: _navItems
//                             .map<Widget>((item) => item['widget'])
//                             .toList(),
//                       ),
//               ),
//             ],
//           ),
//           bottomNavigationBar: MiniPlayer(),
//           //  const SafeArea(child: MiniPlayer()),
//         );
//       },
//     );
//   }

//   Widget _buildPermissionErrorScreen() {
//     return Scaffold(
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(30.0),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(
//                   Icons.music_off_outlined,
//                   size: 80,
//                   color: Colors.orangeAccent,
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   "Sin acceso a la música",
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   "Debes permitir el acceso a tus archivos para que PZ Player pueda reproducir tus canciones.",
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 30),
//                 ElevatedButton(
//                   onPressed: _initAppPermissions,
//                   child: const Text("INTENTAR DE NUEVO"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // 👇 MEJORA: Menú lateral adaptativo
//   Widget _buildNavigationRail(
//     bool isDark,
//     BoxConstraints landscapeConstraints,
//     bool isLandscape,
//   ) {
//     // En landscape, forzamos que sea compacto
//     final bool useListView =
//         isLandscape ||
//         (landscapeConstraints.maxWidth > 600 &&
//             landscapeConstraints.maxWidth <= 900);

//     if (!useListView) {
//       // Tablet grande: Menú estándar
//       return SizedBox(
//         width: 249,
//         child: NavigationRail(
//           backgroundColor: Colors.transparent,
//           extended: true,
//           selectedIndex: _selectedIndex,
//           selectedLabelTextStyle: TextStyle(
//             color: isDark ? Colors.white : Colors.black87,
//             fontWeight: FontWeight.bold,
//             fontSize: 13,
//           ),
//           unselectedLabelTextStyle: TextStyle(
//             color: isDark ? Colors.white54 : Colors.black54,
//             fontSize: 13,
//           ),
//           selectedIconTheme: IconThemeData(
//             color: isDark ? Colors.white : Colors.black87,
//           ),
//           onDestinationSelected: (index) {
//             setState(() => _selectedIndex = index);
//             _tabController.animateTo(index);
//           },
//           destinations: _navItems
//               .map(
//                 (item) => NavigationRailDestination(
//                   icon: Icon(item['icon']),
//                   label: Text(item['label']),
//                 ),
//               )
//               .toList(),
//         ),
//       );
//     }

//     // 👇 LISTVIEW HORIZONTAL
//     // Si es landscape, reducimos el ancho porque no habrá texto
//     return SizedBox(
//       width: isLandscape ? 56 : 65,
//       child: ListView(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         // Pasamos isLandscape para ocultar texto si es necesario
//         children: _buildNavigationListView(context, isDark, isLandscape),
//       ),
//     );
//   }

//   // 👇 METODO AUXILIAR PARA LISTA DE NAVEGACIÓN
//   // Agregamos el parámetro bool isLandscape
//   List<Widget> _buildNavigationListView(
//     BuildContext context,
//     bool isDark,
//     bool isLandscape,
//   ) {
//     return _navItems.map((item) {
//       int index = _navItems.indexOf(item);

//       // Lógica correcta de selección: el índice actual coincide con el del item
//       bool isSelected = _selectedIndex == index;

//       final color = isSelected
//           ? (isDark
//                 ? Colors.blueGrey
//                 : AppColors.primary) // Color primario si está seleccionado
//           : (isDark ? Colors.white38 : Colors.black54); // Gris si no

//       return ListTile(
//         dense: true,
//         selected: isSelected,
//         selectedColor: Colors.transparent,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

//         // 👇 CAMBIO PRINCIPAL: Ocultar título si está en landscape
//         title: isLandscape
//             ? null
//             : Text(
//                 item['label'],
//                 style: TextStyle(
//                   color: color,
//                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                   fontSize: 10,
//                 ),
//               ),

//         leading: Icon(item['icon'], color: color, size: 22),
//         onTap: () {
//           setState(() {
//             if (_selectedIndex != index) {
//               _selectedIndex = index;
//               _tabController.animateTo(index);
//             }
//           });
//         },
//       );
//     }).toList();
//   }

//   PreferredSizeWidget _buildAppBar(
//     BuildContext context,
//     bool isDark,
//     bool isTablet,
//     bool isLandscape,
//   ) {
//     // 👇 En landscape en móvil, ocultamos el título para ganar espacio si hay tabs
//     final bool hideTitle = (!isTablet && isLandscape);

//     return AppBar(
//       leading: Builder(
//         builder: (context) => IconButton(
//           icon: Icon(_isSearching ? Icons.music_note : Icons.menu),
//           onPressed: () =>
//               _isSearching ? null : Scaffold.of(context).openDrawer(),
//         ),
//       ),
//       title: _isSearching
//           ? TextField(
//               autofocus: true,
//               onChanged: (val) => setState(() => _query = val),
//               style: TextStyle(color: isDark ? Colors.white : Colors.black),
//               decoration: InputDecoration(
//                 hintText: "Buscar...",
//                 hintStyle: TextStyle(
//                   color: isDark ? Colors.white54 : Colors.black54,
//                 ),
//                 border: InputBorder.none,
//               ),
//             )
//           : hideTitle
//           ? null
//           : const Text("PZ Player"), // 👇 Ocultar título en landscape móvil
//       actions: [
//         IconButton(
//           icon: Icon(_isSearching ? Icons.close : Icons.search),
//           onPressed: () => setState(() {
//             _isSearching = !_isSearching;
//             if (!_isSearching) _query = "";
//           }),
//         ),
//       ],
//       bottom: (!isTablet && !_isSearching)
//           ? TabBar(
//               controller: _tabController,
//               isScrollable: true,
//               indicatorColor: isDark ? Colors.white : Colors.black,
//               labelColor: isDark ? Colors.white : Colors.black,
//               unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
//               labelStyle: TextStyle(
//                 fontSize: isLandscape ? 12 : 14,
//               ), // 👇 Texto más pequeño en landscape
//               tabs: _navItems.map((item) => Tab(text: item['label'])).toList(),
//             )
//           : null,
//     );
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }
// }

// // --- WIDGET DE TUTORIAL PERSONALIZADO ---
// class _TutorialStepDialog extends StatelessWidget {
//   final Map<String, dynamic> step;
//   final int currentStep;
//   final int totalSteps;
//   final bool isLast;

//   const _TutorialStepDialog({
//     super.key,
//     required this.step,
//     required this.currentStep,
//     required this.totalSteps,
//     required this.isLast,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(step['icon'], size: 60, color: Colors.deepPurple),
//             const SizedBox(height: 20),
//             Text(
//               "${step['title']} ($currentStep/$totalSteps)",
//               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               step['desc'],
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 15,
//                 color: isDark ? Colors.white70 : Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 25),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: const Text("Omitir"),
//                 ),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.deepPurple,
//                   ),
//                   onPressed: () => Navigator.pop(context, true),
//                   child: Text(isLast ? "Finalizar" : "Siguiente"),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class SearchResultsWidget extends StatefulWidget {
//   final String query;
//   final AudioProvider audio;

//   const SearchResultsWidget({
//     super.key,
//     required this.query,
//     required this.audio,
//   });

//   @override
//   State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
// }

// class _SearchResultsWidgetState extends State<SearchResultsWidget> {
//   final Map<int, Uint8List?> _artworkCache = {};

//   @override
//   Widget build(BuildContext context) {
//     final q = widget.query.toLowerCase();
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final isLandscape =
//         MediaQuery.of(context).orientation == Orientation.landscape;

//     // 🔎 FILTRADO
//     final songs = widget.audio.items.where((i) {
//       return i.title.toLowerCase().contains(q) ||
//           (i.artist ?? "").toLowerCase().contains(q) ||
//           (i.album ?? "").toLowerCase().contains(q);
//     }).toList();

//     final albums = widget.audio.items
//         .where((s) => (s.album ?? "").toLowerCase().contains(q))
//         .map((s) => s.album ?? "")
//         .toSet()
//         .toList();

//     final artists = widget.audio.items
//         .where((s) => (s.artist ?? "").toLowerCase().contains(q))
//         .map((s) => s.artist ?? "")
//         .toSet()
//         .toList();

//     final genres = widget.audio.items
//         .where(
//           (s) =>
//               (s.extras?['genre'] ?? "").toString().toLowerCase().contains(q),
//         )
//         .map((s) => (s.extras?['genre'] ?? "").toString())
//         .where((g) => g.isNotEmpty)
//         .toSet()
//         .toList();

//     final folders = widget.audio.items
//         .where(
//           (s) =>
//               (s.extras?['folder'] ?? "").toString().toLowerCase().contains(q),
//         )
//         .map((s) => (s.extras?['folder'] ?? "").toString())
//         .where((f) => f.isNotEmpty)
//         .toSet()
//         .toList();

//     return ListView(
//       physics: const BouncingScrollPhysics(),
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).padding.bottom + 80,
//       ),
//       children: [
//         // 👇 MODIFICADO: Enviamos icono, título y conteo
//         if (songs.isNotEmpty)
//           _sectionHeader(
//             context,
//             "Canciones",
//             songs.length,
//             Icons.library_music,
//           ),

//         ...songs.map((item) {
//           final dynamic rawId = item.extras?['dbId'];
//           final int songId = (rawId is int)
//               ? rawId
//               : int.tryParse(rawId?.toString() ?? '0') ?? 0;
//           return _SongListTile(
//             key: ValueKey(item.id),
//             item: item,
//             songId: songId,
//             isDark: isDark,
//             artworkCache: _artworkCache,
//             onTap: () => widget.audio.play(item),
//             onMenuPressed: () => _showSongMenu(context, item, isLandscape),
//           );
//         }),

//         // 👇 MODIFICADO: Enviamos icono, título y conteo
//         if (albums.isNotEmpty)
//           _sectionHeader(context, "Álbumes", albums.length, Icons.album),

//         ...albums.map(
//           (a) => ListTile(
//             leading: Icon(
//               Icons.album,
//               color: isDark ? Colors.blueGrey : AppColors.accent,
//             ),
//             title: Text(a, style: _bodyStyle(context)),
//             onTap: () {
//               final filtered = widget.audio.items
//                   .where((s) => s.album == a)
//                   .toList();
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) =>
//                       AlbumDetailScreen(albumName: a, songs: filtered),
//                 ),
//               );
//             },
//           ),
//         ),

//         // 👇 MODIFICADO: Enviamos icono, título y conteo
//         if (artists.isNotEmpty)
//           _sectionHeader(context, "Artistas", artists.length, Icons.person),

//         ...artists.map(
//           (art) => ListTile(
//             leading: Icon(
//               Icons.person,
//               color: isDark ? Colors.blueGrey : AppColors.accent,
//             ),
//             title: Text(art, style: _bodyStyle(context)),
//             onTap: () {
//               final filtered = widget.audio.items
//                   .where((s) => s.artist == art)
//                   .toList();
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) =>
//                       ArtistDetailScreen(artistName: art, songs: filtered),
//                 ),
//               );
//             },
//           ),
//         ),

//         // 👇 MODIFICADO: Enviamos icono, título y conteo
//         if (genres.isNotEmpty)
//           _sectionHeader(context, "Géneros", genres.length, Icons.category),

//         ...genres.map(
//           (g) => ListTile(
//             leading: Icon(
//               Icons.category,
//               color: isDark ? Colors.blueGrey : AppColors.accent,
//             ),
//             title: Text(g, style: _bodyStyle(context)),
//             onTap: () {
//               final filtered = widget.audio.items
//                   .where((s) => s.extras?['genre'] == g)
//                   .toList();
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) =>
//                       GenreDetailScreen(genreName: g, songs: filtered),
//                 ),
//               );
//             },
//           ),
//         ),

//         // 👇 MODIFICADO: Enviamos icono, título y conteo
//         if (folders.isNotEmpty)
//           _sectionHeader(context, "Carpetas", folders.length, Icons.folder),

//         ...folders.map(
//           (f) => ListTile(
//             leading: Icon(
//               Icons.folder,
//               color: isDark ? Colors.blueGrey : AppColors.accent,
//             ),
//             title: Text(f, style: _bodyStyle(context)),
//             onTap: () {
//               final filtered = widget.audio.items
//                   .where((s) => s.extras?['folder'] == f)
//                   .toList();
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) =>
//                       FolderDetailScreen(folderName: f, songs: filtered),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   void _showSongMenu(BuildContext context, MediaItem song, bool isLandscape) {
//     final audio = context.read<AudioProvider>();
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: isLandscape,
//       backgroundColor: isDark ? Colors.grey[900] : Colors.white,
//       builder: (_) => SafeArea(
//         child: SingleChildScrollView(
//           child: Wrap(
//             children: [
//               _menuTile(Icons.play_arrow, "Reproducir ahora", () {
//                 Navigator.pop(context);
//                 audio.play(song);
//               }, isDark),
//               _menuTile(Icons.queue_play_next, "Reproducir siguiente", () {
//                 Navigator.pop(context);
//                 audio.playNext(song);
//               }, isDark),
//               _menuTile(Icons.album, "Ir a álbum", () {
//                 Navigator.pop(context);
//                 final filtered = audio.items
//                     .where((s) => s.album == song.album)
//                     .toList();
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => AlbumDetailScreen(
//                       albumName: song.album ?? '',
//                       songs: filtered,
//                     ),
//                   ),
//                 );
//               }, isDark),
//               _menuTile(Icons.person, "Ir a artista", () {
//                 Navigator.pop(context);
//                 final filtered = audio.items
//                     .where((s) => s.artist == song.artist)
//                     .toList();
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => ArtistDetailScreen(
//                       artistName: song.artist ?? '',
//                       songs: filtered,
//                     ),
//                   ),
//                 );
//               }, isDark),
//               _menuTile(Icons.folder, "Ir a carpeta", () {
//                 Navigator.pop(context);
//                 final folder = song.extras?['folder'] ?? '';
//                 final filtered = audio.items
//                     .where((s) => s.extras?['folder'] == folder)
//                     .toList();
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) =>
//                         FolderDetailScreen(folderName: folder, songs: filtered),
//                   ),
//                 );
//               }, isDark),
//               _menuTile(Icons.playlist_add, "Añadir a playlist", () {
//                 Navigator.pop(context);
//                 _showPlaylistSelector(context, song);
//               }, isDark),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showPlaylistSelector(BuildContext context, MediaItem song) {
//     final audio = context.read<AudioProvider>();
//     final playlists = audio.playlists.keys.toList();
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: isDark ? Colors.grey[900] : Colors.white,
//         title: Text(
//           "Selecciona playlist",
//           style: isDark
//               ? AppTextStyles.subheadingDark
//               : AppTextStyles.subheadingLight,
//         ),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: playlists.length,
//             itemBuilder: (context, index) {
//               final name = playlists[index];
//               return ListTile(
//                 leading: Icon(
//                   Icons.queue_music,
//                   color: isDark ? Colors.blueGrey : AppColors.secondary,
//                 ),
//                 title: Text(
//                   name,
//                   style: isDark
//                       ? AppTextStyles.bodyDark
//                       : AppTextStyles.bodyLight,
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   audio.addToPlaylist(name, song);
//                 },
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _menuTile(
//     IconData icon,
//     String text,
//     VoidCallback onTap,
//     bool isDark,
//   ) {
//     return ListTile(
//       leading: Icon(icon, color: isDark ? Colors.blueGrey : AppColors.primary),
//       title: Text(
//         text,
//         style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
//       ),
//       onTap: onTap,
//     );
//   }

//   // 👇 MODIFICADO: Icono + Título en la línea superior, Número + "disponibles" en la inferior
//   Widget _sectionHeader(
//     BuildContext context,
//     String title,
//     int count,
//     IconData icon,
//   ) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return ListTile(
//       contentPadding: const EdgeInsets.symmetric(
//         horizontal: 16.0,
//         vertical: 4.0,
//       ),
//       // Mostramos el icono aquí
//       leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black87),
//       // Título con el nombre
//       title: Text(
//         title,
//         style: TextStyle(
//           color: isDark ? Colors.white : Colors.black87,
//           fontWeight: FontWeight.bold,
//           fontSize: 16,
//         ),
//       ),
//       // Subtítulo con el número "disponibles"
//       subtitle: Text(
//         "$count disponibles",
//         style: TextStyle(
//           color: isDark ? Colors.white54 : Colors.black54,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }

//   TextStyle _bodyStyle(BuildContext context) =>
//       Theme.of(context).brightness == Brightness.light
//       ? AppTextStyles.bodyLight
//       : AppTextStyles.bodyDark;
// }

// class _SongListTile extends StatelessWidget {
//   final MediaItem item;
//   final int songId;
//   final bool isDark;
//   final VoidCallback onTap;
//   final VoidCallback onMenuPressed;
//   final Map<int, Uint8List?> artworkCache;

//   const _SongListTile({
//     super.key,
//     required this.item,
//     required this.songId,
//     required this.isDark,
//     required this.onTap,
//     required this.onMenuPressed,
//     required this.artworkCache,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (artworkCache.containsKey(songId))
//       return _buildTile(artworkCache[songId]);

//     return FutureBuilder<Uint8List?>(
//       future: songId == 0
//           ? Future.value(null)
//           : OnAudioQuery().queryArtwork(
//               songId,
//               ArtworkType.AUDIO,
//               format: ArtworkFormat.JPEG,
//               size: 150,
//             ),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.done) {
//           artworkCache[songId] = snapshot.data;
//           return _buildTile(snapshot.data);
//         }
//         return _buildTile(null);
//       },
//     );
//   }

//   Widget _buildTile(Uint8List? imageBytes) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundColor: isDark
//             ? Colors.white10
//             : AppColors.primary.withOpacity(0.05),
//         backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
//         child: imageBytes == null
//             ? Icon(
//                 Icons.music_note,
//                 color: isDark ? Colors.blueGrey : AppColors.primary,
//               )
//             : null,
//       ),
//       title: Text(
//         item.title,
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//         style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
//       ),
//       subtitle: Text(
//         item.artist ?? 'Desconocido',
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//         style: isDark ? AppTextStyles.captionDark : AppTextStyles.captionLight,
//       ),
//       onTap: onTap,
//       trailing: IconButton(
//         icon: Icon(
//           Icons.more_vert,
//           color: isDark ? Colors.blueGrey : AppColors.secondary,
//         ),
//         onPressed: onMenuPressed,
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';

// import 'package:provider/provider.dart';
// import 'package:pzplayer/core/audio/audio_provider.dart';

// // Importaciones de tu proyecto
// import 'package:pzplayer/ui/screens/album.dart';
// import 'package:pzplayer/ui/screens/artista.dart';
// import 'package:pzplayer/ui/screens/folder.dart';
// import 'package:pzplayer/ui/screens/genre.dart';
// import 'package:pzplayer/ui/screens/library.dart';
// import 'package:pzplayer/ui/screens/playlist.dart';

// import 'package:pzplayer/ui/widgets/lateral.dart'; // MainDrawer
// import 'package:pzplayer/ui/widgets/player_controls.dart';
// import 'package:pzplayer/ui/widgets/utilidades.dart';

// import 'package:shared_preferences/shared_preferences.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final TextEditingController _searchController = TextEditingController();
//   String _query = "";
//   bool _isSearching = false;
//   int _selectedIndex = 0;

//   // ESTADOS DE CONTROL
//   // Ya no necesitamos _permissionsGranted ni _isLoading para permisos aquí
//   // Solo necesitamos verificar si ya cargamos la biblioteca una vez si lo deseas,
//   // pero asumiremos que el Provider maneja el estado.

//   final List<Map<String, dynamic>> _navItems = [
//     {
//       'label': "Biblioteca",
//       'icon': Icons.library_music,
//       'widget': const LibraryScreen(),
//     },
//     {
//       'label': "Álbum",
//       'icon': Icons.album,
//       'widget': const AlbumScreen(albumName: '', songs: []),
//     },
//     {
//       'label': "Artista",
//       'icon': Icons.person,
//       'widget': const ArtistScreen(artistName: '', songs: []),
//     },
//     {
//       'label': "Género",
//       'icon': Icons.style,
//       'widget': GenreScreen(genreName: '', songs: []),
//     },
//     {
//       'label': "Playlist",
//       'icon': Icons.playlist_play,
//       'widget': const PlaylistScreen(playlistName: '', songs: []),
//     },
//     {
//       'label': "Carpeta",
//       'icon': Icons.folder,
//       'widget': const FolderScreen(folderName: '', songs: []),
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: _navItems.length, vsync: this);
//     _tabController.addListener(() {
//       if (!_tabController.indexIsChanging) {
//         setState(() => _selectedIndex = _tabController.index);
//       }
//     });

//     // Al iniciar, verificamos el tutorial.
//     // La carga de datos del AudioProvider debería ocurrir en IntroScreen o al
//     // acceder al provider por primera vez, pero si necesitas asegurarte aquí:
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkTutorialStatus();
//     });
//   }

//   Future<void> _checkTutorialStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     bool seen = prefs.getBool('tutorial_seen') ?? false;

//     // Solo mostrar tutorial si es la primera vez
//     if (!seen) {
//       // Pequeño delay para que la pantalla cargue suavemente
//       await Future.delayed(const Duration(milliseconds: 500));
//       if (mounted) {
//         _showTutorialSteps().then((_) {
//           prefs.setBool('tutorial_seen', true);
//         });
//       }
//     }
//   }

//   Future<void> _showTutorialSteps() async {
//     final steps = [
//       {
//         "icon": Icons.menu,
//         "title": "Navegación",
//         "desc":
//             "Desliza el dedo o usa el menú lateral para cambiar entre Biblioteca, Álbumes, Artistas, etc.",
//       },
//       {
//         "icon": Icons.play_circle_fill,
//         "title": "Reproducción",
//         "desc":
//             "Toca cualquier canción para reproducirla. Usa el menú (tres puntos) para añadir a la cola o ver detalles.",
//       },
//       {
//         "icon": Icons.headphones,
//         "title": "Mini-Reproductor",
//         "desc":
//             "Cuando suena música, toca la barra inferior para abrir el reproductor completo y el ecualizador.",
//       },
//     ];

//     for (int i = 0; i < steps.length; i++) {
//       if (!mounted) return;
//       bool shouldContinue =
//           await showDialog<bool>(
//             context: context,
//             barrierDismissible: false,
//             builder: (context) => _TutorialStepDialog(
//               step: steps[i],
//               currentStep: i + 1,
//               totalSteps: steps.length,
//               isLast: i == steps.length - 1,
//             ),
//           ) ??
//           false;

//       if (!shouldContinue) break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final bool isTablet = constraints.maxWidth > 600;
//         final bool isLandscape = constraints.maxWidth > constraints.maxHeight;

//         return Scaffold(
//           // ✅ DRAWER: ACTIVO SIEMPRE (Móvil y Tablet)
//           drawer: const MainDrawer(),

//           appBar: _buildAppBar(context, isDark, isTablet, isLandscape),

//           body: Row(
//             children: [
//               // ✅ SIDEBAR: ACTIVO SOLO EN TABLET
//               if (isTablet) _buildCustomSidebar(isDark),

//               Expanded(
//                 child: _isSearching && _query.isNotEmpty
//                     ? SearchResultsWidget(
//                         query: _query,
//                         audio: context.read<AudioProvider>(),
//                       )
//                     : TabBarView(
//                         controller: _tabController,
//                         physics: isTablet
//                             ? const NeverScrollableScrollPhysics()
//                             : const BouncingScrollPhysics(),
//                         children: _navItems
//                             .map<Widget>((item) => item['widget'])
//                             .toList(),
//                       ),
//               ),
//             ],
//           ),
//           bottomNavigationBar: MiniPlayer(),
//         );
//       },
//     );
//   }

//   // ✅ SIDEBAR PERSONALIZADO (Solo Iconos en Tablet)
//   Widget _buildCustomSidebar(bool isDark) {
//     const double sidebarWidth = 80.0;

//     return Container(
//       width: sidebarWidth,
//       decoration: BoxDecoration(
//         color: isDark ? Colors.black12 : Colors.grey[100],
//         border: Border(
//           right: BorderSide(
//             color: isDark ? Colors.white10 : Colors.black12,
//             width: 1,
//           ),
//         ),
//       ),
//       child: ListView(
//         padding: const EdgeInsets.symmetric(vertical: 20),
//         children: _navItems.map((item) {
//           int index = _navItems.indexOf(item);
//           bool isSelected = _selectedIndex == index;

//           final Color itemColor = isSelected
//               ? (isDark ? Colors.white : Colors.black)
//               : (isDark ? Colors.white54 : Colors.black54);

//           return InkWell(
//             onTap: () {
//               setState(() {
//                 _selectedIndex = index;
//               });
//               _tabController.animateTo(index);
//             },
//             child: Container(
//               color: isSelected
//                   ? (isDark ? Colors.white10 : Colors.black.withOpacity(0.05))
//                   : Colors.transparent,
//               height: 80,
//               child: Icon(item['icon'], color: itemColor, size: 62),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar(
//     BuildContext context,
//     bool isDark,
//     bool isTablet,
//     bool isLandscape,
//   ) {
//     // Ocultar título solo en móvil apaisado
//     final bool hideTitle = (!isTablet && isLandscape);

//     return AppBar(
//       elevation: 0,
//       // ✅ LEADING: ACTIVO SIEMPRE (Para abrir el Drawer en cualquier dispositivo)
//       leading: Builder(
//         builder: (context) => IconButton(
//           icon: Icon(_isSearching ? Icons.music_note : Icons.menu),
//           onPressed: () =>
//               _isSearching ? null : Scaffold.of(context).openDrawer(),
//         ),
//       ),
//       title: _isSearching
//           ? TextField(
//               autofocus: true,
//               onChanged: (val) => setState(() => _query = val),
//               style: TextStyle(color: isDark ? Colors.white : Colors.black),
//               decoration: InputDecoration(
//                 hintText: "Buscar...",
//                 hintStyle: TextStyle(
//                   color: isDark ? Colors.white54 : Colors.black54,
//                 ),
//                 border: InputBorder.none,
//               ),
//             )
//           : hideTitle
//           ? null
//           : const Text("PZ Player"),
//       actions: [
//         IconButton(
//           icon: Icon(_isSearching ? Icons.close : Icons.search),
//           onPressed: () => setState(() {
//             _isSearching = !_isSearching;
//             if (!_isSearching) _query = "";
//           }),
//         ),
//       ],
//       bottom: isTablet
//           ? null
//           : TabBar(
//               dividerHeight: 0.1,
//               controller: _tabController,
//               isScrollable: true,
//               indicatorColor: isDark ? Colors.white : Colors.black,
//               labelColor: isDark ? Colors.white : Colors.black,
//               unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
//               labelStyle: TextStyle(fontSize: isLandscape ? 12 : 14),
//               tabs: _navItems.map((item) => Tab(text: item['label'])).toList(),
//             ),
//     );
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }
// }

// class _TutorialStepDialog extends StatelessWidget {
//   final Map<String, dynamic> step;
//   final int currentStep;
//   final int totalSteps;
//   final bool isLast;

//   const _TutorialStepDialog({
//     required this.step,
//     required this.currentStep,
//     required this.totalSteps,
//     required this.isLast,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return Dialog(
//       // ✅ Dark Mode: Fondo adaptativo al tema de la app
//       backgroundColor: theme.dialogBackgroundColor,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(step['icon'], size: 60, color: Colors.deepPurple),
//             const SizedBox(height: 20),
//             Text(
//               "${step['title']} ($currentStep/$totalSteps)",
//               // ✅ Estilo: Usa el título grande del tema
//               style:
//                   theme.textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ) ??
//                   const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               step['desc'],
//               textAlign: TextAlign.center,
//               // ✅ Dark Mode: Color de texto adaptativo
//               style:
//                   theme.textTheme.bodyMedium?.copyWith(
//                     color: isDark ? Colors.white70 : Colors.black87,
//                   ) ??
//                   TextStyle(
//                     fontSize: 15,
//                     color: isDark ? Colors.white70 : Colors.black87,
//                   ),
//             ),
//             const SizedBox(height: 25),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 // Botón Omitir
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: Text(
//                     "Omitir",
//                     style: TextStyle(
//                       color: isDark ? Colors.white60 : Colors.black54,
//                     ),
//                   ),
//                 ),
//                 // Botón Siguiente / Finalizar
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.deepPurple,
//                     // ✅ Estilo: Asegura que el texto sea blanco siempre
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   onPressed: () => Navigator.pop(context, true),
//                   child: Text(isLast ? "Finalizar" : "Siguiente"),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';

// Importaciones de tu proyecto
import 'package:pzplayer/ui/screens/album.dart';
import 'package:pzplayer/ui/screens/artista.dart';
import 'package:pzplayer/ui/screens/folder.dart';
import 'package:pzplayer/ui/screens/genre.dart';
import 'package:pzplayer/ui/screens/library.dart';
import 'package:pzplayer/ui/screens/playlist.dart';

import 'package:pzplayer/ui/widgets/lateral.dart';
import 'package:pzplayer/ui/widgets/player_controls.dart';
import 'package:pzplayer/ui/widgets/utilidades.dart';

import 'package:shared_preferences/shared_preferences.dart';

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

  final List<Map<String, dynamic>> _navItems = [
    {'label': "Biblioteca", 'widget': const LibraryScreen()},
    {'label': "Álbum", 'widget': const AlbumScreen(albumName: '', songs: [])},
    {
      'label': "Artista",
      'widget': const ArtistScreen(artistName: '', songs: []),
    },
    {'label': "Género", 'widget': GenreScreen(genreName: '', songs: [])},
    {
      'label': "Playlist",
      'widget': const PlaylistScreen(playlistName: '', songs: []),
    },
    {
      'label': "Carpeta",
      'widget': const FolderScreen(folderName: '', songs: []),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _navItems.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTutorialStatus());
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('tutorial_seen') ?? false)) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showTutorialSteps().then((_) => prefs.setBool('tutorial_seen', true));
      }
    }
  }

  Future<void> _showTutorialSteps() async {
    final steps = [
      {
        "icon": Icons.menu,
        "title": "Navegación",
        "desc": "Usa las pestañas para navegar.",
      },
      {
        "icon": Icons.play_circle_fill,
        "title": "Reproducción",
        "desc": "Toca cualquier canción.",
      },
      {
        "icon": Icons.headphones,
        "title": "Mini-Reproductor",
        "desc": "Toca la barra inferior.",
      },
    ];

    for (int i = 0; i < steps.length; i++) {
      if (!mounted) return;
      bool proceed =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => _TutorialStepDialog(
              step: steps[i],
              currentStep: i + 1,
              totalSteps: steps.length,
              isLast: i == steps.length - 1,
            ),
          ) ??
          false;
      if (!proceed) break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const MainDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: _isSearching
                  ? _buildSearchField(isDark)
                  : const Text("PZ Player"),
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(_isSearching ? Icons.music_note : Icons.menu),
                  onPressed: () =>
                      _isSearching ? null : Scaffold.of(ctx).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () => setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) _query = "";
                  }),
                ),
              ],
              bottom: TabBar(
                tabAlignment: TabAlignment.center,
                controller: _tabController,
                isScrollable: true,
                dividerHeight: 0.1,
                dividerColor: Colors.transparent,
                indicatorColor: isDark ? Colors.white : Colors.black,
                labelColor: isDark ? Colors.white : Colors.black,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                tabs: _navItems
                    .map((item) => Tab(text: item['label']))
                    .toList(),
              ),
            ),
          ];
        },
        // Aquí eliminamos el espacio extra
        body: TabBarView(
          controller: _tabController,
          children: _navItems.map((item) {
            return MediaQuery.removePadding(
              context: context,
              removeTop: true, // ESTO QUITA EL ESPACIO QUE VES EN TU FOTO
              child: item['widget'],
            );
          }).toList(),
        ),
      ),
      bottomNavigationBar: MiniPlayer(),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return TextField(
      autofocus: true,
      onChanged: (val) => setState(() => _query = val),
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: const InputDecoration(
        hintText: "Buscar...",
        border: InputBorder.none,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class _TutorialStepDialog extends StatelessWidget {
  final Map<String, dynamic> step;
  final int currentStep;
  final int totalSteps;
  final bool isLast;

  const _TutorialStepDialog({
    required this.step,
    required this.currentStep,
    required this.totalSteps,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(step['icon'], size: 60, color: Colors.deepPurple),
            const SizedBox(height: 20),
            Text(
              "${step['title']} ($currentStep/$totalSteps)",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(step['desc'], textAlign: TextAlign.center),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Omitir"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(isLast ? "Finalizar" : "Siguiente"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
