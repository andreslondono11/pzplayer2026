// import 'dart:typed_data';
// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:pzplayer/core/audio/audio_provider.dart';
// import 'package:pzplayer/ui/widgets/artista_detalle.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/theme/app_text_styles.dart';

// class ArtistScreen extends StatelessWidget {
//   const ArtistScreen({
//     super.key,
//     required String artistName,
//     required List<MediaItem> songs,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final artists = context.watch<AudioProvider>().artists;
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     if (artists.isEmpty) {
//       // 🔄 Loader temático mientras se escanean álbumes
//       return Center(
//         child: SizedBox(
//           width: 120,
//           height: 120,
//           child: CircularProgressIndicator(
//             strokeWidth: 6,
//             valueColor: AlwaysStoppedAnimation<Color>(
//               isDark ? Colors.blueGrey : AppColors.secondary,
//             ),
//           ),
//         ),
//       );
//     }

//     return GridView.builder(
//       padding: const EdgeInsets.all(8),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 0.75,
//         crossAxisSpacing: 8,
//         mainAxisSpacing: 8,
//       ),
//       itemCount: artists.length,
//       itemBuilder: (context, index) {
//         final artistName = artists.keys.elementAt(index);
//         final songs = artists.values.elementAt(index);

//         // Tomamos la carátula de la primera canción del artista
//         final firstSong = songs.isNotEmpty ? songs.first : null;
//         final dynamic rawCover = firstSong?.extras?['coverBytes'];

//         Uint8List? coverBytes;
//         if (rawCover is Uint8List) {
//           coverBytes = rawCover;
//         } else if (rawCover is List<int>) {
//           coverBytes = Uint8List.fromList(rawCover);
//         } else if (rawCover is List<dynamic>) {
//           coverBytes = Uint8List.fromList(List<int>.from(rawCover));
//         }

//         return GestureDetector(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) =>
//                     ArtistDetailScreen(artistName: artistName, songs: songs),
//               ),
//             );
//           },
//           child: Card(
//             elevation: 3,
//             shadowColor: isDark ? Colors.blueGrey : AppColors.primary,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Expanded(
//                   child: coverBytes != null
//                       ? Image.memory(
//                           coverBytes,
//                           fit: BoxFit.cover,
//                           filterQuality: FilterQuality.high,
//                         )
//                       : Icon(
//                           Icons.person,
//                           size: 80,
//                           color: isDark ? Colors.blueGrey : AppColors.primary,
//                         ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     artistName,
//                     style: isDark
//                         ? AppTextStyles.darktof
//                         : AppTextStyles.darktoif,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                   child: Text(
//                     "${songs.length} canciones",
//                     style: isDark
//                         ? AppTextStyles.darktoi
//                         : AppTextStyles.darktoa,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/ui/widgets/artista_detalle.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ArtistScreen extends StatelessWidget {
  final String? artistName;
  final List<MediaItem>? songs;

  const ArtistScreen({super.key, this.artistName, this.songs});

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: 24,
        color: isDark ? Colors.blueGrey : AppColors.primary,
      ),
    );
  }

  // ✅ MÉTODO ROBUSTO PARA CARGAR IMAGEN
  Future<Uint8List?> _fetchArtistArt(int songId) async {
    final audioQuery = OnAudioQuery();
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

  @override
  Widget build(BuildContext context) {
    final artists = context.watch<AudioProvider>().artists;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (artists.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? Colors.blueGrey : AppColors.secondary,
          ),
        ),
      );
    }

    // ✅ CAMBIO A LISTVIEW
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: artists.length,
      itemExtent: 72.0,
      itemBuilder: (context, index) {
        final currentArtistName = artists.keys.elementAt(index);
        final currentSongs = artists.values.elementAt(index);

        final firstSong = currentSongs.isNotEmpty ? currentSongs.first : null;
        final dynamic rawId = firstSong?.extras?['dbId'];
        final int songId = (rawId is int)
            ? rawId
            : int.tryParse(rawId?.toString() ?? '0') ?? 0;

        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtistDetailScreen(
                  artistName: currentArtistName,
                  songs: currentSongs,
                ),
              ),
            );
          },
          leading: songId == 0
              ? _buildPlaceholder(isDark)
              : ClipOval(
                  child: FutureBuilder<Uint8List?>(
                    future: _fetchArtistArt(songId),
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
                      return _buildPlaceholder(isDark);
                    },
                  ),
                ),
          title: Text(
            currentArtistName,
            style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            "${currentSongs.length} canciones",
            style: isDark
                ? AppTextStyles.captionDark
                : AppTextStyles.captionLight,
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white24 : Colors.black26,
            size: 20,
          ),
        );
      },
    );
  }
}
