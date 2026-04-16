import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import 'package:pzplayer/ui/widgets/genre_detalle.dart';
import '../../core/audio/audio_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// ✅ CAMBIO A STATEFULWIDGET para manejar la caché de imágenes
class GenreScreen extends StatefulWidget {
  const GenreScreen({
    super.key,
    required String genreName,
    required List<dynamic> songs,
  });

  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen> {
  // --- MAPA DE CACHÉ ---
  // Guardaremos las imágenes aquí usando el nombre del género como llave.
  // Ejemplo: { "Rock": Uint8List(...), "Salsa": Uint8List(...) }
  final Map<String, Uint8List> _genreArtCache = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Map<String, List<MediaItem>> genresMap = provider.genres;
    final Map<String, List<MediaItem>> filteredGenres = Map.from(genresMap);
    filteredGenres.remove('Desconocido');

    final sortedKeys = filteredGenres.keys.toList()..sort();

    // Agregamos "Todas las Canciones" al final
    sortedKeys.add('Todas las Canciones');

    if (filteredGenres.isEmpty && sortedKeys.length <= 1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              "No hay géneros encontrados",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => provider.refreshLibrary(),
              icon: const Icon(Icons.refresh),
              label: const Text("Forzar Escaneo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.blueGrey : Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double minCardWidth = 150;
        int crossAxisCount = (constraints.maxWidth / minCardWidth).floor();
        crossAxisCount = crossAxisCount.clamp(2, 6);

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.78,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
          ),
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final genreName = sortedKeys[index];

            // --- TARJETA "TODAS LAS CANCIONES" ---
            if (genreName == 'Todas las Canciones') {
              return _buildAllSongsCard(context, isDark, provider.items.length);
            }

            // --- TARJETA DE GÉNERO NORMAL ---
            final songs = filteredGenres[genreName]!;

            // 🎨 LÓGICA DE IMAGEN CON PERSISTENCIA (CACHÉ)
            return _buildGenreCard(context, genreName, songs, isDark);
          },
        );
      },
    );
  }

  // Widget dedicado a construir la tarjeta con lógica de caché
  // Widget dedicado a construir la tarjeta con lógica de caché
  Widget _buildGenreCard(
    BuildContext context,
    String genreName,
    List<MediaItem> songs,
    bool isDark,
  ) {
    // 1. Verificar si YA TENEMOS la imagen en caché
    if (_genreArtCache.containsKey(genreName)) {
      return _buildCardWithImage(
        context,
        genreName,
        songs,
        isDark,
        _genreArtCache[genreName]!,
      );
    }

    // 2. Si NO está en caché, buscar el ID de la primera canción válida
    int? dbId;
    for (var song in songs) {
      final id = song.extras?['dbId'];
      if (id is int && id > 0) {
        dbId = id;
        break;
      }
    }

    // 3. Si tenemos ID, cargar imagen
    if (dbId != null) {
      return FutureBuilder<Uint8List?>(
        future: OnAudioQuery().queryArtwork(
          dbId,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: 400,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty) {
            // ✅ CORRECCIÓN DEFINITIVA: Solo guardamos en el mapa. SIN setState.
            // El widget se redibuja automáticamente porque FutureBuilder actualizó su estado.
            if (!_genreArtCache.containsKey(genreName)) {
              _genreArtCache[genreName] = snapshot.data!;
            }

            return _buildCardWithImage(
              context,
              genreName,
              songs,
              isDark,
              snapshot.data!,
            );
          }
          // Mientras carga o falla, mostrar placeholder
          return _buildCardPlaceholder(context, genreName, songs, isDark);
        },
      );
    }

    // 4. Si no hay ID, mostrar placeholder directamente
    return _buildCardPlaceholder(context, genreName, songs, isDark);
  }

  // 4. Si no hay ID, mostrar placeholder directamente

  // Construye la tarjeta visual final con la imagen ya cargada
  Widget _buildCardWithImage(
    BuildContext context,
    String genreName,
    List<MediaItem> songs,
    bool isDark,
    Uint8List imageBytes,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                GenreDetailScreen(genreName: genreName, songs: songs),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  genreName,
                  style: isDark
                      ? AppTextStyles.bodyDark.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )
                      : AppTextStyles.bodyLight.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${songs.length} canciones",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construye la tarjeta visual con el placeholder (sin imagen)
  Widget _buildCardPlaceholder(
    BuildContext context,
    String genreName,
    List<MediaItem> songs,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                GenreDetailScreen(genreName: genreName, songs: songs),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: _buildPlaceholder(isDark, genreName),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  genreName,
                  style: isDark
                      ? AppTextStyles.bodyDark.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )
                      : AppTextStyles.bodyLight.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${songs.length} canciones",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSongsCard(BuildContext context, bool isDark, int totalSongs) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GenreDetailScreen(
              genreName: "Biblioteca Completa",
              songs: context.read<AudioProvider>().items,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.secondary, Colors.deepPurple]
                      : [AppColors.primary, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.music_note, size: 50, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Todas las Canciones",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "$totalSongs canciones",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark, String name) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF373737), const Color(0xFF2C2C2C)]
              : [const Color(0xFFE0E0E0), const Color(0xFFBDBDBD)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.category_outlined,
          size: 40,
          color: isDark ? Colors.white38 : Colors.black45,
        ),
      ),
    );
  }
}
