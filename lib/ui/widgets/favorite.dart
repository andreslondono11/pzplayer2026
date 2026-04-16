import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/core/theme/app_colors.dart';
import 'package:pzplayer/core/theme/app_text_styles.dart';
import 'package:pzplayer/ui/widgets/player_controls.dart';

class FavoriteSongsScreen extends StatefulWidget {
  const FavoriteSongsScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteSongsScreen> createState() => _FavoriteSongsScreenState();
}

class _FavoriteSongsScreenState extends State<FavoriteSongsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mis Favoritos",
          style: isDark
              ? AppTextStyles.headingDark
              : AppTextStyles.headingLight,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: isDark ? Colors.black : Colors.white,
      // ✅ CAMBIO ESTRUCTURAL: Usamos un Column para separar la lista del MiniPlayer
      body: Column(
        children: [
          // ✅ LA LISTA OCUPA TODO EL ESPACIO DISPONIBLE (Expanded)
          Expanded(
            child: Consumer<AudioProvider>(
              builder: (context, provider, child) {
                final allSongs = provider.items;
                final favoriteSongs = allSongs
                    .where((song) => provider.isSongFavorite(song))
                    .toList();

                if (favoriteSongs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "No tienes canciones favoritas aún.",
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
                  itemCount: favoriteSongs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final song = favoriteSongs[index];
                    final isLandscape =
                        MediaQuery.of(context).orientation ==
                        Orientation.landscape;

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        onTap: () {
                          provider.registrarReproduccionUniversal(song);
                          provider.playItems(favoriteSongs, startIndex: index);
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: QueryArtworkWidget(
                            id: song.extras?['dbId'] as int? ?? 0,
                            type: ArtworkType.AUDIO,
                            artworkHeight: 50,
                            artworkWidth: 50,
                            nullArtworkWidget: Container(
                              width: 50,
                              height: 50,
                              color: isDark ? Colors.white10 : Colors.black12,
                              child: Icon(
                                Icons.music_note,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: isDark
                              ? AppTextStyles.bodyDark
                              : AppTextStyles.bodyLight,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.artist ?? 'Desconocido',
                          style: isDark
                              ? AppTextStyles.captionDark
                              : AppTextStyles.captionLight,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                              isLandscape,
                              favoriteSongs,
                              index,
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
          // ✅ MINI PLAYER AL FINAL FIJO
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

  // -// --- MENÚ PERSISTENTE (Optimizado para tiempo real) ---
  void _showSongMenu(
    BuildContext context,
    MediaItem song,
    bool isLandscape,
    List<MediaItem> currentList,
    int currentIndex,
  ) {
    final audio = context.read<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: isLandscape,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      isDismissible: true, // Cambiado a true para mejor UX
      enableDrag: true, // Cambiado a true para poder deslizar y cerrar
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        // 👈 CLAVE: Permite actualizar el modal
        builder: (BuildContext context, StateSetter setModalState) {
          // Re-evaluamos el estado de favorito dentro del builder
          final bool isFav = audio.isSongFavorite(song);

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Opciones",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                // Opción: Reproducir ahora
                ListTile(
                  leading: Icon(
                    Icons.play_arrow,
                    color: isDark ? Colors.blueGrey : AppColors.primary,
                  ),
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

                // Opción: FAVORITOS (Actualización en tiempo real)
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
                    // 1. Ejecutamos la lógica en el Provider
                    await audio.toggleFavoriteSong(song);

                    // 2. ⚡ Forzamos el redibujado SOLO del contenido del modal
                    setModalState(() {});
                  },
                ),

                // Opción: Reproducir Siguiente
                ListTile(
                  leading: Icon(
                    Icons.queue_play_next,
                    color: isDark ? Colors.blueGrey : AppColors.primary,
                  ),
                  title: Text(
                    "Reproducir Siguiente",
                    style: isDark
                        ? AppTextStyles.bodyDark
                        : AppTextStyles.bodyLight,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    audio.playNext(song);
                  },
                ),

                // Opción: Añadir a la cola
                ListTile(
                  leading: Icon(
                    Icons.queue_music,
                    color: isDark ? Colors.blueGrey : AppColors.primary,
                  ),
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

                // Opción: Añadir Playlist
                ListTile(
                  leading: Icon(
                    Icons.playlist_add,
                    color: isDark ? Colors.blueGrey : AppColors.primary,
                  ),
                  title: Text(
                    "Añadir Playlist",
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
