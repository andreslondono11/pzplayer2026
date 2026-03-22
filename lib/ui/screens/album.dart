// import 'dart:typed_data';
// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:pzplayer/ui/widgets/album_detalle.dart';
// import '../../core/audio/audio_provider.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/theme/app_text_styles.dart';

// class AlbumScreen extends StatelessWidget {
//   const AlbumScreen({
//     super.key,
//     required String albumName,
//     required List<MediaItem> songs,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final albums = context.watch<AudioProvider>().albums;
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     if (albums.isEmpty) {
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
//       itemCount: albums.length,
//       itemBuilder: (context, index) {
//         final albumName = albums.keys.elementAt(index);
//         final songs = albums.values.elementAt(index);

//         // Tomamos la primera canción del álbum
//         final firstSong = songs.isNotEmpty ? songs.first : null;

//         // Extraemos los bytes de la carátula si existen
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
//                     AlbumDetailScreen(albumName: albumName, songs: songs),
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
//                       ? Image.memory(coverBytes, fit: BoxFit.cover)
//                       : Icon(
//                           Icons.album,
//                           size: 80,
//                           color: isDark ? Colors.blueGrey : AppColors.primary,
//                         ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     albumName,
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
import 'package:pzplayer/ui/widgets/album_detalle.dart';
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({
    super.key,
    required String albumName,
    required List<MediaItem> songs,
  });

  @override
  Widget build(BuildContext context) {
    final albums = context.watch<AudioProvider>().albums;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 📱 Lógica para detectar orientación y tamaño
    final orientation = MediaQuery.of(context).orientation;
    final width = MediaQuery.of(context).size.width;

    if (albums.isEmpty) {
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
        // Si está en landscape o la pantalla es muy ancha (> 600px), usa más columnas
        crossAxisCount: orientation == Orientation.landscape || width > 600
            ? 5
            : 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final albumName = albums.keys.elementAt(index);
        final songs = albums.values.elementAt(index);

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
                    AlbumDetailScreen(albumName: albumName, songs: songs),
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
                      ? Image.memory(coverBytes, fit: BoxFit.cover)
                      : Icon(
                          Icons.album,
                          size: 80,
                          color: isDark ? Colors.blueGrey : AppColors.primary,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    albumName,
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
