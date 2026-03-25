import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/core/theme/app_colors.dart';
import 'package:pzplayer/core/theme/app_text_styles.dart';

class ProgressBarWidget extends StatelessWidget {
  const ProgressBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<Duration>(
      stream: audio.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;

        return StreamBuilder<Duration?>(
          stream: audio.durationStream,
          builder: (context, durationSnap) {
            final duration = durationSnap.data ?? Duration.zero;

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3, // 🔑 línea más fina
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6, // 🔑 pulgar pequeño
                    ),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: isDark ? Colors.white : Colors.black,
                    inactiveTrackColor:
                        Theme.of(context).brightness == Brightness.light
                        // ignore: deprecated_member_use
                        ? AppColors.textSecondary.withOpacity(0.3)
                        : Colors.white24,
                    thumbColor: isDark ? Colors.white : Colors.black,
                  ),
                  child: Slider(
                    value: position.inMilliseconds.toDouble().clamp(
                      0,
                      duration.inMilliseconds.toDouble(),
                    ),
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      audio.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: Theme.of(context).brightness == Brightness.light
                            ? AppTextStyles.captionLight
                            : AppTextStyles.captionDark,
                      ),
                      Text(
                        _formatDuration(duration),
                        style: Theme.of(context).brightness == Brightness.light
                            ? AppTextStyles.captionLight
                            : AppTextStyles.captionDark,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
