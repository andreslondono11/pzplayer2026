import 'dart:math';
import 'dart:ui';
import 'dart:typed_data'; // Import vital para Uint8List
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:on_audio_query/on_audio_query.dart'; // 🔑 Import vital para queryArtwork
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/core/theme/app_colors.dart';
import 'package:pzplayer/core/theme/app_text_styles.dart';
import 'package:pzplayer/ui/widgets/progess.dart';

// Borramos el import problemático y movemos el widget PlaylistButton al final de este archivo.
// import 'package:pzplayer/ui/widgets/playlist_button.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late AnimationController _rotationController;

  // 🔑 Caché para la portada del disco para evitar parpadeos al girar
  final Map<int, Uint8List?> _coverCache = {};

  @override
  void initState() {
    super.initState();
    _initTts();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
  }

  void _initTts() {
    _tts.setLanguage("es-ES");
    _tts.setPitch(1.0);
    _tts.setSpeechRate(0.9);
  }

  @override
  void dispose() {
    _tts.stop();
    _rotationController.dispose();
    super.dispose();
  }

  String _randomAdvice(String songTitle, String? artist) {
    final frases = [
      "La canción $songTitle de $artist es ideal para levantar el ánimo.",
      "Ponle volumen a $songTitle, te dará energía.",
      "Relájate con $songTitle, es perfecta para la noche.",
      "Que el beat de $songTitle sea el motor de tu día.",

      "PZ Player presenta: $songTitle, el sonido que define tu camino.",

      "Escucha $songTitle de $artist, un viaje sonoro único.",

      "Deja que $songTitle te acompañe en tu momento de inspiración.",

      "Con $songTitle, cada paso se siente más ligero.",

      "El ritmo de $songTitle es la chispa que necesitas.",

      "Nada mejor que $songTitle para empezar la mañana.",

      "Sumérgete en $songTitle y olvida las preocupaciones.",

      "El estilo de $artist en $songTitle es pura magia.",

      "Haz que tu día brille con $songTitle.",

      "Cuando suena $songTitle, todo se transforma.",

      "La melodía de $songTitle es un abrazo sonoro.",

      "Déjate llevar por la energía de $songTitle.",

      "El flow de $songTitle te impulsa hacia adelante.",

      "Con $songTitle, cada momento se vuelve especial.",

      "El arte de $artist en $songTitle es inolvidable.",

      "Escuchar $songTitle es como viajar sin moverte.",

      "El ritmo de $songTitle te conecta con tu esencia.",

      "Nada como $songTitle para recargar energías.",

      "La vibra de $songTitle ilumina cualquier espacio.",

      "Haz de $songTitle tu soundtrack personal.",

      "El poder de $songTitle está en su sencillez.",

      "Con $songTitle, la rutina se vuelve aventura.",

      "El toque de $artist en $songTitle es único.",

      "Cada nota de $songTitle es un recordatorio de alegría.",

      "El beat de $songTitle es pura motivación.",

      "Haz que $songTitle sea tu himno del día.",

      "La fuerza de $songTitle te acompaña siempre.",

      "El sonido de $songTitle es pura libertad.",

      "Con $songTitle, todo parece posible.",

      "El estilo de $songTitle es perfecto para relajarte.",

      "Haz que $songTitle sea tu refugio musical.",

      "El ritmo de $songTitle te invita a bailar.",

      "Nada como $songTitle para cerrar el día.",

      "El arte de $artist brilla en $songTitle.",

      "Cada acorde de $songTitle es un regalo.",

      "Haz que $songTitle sea tu momento zen.",

      "El beat de $songTitle te llena de energía positiva.",

      "Con $songTitle, la noche se vuelve mágica.",

      "El poder de $songTitle está en su vibra.",

      "Haz que $songTitle sea tu impulso creativo.",

      "El ritmo de $songTitle es pura adrenalina.",

      "Nada como $songTitle para inspirarte.",

      "El estilo de $songTitle es perfecto para soñar.",

      "Haz que $songTitle sea tu pausa musical.",

      "El sonido de $songTitle es un viaje interior.",

      "Con $songTitle, cada instante se disfruta más.",

      "El beat de $songTitle es tu mejor compañía.",

      "Haz que $songTitle sea tu energía diaria.",

      "El arte de $artist se siente en cada nota de $songTitle.",

      "Nada como $songTitle para acompañar tu camino.",

      "El ritmo de $songTitle es pura motivación.",

      "Haz que $songTitle sea tu inspiración constante.",

      "El poder de $songTitle está en su esencia.",

      "Con $songTitle, todo fluye mejor.",

      "El estilo de $songTitle es perfecto para meditar.",

      "Haz que $songTitle sea tu momento de calma.",

      "El beat de $songTitle te conecta con la vida.",

      "Nada como $songTitle para empezar con fuerza.",

      "El sonido de $songTitle es pura emoción.",

      "Haz que $songTitle sea tu chispa creativa.",

      "El ritmo de $songTitle te invita a moverte.",

      "Con $songTitle, cada día es especial.",

      "El arte de $artist transforma $songTitle en magia.",

      "Haz que $songTitle sea tu refugio sonoro.",

      "El beat de $songTitle es tu motor interno.",

      "Nada como $songTitle para relajarte al final del día.",

      "El estilo de $songTitle es pura elegancia.",

      "Haz que $songTitle sea tu energía nocturna.",

      "El poder de $songTitle está en su ritmo.",

      "Con $songTitle, todo se siente más ligero.",

      "El sonido de $songTitle es pura inspiración.",

      "Haz que $songTitle sea tu canción del momento.",

      "El beat de $songTitle te impulsa hacia adelante.",

      "Nada como $songTitle para acompañar tu viaje.",

      "El arte de $artist en $songTitle es inolvidable.",

      "Haz que $songTitle sea tu mantra musical.",

      "El ritmo de $songTitle es pura alegría.",

      "Con $songTitle, cada instante vibra más.",

      "El estilo de $songTitle es perfecto para motivarte.",

      "Haz que $songTitle sea tu pausa energética.",

      "El sonido de $songTitle es pura calma.",

      "Nada como $songTitle para encender tu día.",

      "El beat de $songTitle es tu mejor aliado.",

      "Haz que $songTitle sea tu soundtrack personal.",

      "El poder de $songTitle está en su melodía.",

      "Con $songTitle, todo se vuelve más brillante.",

      "El arte de $artist se refleja en $songTitle.",

      "Haz que $songTitle sea tu impulso diario.",

      "El ritmo de $songTitle es pura pasión.",

      "Nada como $songTitle para inspirar tu creatividad.",

      "El estilo de $songTitle es perfecto para disfrutar.",

      "Haz que $songTitle sea tu momento de paz.",

      "El sonido de $songTitle es pura energía.",

      "Con $songTitle, cada día se siente mejor.",
    ];
    return frases[Random().nextInt(frases.length)];
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final current = audio.current;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Manejo inteligente de la animación del disco
    if (audio.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!audio.isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }

    if (current == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🔑 CAMBIO 1: Extraemos el dbId en lugar de intentar normalizar coverBytes
    final dynamic rawId = current.extras?['dbId'];
    final int songId = (rawId is int)
        ? rawId
        : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    return Scaffold(
      body: Stack(
        children: [
          // 🔑 CAMBIO 2: Pasamos el songId al fondo dinámico
          _buildDynamicBackground(songId, isDark),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isLandscape =
                    constraints.maxWidth > constraints.maxHeight;

                return Column(
                  children: [
                    _buildCloseButton(context, isDark),
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
        ],
      ),
      floatingActionButton: _buildGlassFab(current, isDark),
    );
  }

  // 🔑 Fondo dinámico ahora usa FutureBuilder con el songId
  Widget _buildDynamicBackground(int songId, bool isDark) {
    if (songId == 0) return _defaultGradient(isDark);

    return FutureBuilder<Uint8List?>(
      // Usamos una cache separada o la misma, pero cargamos tamaño grande para el fondo
      future: OnAudioQuery().queryArtwork(songId, ArtworkType.AUDIO, size: 800),
      builder: (context, snapshot) {
        final Uint8List? bytes = snapshot.data;

        return Container(
          decoration: BoxDecoration(
            // gradient: bytes == null ? _defaultGradient(isDark).gradient : null,
            image: bytes != null
                ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
                : null,
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 15.0,
              sigmaY: 15.0,
            ), // Más blur para el fondo
            child: Container(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.white.withOpacity(0.3),
            ),
          ),
        );
      },
    );
  }

  Container _defaultGradient(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [Colors.grey.shade900, Colors.black]
              : [Colors.white, Colors.grey.shade300],
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
        // 🔑 CAMBIO 3: Pasamos songId a _buildCover
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

  Widget _buildCloseButton(BuildContext context, bool isDark) {
    return IconButton(
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 45,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  // 🔑 _buildCover corregido para usar songId y FutureBuilder
  Widget _buildCover(
    AudioProvider audio,
    MediaItem current,
    int songId,
    double size,
  ) {
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
          // Sombra del disco
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
          // Vinilo giratorio
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
          // 🔑 Imagen central giratoria con FutureBuilder y Caché
          RotationTransition(
            turns: _rotationController,
            child: ClipOval(child: _buildDiskArt(songId, size * 0.45)),
          ),
          // Punto central fijo
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
        ],
      ),
    );
  }

  // 🔑 Widget auxiliar para cargar la portada del disco con caché
  Widget _buildDiskArt(int songId, double artsize) {
    if (songId == 0) return _defaultDiskIcon(artsize);

    // Si ya está en caché, la cargamos al instante (sin parpadeo)
    if (_coverCache.containsKey(songId)) {
      return _diskImageContainer(_coverCache[songId], artsize);
    }

    // Si no, la buscamos
    return FutureBuilder<Uint8List?>(
      future: OnAudioQuery().queryArtwork(songId, ArtworkType.AUDIO, size: 500),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _coverCache[songId] = snapshot.data; // Guardamos en caché
          return _diskImageContainer(snapshot.data, artsize);
        }
        // Mientras carga, mostramos el contenedor vacío para mantener la forma
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
              const PlaylistButton(), // 👈 Widget movido abajo
              const SizedBox(width: 25),
              IconButton(
                icon: Icon(
                  audio.shuffleEnabled
                      ? Icons.shuffle_on_rounded
                      : Icons.shuffle_rounded,
                  size: 28,
                  color: audio.shuffleEnabled
                      ? Colors.blueAccent
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
                onPressed: () => audio.toggleShuffle(),
              ),
              const SizedBox(width: 25),
              IconButton(
                icon: Icon(
                  audio.loopMode == LoopMode.one
                      ? Icons.repeat_one_rounded
                      : audio.loopMode == LoopMode.all
                      ? Icons.repeat_on_rounded
                      : Icons.repeat_rounded,
                  size: 28,
                  color: audio.loopMode != LoopMode.off
                      ? Colors.blueAccent
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
                onPressed: () => audio.toggleLoopMode(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassFab(MediaItem current, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: () async {
            final advice = _randomAdvice(current.title, current.artist);
            await _tts.speak(advice);
            if (!mounted) return;
            showModalBottomSheet(
              context: context,
              backgroundColor: isDark ? Colors.black87 : Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              builder: (_) => Container(
                padding: const EdgeInsets.all(30),
                child: Text(
                  advice,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.deepPurpleAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  "IA",
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

// --- WIDGETS AUXILIARES MANTENIDOS ---

class VinylLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
          .withOpacity(0.06) // Un poco más sutil
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

// 🔑 Widget PlaylistButton movido aquí para solucionar el import
class PlaylistButton extends StatelessWidget {
  const PlaylistButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(
        Icons.queue_music,
        size: 30,
        color: isDark ? Colors.blueGrey : AppColors.primary,
      ),
      onPressed: () => _showQueueModal(context, isDark),
    );
  }

  void _showQueueModal(BuildContext context, bool isDark) {
    final audio = context.read<AudioProvider>();
    final queue = audio.queue;

    if (queue.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("La cola está vacía")));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.black87 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                "Cola actual (${queue.length})",
                style: isDark
                    ? AppTextStyles.subheadingDark
                    : AppTextStyles.subheadingLight,
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final song = queue[index];
                  // Nota: En la cola no cargamos imágenes para maximizar rendimiento
                  return ListTile(
                    leading: Icon(
                      Icons.music_note,
                      color: isDark ? Colors.blueGrey : AppColors.primary,
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
                    onTap: () {
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
  }
}
