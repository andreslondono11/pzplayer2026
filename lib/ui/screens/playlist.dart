// import 'dart:typed_data';
// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:provider/provider.dart';
// import 'package:pzplayer/ui/widgets/playlist_detalle.dart';
// import '../../core/audio/audio_provider.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/theme/app_text_styles.dart';

// class PlaylistScreen extends StatefulWidget {
//   // 🔑 Mantenemos los parámetros intactos
//   final String playlistName;
//   final List<MediaItem> songs;

//   const PlaylistScreen({
//     super.key,
//     required this.playlistName,
//     required this.songs,
//   });

//   @override
//   State<PlaylistScreen> createState() => _PlaylistScreenState();
// }

// class _PlaylistScreenState extends State<PlaylistScreen> {
//   final Map<int, Uint8List?> _playlistArtCache = {};

//   @override
//   Widget build(BuildContext context) {
//     final playlists = context.watch<AudioProvider>().playlists;
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Playlists",
//           style: isDark
//               ? AppTextStyles.headingDark
//               : AppTextStyles.headingLight,
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(
//               Icons.add,
//               color: isDark ? Colors.blueGrey : AppColors.primary,
//             ),
//             onPressed: () => _showCreatePlaylistDialog(context, isDark),
//           ),
//         ],
//       ),
//       body: playlists.isEmpty
//           ? Center(
//               child: Text(
//                 "No hay playlists",
//                 style: isDark
//                     ? AppTextStyles.captionDark
//                     : AppTextStyles.captionLight,
//               ),
//             )
//           : ListView.builder(
//               itemCount: playlists.length,
//               itemBuilder: (context, index) {
//                 final playlistName = playlists.keys.elementAt(index);
//                 final songs = playlists.values.elementAt(index);

//                 final firstSong = songs.isNotEmpty ? songs.first : null;
//                 final dynamic rawId = firstSong?.extras?['dbId'];
//                 final int songId = (rawId is int)
//                     ? rawId
//                     : int.tryParse(rawId?.toString() ?? '0') ?? 0;

//                 return ListTile(
//                   leading: _buildPlaylistArt(songId, isDark),
//                   title: Text(
//                     playlistName,
//                     style: isDark
//                         ? AppTextStyles.bodyDark
//                         : AppTextStyles.bodyLight,
//                   ),
//                   subtitle: Text(
//                     "${songs.length} canciones",
//                     style: isDark
//                         ? AppTextStyles.captionDark
//                         : AppTextStyles.captionLight,
//                   ),
//                   trailing: IconButton(
//                     icon: Icon(
//                       Icons.delete,
//                       color: isDark ? Colors.blueGrey : AppColors.primary,
//                     ),
//                     onPressed: () {
//                       context.read<AudioProvider>().deletePlaylist(
//                         playlistName,
//                       );
//                     },
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => PlaylistDetailScreen(
//                           playlistName: playlistName,
//                           songs: songs,
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }

//   Widget _buildPlaylistArt(int songId, bool isDark) {
//     if (songId == 0) return _defaultIcon(isDark);
//     if (_playlistArtCache.containsKey(songId)) {
//       return _artContainer(_playlistArtCache[songId], isDark);
//     }

//     return FutureBuilder<Uint8List?>(
//       future: OnAudioQuery().queryArtwork(songId, ArtworkType.AUDIO, size: 150),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.done) {
//           _playlistArtCache[songId] = snapshot.data;
//           return _artContainer(snapshot.data, isDark);
//         }
//         return _artContainer(null, isDark);
//       },
//     );
//   }

//   Widget _artContainer(Uint8List? bytes, bool isDark) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(8),
//       child: Container(
//         width: 50,
//         height: 50,
//         color: isDark
//             ? Colors.white.withOpacity(0.05)
//             : Colors.black.withOpacity(0.05),
//         child: bytes != null
//             ? Image.memory(bytes, fit: BoxFit.cover)
//             : _defaultIcon(isDark),
//       ),
//     );
//   }

//   Widget _defaultIcon(bool isDark) {
//     return Icon(
//       Icons.queue_music,
//       size: 30,
//       color: isDark ? Colors.blueGrey : AppColors.primary,
//     );
//   }

//   Future<void> _showCreatePlaylistDialog(
//     BuildContext context,
//     bool isDark,
//   ) async {
//     final nameController = TextEditingController();
//     await showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text(
//           "Nueva Playlist",
//           style: isDark
//               ? AppTextStyles.subheadingDark
//               : AppTextStyles.subheadingLight,
//         ),
//         content: TextField(
//           controller: nameController,
//           autofocus: true,
//           style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
//           decoration: InputDecoration(
//             hintText: "Nombre",
//             hintStyle: isDark
//                 ? AppTextStyles.captionDark
//                 : AppTextStyles.captionLight,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               "Cancelar",
//               style: isDark ? AppTextStyles.button : AppTextStyles.button2,
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               final name = nameController.text.trim();
//               if (name.isNotEmpty) {
//                 context.read<AudioProvider>().createPlaylist(name);
//                 Navigator.pop(context);
//               }
//             },
//             child: Text(
//               "Guardar",
//               style: isDark ? AppTextStyles.button : AppTextStyles.button2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/ui/widgets/favorite.dart';
import 'package:pzplayer/ui/widgets/most_played.dart';
import 'package:pzplayer/ui/widgets/playlist_detalle.dart';
// ✅ Importación de la pantalla de Más Escuchados
// import 'package:pzplayer/ui/screens/most_played_screen.dart';
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PlaylistScreen extends StatefulWidget {
  // 🔑 Mantenemos los parámetros intactos
  final String playlistName;
  final List<MediaItem> songs;

  const PlaylistScreen({
    super.key,
    required this.playlistName,
    required this.songs,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final Map<int, Uint8List?> _playlistArtCache = {};

  @override
  Widget build(BuildContext context) {
    final playlists = context.watch<AudioProvider>().playlists;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Playlists",
          style: isDark
              ? AppTextStyles.headingDark
              : AppTextStyles.headingLight,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: isDark ? Colors.blueGrey : AppColors.primary,
            ),
            onPressed: () => _showCreatePlaylistDialog(context, isDark),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ ENLACE A "MÁS ESCUCHADOS" (Arriba de la lista)
          ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.trending_up,
                color: Colors.deepPurple,
                size: 30,
              ),
            ),
            title: Text(
              "Más Escuchados",
              style: isDark
                  ? AppTextStyles.bodyDark.copyWith(fontWeight: FontWeight.bold)
                  : AppTextStyles.bodyLight.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
            ),
            subtitle: Text(
              "Tus álbumes favoritos",
              style: isDark
                  ? AppTextStyles.captionDark
                  : AppTextStyles.captionLight,
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.blueGrey : AppColors.primary,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MostPlayedScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.deepPurple,
                size: 30,
              ),
            ),
            title: Text(
              "Favoritos",
              style: isDark
                  ? AppTextStyles.bodyDark.copyWith(fontWeight: FontWeight.bold)
                  : AppTextStyles.bodyLight.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
            ),
            subtitle: Text(
              "Tus Canciones favoritas",
              style: isDark
                  ? AppTextStyles.captionDark
                  : AppTextStyles.captionLight,
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.blueGrey : AppColors.primary,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoriteSongsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),

          // LISTA DE PLAYLISTS EXISTENTES
          Expanded(
            child: playlists.isEmpty
                ? Center(
                    child: Text(
                      "No hay playlists",
                      style: isDark
                          ? AppTextStyles.captionDark
                          : AppTextStyles.captionLight,
                    ),
                  )
                : ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlistName = playlists.keys.elementAt(index);
                      final songs = playlists.values.elementAt(index);

                      final firstSong = songs.isNotEmpty ? songs.first : null;
                      final dynamic rawId = firstSong?.extras?['dbId'];
                      final int songId = (rawId is int)
                          ? rawId
                          : int.tryParse(rawId?.toString() ?? '0') ?? 0;

                      return ListTile(
                        leading: _buildPlaylistArt(songId, isDark),
                        title: Text(
                          playlistName,
                          style: isDark
                              ? AppTextStyles.bodyDark
                              : AppTextStyles.bodyLight,
                        ),
                        subtitle: Text(
                          "${songs.length} canciones",
                          style: isDark
                              ? AppTextStyles.captionDark
                              : AppTextStyles.captionLight,
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: isDark ? Colors.blueGrey : AppColors.primary,
                          ),
                          onPressed: () {
                            context.read<AudioProvider>().deletePlaylist(
                              playlistName,
                            );
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaylistDetailScreen(
                                playlistName: playlistName,
                                songs: songs,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistArt(int songId, bool isDark) {
    if (songId == 0) return _defaultIcon(isDark);
    if (_playlistArtCache.containsKey(songId)) {
      return _artContainer(_playlistArtCache[songId], isDark);
    }

    return FutureBuilder<Uint8List?>(
      future: OnAudioQuery().queryArtwork(songId, ArtworkType.AUDIO, size: 150),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _playlistArtCache[songId] = snapshot.data;
          return _artContainer(snapshot.data, isDark);
        }
        return _artContainer(null, isDark);
      },
    );
  }

  Widget _artContainer(Uint8List? bytes, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 50,
        height: 50,
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        child: bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover)
            : _defaultIcon(isDark),
      ),
    );
  }

  Widget _defaultIcon(bool isDark) {
    return Icon(
      Icons.queue_music,
      size: 30,
      color: isDark ? Colors.blueGrey : AppColors.primary,
    );
  }

  Future<void> _showCreatePlaylistDialog(
    BuildContext context,
    bool isDark,
  ) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Nueva Playlist",
          style: isDark
              ? AppTextStyles.subheadingDark
              : AppTextStyles.subheadingLight,
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
          decoration: InputDecoration(
            hintText: "Nombre",
            hintStyle: isDark
                ? AppTextStyles.captionDark
                : AppTextStyles.captionLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancelar",
              style: isDark ? AppTextStyles.button : AppTextStyles.button2,
            ),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                context.read<AudioProvider>().createPlaylist(name);
                Navigator.pop(context);
              }
            },
            child: Text(
              "Guardar",
              style: isDark ? AppTextStyles.button : AppTextStyles.button2,
            ),
          ),
        ],
      ),
    );
  }
}
