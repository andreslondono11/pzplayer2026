// import 'dart:math';
// import 'dart:ui';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:provider/provider.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:audio_service/audio_service.dart';
// import 'package:pzplayer/core/audio/audio_provider.dart';
// import 'package:pzplayer/core/audio/equalizador.dart';
// import 'package:pzplayer/core/theme/app_colors.dart';
// import 'package:pzplayer/core/theme/app_text_styles.dart';
// import 'package:pzplayer/ui/widgets/progess.dart';

// class PlayerScreen extends StatefulWidget {
//   const PlayerScreen({super.key});

//   @override
//   State<PlayerScreen> createState() => _PlayerScreenState();
// }

// class _PlayerScreenState extends State<PlayerScreen>
//     with SingleTickerProviderStateMixin {
//   final FlutterTts _tts = FlutterTts();
//   late AnimationController _rotationController;
//   final Map<int, Uint8List?> _coverCache = {};

//   @override
//   void initState() {
//     super.initState();
//     _initTts();
//     _rotationController = AnimationController(
//       duration: const Duration(seconds: 15),
//       vsync: this,
//     );

//     // ✅ REGISTRO AL ABRIR PANTALLA
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final audio = context.read<AudioProvider>();
//       if (audio.current != null) {
//         audio.registrarReproduccionUniversal(audio.current!);
//       }
//     });
//   }

//   void _initTts() {
//     _tts.setLanguage("es-ES");
//     _tts.setPitch(1.0);
//     _tts.setSpeechRate(0.9);
//   }

//   @override
//   void dispose() {
//     _tts.stop();
//     _rotationController.dispose();
//     super.dispose();
//   }

//   String _randomAdvice(
//     String songTitle,
//     String? artist,
//     String? genre,
//     String? album,
//   ) {
//     final frases = [
//       "Este álbum de $album es un testimonio de resiliencia, donde cada canción es un triunfo sobre la adversidad.",
//       "En cada nota de $songTitle encuentro la certeza de que la resiliencia es la música del alma.",

//       "PZPlayer presenta la canción $songTitle: el sonido de tu destino.",
//     ];
//     return frases[Random().nextInt(frases.length)];
//   }

//   @override
//   Widget build(BuildContext context) {
//     final audio = context.watch<AudioProvider>();
//     final current = audio.current;
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     if (audio.isPlaying && !_rotationController.isAnimating) {
//       _rotationController.repeat();
//     } else if (!audio.isPlaying && _rotationController.isAnimating) {
//       _rotationController.stop();
//     }

//     if (current == null) {
//       return Scaffold(
//         backgroundColor: isDark ? Colors.black : Colors.white,
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     final dynamic rawId = current.extras?['dbId'];
//     final int songId = (rawId is int)
//         ? rawId
//         : int.tryParse(rawId?.toString() ?? '0') ?? 0;

//     return Scaffold(
//       body: Stack(
//         children: [
//           _buildThemedBackground(isDark),
//           GestureDetector(
//             onVerticalDragEnd: (details) {
//               if (details.primaryVelocity != null &&
//                   details.primaryVelocity! > 500) {
//                 Navigator.pop(context);
//               }
//             },
//             child: SafeArea(
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   final bool isLandscape =
//                       constraints.maxWidth > constraints.maxHeight;

//                   return Column(
//                     children: [
//                       _buildCloseButton(context, isDark),
//                       Expanded(
//                         child: isLandscape
//                             ? _buildLandscape(
//                                 context,
//                                 audio,
//                                 current,
//                                 songId,
//                                 isDark,
//                                 constraints,
//                               )
//                             : _buildPortrait(
//                                 context,
//                                 audio,
//                                 current,
//                                 songId,
//                                 isDark,
//                               ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: _buildGlassFab(current, isDark),
//     );
//   }

//   Widget _buildThemedBackground(bool isDark) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: isDark
//               ? [const Color(0xFF1a0b2e), const Color(0xFF000000)]
//               : [Colors.grey.shade100, Colors.white],
//         ),
//       ),
//     );
//   }

//   Widget _buildPortrait(
//     BuildContext context,
//     AudioProvider audio,
//     MediaItem current,
//     int songId,
//     bool isDark,
//   ) {
//     return Column(
//       children: [
//         Text(
//           'Desliza para cambiar',
//           style: TextStyle(
//             color: isDark ? Colors.white54 : Colors.black54,
//             fontSize: 12,
//           ),
//         ),
//         const Spacer(),
//         _buildCover(audio, current, songId, 300),
//         const Spacer(),
//         _buildMetadata(current, isDark),
//         const SizedBox(height: 20),
//         const Padding(
//           padding: EdgeInsets.symmetric(horizontal: 25),
//           child: ProgressBarWidget(),
//         ),
//         const SizedBox(height: 10),
//         _buildFullControls(audio, isDark),
//         const SizedBox(height: 40),
//       ],
//     );
//   }

//   Widget _buildLandscape(
//     BuildContext context,
//     AudioProvider audio,
//     MediaItem current,
//     int songId,
//     bool isDark,
//     BoxConstraints constraints,
//   ) {
//     double dynamicDiskSize = constraints.maxHeight * 0.65;
//     return Row(
//       children: [
//         Expanded(
//           flex: 4,
//           child: Center(
//             child: _buildCover(audio, current, songId, dynamicDiskSize),
//           ),
//         ),
//         Expanded(
//           flex: 5,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _buildMetadata(current, isDark),
//                 const SizedBox(height: 15),
//                 const Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 20),
//                   child: ProgressBarWidget(),
//                 ),
//                 _buildFullControls(audio, isDark),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCloseButton(BuildContext context, bool isDark) {
//     return IconButton(
//       icon: Icon(
//         Icons.keyboard_arrow_down_rounded,
//         size: 45,
//         color: isDark ? Colors.white70 : Colors.black87,
//       ),
//       onPressed: () => Navigator.pop(context),
//     );
//   }

//   Widget _buildCover(
//     AudioProvider audio,
//     MediaItem current,
//     int songId,
//     double size,
//   ) {
//     // Calculate favorite status once to improve performance
//     final bool isFavorite = audio.isSongFavorite(current);
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     // final bool isFavorite = audio.isSongFavorite(current);
//     return GestureDetector(
//       onHorizontalDragEnd: (details) {
//         if (details.primaryVelocity != null) {
//           if (details.primaryVelocity! < 0) audio.skipNext();
//           if (details.primaryVelocity! > 0) audio.skipPrevious();
//         }
//       },
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Background shadow
//           Container(
//             width: size,
//             height: size,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.5),
//                   blurRadius: 40,
//                   spreadRadius: 2,
//                 ),
//               ],
//             ),
//           ),
//           // Rotating Vinyl Disk
//           RotationTransition(
//             turns: _rotationController,
//             child: Container(
//               width: size,
//               height: size,
//               decoration: const BoxDecoration(
//                 shape: BoxShape.circle,
//                 gradient: RadialGradient(
//                   colors: [
//                     Colors.black45,
//                     Colors.black,
//                     Colors.black87,
//                     Colors.black,
//                   ],
//                   stops: [0.0, 0.4, 0.7, 1.0],
//                 ),
//               ),
//               child: CustomPaint(painter: VinylLinesPainter()),
//             ),
//           ),
//           // Album Art
//           RotationTransition(
//             turns: _rotationController,
//             child: ClipOval(child: _buildDiskArt(songId, size * 0.99)),
//           ),
//           // Center Pin (Spindle)
//           Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.9),
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 2),
//               ],
//             ),
//           ),
//           // Favorite Button
//           Positioned(
//             top: 10,
//             right: 10,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.3),
//                 shape: BoxShape.circle,
//               ),
//               child: IconButton(
//                 icon: Icon(
//                   isFavorite ? Icons.favorite : Icons.favorite_border,
//                   color: isFavorite
//                       ? Colors.red
//                       : (isDark ? Colors.white70 : Colors.black54),
//                   size: 28,
//                 ),
//                 onPressed: () => audio.toggleFavoriteSong(current),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDiskArt(int songId, double artsize) {
//     if (songId == 0) return _defaultDiskIcon(artsize);
//     if (_coverCache.containsKey(songId)) {
//       return _diskImageContainer(_coverCache[songId], artsize);
//     }

//     return FutureBuilder<Uint8List?>(
//       future: OnAudioQuery().queryArtwork(songId, ArtworkType.AUDIO, size: 500),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.done) {
//           _coverCache[songId] = snapshot.data;
//           return _diskImageContainer(snapshot.data, artsize);
//         }
//         return _diskImageContainer(null, artsize);
//       },
//     );
//   }

//   Widget _diskImageContainer(Uint8List? bytes, double artsize) {
//     return Container(
//       width: artsize,
//       height: artsize,
//       color: Colors.grey.shade900,
//       child: bytes != null
//           ? Image.memory(bytes, fit: BoxFit.cover)
//           : _defaultDiskIcon(artsize),
//     );
//   }

//   Widget _defaultDiskIcon(double artsize) {
//     return Icon(Icons.music_note, color: Colors.white24, size: artsize * 0.5);
//   }

//   Widget _buildMetadata(MediaItem current, bool isDark) {
//     final textColor = isDark ? Colors.white : Colors.black87;
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 30),
//           child: Text(
//             current.title,
//             style: TextStyle(
//               color: textColor,
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//             ),
//             textAlign: TextAlign.center,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           current.artist ?? 'Desconocido',
//           style: TextStyle(
//             color: isDark ? Colors.white60 : Colors.black54,
//             fontSize: 16,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFullControls(AudioProvider audio, bool isDark) {
//     final iconColor = isDark ? Colors.white : Colors.black87;
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 20),
//       padding: const EdgeInsets.symmetric(vertical: 15),
//       decoration: BoxDecoration(
//         color: isDark
//             ? Colors.white.withOpacity(0.08)
//             : Colors.black.withOpacity(0.04),
//         borderRadius: BorderRadius.circular(35),
//         border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               IconButton(
//                 icon: Icon(
//                   Icons.skip_previous_rounded,
//                   size: 45,
//                   color: iconColor,
//                 ),
//                 onPressed: audio.skipPrevious,
//               ),
//               GestureDetector(
//                 onTap: () => audio.isPlaying ? audio.pause() : audio.resume(),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: iconColor,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     audio.isPlaying
//                         ? Icons.pause_rounded
//                         : Icons.play_arrow_rounded,
//                     size: 45,
//                     color: isDark ? Colors.black : Colors.white,
//                   ),
//                 ),
//               ),
//               IconButton(
//                 icon: Icon(Icons.skip_next_rounded, size: 45, color: iconColor),
//                 onPressed: audio.skipNext,
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const PlaylistButton(),
//               const SizedBox(width: 15),
//               IconButton(
//                 icon: const Icon(Icons.equalizer_rounded, size: 28),
//                 color: isDark ? Colors.white70 : Colors.black54,
//                 onPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const EqualizerScreen()),
//                 ),
//               ),
//               const SizedBox(width: 15),
//               IconButton(
//                 icon: Icon(
//                   audio.shuffleEnabled
//                       ? Icons.shuffle_on_rounded
//                       : Icons.shuffle_rounded,
//                   size: 28,
//                 ),
//                 color: audio.shuffleEnabled
//                     ? Colors.blueGrey
//                     : (isDark ? Colors.white70 : Colors.black54),
//                 onPressed: () => audio.toggleShuffle(),
//               ),
//               const SizedBox(width: 15),
//               IconButton(
//                 icon: Icon(
//                   audio.loopMode == LoopMode.one
//                       ? Icons.repeat_one_rounded
//                       : audio.loopMode == LoopMode.all
//                       ? Icons.repeat_on_rounded
//                       : Icons.repeat_rounded,
//                   size: 28,
//                 ),
//                 color: audio.loopMode != LoopMode.off
//                     ? Colors.blueGrey
//                     : (isDark ? Colors.white70 : Colors.black54),
//                 onPressed: () => audio.toggleLoopMode(),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGlassFab(MediaItem current, bool isDark) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(30),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: InkWell(
//           onTap: () async {
//             final advice = _randomAdvice(
//               current.title,
//               current.artist,
//               current.genre,
//               current.album,
//             );
//             await _tts.speak(advice);
//             if (!mounted) return;
//             showModalBottomSheet(
//               context: context,
//               backgroundColor: isDark ? Colors.black87 : Colors.white,
//               shape: const RoundedRectangleBorder(
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//               ),
//               builder: (_) => Container(
//                 padding: const EdgeInsets.all(30),
//                 child: Text(
//                   advice,
//                   style: TextStyle(
//                     color: isDark ? Colors.white : Colors.black87,
//                     fontSize: 18,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             );
//           },
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             decoration: BoxDecoration(
//               color: isDark
//                   ? Colors.white.withOpacity(0.1)
//                   : Colors.black.withOpacity(0.05),
//               borderRadius: BorderRadius.circular(30),
//               border: Border.all(
//                 color: isDark ? Colors.white24 : Colors.black12,
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(
//                   Icons.auto_awesome,
//                   color: Colors.deepPurpleAccent,
//                   size: 24,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   "IA",
//                   style: TextStyle(
//                     color: isDark ? Colors.white : Colors.black87,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class VinylLinesPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white.withOpacity(0.06)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;

//     final center = Offset(size.width / 2, size.height / 2);
//     for (var i = 1; i < 15; i++) {
//       canvas.drawCircle(center, (size.width / 2) * (i / 15), paint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// class PlaylistButton extends StatelessWidget {
//   const PlaylistButton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return IconButton(
//       icon: Icon(
//         Icons.queue_music,
//         size: 30,
//         color: isDark ? Colors.white : Colors.black,
//       ),
//       onPressed: () => _showQueueModal(context, isDark),
//     );
//   }

//   void _showQueueModal(BuildContext context, bool isDark) {
//     final audioInitial = Provider.of<AudioProvider>(context, listen: false);

//     if (audioInitial.queue.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("La cola está vacía")));
//       return;
//     }

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: isDark ? Colors.black87 : Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//       ),
//       builder: (context) => Consumer<AudioProvider>(
//         builder: (context, audio, child) {
//           final queue = audio.queue;
//           final currentSong = audio.currentSong;

//           return Container(
//             constraints: BoxConstraints(
//               maxHeight: MediaQuery.of(context).size.height * 0.80,
//             ),
//             child: SafeArea(
//               child: Column(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(25, 20, 15, 10),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "Cola de reproducción",
//                               style: isDark
//                                   ? AppTextStyles.subheadingDark
//                                   : AppTextStyles.subheadingLight,
//                             ),
//                             Text(
//                               "${queue.length} canciones",
//                               style: isDark
//                                   ? AppTextStyles.captionDark
//                                   : AppTextStyles.captionLight,
//                             ),
//                           ],
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.close),
//                           onPressed: () => Navigator.pop(context),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Divider(),
//                   Expanded(
//                     child: ReorderableListView.builder(
//                       onReorder: (oldIndex, newIndex) {
//                         if (newIndex > oldIndex) newIndex -= 1;
//                         audio.reorderQueue(oldIndex, newIndex);
//                       },
//                       itemCount: queue.length,
//                       padding: const EdgeInsets.only(bottom: 30),
//                       itemBuilder: (context, index) {
//                         final song = queue[index];
//                         final isPlaying = currentSong?.id == song.id;

//                         return ListTile(
//                           key: ValueKey(song.id),
//                           leading: Icon(
//                             isPlaying ? Icons.volume_up : Icons.music_note,
//                             color: isPlaying ? AppColors.primary : Colors.grey,
//                           ),
//                           title: Text(
//                             song.title,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style:
//                                 (isDark
//                                         ? AppTextStyles.bodyDark
//                                         : AppTextStyles.bodyLight)
//                                     .copyWith(
//                                       fontWeight: isPlaying
//                                           ? FontWeight.bold
//                                           : FontWeight.normal,
//                                       color: isPlaying
//                                           ? AppColors.primary
//                                           : null,
//                                     ),
//                           ),
//                           subtitle: Text(
//                             song.artist ?? 'Artista desconocido',
//                             style: isDark
//                                 ? AppTextStyles.captionDark
//                                 : AppTextStyles.captionLight,
//                           ),
//                           trailing: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               if (isPlaying)
//                                 const Text(
//                                   "SONANDO",
//                                   style: TextStyle(
//                                     color: Colors.green,
//                                     fontSize: 8,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               PopupMenuButton<String>(
//                                 icon: const Icon(Icons.more_vert, size: 22),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(15),
//                                 ),
//                                 onSelected: (value) {
//                                   // IMPORTANTE: Para 'favorite' no cerramos el menú manualmente si queremos tiempo real,
//                                   // pero PopupMenuButton cierra por defecto al seleccionar.
//                                   // Si usas el StatefulBuilder de abajo, manejamos el click internamente.
//                                   if (value != 'favorite') {
//                                     _handleMenuAction(
//                                       context,
//                                       value,
//                                       song,
//                                       audio,
//                                       index,
//                                     );
//                                   }
//                                 },
//                                 itemBuilder: (context) {
//                                   return [
//                                     _buildPopupItem(
//                                       'play_now',
//                                       Icons.play_arrow,
//                                       "Reproducir ahora",
//                                     ),
//                                     _buildPopupItem(
//                                       'info',
//                                       Icons.info_outline,
//                                       "Detalles",
//                                     ),
//                                     _buildPopupItem(
//                                       'add_playlist',
//                                       Icons.playlist_add,
//                                       "Añadir a playlist",
//                                     ),

//                                     // --- ITEM DE FAVORITO CON TIEMPO REAL ---
//                                     PopupMenuItem<String>(
//                                       value: 'favorite',
//                                       child: StatefulBuilder(
//                                         builder: (context, setMenuItemState) {
//                                           final bool isFav = audio
//                                               .isSongFavorite(song);
//                                           return InkWell(
//                                             onTap: () async {
//                                               // Ejecuta la lógica del provider
//                                               await audio.toggleFavoriteSong(
//                                                 song,
//                                               );
//                                               // Refresca el estado SOLO de este item
//                                               setMenuItemState(() {});
//                                             },
//                                             child: Row(
//                                               children: [
//                                                 Icon(
//                                                   isFav
//                                                       ? Icons.favorite
//                                                       : Icons.favorite_border,
//                                                   color: isFav
//                                                       ? Colors.red
//                                                       : (Theme.of(
//                                                                   context,
//                                                                 ).brightness ==
//                                                                 Brightness.dark
//                                                             ? Colors.blueGrey
//                                                             : Colors.black54),
//                                                 ),
//                                                 const SizedBox(width: 12),
//                                                 Text(
//                                                   isFav
//                                                       ? "Quitar de favoritos"
//                                                       : "Añadir a favoritos",
//                                                   style: TextStyle(
//                                                     color:
//                                                         Theme.of(
//                                                               context,
//                                                             ).brightness ==
//                                                             Brightness.dark
//                                                         ? Colors.white
//                                                         : Colors.black87,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                     ),

//                                     const PopupMenuDivider(),

//                                     _buildPopupItem(
//                                       'remove',
//                                       Icons.delete_outline,
//                                       "Quitar de la cola",
//                                       isDestructive: true,
//                                     ),
//                                   ];
//                                 },
//                               ),
//                               const Icon(
//                                 Icons.drag_handle,
//                                 color: Colors.grey,
//                                 size: 20,
//                               ),
//                             ],
//                           ),
//                           onTap: () {
//                             audio.registrarReproduccionUniversal(song);
//                             audio.playItems(queue, startIndex: index);
//                             Navigator.pop(context);
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Future<void> _handleMenuAction(
//     BuildContext context,
//     String value,
//     MediaItem song,
//     AudioProvider audio,
//     int index,
//   ) async {
//     switch (value) {
//       case 'play_now':
//         audio.registrarReproduccionUniversal(song);
//         audio.playItems([song]);
//         Navigator.pop(context);
//         break;
//       case 'info':
//         _showSongDetails(context, song);
//         break;
//       case 'add_playlist':
//         _showPlaylistSelector(context, song);
//         break;
//       // ✅ Corregido: Quitamos los espacios extra y el texto en español
//       case 'favorite':
//         audio.toggleFavoriteSong(song);

//         // Si tu _menuTile está dentro de un StatefulWidget,
//         // probablemente necesites llamar a setState(() {}) aquí
//         // para que el icono cambie visualmente antes de cerrar.
//         Navigator.pop(context);
//         // No olvides el Navigator.pop(context) si quieres que el menú se cierre al marcar
//         break;
//       case 'remove':
//         audio.removeFromQueue(index);
//         break;
//     }
//   }

//   PopupMenuItem<String> _buildPopupItem(
//     String value,
//     IconData icon,
//     String text, {
//     bool isDestructive = false,
//   }) {
//     return PopupMenuItem<String>(
//       value: value,
//       child: Row(
//         children: [
//           Icon(icon, size: 18, color: isDestructive ? Colors.red : null),
//           const SizedBox(width: 10),
//           Text(
//             text,
//             style: TextStyle(
//               color: isDestructive ? Colors.red : null,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSongDetails(BuildContext context, MediaItem song) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     // Extraemos datos adicionales de los 'extras' del MediaItem
//     final String path =
//         song.extras?['url'] ??
//         song.id; // La ID suele ser la ruta en archivos locales
//     final String genre = song.genre ?? "Desconocido";

//     // Obtenemos el nombre de la carpeta a partir de la ruta
//     final String folder = path.split('/').length > 1
//         ? path.split('/')[path.split('/').length - 2]
//         : "Raíz";

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         backgroundColor: isDark ? Colors.grey[900] : Colors.white,
//         title: Row(
//           children: [
//             Icon(
//               Icons.info_outline,
//               color: isDark ? Colors.blueGrey : AppColors.primary,
//             ),
//             const SizedBox(width: 10),
//             const Text("Detalles de la canción"),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _detailRow("Título", song.title, isDark),
//               _detailRow("Artista", song.artist ?? 'Desconocido', isDark),
//               _detailRow("Álbum", song.album ?? 'Desconocido', isDark),
//               _detailRow("Género", genre, isDark),
//               if (song.duration != null)
//                 _detailRow(
//                   "Duración",
//                   "${song.duration!.inMinutes}:${(song.duration!.inSeconds % 60).toString().padLeft(2, '0')}",
//                   isDark,
//                 ),
//               const Divider(),
//               _detailRow("Carpeta", folder, isDark),
//               _detailRow("Ubicación", path, isDark, isPath: true),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               "Cerrar",
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isDark ? Colors.white70 : AppColors.primary,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Widget auxiliar para organizar las filas de detalles
//   Widget _detailRow(
//     String label,
//     String value,
//     bool isDark, {
//     bool isPath = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//               color: isDark ? Colors.blueGrey : Colors.grey[600],
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 14,
//               color: isDark ? Colors.white : Colors.black87,
//               // Si es la ruta, permitimos que sea pequeña para que quepa mejor
//               fontStyle: isPath ? FontStyle.italic : FontStyle.normal,
//             ),
//             maxLines: isPath ? 3 : 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }

//   void _showPlaylistSelector(BuildContext context, MediaItem song) {
//     final audio = context.read<AudioProvider>();
//     final playlists = audio.playlists.keys.toList();
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text(
//           "Selecciona playlist",
//           style: isDark
//               ? AppTextStyles.headingDark
//               : AppTextStyles.headingLight,
//         ),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: playlists.isEmpty
//               ? const Text("No hay playlists creadas")
//               : ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: playlists.length,
//                   itemBuilder: (context, index) {
//                     final name = playlists[index];
//                     return ListTile(
//                       leading: Icon(
//                         Icons.queue_music,
//                         color: isDark ? Colors.blueGrey : AppColors.primary,
//                       ),
//                       title: Text(
//                         name,
//                         style: isDark
//                             ? AppTextStyles.bodyDark
//                             : AppTextStyles.bodyLight,
//                       ),
//                       onTap: () {
//                         audio.addToPlaylist(name, song);
//                         Navigator.pop(context);
//                       },
//                     );
//                   },
//                 ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancelar"),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:video_player/video_player.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/core/audio/equalizador.dart';
import 'package:pzplayer/core/theme/app_colors.dart';
import 'package:pzplayer/core/theme/app_text_styles.dart';
import 'package:pzplayer/ui/widgets/progess.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late AnimationController _rotationController;
  late VideoPlayerController _videoController;
  final Map<int, Uint8List?> _coverCache = {};
  bool _showAtmosphere = false;
  String? _lastSongId;
  late AudioProvider _audioProvider; // Referencia segura para dispose

  @override
  void initState() {
    super.initState();
    _initTts();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    // Inicializamos el controlador del video desde el inicio (Pre-cache)
    _videoController = VideoPlayerController.asset(
      'assets/videos/videoplayback.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    // Lo pre-cargamos en segundo plano
    _videoController.initialize().then((_) {
      _videoController.setVolume(0.0);
      _videoController.setLooping(true);
      setState(() {}); // Para que el Stack sepa que ya puede mostrarlo
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioProvider = context.read<AudioProvider>();

      if (_audioProvider.current != null) {
        _audioProvider.registrarReproduccionUniversal(_audioProvider.current!);
        _lastSongId = _audioProvider.current!.id;
      }

      _audioProvider.addListener(_onAudioChanged);
    });
  }

  // ✅ ESTA FUNCIÓN ES LA CLAVE: Detecta el cambio de canción
  void _onAudioChanged() {
    if (_showAtmosphere && _audioProvider.current != null) {
      if (_lastSongId != _audioProvider.current!.id) {
        _lastSongId = _audioProvider.current!.id;

        // El video ya está corriendo, solo disparamos la voz
        _playTtsAdvice(_audioProvider.current!);
      }
    }
  }

  void _initTts() {
    _tts.setLanguage("es-ES");
    _tts.setPitch(1.0);
    _tts.setSpeechRate(0.9);
  }

  void _playTtsAdvice(MediaItem current) {
    final advice = _randomAdvice(
      current.title,
      current.artist,
      current.genre,
      current.album,
    );
    _tts.speak(advice);
  }

  // ✅ FUNCIÓN DIAGNÓSTICA
  // ✅ Toggle ultra rápido
  void _toggleAtmosphere(MediaItem current) {
    setState(() {
      _showAtmosphere = !_showAtmosphere;
    });

    if (_showAtmosphere) {
      _lastSongId = current.id;
      // Como ya lo inicializamos en el initState, solo le damos play
      _videoController.play();
      _playTtsAdvice(current);
    } else {
      _lastSongId = null;
      _tts.stop();
      _videoController.pause();
    }
  }

  @override
  void dispose() {
    // 1. Limpiamos el listener usando la referencia guardada (adiós chillidos)
    _audioProvider.removeListener(_onAudioChanged);

    // 2. Paramos procesos
    _tts.stop();
    _rotationController.dispose();

    // 3. Limpieza profunda del video
    _videoController.pause();
    _videoController.dispose();

    super.dispose();
  }

  String _randomAdvice(
    String songTitle,
    String? artist,
    String? genre,
    String? album,
  ) {
    final frases = [
      "Este álbum de $album es un testimonio de resiliencia, donde cada canción es un triunfo sobre la adversidad.",
      "En cada nota de $songTitle encuentro la certeza de que la resiliencia es la música del alma.",
      "PZPlayer presenta la canción $songTitle: el sonido de tu destino.",

      // Lista de mensajes lista para copiar y pegar
      "Deja que las frecuencias de $songTitle reorganicen tu caos interno hoy.",
      "$album no es solo música; es el mapa sonoro de una voluntad que se negó a rendirse.",
      "Hay una verdad oculta entre los acordes de $songTitle que solo tu oído puede descifrar.",
      "La arquitectura sonora de $songTitle fue diseñada para sostenerte cuando el mundo pesa.",
      "Escuchar $songTitle es entablar una conversación privada con el alma de quien la creó.",
      "Si tu fuerza flaquea, deja que el tempo de $songTitle marque el ritmo de tu regreso.",
      "$songTitle es la prueba irrefutable de que se puede crear belleza a partir de las grietas.",
      "Que la armonía de $songTitle te recuerde que tu propia lucha también es una obra de arte.",
      "No es solo una pista; $songTitle es el eco de tu victoria personal sobre el silencio.",
      "Convierte la melancolía de $album en el combustible para tu próximo gran salto.",
      "Cierra los ojos. $songTitle es el único lugar del mundo donde el tiempo no tiene poder.",
      "La producción de $songTitle es el abrazo sónico que no sabías que necesitabas.",
      "Que la pureza de esta mezcla en $songTitle limpie el ruido del mundo exterior.",
      "Hay una luz especial en los arreglos de $songTitle; deja que ilumine tu camino hoy.",
      "En la pausa entre cada nota de $songTitle, encontrarás la paz que estabas buscando.",
      "Tu resiliencia tiene una firma sonora, y hoy se parece mucho a $songTitle.",
      "PZPlayer no reproduce archivos, libera emociones. Disfruta el viaje con $songTitle.",
      "Tu historia es el lienzo, y $songTitle es el color exacto que te hacía falta.",
      "Siente la profundidad del bajo en $songTitle; es el latido de tu propia persistencia.",
      "Que el brillo de los agudos en $songTitle aclare tus pensamientos en este momento.",
      "Cada matiz de $songTitle es un recordatorio de que los detalles en tu vida sí importan.",
      "Navega por el paisaje sonoro de $album y redescubre tu propia fuerza interior.",
      "La música de $artist en $songTitle es el bálsamo técnico para un espíritu cansado.",
      "Pzplatinum presenta: $songTitle, el sonido diseñado para acompañar tu destino.",
      "Deja que el sustain de $songTitle te enseñe a resistir un poco más. Casi llegas.",
    ];
    return frases[Random().nextInt(frases.length)];
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final current = audio.current;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (audio.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!audio.isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }

    if (current == null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final dynamic rawId = current.extras?['dbId'];
    final int songId = (rawId is int)
        ? rawId
        : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    return Scaffold(
      body: Stack(
        children: [
          // CAPA 1: VIDEO DE FONDO
          if (_showAtmosphere && _videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),

          // CAPA 2: FONDO GRADIENTE NORMAL
          if (!_showAtmosphere) _buildThemedBackground(isDark),

          // CAPA 3: OSCURECIMIENTO
          Container(
            color: _showAtmosphere
                ? Colors.black.withOpacity(0.4)
                : Colors.transparent,
          ),

          // CONTENIDO PRINCIPAL
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 500) {
                Navigator.pop(context);
              }
            },
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isLandscape =
                      constraints.maxWidth > constraints.maxHeight;

                  return Column(
                    children: [
                      _buildCloseButton(context, isDark, _showAtmosphere),
                      Expanded(
                        child: isLandscape
                            ? _buildLandscape(
                                context,
                                audio,
                                current,
                                songId,
                                isDark,
                                constraints,
                              )
                            : _buildPortrait(
                                context,
                                audio,
                                current,
                                songId,
                                isDark,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildAtmosphereFab(current, isDark),
    );
  }
  // Métodos auxiliares que asumo tienes definidos abajo para que el código compile:
  // Widget _buildThemedBackground(bool isDark) => Container(color: isDark ? Colors.black : Colors.white);
  // Widget _buildCloseButton(BuildContext c, bool d, bool a) => const SizedBox.shrink();
  // Widget _buildPortrait(BuildContext c, AudioProvider a, MediaItem m, int s, bool d) => const SizedBox.shrink();
  //   Widget _buildLandscape(BuildContext c, AudioProvider a, MediaItem m, int s, bool d, BoxConstraints bc) => const SizedBox.shrink();
  //   Widget _buildAtmosphereFab(MediaItem current, bool isDark) {
  //     return FloatingActionButton(
  //       onPressed: () => _toggleAtmosphere(current),
  //       child: Icon(_showAtmosphere ? Icons.auto_awesome : Icons.auto_awesome_outlined),
  //     );
  //   }
  // }

  Widget _buildThemedBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1a0b2e), const Color(0xFF000000)]
              : [Colors.grey.shade100, Colors.white],
        ),
      ),
    );
  }

  Widget _buildPortrait(
    BuildContext context,
    AudioProvider audio,
    MediaItem current,
    int songId,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          'Desliza para cambiar',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        _buildCover(audio, current, songId, 300),
        const Spacer(),
        _buildMetadata(current, isDark),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: ProgressBarWidget(),
        ),
        const SizedBox(height: 10),
        _buildFullControls(audio, isDark),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLandscape(
    BuildContext context,
    AudioProvider audio,
    MediaItem current,
    int songId,
    bool isDark,
    BoxConstraints constraints,
  ) {
    double dynamicDiskSize = constraints.maxHeight * 0.65;
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Center(
            child: _buildCover(audio, current, songId, dynamicDiskSize),
          ),
        ),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMetadata(current, isDark),
                const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ProgressBarWidget(),
                ),
                _buildFullControls(audio, isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton(
    BuildContext context,
    bool isDark,
    bool showAtmosphere,
  ) {
    return IconButton(
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 45,
        color: showAtmosphere
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black87),
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  Widget _buildCover(
    AudioProvider audio,
    MediaItem current,
    int songId,
    double size,
  ) {
    final bool isFavorite = audio.isSongFavorite(current);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < 0) audio.skipNext();
          if (details.primaryVelocity! > 0) audio.skipPrevious();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background shadow
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Rotating Vinyl Disk
          RotationTransition(
            turns: _rotationController,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.black45,
                    Colors.black,
                    Colors.black87,
                    Colors.black,
                  ],
                  stops: [0.0, 0.4, 0.7, 1.0],
                ),
              ),
              child: CustomPaint(painter: VinylLinesPainter()),
            ),
          ),
          // Album Art
          RotationTransition(
            turns: _rotationController,
            child: ClipOval(child: _buildDiskArt(songId, size * 0.99)),
          ),
          // Center Pin (Spindle)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 2),
              ],
            ),
          ),
          // Favorite Button
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? Colors.red
                      : (isDark ? Colors.white70 : Colors.black54),
                  size: 28,
                ),
                onPressed: () => audio.toggleFavoriteSong(current),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiskArt(int songId, double artsize) {
    if (songId == 0) return _defaultDiskIcon(artsize);
    if (_coverCache.containsKey(songId)) {
      return _diskImageContainer(_coverCache[songId], artsize);
    }

    return FutureBuilder<Uint8List?>(
      future: OnAudioQuery().queryArtwork(songId, ArtworkType.AUDIO, size: 500),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _coverCache[songId] = snapshot.data;
          return _diskImageContainer(snapshot.data, artsize);
        }
        return _diskImageContainer(null, artsize);
      },
    );
  }

  Widget _diskImageContainer(Uint8List? bytes, double artsize) {
    return Container(
      width: artsize,
      height: artsize,
      color: Colors.grey.shade900,
      child: bytes != null
          ? Image.memory(bytes, fit: BoxFit.cover)
          : _defaultDiskIcon(artsize),
    );
  }

  Widget _defaultDiskIcon(double artsize) {
    return Icon(Icons.music_note, color: Colors.white24, size: artsize * 0.5);
  }

  Widget _buildMetadata(MediaItem current, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            current.title,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          current.artist ?? 'Desconocido',
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildFullControls(AudioProvider audio, bool isDark) {
    final iconColor = isDark ? Colors.white : Colors.black87;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.skip_previous_rounded,
                  size: 45,
                  color: iconColor,
                ),
                onPressed: audio.skipPrevious,
              ),
              GestureDetector(
                onTap: () => audio.isPlaying ? audio.pause() : audio.resume(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    audio.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 45,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.skip_next_rounded, size: 45, color: iconColor),
                onPressed: audio.skipNext,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PlaylistButton(),
              const SizedBox(width: 15),
              IconButton(
                icon: const Icon(Icons.equalizer_rounded, size: 28),
                color: isDark ? Colors.white70 : Colors.black54,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                ),
              ),
              const SizedBox(width: 15),
              IconButton(
                icon: Icon(
                  audio.shuffleEnabled
                      ? Icons.shuffle_on_rounded
                      : Icons.shuffle_rounded,
                  size: 28,
                ),

                color: audio.shuffleEnabled
                    ? Colors.blueGrey
                    : (isDark ? Colors.white70 : Colors.black54),
                onPressed: () => audio.toggleShuffle(),
              ),
              const SizedBox(width: 15),
              IconButton(
                icon: Icon(
                  audio.loopMode == LoopMode.one
                      ? Icons.repeat_one_rounded
                      : audio.loopMode == LoopMode.all
                      ? Icons.repeat_on_rounded
                      : Icons.repeat_rounded,
                  size: 28,
                ),
                color: audio.loopMode != LoopMode.off
                    ? Colors.blueGrey
                    : (isDark ? Colors.white70 : Colors.black54),
                onPressed: () => audio.toggleLoopMode(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET DEL FAB MODIFICADO (BOTÓN MÁGICO)
  Widget _buildAtmosphereFab(MediaItem current, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: () => _toggleAtmosphere(current),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _showAtmosphere
                  ? Colors.white.withOpacity(0.3)
                  : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _showAtmosphere
                    ? Colors.white.withOpacity(0.5)
                    : (isDark ? Colors.white24 : Colors.black12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showAtmosphere
                      ? Icons.movie_filter
                      : Icons.video_camera_front,
                  color: Colors.deepPurpleAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _showAtmosphere ? "Modo Env" : "Inspirate con video",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- PAINTERS Y WIDGETS AUXILIARES (Vinyl, Playlist, Menús) ---
// Nota: He reorganizado los widgets auxiliares para asegurar que no haya problemas de referencia faltante y que el código sea completo.

class VinylLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 1; i < 15; i++) {
      canvas.drawCircle(center, (size.width / 2) * (i / 15), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlaylistButton extends StatelessWidget {
  const PlaylistButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      icon: Icon(
        Icons.queue_music,
        size: 30,
        color: isDark ? Colors.white : Colors.black,
      ),
      onPressed: () => _showQueueModal(context, isDark),
    );
  }

  void _showQueueModal(BuildContext context, bool isDark) {
    final audioInitial = Provider.of<AudioProvider>(context, listen: false);

    if (audioInitial.queue.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("La cola está vacía")));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.black87 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Consumer<AudioProvider>(
        builder: (context, audio, child) {
          final queue = audio.queue;
          final currentSong = audio.currentSong;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 20, 15, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cola de reproducción",
                              style: isDark
                                  ? AppTextStyles.subheadingDark
                                  : AppTextStyles.subheadingLight,
                            ),
                            Text(
                              "${queue.length} canciones",
                              style: isDark
                                  ? AppTextStyles.captionDark
                                  : AppTextStyles.captionLight,
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ReorderableListView.builder(
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        audio.reorderQueue(oldIndex, newIndex);
                      },
                      itemCount: queue.length,
                      padding: const EdgeInsets.only(bottom: 30),
                      itemBuilder: (context, index) {
                        final song = queue[index];
                        final isPlaying = currentSong?.id == song.id;

                        return ListTile(
                          key: ValueKey(song.id),
                          leading: Icon(
                            isPlaying ? Icons.volume_up : Icons.music_note,
                            color: isPlaying ? AppColors.primary : Colors.grey,
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                (isDark
                                        ? AppTextStyles.bodyDark
                                        : AppTextStyles.bodyLight)
                                    .copyWith(
                                      fontWeight: isPlaying
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isPlaying
                                          ? AppColors.primary
                                          : null,
                                    ),
                          ),
                          subtitle: Text(
                            song.artist ?? 'Artista desconocido',
                            style: isDark
                                ? AppTextStyles.captionDark
                                : AppTextStyles.captionLight,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPlaying)
                                const Text(
                                  "SONANDO",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 22),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                onSelected: (value) {
                                  // Lógica de menú integrada (incluyendo favorito)
                                  if (value != 'favorite') {
                                    _handleMenuAction(
                                      context,
                                      value,
                                      song,
                                      audio,
                                      index,
                                    );
                                  }
                                },
                                itemBuilder: (context) {
                                  return [
                                    _buildPopupItem(
                                      'play_now',
                                      Icons.play_arrow,
                                      "Reproducir ahora",
                                    ),
                                    _buildPopupItem(
                                      'info',
                                      Icons.info_outline,
                                      "Detalles",
                                    ),
                                    _buildPopupItem(
                                      'add_playlist',
                                      Icons.playlist_add,
                                      "Añadir a playlist",
                                    ),
                                    // ✅ ITEM DE FAVORITO CON TIEMPO REAL
                                    PopupMenuItem<String>(
                                      value: 'favorite',
                                      child: StatefulBuilder(
                                        builder: (context, setMenuItemState) {
                                          final bool isFav = audio
                                              .isSongFavorite(song);
                                          return InkWell(
                                            onTap: () async {
                                              await audio.toggleFavoriteSong(
                                                song,
                                              );
                                              setMenuItemState(() {});
                                            },
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isFav
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: isFav
                                                      ? Colors.red
                                                      : (Theme.of(
                                                                  context,
                                                                ).brightness ==
                                                                Brightness.dark
                                                            ? Colors.blueGrey
                                                            : Colors.black54),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  isFav
                                                      ? "Quitar de favoritos"
                                                      : "Añadir a favoritos",
                                                  style: TextStyle(
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    _buildPopupItem(
                                      'remove',
                                      Icons.delete_outline,
                                      "Quitar de la cola",
                                      isDestructive: true,
                                    ),
                                  ];
                                },
                              ),
                              const Icon(
                                Icons.drag_handle,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                          onTap: () {
                            audio.registrarReproduccionUniversal(song);
                            audio.playItems(queue, startIndex: index);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String value,
    MediaItem song,
    AudioProvider audio,
    int index,
  ) async {
    switch (value) {
      case 'play_now':
        audio.registrarReproduccionUniversal(song);
        audio.playItems([song]);
        Navigator.pop(context);
        break;
      case 'info':
        _showSongDetails(context, song);
        break;
      case 'add_playlist':
        _showPlaylistSelector(context, song);
        break;
      case 'favorite':
        // Lógica manejada dentro del StatefulBuilder del item
        break;
      case 'remove':
        audio.removeFromQueue(index);
        break;
    }
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String text, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDestructive ? Colors.red : null),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: isDestructive ? Colors.red : null,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showSongDetails(BuildContext context, MediaItem song) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String path = song.extras?['url'] ?? song.id;
    final String genre = song.genre ?? "Desconocido";

    // 📂 Lógica para carpeta
    final String folder = path.split('/').length > 1
        ? path.split('/')[path.split('/').length - 2]
        : "Raíz";

    // 📝 Obtener extensión y tamaño real
    String fileExtension = path.split('.').last.toUpperCase();
    String fileSize = "Calculando...";

    try {
      final file = File(path);
      if (file.existsSync()) {
        int bytes = file.lengthSync();
        fileSize = "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
      }
    } catch (e) {
      fileSize = "No disponible";
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Column(
          children: [
            Icon(
              Icons.audiotrack,
              size: 40,
              color: isDark ? Colors.blueAccent : AppColors.primary,
            ),
            const SizedBox(height: 10),
            const Text("Información Técnica", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("METADATOS", isDark),
              _detailRow("Título", song.title, isDark),
              _detailRow("Artista", song.artist ?? 'Desconocido', isDark),
              _detailRow("Álbum", song.album ?? 'Desconocido', isDark),
              _detailRow("Género", genre, isDark),

              const Divider(height: 30),
              _sectionTitle("ARCHIVO", isDark),
              _detailRow("Formato", fileExtension, isDark),
              _detailRow("Tamaño", fileSize, isDark),
              if (song.duration != null)
                _detailRow(
                  "Duración",
                  "${song.duration!.inMinutes}:${(song.duration!.inSeconds % 60).toString().padLeft(2, '0')}",
                  isDark,
                ),

              const Divider(height: 30),
              _sectionTitle("UBICACIÓN", isDark),
              _detailRow("Carpeta", folder, isDark),
              _detailRow("Ruta completa", path, isDark, isPath: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "ENTENDIDO",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.blueAccent : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 Widget auxiliar para títulos de sección
  Widget _sectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white38 : Colors.black38,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    bool isDark, {
    bool isPath = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDark ? Colors.blueGrey : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
              fontStyle: isPath ? FontStyle.italic : FontStyle.normal,
            ),
            maxLines: isPath ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showPlaylistSelector(BuildContext context, MediaItem song) {
    // Usamos listen: false porque estamos en una función, no en el build
    final audio = Provider.of<AudioProvider>(context, listen: false);
    final playlists = audio.playlists.keys.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // Usamos un context diferente para el diálogo
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Seleccionar Playlist",
          style: isDark
              ? AppTextStyles.headingDark
              : AppTextStyles.headingLight,
        ),
        content: SizedBox(
          width: double.maxFinite,
          // ConstrainedBox evita que el diálogo crezca infinitamente si hay muchas playlists
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height *
                  0.4, // Máximo 40% de la pantalla
            ),
            child: playlists.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No hay playlists creadas",
                      textAlign: TextAlign.center,
                      style: isDark
                          ? AppTextStyles.bodyDark
                          : AppTextStyles.bodyLight,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true, // Importante dentro de diálogos
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final name = playlists[index];
                      return ListTile(
                        leading: Icon(
                          Icons.queue_music,
                          color: isDark ? Colors.blueGrey : AppColors.primary,
                        ),
                        title: Text(
                          name,
                          style: isDark
                              ? AppTextStyles.subheadingDark
                              : AppTextStyles.bodyLight,
                        ),
                        onTap: () {
                          // 1. Ejecutar la lógica
                          audio.addToPlaylist(name, song);

                          // 2. Notificar al usuario (Opcional pero recomendado)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Añadida a $name"),
                              duration: const Duration(seconds: 1),
                            ),
                          );

                          // 3. Cerrar el diálogo usando el context del builder
                          Navigator.pop(dialogContext);
                        },
                      );
                    },
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "Cancelar",
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
