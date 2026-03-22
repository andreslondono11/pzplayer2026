import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/ui/widgets/artista_detalle.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ArtistScreen extends StatelessWidget {
  const ArtistScreen({
    super.key,
    required String artistName,
    required List<MediaItem> songs,
  });

  @override
  Widget build(BuildContext context) {
    final artists = context.watch<AudioProvider>().artists;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (artists.isEmpty) {
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artistName = artists.keys.elementAt(index);
        final songs = artists.values.elementAt(index);

        // Tomamos la carátula de la primera canción del artista
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
                    ArtistDetailScreen(artistName: artistName, songs: songs),
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
                          Icons.person,
                          size: 80,
                          color: isDark ? Colors.blueGrey : AppColors.primary,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    artistName,
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
