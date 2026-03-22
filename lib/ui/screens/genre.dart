// import 'dart:typed_data';
// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import 'package:pzplayer/ui/widgets/genre_detalle.dart';
// import '../../core/audio/audio_provider.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/theme/app_text_styles.dart';

// class GenreScreen extends StatelessWidget {
//   const GenreScreen({
//     super.key,
//     required String genreName,
//     required List<MediaItem> songs,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final genres = context.watch<AudioProvider>().genres;
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     if (genres.isEmpty) {
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
//       itemCount: genres.length,
//       itemBuilder: (context, index) {
//         final genreName = genres.keys.elementAt(index);
//         final songs = genres.values.elementAt(index);

//         // Tomamos la carátula de la primera canción del género
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
//                     GenreDetailScreen(genreName: genreName, songs: songs),
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
//                           Icons.library_music,
//                           size: 80,
//                           color: isDark ? Colors.blueGrey : AppColors.primary,
//                         ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     genreName,
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
import 'package:provider/provider.dart';

import 'package:pzplayer/ui/widgets/genre_detalle.dart';
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class GenreScreen extends StatelessWidget {
  const GenreScreen({
    super.key,
    required String genreName,
    required List<MediaItem> songs,
  });

  @override
  Widget build(BuildContext context) {
    final genres = context.watch<AudioProvider>().genres;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 📱 Ajuste dinámico de columnas según orientación o tamaño de pantalla
    final orientation = MediaQuery.of(context).orientation;
    final width = MediaQuery.of(context).size.width;

    if (genres.isEmpty) {
      // 🔄 Loader temático mientras se escanean álbumes
      return Center(
        child: SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.blueGrey : AppColors.secondary,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // Cambia a 4 columnas si está en landscape o es una tablet (ancho > 600px)
        crossAxisCount: orientation == Orientation.landscape || width > 600
            ? 5
            : 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genreName = genres.keys.elementAt(index);
        final songs = genres.values.elementAt(index);

        // Tomamos la carátula de la primera canción del género
        final firstSong = songs.isNotEmpty ? songs.first : null;
        final dynamic rawCover = firstSong?.extras?['coverBytes'];

        Uint8List? coverBytes;
        if (rawCover is Uint8List) {
          coverBytes = rawCover;
        } else if (rawCover is List<int>) {
          coverBytes = Uint8List.fromList(rawCover);
        } else if (rawCover is List<dynamic>) {
          coverBytes = Uint8List.fromList(List<int>.from(rawCover));
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GenreDetailScreen(genreName: genreName, songs: songs),
              ),
            );
          },
          child: Card(
            elevation: 3,
            shadowColor: isDark ? Colors.blueGrey : AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: coverBytes != null
                      ? Image.memory(
                          coverBytes,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        )
                      : Icon(
                          Icons.library_music,
                          size: 80,
                          color: isDark ? Colors.blueGrey : AppColors.primary,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    genreName,
                    style: isDark
                        ? AppTextStyles.darktof
                        : AppTextStyles.darktoif,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "${songs.length} canciones",
                    style: isDark
                        ? AppTextStyles.darktoi
                        : AppTextStyles.darktoa,
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
