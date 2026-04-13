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
import 'package:on_audio_query/on_audio_query.dart'; // 🔑 Necesario para queryArtwork
import 'package:provider/provider.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/ui/widgets/artista_detalle.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ArtistScreen extends StatelessWidget {
  // 🔑 Mantengo los parámetros que pediste
  final String? artistName;
  final List<MediaItem>? songs;

  const ArtistScreen({super.key, this.artistName, this.songs});

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05),
      child: Icon(
        Icons.person,
        size: 80,
        color: isDark ? Colors.blueGrey : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final artists = context.watch<AudioProvider>().artists;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    if (artists.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? Colors.blueGrey : AppColors.secondary,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: width > 600 ? 5 : 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final currentArtistName = artists.keys.elementAt(index);
        final currentSongs = artists.values.elementAt(index);

        // 🔑 Obtenemos el ID desde los extras del Provider corregido
        final firstSong = currentSongs.isNotEmpty ? currentSongs.first : null;
        final dynamic rawId = firstSong?.extras?['dbId'];
        final int songId = (rawId is int)
            ? rawId
            : int.tryParse(rawId?.toString() ?? '0') ?? 0;

        return GestureDetector(
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
          child: Card(
            elevation: 3,
            shadowColor: isDark ? Colors.blueGrey : AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: songId == 0
                      ? _buildPlaceholder(isDark)
                      : FutureBuilder<Uint8List?>(
                          future: OnAudioQuery().queryArtwork(
                            songId,
                            ArtworkType.AUDIO,
                            format: ArtworkFormat.JPEG,
                            size: 400,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData &&
                                snapshot.data != null &&
                                snapshot.data!.isNotEmpty) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            }
                            return _buildPlaceholder(isDark);
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    currentArtistName,
                    style: isDark
                        ? AppTextStyles.bodyDark
                        : AppTextStyles.bodyLight,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Text(
                    "${currentSongs.length} canciones",
                    style: isDark
                        ? AppTextStyles.captionDark
                        : AppTextStyles.captionLight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
