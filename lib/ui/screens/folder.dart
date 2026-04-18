import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import 'package:pzplayer/ui/widgets/folder_detalle.dart';
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class FolderScreen extends StatelessWidget {
  final String? folderName;
  final List<MediaItem>? songs;

  const FolderScreen({super.key, this.folderName, this.songs});

  @override
  Widget build(BuildContext context) {
    final folders = context.watch<AudioProvider>().folders;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ DETECTAMOS ORIENTACIÓN
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ AJUSTE RESPONSIVE
        int crossAxisCount;

        if (isLandscape) {
          // En horizontal: Muchas columnas para ver muchas carpetas pequeñas
          crossAxisCount = (constraints.maxWidth / 120).floor().clamp(6, 10);
        } else {
          // En vertical: Lista estándar (1 columna)
          crossAxisCount = 1;
        }

        // Si estamos en vertical, usamos ListView directamente
        if (crossAxisCount == 1) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            physics: const BouncingScrollPhysics(),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              return _buildFolderTile(context, folders, index, isDark);
            },
          );
        }

        // Si estamos en horizontal, usamos GridView compacto
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.8, // Un poco más apaisado para el nombre
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
          ),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            return _buildFolderCard(context, folders, index, isDark);
          },
        );
      },
    );
  }

  // --- WIDGET PARA LISTA VERTICAL (Portrait) ---
  Widget _buildFolderTile(
    BuildContext context,
    Map<String, List<MediaItem>> folders,
    int index,
    bool isDark,
  ) {
    final folderPath = folders.keys.elementAt(index);
    final currentFolderName = folderPath.split('/').last;
    final currentSongs = folders.values.elementAt(index);

    // Extraer ID
    final firstSong = currentSongs.isNotEmpty ? currentSongs.first : null;
    final dynamic rawId = firstSong?.extras?['dbId'];
    final int songId = (rawId is int)
        ? rawId
        : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  size: 200,
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
        style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        "${currentSongs.length} canciones",
        style: isDark ? AppTextStyles.captionDark : AppTextStyles.captionLight,
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

  // --- WIDGET PARA GRID (Landscape) ---
  Widget _buildFolderCard(
    BuildContext context,
    Map<String, List<MediaItem>> folders,
    int index,
    bool isDark,
  ) {
    final folderPath = folders.keys.elementAt(index);
    final currentFolderName = folderPath.split('/').last;
    final currentSongs = folders.values.elementAt(index);

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
            builder: (_) => FolderDetailScreen(
              folderName: currentFolderName,
              songs: currentSongs,
            ),
          ),
        );
      },
      child: Card(
        elevation: 0,
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: isDark ? Colors.white10 : Colors.black45,
                child: songId == 0
                    ? Icon(
                        Icons.folder,
                        size: 40,
                        color: isDark ? Colors.blueGrey : AppColors.primary,
                      )
                    : FutureBuilder<Uint8List?>(
                        future: OnAudioQuery().queryArtwork(
                          songId,
                          ArtworkType.AUDIO,
                          format: ArtworkFormat.JPEG,
                          size: 300,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData &&
                              snapshot.data != null &&
                              snapshot.data!.isNotEmpty) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            );
                          }
                          return Icon(
                            Icons.folder,
                            size: 40,
                            color: isDark ? Colors.blueGrey : AppColors.primary,
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                currentFolderName,
                style:
                    (isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight)
                        .copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Text(
                "${currentSongs.length} canciones",
                style: TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
