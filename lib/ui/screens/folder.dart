// import 'dart:typed_data';
// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import 'package:pzplayer/ui/widgets/folder_detalle.dart';
// import '../../core/audio/audio_provider.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/theme/app_text_styles.dart';

// class FolderScreen extends StatelessWidget {
//   const FolderScreen({
//     super.key,
//     required String folderName,
//     required List<MediaItem> songs,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final folders = context.watch<AudioProvider>().folders;
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     if (folders.isEmpty) {
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

//     return ListView.builder(
//       itemCount: folders.length,
//       itemBuilder: (context, index) {
//         final folderPath = folders.keys.elementAt(index);
//         final folderName = folderPath.split('/').last; // 🔑 solo el nombre

//         final songs = folders.values.elementAt(index);

//         // Tomamos la carátula de la primera canción de la carpeta
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

//         return ListTile(
//           leading: coverBytes != null
//               ? ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.memory(
//                     coverBytes,
//                     width: 50,
//                     height: 50,
//                     fit: BoxFit.cover,
//                     filterQuality: FilterQuality.high,
//                   ),
//                 )
//               : Icon(
//                   Icons.folder,
//                   size: 40,
//                   color: isDark ? Colors.blueGrey : AppColors.primary,
//                 ),
//           title: Text(
//             folderName,
//             style: isDark ? AppTextStyles.darktof : AppTextStyles.darktoif,
//             overflow: TextOverflow.ellipsis,
//           ),
//           subtitle: Text(
//             "${songs.length} canciones",
//             style: isDark ? AppTextStyles.darktoi : AppTextStyles.darktoa,
//           ),
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) =>
//                     FolderDetailScreen(folderName: folderName, songs: songs),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }
import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart'; // 🔑 Necesario para las miniaturas
import 'package:provider/provider.dart';

import 'package:pzplayer/ui/widgets/folder_detalle.dart';
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class FolderScreen extends StatelessWidget {
  // MANTENIDO: Constructor original con parámetros
  final String? folderName;
  final List<MediaItem>? songs;

  const FolderScreen({super.key, this.folderName, this.songs});

  @override
  Widget build(BuildContext context) {
    final folders = context.watch<AudioProvider>().folders;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (folders.isEmpty) {
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

    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: folders.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              return _buildFolderTile(context, folders, index, isDark);
            },
          );
        } else {
          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              return _buildFolderTile(context, folders, index, isDark);
            },
          );
        }
      },
    );
  }

  Widget _buildFolderTile(
    BuildContext context,
    Map<String, List<MediaItem>> folders,
    int index,
    bool isDark,
  ) {
    final folderPath = folders.keys.elementAt(index);
    final currentFolderName = folderPath.split('/').last;
    final currentSongs = folders.values.elementAt(index);

    // 🔑 CAMBIO CLAVE: Extraemos el dbId en lugar de coverBytes
    final firstSong = currentSongs.isNotEmpty ? currentSongs.first : null;
    final dynamic rawId = firstSong?.extras?['dbId'];
    final int songId = (rawId is int)
        ? rawId
        : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        clipBehavior: Clip.antiAlias,
        child: songId == 0
            ? Icon(
                Icons.folder,
                color: isDark ? Colors.blueGrey : AppColors.primary,
              )
            : FutureBuilder<Uint8List?>(
                future: OnAudioQuery().queryArtwork(
                  songId,
                  ArtworkType.AUDIO,
                  format: ArtworkFormat.JPEG,
                  size: 200, // Tamaño pequeño para la lista
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data != null &&
                      snapshot.data!.isNotEmpty) {
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  }
                  return Icon(
                    Icons.folder,
                    color: isDark ? Colors.blueGrey : AppColors.primary,
                  );
                },
              ),
      ),
      title: Text(
        currentFolderName,
        style: isDark ? AppTextStyles.darktof : AppTextStyles.darktoif,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        "${currentSongs.length} canciones",
        style: isDark ? AppTextStyles.darktoi : AppTextStyles.darktoa,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FolderDetailScreen(
              folderName: currentFolderName,
              songs: currentSongs,
            ),
          ),
        );
      },
    );
  }
}
