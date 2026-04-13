import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/ui/widgets/album_detalle.dart';

import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AlbumScreen extends StatelessWidget {
  final String? albumName;
  final List<MediaItem>? songs;

  const AlbumScreen({super.key, this.albumName, this.songs});

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05),
      child: Icon(
        Icons.album,
        size: 50,
        color: isDark ? Colors.blueGrey : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final albums = context.watch<AudioProvider>().albums;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    if (albums.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: width > 600 ? 5 : 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final currentAlbumName = albums.keys.elementAt(index);
        final currentSongs = albums.values.elementAt(index);

        final firstSong = currentSongs.isNotEmpty ? currentSongs.first : null;
        final dynamic rawAlbumId = firstSong?.extras?['albumId'];
        final dynamic rawSongId = firstSong?.extras?['dbId'];

        // 🕵️ MODO DIAGNÓSTICO: Mira la consola de VS Code / Android Studio
        print('--- DIAGNÓSTICO PZ PLAYER ---');
        print('Álbum: $currentAlbumName');
        print('AlbumID Extraído: $rawAlbumId');
        print('SongID Extraído: $rawSongId');
        print('Ruta del archivo: ${firstSong?.id}');
        print('-----------------------------');

        // Convertimos a int de forma segura
        final int albumId = (rawAlbumId is int)
            ? rawAlbumId
            : int.tryParse(rawAlbumId?.toString() ?? '0') ?? 0;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlbumDetailScreen(
                albumName: currentAlbumName,
                songs: currentSongs,
              ),
            ),
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: albumId == 0
                      ? _buildPlaceholder(isDark)
                      : FutureBuilder<Uint8List?>(
                          // 🔑 CAMBIO 2: Usamos ArtworkType.ALBUM y el albumId
                          future: OnAudioQuery().queryArtwork(
                            albumId,
                            ArtworkType
                                .ALBUM, // Esto es mucho más fiable para álbumes
                            format: ArtworkFormat.JPEG,
                            size: 500,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData &&
                                snapshot.data != null &&
                                snapshot.data!.isNotEmpty) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(isDark),
                              );
                            }
                            return _buildPlaceholder(isDark);
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentAlbumName,
                        style:
                            (isDark
                                    ? AppTextStyles.bodyDark
                                    : AppTextStyles.bodyLight)
                                .copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${currentSongs.length} canciones",
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
        );
      },
    );
  }
}
