// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:on_audio_query/on_audio_query.dart';
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

//     if (current == null) return _buildEmptyState(isDark);

//     final dynamic rawArt = current.extras?['coverBytes'];
//     Uint8List? imageBytes;
//     if (rawArt is Uint8List) imageBytes = rawArt;

//     final dynamic rawId = current.extras?['dbId'];
//     final int songId = (rawId is int)
//         ? rawId
//         : int.tryParse(rawId?.toString() ?? '0') ?? 0;

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         // Fondo más suave con transparencia sutil
//         color: isDark
//             ? const Color(0xFF1E1E1E).withOpacity(0.92)
//             : Colors.white.withOpacity(0.94),
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(
//           color: isDark
//               ? Colors.white.withOpacity(0.05)
//               : Colors.black.withOpacity(0.05),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(24),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             onTap: () => Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const PlayerScreen()),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Handle más discreto y elegante
//                 const SizedBox(height: 6),
//                 Container(
//                   width: 30,
//                   height: 3,
//                   decoration: BoxDecoration(
//                     color: isDark ? Colors.white10 : Colors.black12,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),

//                 ListTile(
//                   contentPadding: const EdgeInsets.fromLTRB(14, 2, 10, 2),
//                   leading: Hero(
//                     tag: 'player_art',
//                     child: _buildLeadingImage(
//                       songId,
//                       imageBytes,
//                       isDark,
//                       audio.isPlaying,
//                     ),
//                   ),
//                   title: Text(
//                     current.title,
//                     style:
//                         (isDark
//                                 ? AppTextStyles.bodyDark
//                                 : AppTextStyles.bodyLight)
//                             .copyWith(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 14.5,
//                               letterSpacing: -0.2,
//                             ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   subtitle: Text(
//                     current.artist ?? 'Desconocido',
//                     style:
//                         (isDark
//                                 ? AppTextStyles.captionDark
//                                 : AppTextStyles.captionLight)
//                             .copyWith(
//                               fontSize: 12,
//                               color: isDark ? Colors.white60 : Colors.black54,
//                             ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   trailing: _buildPlayButton(audio, isDark),
//                 ),

//                 // Progreso más fino y minimalista
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: _buildProgressBar(audio, isDark),
//                 ),
//                 const SizedBox(height: 10),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLeadingImage(
//     int songId,
//     Uint8List? imageBytes,
//     bool isDark,
//     bool isPlaying,
//   ) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 500),
//       width: 44,
//       height: 44,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         boxShadow: [
//           if (isPlaying)
//             BoxShadow(
//               color: AppColors.secondary.withOpacity(0.2),
//               blurRadius: 10,
//               spreadRadius: 1,
//             ),
//         ],
//       ),
//       child: imageBytes != null
//           ? _buildCircleImage(imageBytes, isDark)
//           : FutureBuilder<Uint8List?>(
//               future: songId == 0
//                   ? Future.value(null)
//                   : OnAudioQuery().queryArtwork(
//                       songId,
//                       ArtworkType.AUDIO,
//                       size: 200,
//                     ),
//               builder: (context, snapshot) =>
//                   _buildCircleImage(snapshot.data, isDark),
//             ),
//     );
//   }

//   Widget _buildPlayButton(AudioProvider audio, bool isDark) {
//     return Container(
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: isDark
//             ? Colors.white.withOpacity(0.05)
//             : AppColors.primary.withOpacity(0.05),
//       ),
//       child: IconButton(
//         padding: EdgeInsets.zero,
//         icon: Icon(
//           audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
//           size: 32,
//           color: isDark ? Colors.white : AppColors.primary,
//         ),
//         onPressed: () => audio.isPlaying ? audio.pause() : audio.resume(),
//       ),
//     );
//   }

//   Widget _buildCircleImage(Uint8List? bytes, bool isDark) {
//     return Container(
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: isDark ? Colors.white : Colors.grey[100],
//         image: bytes != null
//             ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
//             : null,
//       ),
//       child: bytes == null
//           ? Icon(
//               Icons.music_note_rounded,
//               color: isDark
//                   ? Colors.white38
//                   : AppColors.primary.withOpacity(0.4),
//               size: 22,
//             )
//           : null,
//     );
//   }

//   Widget _buildProgressBar(AudioProvider audio, bool isDark) {
//     return StreamBuilder<Duration>(
//       stream: audio.positionStream,
//       builder: (context, snapshot) {
//         final position = snapshot.data ?? Duration.zero;
//         final duration = audio.duration ?? Duration.zero;
//         final progress = (duration.inMilliseconds > 0)
//             ? (position.inMilliseconds / duration.inMilliseconds).clamp(
//                 0.0,
//                 1.0,
//               )
//             : 0.0;

//         return ClipRRect(
//           borderRadius: BorderRadius.circular(10),
//           child: LinearProgressIndicator(
//             value: progress,
//             minHeight: 2.2, // Más fino
//             backgroundColor: isDark
//                 ? Colors.white.withOpacity(0.08)
//                 : Colors.black.withOpacity(0.05),
//             valueColor: AlwaysStoppedAnimation<Color>(
//               isDark
//                   ? AppColors.secondary.withOpacity(0.8)
//                   : AppColors.secondary,
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEmptyState(bool isDark) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       decoration: BoxDecoration(
//         color: isDark
//             ? Colors.white.withOpacity(0.03)
//             : Colors.black.withOpacity(0.02),
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: isDark ? Colors.white : Colors.black,
//           child: const Icon(
//             Icons.music_note_rounded,
//             color: Colors.grey,
//             size: 20,
//           ),
//         ),
//         title: Text(
//           "PZ Player",
//           style: (isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight)
//               .copyWith(fontSize: 14),
//         ),
//         subtitle: const Text(
//           "Listo para sonar",
//           style: TextStyle(color: Colors.grey, fontSize: 11),
//         ),
//       ),
//     );
//   }
// }
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
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

    if (current == null) return _buildEmptyState(isDark);

    final dynamic rawArt = current.extras?['coverBytes'];
    Uint8List? imageBytes;
    if (rawArt is Uint8List) imageBytes = rawArt;

    final dynamic rawId = current.extras?['dbId'];
    final int songId = (rawId is int)
        ? rawId
        : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    // 👇 DETECTAR SI ESTÁ ACOSTADO (HORIZONTAL)
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Container(
      // 👇 AQUÍ ESTÁ LA SOLUCIÓN:
      // En horizontal le fijamos un ancho de 250px para que NO se estire.
      // En vertical ocupará todo el ancho (double.infinity).
      width: isLandscape ? 250 : double.infinity,

      margin: isLandscape
          ? const EdgeInsets.only(
              left: 00,
              right: 00,
              bottom: 10,
              top: 10,
            ) // Pegado a la derecha
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayerScreen()),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle (Ocultarlo en landscape para ahorrar espacio)
                if (!isLandscape) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 30,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],

                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(14, 2, 10, 2),
                  leading: Hero(
                    tag: 'player_art',
                    child: _buildLeadingImage(
                      songId,
                      imageBytes,
                      isDark,
                      audio.isPlaying,
                    ),
                  ),
                  title: Text(
                    current.title,
                    style:
                        (isDark
                                ? AppTextStyles.bodyDark
                                : AppTextStyles.bodyLight)
                            .copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                              letterSpacing: -0.2,
                            ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    current.artist ?? 'Desconocido',
                    style:
                        (isDark
                                ? AppTextStyles.captionDark
                                : AppTextStyles.captionLight)
                            .copyWith(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _buildPlayButton(audio, isDark),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildProgressBar(audio, isDark),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingImage(
    int songId,
    Uint8List? imageBytes,
    bool isDark,
    bool isPlaying,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,

        boxShadow: [
          if (isPlaying)
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: imageBytes != null
          ? _buildCircleImage(imageBytes, isDark)
          : FutureBuilder<Uint8List?>(
              future: songId == 0
                  ? Future.value(null)
                  : OnAudioQuery().queryArtwork(
                      songId,
                      ArtworkType.AUDIO,
                      size: 200,
                    ),
              builder: (context, snapshot) =>
                  _buildCircleImage(snapshot.data, isDark),
            ),
    );
  }

  Widget _buildPlayButton(AudioProvider audio, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : AppColors.primary.withOpacity(0.05),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 32,
          color: isDark ? Colors.white : AppColors.primary,
        ),
        onPressed: () => audio.isPlaying ? audio.pause() : audio.resume(),
      ),
    );
  }

  Widget _buildCircleImage(Uint8List? bytes, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white : Colors.grey[100],
        image: bytes != null
            ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
            : null,
      ),
      child: bytes == null
          ? Icon(
              Icons.music_note_rounded,
              color: isDark
                  ? Colors.blueGrey
                  : AppColors.primary.withOpacity(0.4),
              size: 22,
            )
          : null,
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

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 2.2,
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.blueGrey : AppColors.secondary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDark ? Colors.white : Colors.black,
          child: const Icon(
            Icons.music_note_rounded,
            color: Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          "PZ Player",
          style: (isDark ? AppTextStyles.bodyDark : AppTextStyles.bodyLight)
              .copyWith(fontSize: 14),
        ),
        subtitle: const Text(
          "Listo para sonar",
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ),
    );
  }
}
