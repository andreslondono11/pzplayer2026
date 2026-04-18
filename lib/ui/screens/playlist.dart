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
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PlaylistScreen extends StatefulWidget {
  final String? playlistName;
  final List<MediaItem>? songs;

  const PlaylistScreen({super.key, this.playlistName, this.songs});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final Map<int, Uint8List?> _playlistArtCache = {};

  @override
  Widget build(BuildContext context) {
    final playlists = context.watch<AudioProvider>().playlists;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ELIMINAMOS EL SCAFFOLD Y EL APPBAR INTERNO
    // Usamos un CustomScrollView para que el scroll sea fluido con el HomeScreen
    return CustomScrollView(
      slivers: [
        // Botón para crear Playlist (equivalente al action del AppBar)
        SliverToBoxAdapter(
          child: ListTile(
            leading: Icon(
              Icons.add_box,
              color: isDark ? Colors.blueGrey : AppColors.primary,
            ),
            title: Text(
              "Crear nueva playlist",
              style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
            ),

            onTap: () => _showCreatePlaylistDialog(context, isDark),
          ),
        ),

        // Sección de "Más Escuchados"
        SliverToBoxAdapter(
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.trending_up,
                color: Colors.blueGrey,
                size: 30,
              ),
            ),
            title: Text(
              "Más Escuchados",
              style: (isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Tus álbumes favoritos",
              style: isDark
                  ? AppTextStyles.captionDark
                  : AppTextStyles.captionLight,
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.blueGrey),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MostPlayedScreen()),
            ),
          ),
        ),

        // Sección de "Favoritos"
        SliverToBoxAdapter(
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.blueGrey,
                size: 30,
              ),
            ),
            title: Text(
              "Favoritos",
              style: (isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Tus Canciones favoritas",
              style: isDark
                  ? AppTextStyles.captionDark
                  : AppTextStyles.captionLight,
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.blueGrey),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoriteSongsScreen()),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: Divider(height: 1)),

        // Lista de Playlists (Reemplaza al ListView.builder para evitar desbordamiento)
        playlists.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    "No hay playlists",
                    style: isDark
                        ? AppTextStyles.captionDark
                        : AppTextStyles.captionLight,
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
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
                      onPressed: () => context
                          .read<AudioProvider>()
                          .deletePlaylist(playlistName),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailScreen(
                          playlistName: playlistName,
                          songs: songs,
                        ),
                      ),
                    ),
                  );
                }, childCount: playlists.length),
              ),
      ],
    );
  }

  // --- MANTENEMOS TU LÓGICA DE ARTE Y DIÁLOGOS EXACTAMENTE IGUAL ---

  Widget _buildPlaylistArt(int songId, bool isDark) {
    if (songId == 0) return _defaultIcon(isDark);
    if (_playlistArtCache.containsKey(songId))
      return _artContainer(_playlistArtCache[songId], isDark);

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
