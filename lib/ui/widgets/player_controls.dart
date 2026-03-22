// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:pzplayer/core/audio/audio_provider.dart';
// import 'package:pzplayer/core/theme/app_colors.dart';
// import 'package:pzplayer/core/theme/app_text_styles.dart';
// import 'package:pzplayer/ui/screens/now_playing_screen.dart';

// class MiniPlayer extends StatelessWidget {
//   const MiniPlayer({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final audio = context.watch<AudioProvider>();
//     final current = audio.current;

//     // ✅ Si no hay canción activa
//     if (current == null) {
//       return Container(
//         decoration: BoxDecoration(
//           color: isDark ? Colors.blueGrey : AppColors.secondary,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [AppColors.softShadow],
//         ),
//         child: ListTile(
//           leading: Icon(
//             Icons.stop,
//             color: Theme.of(context).brightness == Brightness.light
//                 ? AppColors.primary
//                 : AppColors.white,
//           ),
//           title: Text(
//             "No hay canción en reproducción",
//             style: Theme.of(context).brightness == Brightness.light
//                 ? AppTextStyles.captionLight
//                 : AppTextStyles.captionDark,
//           ),
//         ),
//       );
//     }

//     final coverBytes = audio.normalizeCover(current.extras?['coverBytes']);

//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const PlayerScreen()),
//         );
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: Theme.of(context).brightness == Brightness.light
//               // ignore: deprecated_member_use
//               ? Colors.white.withOpacity(0.9)
//               // ignore: deprecated_member_use
//               : Colors.black.withOpacity(0.7),
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [AppColors.softShadow],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // 🔑 Línea de progreso más fina
//             StreamBuilder<Duration>(
//               stream: audio.positionStream,
//               builder: (context, snapshot) {
//                 final position = snapshot.data ?? Duration.zero;
//                 final duration = audio.duration ?? Duration.zero;

//                 return SliderTheme(
//                   data: SliderTheme.of(context).copyWith(
//                     trackHeight: 3, // línea más fina
//                     thumbShape: const RoundSliderThumbShape(
//                       enabledThumbRadius: 6,
//                     ),
//                     activeTrackColor: AppColors.primary,
//                     inactiveTrackColor:
//                         Theme.of(context).brightness == Brightness.light
//                         // ignore: deprecated_member_use
//                         ? AppColors.textSecondary.withOpacity(0.3)
//                         : Colors.white24,
//                     thumbColor: isDark ? Colors.blueGrey : AppColors.secondary,
//                   ),
//                   child: Slider(
//                     thumbColor: isDark ? Colors.blueGrey : AppColors.secondary,
//                     activeColor: isDark ? Colors.blueGrey : AppColors.secondary,
//                     inactiveColor: isDark
//                         ? Colors.blueGrey
//                         : AppColors.secondary,
//                     value: position.inMilliseconds.toDouble().clamp(
//                       0,
//                       duration.inMilliseconds.toDouble(),
//                     ),
//                     max: duration.inMilliseconds.toDouble(),
//                     onChanged: null, // 🚫 no interactivo aquí
//                   ),
//                 );
//               },
//             ),
//             ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: isDark ? Colors.blueGrey : AppColors.primary,

//                 backgroundImage: coverBytes != null
//                     ? MemoryImage(coverBytes)
//                     : null,
//                 child: coverBytes == null
//                     ? Icon(Icons.music_note, color: Colors.white)
//                     : null,
//               ),
//               title: Text(
//                 current.title,
//                 style: Theme.of(context).brightness == Brightness.light
//                     ? AppTextStyles.bodyLight
//                     : AppTextStyles.bodyDark,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               subtitle: Text(
//                 current.artist ?? 'Desconocido',
//                 style: Theme.of(context).brightness == Brightness.light
//                     ? AppTextStyles.captionLight
//                     : AppTextStyles.captionDark,
//               ),
//               trailing: IconButton(
//                 icon: Icon(
//                   audio.isPlaying
//                       ? Icons.pause
//                       : (audio.current == null ? Icons.stop : Icons.play_arrow),
//                   color: Theme.of(context).brightness == Brightness.light
//                       ? AppColors.primary
//                       : AppColors.white,
//                 ),
//                 onPressed: () {
//                   if (audio.isPlaying) {
//                     audio.pause();
//                   } else if (audio.current == null) {
//                     // Estado de stop
//                   } else {
//                     audio.resume();
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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
    final audio = context.watch<AudioProvider>();
    final current = audio.current;

    // 🔑 ESTADO VISIBLE CUANDO NO HAY REPRODUCCIÓN
    if (current == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppColors.softShadow],
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isDark
                ? Colors.blueGrey.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.1),
            child: Icon(
              Icons.music_off,
              color: isDark ? Colors.white38 : AppColors.primary,
            ),
          ),
          title: Text(
            "PZ Player",
            style: isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight,
          ),
          subtitle: Text(
            "Selecciona una canción",
            style: isDark
                ? AppTextStyles.captionDark
                : AppTextStyles.captionLight,
          ),
          trailing: Icon(
            Icons.play_circle_outline,
            color: isDark ? Colors.white24 : Colors.black26,
            size: 32,
          ),
        ),
      );
    }

    // --- ESTADO CUANDO SÍ HAY UNA CANCIÓN SELECCIONADA ---
    final coverBytes = audio.normalizeCover(current.extras?['coverBytes']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
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
            // Barra de progreso fina
            StreamBuilder<Duration>(
              stream: audio.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = audio.duration ?? Duration.zero;
                final double progress = (duration.inMilliseconds > 0)
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
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: CircleAvatar(
                backgroundColor: isDark ? Colors.blueGrey : AppColors.primary,
                backgroundImage: coverBytes != null
                    ? MemoryImage(coverBytes)
                    : null,
                child: coverBytes == null
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
                onPressed: () {
                  if (audio.isPlaying) {
                    audio.pause();
                  } else {
                    audio.resume();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
