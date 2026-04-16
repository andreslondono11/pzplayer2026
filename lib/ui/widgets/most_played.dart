import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/core/theme/app_colors.dart';
import 'package:pzplayer/core/theme/app_text_styles.dart';
import 'package:pzplayer/ui/widgets/player_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MostPlayedScreen extends StatefulWidget {
  const MostPlayedScreen({Key? key}) : super(key: key);

  @override
  State<MostPlayedScreen> createState() => _MostPlayedScreenState();
}

class _MostPlayedScreenState extends State<MostPlayedScreen> {
  // Mapa para guardar los contadores de reproducciones y ordenar correctamente
  Map<String, int> _countsMap = {};
  // Variable para guardar el tiempo total calculado
  String _globalTimeStr = "Calculando...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<AudioProvider>(context, listen: false);

      // 1. Cargamos el ranking del provider
      await provider.cargarMasEscuchados('songs');

      // 2. Cargamos los contadores desde SharedPreferences para ordenar y mostrar
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> rawMap = jsonDecode(
        prefs.getString('counts_songs') ?? '{}',
      );

      // Convertimos a Map<String, int> para facilitar el uso
      setState(() {
        _countsMap = rawMap.map((key, value) => MapEntry(key, (value as int)));
      });

      // 3. Calculamos el tiempo total usando el mapa cargado
      if (mounted) {
        final time = await _calculateGlobalTime(provider);
        setState(() {
          _globalTimeStr = time;
        });
      }
    });
  }

  /// Formato estricto HH:MM:SS o MM:SS (Sin redondeos tipo "1h 30m")
  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = secs.toString().padLeft(2, '0');

    if (hours > 0) {
      return "$hoursStr:$minutesStr:$secondsStr";
    } else {
      return "$minutesStr:$secondsStr";
    }
  }

  Future<String> _calculateGlobalTime(AudioProvider provider) async {
    try {
      int totalSeconds = 0;

      // Usamos take(500) para no congelar la app si la biblioteca es gigante
      for (var song in provider.items.take(500)) {
        // Usamos el mapa cargado en memoria en lugar de leer prefs de nuevo
        final id = song.extras?['dbId']?.toString() ?? song.id;
        final count = _countsMap[id] ?? 0;

        if (count > 0 && song.duration != null) {
          totalSeconds += (song.duration!.inSeconds * count).toInt();
        }
      }

      return _formatDuration(totalSeconds);
    } catch (e) {
      return "Error";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Top 10 Canciones",
          style: isDark
              ? AppTextStyles.headingDark
              : AppTextStyles.headingLight,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Column(
        children: [
          // LISTA Y CONTENIDO
          Expanded(
            child: Consumer<AudioProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingMostPlayed) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Tomamos todas las canciones candidatas
                final allRankedSongs = provider.mostPlayedItems
                    .whereType<MediaItem>()
                    .toList();

                // Las ordenamos MANUALMENTE basándonos en el contador de reproducciones
                allRankedSongs.sort((a, b) {
                  final idA = a.extras?['dbId']?.toString() ?? a.id;
                  final idB = b.extras?['dbId']?.toString() ?? b.id;
                  final countA = _countsMap[idA] ?? 0;
                  final countB = _countsMap[idB] ?? 0;
                  // Orden descendente (mayor a menor)
                  return countB.compareTo(countA);
                });

                // Filtramos para asegurar que solo mostramos canciones con > 0 reproducciones
                final validSongs = allRankedSongs.where((s) {
                  final id = s.extras?['dbId']?.toString() ?? s.id;
                  return (_countsMap[id] ?? 0) > 0;
                }).toList();

                // Tomamos el Top 10 definitivo
                final top10 = validSongs.take(10).toList();

                if (top10.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Aún no has escuchado canciones suficientes.\n¡Reproduce música para ver el ranking!",
                        textAlign: TextAlign.center,
                        style: isDark
                            ? AppTextStyles.captionDark
                            : AppTextStyles.captionLight,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: top10.length + 1, // +1 Cabecera
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    // ITEM 0: CABECERA TIEMPO TOTAL
                    if (index == 0) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.history, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Text(
                                  "Tiempo total escuchado",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _globalTimeStr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // RESTO: CANCIONES
                    final itemIndex = index - 1;
                    final song = top10[itemIndex];

                    // ✅ COLOR UNIFORME PARA TODOS (Sin colores de medalla)
                    final rankColor = Colors.blueGrey;

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        // ✅ BORDE UNIFORME PARA TODOS
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black12,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        onTap: () {
                          provider.registrarReproduccionUniversal(song);
                          provider.play(song);
                        },
                        leading: Container(
                          width: 30,
                          alignment: Alignment.center,
                          child: Text(
                            "#${itemIndex + 1}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: rankColor, // Color uniforme
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: QueryArtworkWidget(
                                id: song.extras?['dbId'] as int? ?? 0,
                                type: ArtworkType.AUDIO,
                                artworkHeight: 50,
                                artworkWidth: 50,
                                nullArtworkWidget: Container(
                                  width: 50,
                                  height: 50,
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12,
                                  child: Icon(
                                    Icons.music_note,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    style: isDark
                                        ? AppTextStyles.bodyDark
                                        : AppTextStyles.bodyLight,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    song.artist ?? 'Desconocido',
                                    style: isDark
                                        ? AppTextStyles.captionDark
                                        : AppTextStyles.captionLight,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Duración de la canción
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    song.duration != null
                                        ? "${song.duration!.inMinutes}:${(song.duration!.inSeconds % 60).toString().padLeft(2, '0')}"
                                        : "--:--",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              // Contador de veces (Directo desde memoria, sin FutureBuilder)
                              Row(
                                children: [
                                  Icon(
                                    Icons.headphones,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${_countsMap[song.extras?['dbId']?.toString() ?? song.id] ?? 0} veces",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          onPressed: () {
                            _showSongMenu(
                              context,
                              song,
                              top10, // Pasamos la lista top10
                              itemIndex,
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // MINI PLAYER
          const MiniPlayer(),
        ],
      ),
    );
  }

  void _showPlaylistSelector(BuildContext context, MediaItem song) {
    final audio = context.read<AudioProvider>();
    final playlists = audio.playlists.keys.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Selecciona playlist",
          style: isDark ? AppTextStyles.darkto : AppTextStyles.darkti,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final name = playlists[index];
              return ListTile(
                leading: Icon(
                  Icons.queue_music,
                  color: isDark ? Colors.blueGrey : AppColors.secondary,
                ),
                title: Text(
                  name,
                  style: isDark ? AppTextStyles.darkto : AppTextStyles.darkti,
                ),
                onTap: () {
                  Navigator.pop(context);
                  audio.addToPlaylist(name, song);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancelar",
              style: isDark ? AppTextStyles.button : AppTextStyles.button2,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSongMenu(
    BuildContext context,
    MediaItem song,
    List<MediaItem> currentList,
    int currentIndex,
  ) {
    final audio = context.read<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final bool isFav = audio.isSongFavorite(song);

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Opciones",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                ListTile(
                  leading: Icon(Icons.play_arrow, color: AppColors.primary),
                  title: Text(
                    "Reproducir ahora",
                    style: isDark
                        ? AppTextStyles.bodyDark
                        : AppTextStyles.bodyLight,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    audio.registrarReproduccionUniversal(song);
                    audio.playItems([song]);
                  },
                ),
                ListTile(
                  leading: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav
                        ? Colors.red
                        : (isDark ? Colors.blueGrey : AppColors.primary),
                  ),
                  title: Text(
                    isFav ? "Quitar de favoritos" : "Añadir a favoritos",
                    style: isDark
                        ? AppTextStyles.bodyDark
                        : AppTextStyles.bodyLight,
                  ),
                  onTap: () async {
                    await audio.toggleFavoriteSong(song);
                    setModalState(() {});
                  },
                ),
                ListTile(
                  leading: Icon(Icons.queue_music, color: AppColors.primary),
                  title: Text(
                    "Añadir a la cola",
                    style: isDark
                        ? AppTextStyles.bodyDark
                        : AppTextStyles.bodyLight,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    audio.addToQueue(song);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.playlist_add, color: AppColors.primary),
                  title: Text(
                    "Añadir a Playlist",
                    style: isDark
                        ? AppTextStyles.bodyDark
                        : AppTextStyles.bodyLight,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showPlaylistSelector(context, song);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
