// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:audio_service/audio_service.dart';
// import 'package:provider/provider.dart';
// import 'package:pzplayer/ui/widgets/artista_detalle.dart';
// import '../../core/audio/audio_provider.dart';
// import 'album_detalle.dart';

// import 'genre_detalle.dart';

// class PlaylistDetailScreen extends StatelessWidget {
//   final String playlistName;
//   final List<MediaItem> songs;

//   const PlaylistDetailScreen({
//     super.key,
//     required this.playlistName,
//     required this.songs,
//   });

//   void _showSongMenu(BuildContext context, MediaItem song) {
//     final audio = context.read<AudioProvider>();

//     showModalBottomSheet(
//       context: context,
//       builder: (_) => SafeArea(
//         child: Wrap(
//           children: [
//             ListTile(
//               leading: const Icon(Icons.play_arrow),
//               title: const Text("Reproducir ahora"),
//               onTap: () {
//                 Navigator.pop(context);
//                 audio.playItems([song]);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.queue_play_next),
//               title: const Text("Reproducir siguiente"),
//               onTap: () {
//                 Navigator.pop(context);
//                 audio.playNext(song); // 🔑 usa el método nuevo
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.queue_music),
//               title: const Text("Añadir a la cola"),
//               onTap: () {
//                 Navigator.pop(context);
//                 audio.addToQueue(song); // 🔑 usa el método nuevo
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.album),
//               title: const Text("Ir a álbum"),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => AlbumDetailScreen(
//                       albumName: song.album ?? 'Desconocido',
//                       songs: audio.albums[song.album ?? 'Desconocido'] ?? [],
//                     ),
//                   ),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text("Ir a artista"),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => ArtistDetailScreen(
//                       artistName: song.artist ?? 'Desconocido',
//                       songs: audio.artists[song.artist ?? 'Desconocido'] ?? [],
//                     ),
//                   ),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.library_music),
//               title: const Text("Ir a género"),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => GenreDetailScreen(
//                       genreName: song.extras?['genre'] ?? 'Desconocido',
//                       songs:
//                           audio.genres[song.extras?['genre'] ??
//                               'Desconocido'] ??
//                           [],
//                     ),
//                   ),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.playlist_add),
//               title: const Text("Añadir a playlist"),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showPlaylistSelector(context, song);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.remove_circle, color: Colors.red),
//               title: const Text("Eliminar de esta playlist"),
//               onTap: () {
//                 Navigator.pop(context);
//                 audio.removeFromPlaylist(playlistName, song);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showPlaylistSelector(BuildContext context, MediaItem song) {
//     final audio = context.read<AudioProvider>();
//     final playlists = audio.playlists.keys.toList();

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Selecciona playlist"),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: playlists.length,
//             itemBuilder: (context, index) {
//               final name = playlists[index];
//               return ListTile(
//                 leading: const Icon(Icons.queue_music),
//                 title: Text(name),
//                 onTap: () {
//                   Navigator.pop(context);
//                   audio.addToPlaylist(name, song);
//                 },
//               );
//             },
//           ),
//         ),
//         actions: [
//           TextButton(
//             child: const Text("Cancelar"),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(playlistName)),
//       body: songs.isEmpty
//           ? const Center(child: Text("Playlist vacía"))
//           : ListView.builder(
//               itemCount: songs.length,
//               itemBuilder: (context, index) {
//                 final song = songs[index];
//                 final dynamic rawCover = song.extras?['coverBytes'];

//                 Uint8List? coverBytes;
//                 if (rawCover is Uint8List) {
//                   coverBytes = rawCover;
//                 } else if (rawCover is List<int>) {
//                   coverBytes = Uint8List.fromList(rawCover);
//                 } else if (rawCover is List<dynamic>) {
//                   coverBytes = Uint8List.fromList(List<int>.from(rawCover));
//                 }

//                 return ListTile(
//                   leading: CircleAvatar(
//                     backgroundImage: coverBytes != null
//                         ? MemoryImage(coverBytes)
//                         : null,
//                     child: coverBytes == null
//                         ? const Icon(Icons.music_note)
//                         : null,
//                   ),
//                   title: Text(song.title),
//                   subtitle: Text(song.artist ?? 'Desconocido'),
//                   onTap: () => context.read<AudioProvider>().playItems(
//                     songs,
//                     startIndex: index,
//                   ),
//                   onLongPress: () => _showSongMenu(context, song),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.more_vert),
//                     onPressed: () => _showSongMenu(context, song),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/ui/widgets/artista_detalle.dart';
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'album_detalle.dart';
import 'genre_detalle.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistName;
  final List<MediaItem> songs;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistName,
    required this.songs,
  });

  // --- Lógica de Utilidad ---

  Uint8List? _parseCover(dynamic raw) {
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);
    if (raw is List<dynamic>) return Uint8List.fromList(List<int>.from(raw));
    return null;
  }

  // --- Menús y Diálogos ---

  void _showSongMenu(BuildContext context, MediaItem song) {
    final audio = context.read<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Crucial para que no se corte en horizontal
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
              _menuTile(
                Icons.remove_circle,
                "Eliminar de esta playlist",
                () {
                  Navigator.pop(context);
                  audio.removeFromPlaylist(playlistName, song);
                },
                isDark,
                isDelete: true,
              ),
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
    bool isDark, {
    bool isDelete = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDelete
            ? Colors.red
            : (isDark ? Colors.blueGrey : AppColors.primary),
      ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final firstSongCover = songs.isNotEmpty
        ? _parseCover(songs.first.extras?['coverBytes'])
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          playlistName,
          style: isDark
              ? AppTextStyles.headingDark
              : AppTextStyles.headingLight,
        ),
      ),
      body: songs.isEmpty
          ? const Center(child: Text("Playlist vacía"))
          : Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Encabezado de Dos Columnas
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCoverArt(
                                firstSongCover,
                                isDark,
                                size: isLandscape ? 100 : 140,
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playlistName,
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
                      // Lista de canciones
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final song = songs[index];
                            final Uint8List? songCover = _parseCover(
                              song.extras?['coverBytes'],
                            );

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
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    color: isDark
                                        ? Colors.blueGrey.withOpacity(0.2)
                                        : AppColors.primary.withOpacity(0.1),
                                    child: songCover != null
                                        ? Image.memory(
                                            songCover,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            Icons.music_note,
                                            color: isDark
                                                ? Colors.white70
                                                : AppColors.primary,
                                          ),
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
                                onTap: () => context
                                    .read<AudioProvider>()
                                    .playItems(songs, startIndex: index),
                                onLongPress: () => _showSongMenu(context, song),
                              ),
                            );
                          }, childCount: songs.length),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCoverArt(Uint8List? cover, bool isDark, {double size = 140}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: cover != null
            ? Image.memory(cover, width: size, height: size, fit: BoxFit.cover)
            : Container(
                width: size,
                height: size,
                color: isDark
                    ? Colors.blueGrey
                    : AppColors.primary.withOpacity(0.2),
                child: Icon(
                  Icons.queue_music,
                  size: size / 2,
                  color: isDark ? Colors.white24 : AppColors.primary,
                ),
              ),
      ),
    );
  }
}
