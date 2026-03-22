import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:pzplayer/ui/widgets/playlist_detalle.dart';
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({
    super.key,
    required String playlistName,
    required List<MediaItem> songs,
  });

  @override
  Widget build(BuildContext context) {
    final playlists = context.watch<AudioProvider>().playlists;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Playlists",
          style: isDark
              ? AppTextStyles.headingDark
              : AppTextStyles.headingLight,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: isDark ? Colors.blueGrey : AppColors.primary,
            ),
            onPressed: () async {
              final nameController = TextEditingController();

              await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(
                    "Nueva Playlist",
                    style: isDark
                        ? AppTextStyles.subheadingDark
                        : AppTextStyles.subheadingLight,
                  ),
                  content: TextField(
                    controller: nameController,
                    style: isDark
                        ? AppTextStyles.bodyDark
                        : AppTextStyles.bodyLight,
                    decoration: InputDecoration(
                      hintText: "Nombre",
                      hintStyle: isDark
                          ? AppTextStyles.captionDark
                          : AppTextStyles.captionLight,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancelar",
                        style: isDark
                            ? AppTextStyles.button
                            : AppTextStyles.button2,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final name = nameController.text;
                        if (name.isNotEmpty) {
                          context.read<AudioProvider>().createPlaylist(name);
                          Navigator.pop(context);

                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) {
                              final items = context.read<AudioProvider>().items;
                              return SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.7,
                                child: ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final song = items[index];
                                    final dynamic rawCover =
                                        song.extras?['coverBytes'];

                                    Uint8List? coverBytes;
                                    if (rawCover is Uint8List) {
                                      coverBytes = rawCover;
                                    } else if (rawCover is List<int>) {
                                      coverBytes = Uint8List.fromList(rawCover);
                                    } else if (rawCover is List<dynamic>) {
                                      coverBytes = Uint8List.fromList(
                                        List<int>.from(rawCover),
                                      );
                                    }

                                    return ListTile(
                                      leading: coverBytes != null
                                          ? CircleAvatar(
                                              backgroundImage: MemoryImage(
                                                coverBytes,
                                              ),
                                            )
                                          : Icon(
                                              Icons.music_note,
                                              color: isDark
                                                  ? Colors.blueGrey
                                                  : AppColors.primary,
                                            ),
                                      title: Text(
                                        song.title,
                                        style: isDark
                                            ? AppTextStyles.bodyDark
                                            : AppTextStyles.bodyLight,
                                      ),
                                      subtitle: Text(
                                        song.artist ?? 'Desconocido',
                                        style: isDark
                                            ? AppTextStyles.captionDark
                                            : AppTextStyles.captionLight,
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.add_circle,
                                          color: AppColors.primary,
                                        ),
                                        onPressed: () {
                                          context
                                              .read<AudioProvider>()
                                              .addToPlaylist(name, song);
                                        },
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        }
                      },
                      child: Text(
                        "Siguiente",
                        style: isDark
                            ? AppTextStyles.button
                            : AppTextStyles.button2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: playlists.isEmpty
          ? Center(
              child: Text(
                "No hay playlists",
                style: isDark
                    ? AppTextStyles.captionDark
                    : AppTextStyles.captionLight,
              ),
            )
          : ListView.builder(
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlistName = playlists.keys.elementAt(index);
                final songs = playlists.values.elementAt(index);

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

                return ListTile(
                  leading: coverBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            coverBytes,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          ),
                        )
                      : Icon(
                          Icons.queue_music,
                          size: 40,
                          color: isDark ? Colors.blueGrey : AppColors.primary,
                        ),
                  title: Text(
                    playlistName,
                    style: isDark
                        ? AppTextStyles.subheadingDark
                        : AppTextStyles.subheadingLight,
                  ),
                  subtitle: Text(
                    "${songs.length} canciones",
                    style: isDark
                        ? AppTextStyles.darktoi
                        : AppTextStyles.darktoa,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // IconButton(
                      //   icon: Icon(Icons.play_arrow, color: AppColors.primary),
                      //   onPressed: () {
                      //     context.read<AudioProvider>().playPlaylist(
                      //       playlistName,
                      //     );
                      //   },
                      // ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: isDark ? Colors.blueGrey : AppColors.primary,
                        ),
                        onPressed: () {
                          context.read<AudioProvider>().deletePlaylist(
                            playlistName,
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailScreen(
                          playlistName: playlistName,
                          songs: songs,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
