import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/core/theme/app_colors.dart';
import 'package:pzplayer/core/theme/app_text_styles.dart';
import 'package:pzplayer/ui/screens/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Usamos watch para que cualquier cambio en el provider reconstruya el widget
    final audio = context.watch<AudioProvider>();
    final current = audio.current;

    if (current == null) {
      return _buildEmptyState(isDark);
    }

    // 🔑 EXTRACCIÓN DIRECTA DE BYTES
    // Intentamos obtener los bytes directamente del provider si es posible,
    // o de los extras del MediaItem actual.
    final dynamic rawArt = current.extras?['coverBytes'];
    Uint8List? imageBytes;

    if (rawArt is Uint8List) {
      imageBytes = rawArt;
    } else if (rawArt is List<int>) {
      imageBytes = Uint8List.fromList(rawArt);
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.85)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppColors.softShadow],
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de progreso
            _buildProgressBar(audio, isDark),

            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.blueGrey : AppColors.primary,
                  image: imageBytes != null
                      ? DecorationImage(
                          image: MemoryImage(imageBytes),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageBytes == null
                    ? const Icon(Icons.music_note, color: Colors.white)
                    : null,
              ),
              title: Text(
                current.title,
                style: isDark
                    ? AppTextStyles.bodyDark
                    : AppTextStyles.bodyLight,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              subtitle: Text(
                current.artist ?? 'Desconocido',
                style: isDark
                    ? AppTextStyles.captionDark
                    : AppTextStyles.captionLight,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              trailing: IconButton(
                icon: Icon(
                  audio.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 38,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
                onPressed: () =>
                    audio.isPlaying ? audio.pause() : audio.resume(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(AudioProvider audio, bool isDark) {
    return StreamBuilder<Duration>(
      stream: audio.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = audio.duration ?? Duration.zero;
        final progress = (duration.inMilliseconds > 0)
            ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                0.0,
                1.0,
              )
            : 0.0;

        return LinearProgressIndicator(
          value: progress,
          minHeight: 2.5,
          backgroundColor: isDark ? Colors.white10 : Colors.black12,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? Colors.blueGrey : AppColors.secondary,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.music_off)),
        title: const Text("PZ Player"),
        subtitle: const Text("Selecciona una canción"),
      ),
    );
  }
}
