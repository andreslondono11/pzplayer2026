import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pzplayer/ui/widgets/folder_detalle.dart';
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class FolderScreen extends StatelessWidget {
  const FolderScreen({
    super.key,
    required String folderName,
    required List<MediaItem> songs,
  });

  @override
  Widget build(BuildContext context) {
    final folders = context.watch<AudioProvider>().folders;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (folders.isEmpty) {
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

    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folderPath = folders.keys.elementAt(index);
        final folderName = folderPath.split('/').last; // 🔑 solo el nombre

        final songs = folders.values.elementAt(index);

        // Tomamos la carátula de la primera canción de la carpeta
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

        return ListTile(
          leading: coverBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    coverBytes,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                )
              : Icon(
                  Icons.folder,
                  size: 40,
                  color: isDark ? Colors.blueGrey : AppColors.primary,
                ),
          title: Text(
            folderName,
            style: isDark ? AppTextStyles.darktof : AppTextStyles.darktoif,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            "${songs.length} canciones",
            style: isDark ? AppTextStyles.darktoi : AppTextStyles.darktoa,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    FolderDetailScreen(folderName: folderName, songs: songs),
              ),
            );
          },
        );
      },
    );
  }
}
