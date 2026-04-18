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

  /// ✅ NUEVO: Método robusto para obtener la carátula.
  /// Intenta buscar por AlbumID, y si falla, busca por SongID.
  Future<Uint8List?> _fetchAlbumArt(int albumId, int songId) async {
    final audioQuery = OnAudioQuery();

    // 1. Intentar por ID de Álbum (Lo ideal)
    if (albumId > 0) {
      try {
        final art = await audioQuery.queryArtwork(
          albumId,
          ArtworkType.ALBUM,
          format: ArtworkFormat.JPEG,
          size: 500,
        );
        if (art != null && art.isNotEmpty) {
          return art;
        }
      } catch (e) {
        // Ignorar error y pasar al siguiente método
      }
    }

    // 2. Intentar por ID de Canción (Fallback)
    // Muchas veces la imagen está incrustada en el MP3 y no en la DB del álbum
    if (songId > 0) {
      try {
        final art = await audioQuery.queryArtwork(
          songId,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: 500,
        );
        if (art != null && art.isNotEmpty) {
          return art;
        }
      } catch (e) {
        // Ignorar error
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final albums = context.watch<AudioProvider>().albums;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ DETECTAMOS ORIENTACIÓN
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (albums.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),

      // ✅ AJUSTE RESPONSIVE CUADROS
      // Portrait: 2 columnas (estándar)
      // Landscape: 6 columnas (muchos cuadros pequeños para ver más álbumes)
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLandscape ? 6 : 2,

        // Mantenemos la proporción 0.8 para que se vean cuadrados
        childAspectRatio: 0.8,

        crossAxisSpacing: 8, // Reducimos un poco el espacio en landscape
        mainAxisSpacing: 8,
      ),

      itemCount: albums.length,
      itemBuilder: (context, index) {
        final currentAlbumName = albums.keys.elementAt(index);
        final currentSongs = albums.values.elementAt(index);

        final firstSong = currentSongs.isNotEmpty ? currentSongs.first : null;

        // Extraemos IDs de forma segura
        final dynamic rawAlbumId = firstSong?.extras?['albumId'];
        final dynamic rawSongId = firstSong?.extras?['dbId'];

        final int albumId = (rawAlbumId is int)
            ? rawAlbumId
            : int.tryParse(rawAlbumId?.toString() ?? '0') ?? 0;

        final int songId = (rawSongId is int)
            ? rawSongId
            : int.tryParse(rawSongId?.toString() ?? '0') ?? 0;

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
              borderRadius: BorderRadius.circular(
                12,
              ), // Radio un poco menor para caber más
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: FutureBuilder<Uint8List?>(
                    future: _fetchAlbumArt(albumId, songId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData &&
                          snapshot.data != null &&
                          snapshot.data!.isNotEmpty) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholder(isDark),
                        );
                      }
                      return _buildPlaceholder(isDark);
                    },
                  ),
                ),
                Padding(
                  // Reducimos el padding en landscape para aprovechar espacio
                  padding: EdgeInsets.all(isLandscape ? 6 : 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentAlbumName,
                        style:
                            (isDark
                                    ? AppTextStyles.bodyDark
                                    : AppTextStyles.bodyLight)
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  // Fuente un poco más pequeña en landscape
                                  fontSize: isLandscape ? 11 : null,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${currentSongs.length} canciones",
                        style:
                            (isDark
                                    ? AppTextStyles.captionDark
                                    : AppTextStyles.captionLight)
                                .copyWith(fontSize: isLandscape ? 9 : null),
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
