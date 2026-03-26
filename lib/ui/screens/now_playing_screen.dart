import 'dart:math';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/core/audio/equalizador.dart';
import 'package:pzplayer/core/theme/app_colors.dart';
import 'package:pzplayer/core/theme/app_text_styles.dart';
import 'package:pzplayer/ui/widgets/progess.dart';
// 🔑 Importante: Asegúrate de que esta ruta sea correcta según tu proyecto
// import 'package:pzplayer/ui/screens/equalizer_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late AnimationController _rotationController;
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

  String _randomAdvice(
    String songTitle,
    String? artist,
    String? genre,
    String? album,
  ) {
    final frases = [
      "Con $songTitle, cada día se siente mejor, no solo porque la música acompaña mis pasos, sino porque me recuerda que incluso en la rutina hay belleza escondida. Es como si cada nota abriera una ventana hacia un mundo más luminoso, donde las preocupaciones se disuelven y la esperanza se renueva. Escucharla es un recordatorio de que la vida, con sus matices y silencios, siempre guarda un espacio para la calma y la alegría.",
      "Pzplatinum te dice gracias por estar aquí, porque cada oyente hace que esta experiencia musical cobre vida. Tu presencia le da sentido a cada nota, y compartir esta aplicación es abrir la puerta para que otros también descubran un universo de sonidos y emociones."
          "Este artista, $artist, no solo es de los mejores en su carrera, sino que ha logrado transformar su talento en un legado. Cada canción es un reflejo de su pasión, de su historia y de la fuerza con la que ha marcado el camino en la música.",
      "Cada canción en el género $album me enseña que la vida, como la música, se disfruta mejor cuando aceptamos sus cambios de ritmo.",
      "Con $songTitle, descubro que la vida no se mide en años, sino en momentos que nos hacen vibrar."
          "Este $album de $artist es más que música: es un espejo de la vida, con sus luces, sombras y aprendizajes."
          "En los días de reflexión, el álbum $album de $artist es un recordatorio de que la vida también se escribe en silencios."
          "Cuando la esperanza parece lejana, escuchar $songTitle nos devuelve la certeza de que todo ciclo tiene un renacer."
          "El género $genre acompaña los momentos de lucha, enseñando que la vida, como la música, se construye con ritmo y resistencia."
          "Este álbum de $artist es perfecto para los viajes largos, porque cada canción se convierte en un paisaje interior."
          "Con $songTitle, la vida se siente como un relato compartido, donde cada nota nos recuerda que no estamos solos."
          "En un día como hoy, la música de $artist nos recuerda que cada instante puede ser un renacer."
          "Un día como hoy merece el álbum $album, porque la vida también se celebra con melodías que nos acompañan."
          "Hoy, con $songTitle, entendemos que la existencia se construye con notas que dan sentido a lo cotidiano."
          "El género $genre nos enseña que en un día como hoy, la vida fluye con ritmos que reflejan nuestras emociones."
          "Un día como hoy, cada canción es un recordatorio de que la vida se disfruta mejor cuando la compartimos."
          "En un día como hoy, el álbum $album de $artist me recuerda que la vida es una lucha constante, pero cada nota es un triunfo sobre el silencio."
          "Con $songTitle, descubro que las batallas diarias se vuelven más ligeras, porque la música siempre ofrece un respiro."
          "El género $genre me enseña que la lucha constante no es derrota, sino ritmo: un pulso que nos mantiene en pie."
          "Este álbum de $artist acompaña mis días de esfuerzo, recordándome que cada lucha deja huellas que se convierten en aprendizaje."
          "Cada canción es un reflejo de la vida misma: una lucha constante que, al final, se transforma en melodía y esperanza."
          "En un día como hoy, el álbum $album de $artist me recuerda que la superación es un viaje, no un destino."
          "Con $songTitle, descubro que cada caída es solo el inicio de una nueva fuerza que me impulsa hacia adelante."
          "El género $genre me enseña que la vida se supera como la música: aceptando cada cambio de ritmo con valentía."
          "Este álbum de $artist es la banda sonora de mis logros, porque cada canción refleja la lucha convertida en victoria."
          "En cada nota de $songTitle encuentro la certeza de que la superación es posible, incluso en los días más difíciles."
          "El álbum $album de $artist me recuerda que cada caída es solo el inicio de una nueva victoria."
          "Con $songTitle, descubro que la fuerza interior siempre encuentra su ritmo."
          "El género $genre me enseña que la superación es aceptar cada cambio de compás en la vida."
          "Este álbum de $artist es la banda sonora de mis logros, porque cada canción refleja lucha convertida en esperanza."
          "En cada nota de $songTitle encuentro la certeza de que la superación es posible, incluso en los días más oscuros."
          "Un día como hoy, el álbum $album me inspira a seguir, recordando que la música también es resiliencia."
          "Con $songTitle, la vida me enseña que superar es aprender a bailar con las dificultades."
          "El género $genre vibra como un recordatorio de que la superación es ritmo constante, nunca pausa."
          "Este álbum de $artist acompaña mis batallas, transformando cada esfuerzo en melodía de triunfo."
          "Cada canción de $album es un consejo de vida: no rendirse, incluso cuando el silencio parece más fuerte."
          "Con $songTitle, descubro que la superación no es llegar a la cima, sino disfrutar cada paso del camino."
          "El género $genre me recuerda que la vida se supera con pasión, como cada acorde que rompe el silencio."
          "Este álbum de $artist es un mapa de resiliencia, donde cada canción señala un nuevo horizonte."
          "En un día como hoy, $songTitle me enseña que la superación es confiar en que siempre habrá otra melodía."
          "Cada nota en $album es un recordatorio de que la vida, como la música, se supera con paciencia y fe."
          //🌞 Lunes
          "En un lunes como hoy, el álbum $album de $artist me recuerda que cada inicio es una oportunidad de superación."
          "Con $songTitle, descubro que los comienzos pueden ser difíciles, pero siempre traen nuevas fuerzas."
          //🌱 Martes
          "El género $genre me inspira a mantener el ritmo, porque la superación se construye paso a paso."
          "Este martes, $songTitle me enseña que la constancia es la clave para transformar los sueños en logros."
          //🌿 Miércoles-
          "En mitad de la semana, el álbum $album me recuerda que la lucha constante también es crecimiento."
          "Con $songTitle, cada miércoles se convierte en un recordatorio de que la superación es posible."
          //🌺 Jueves-
          "El género $genre me acompaña en este jueves, enseñándome que la vida se supera con ritmo y pasión."
          "Este álbum de $artist es la energía que necesito para seguir avanzando hacia mis metas."
          //🌟 Viernes-
          "En un viernes como hoy, $songTitle me recuerda que la superación también se celebra con alegría."
          "El álbum $album de $artist es la banda sonora perfecta para cerrar la semana con fuerza y esperanza."
          //🌈 Sábado-
          "El género $genre me inspira a disfrutar el camino, porque la superación también está en los momentos de calma."
          "Este sábado, $songTitle me enseña que cada logro merece ser celebrado como una melodía única."
          //🌻 Domingo-
          "En un domingo como hoy, el álbum $album me recuerda que la superación también es descansar y renovar fuerzas."
          "Con $songTitle, descubro que la vida se supera mejor cuando aprendemos a valorar la paz."
          "El género $genre me acompaña en este día, enseñándome que cada final es también un nuevo comienzo.",

      //❤️ Frases de Amor
      "Con $songTitle, descubro que el amor es la melodía más eterna de la vida."
          "El álbum $album de $artist me recuerda que cada historia de amor merece su propia banda sonora."
          "El género $genre vibra como el corazón enamorado: intenso, sincero y lleno de pasión."
          "Este álbum de $artist es un espejo del amor, con sus luces y sombras que nos hacen crecer."
          "Cada nota de $songTitle me enseña que el amor verdadero nunca se olvida, solo se transforma."
          //🌟 Frases de Esperanza
          "En un día como hoy, $songTitle me recuerda que la esperanza siempre encuentra su camino."
          "El álbum $album de $artist es un faro que ilumina los momentos oscuros con fe y confianza."
          "El género $genre me inspira a creer que cada final es también un nuevo comienzo."
          "Este álbum de $artist me enseña que la esperanza se canta mejor cuando compartimos la vida."
          "Cada canción de $album es una promesa de que lo mejor aún está por llegar."
          //💪 Frases de Resiliencia-
          "Con $songTitle, aprendo que la resiliencia es transformar las heridas en fuerza."
          "El álbum $album de $artist acompaña mis batallas, recordándome que cada caída es parte del camino."
          "El género $genre me enseña que la vida se supera con ritmo, paciencia y coraje."
          "Este álbum de $artist es un testimonio de resiliencia, donde cada canción es un triunfo sobre la adversidad."
          "En cada nota de $songTitle encuentro la certeza de que la resiliencia es la música del alma.",
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dynamic rawId = current.extras?['dbId'];
    final int songId = (rawId is int)
        ? rawId
        : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    return Scaffold(
      body: Stack(
        children: [
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

  Widget _buildDynamicBackground(int songId, bool isDark) {
    if (songId == 0) return _defaultGradient(isDark);
    return FutureBuilder<Uint8List?>(
      future: OnAudioQuery().queryArtwork(songId, ArtworkType.AUDIO, size: 800),
      builder: (context, snapshot) {
        final Uint8List? bytes = snapshot.data;
        return Container(
          decoration: BoxDecoration(
            image: bytes != null
                ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
                : null,
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
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
          RotationTransition(
            turns: _rotationController,
            child: ClipOval(child: _buildDiskArt(songId, size * 0.45)),
          ),
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

  Widget _buildDiskArt(int songId, double artsize) {
    if (songId == 0) return _defaultDiskIcon(artsize);
    if (_coverCache.containsKey(songId))
      return _diskImageContainer(_coverCache[songId], artsize);

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
              // 🔑 BOTÓN DE ECUALIZADOR AÑADIDO AQUÍ
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

  Widget _buildGlassFab(MediaItem current, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: () async {
            final advice = _randomAdvice(
              current.title,
              current.artist,
              current.genre,
              current.album,
            );
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

// Widget PlaylistButton ficticio para que compile si no lo tienes importado

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
        color: isDark ? Colors.white : Colors.black,
      ),
      onPressed: () => _showQueueModal(context, isDark),
    );
  }

  void _showQueueModal(BuildContext context, bool isDark) {
    // Chequeo inicial rápido antes de abrir el modal
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
        // El Consumer escucha cambios y redibuja solo el contenido del modal
        builder: (context, audio, child) {
          final queue = audio.queue;
          final currentSong = audio.currentSong;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.80,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // CABECERA
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
                              "${queue.length} canciones", // Corregido: queue.length
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

                  // LISTA REORDENABLE REACTIVA
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
                                onSelected: (value) => _handleMenuAction(
                                  context,
                                  value,
                                  song,
                                  audio,
                                  index,
                                ),
                                itemBuilder: (context) => [
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
                                  const PopupMenuDivider(),
                                  _buildPopupItem(
                                    'remove',
                                    Icons.delete_outline,
                                    "Quitar de la cola",
                                    isDestructive: true,
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.drag_handle,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ],
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
  ) {
    switch (value) {
      case 'play_now':
        audio.playItems([song]);
        Navigator.pop(context);
        break;
      case 'info':
        _showSongDetails(context, song);
        break;
      case 'add_playlist':
        _showPlaylistSelector(context, song);
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Detalles de la canción"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Título: ${song.title}"),
            Text("Artista: ${song.artist ?? 'Desconocido'}"),
            Text("Álbum: ${song.album ?? 'Desconocido'}"),
            if (song.duration != null)
              Text(
                "Duración: ${song.duration!.inMinutes}:${(song.duration!.inSeconds % 60).toString().padLeft(2, '0')}",
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cerrar",
              style: TextStyle(color: isDark ? Colors.white : AppColors.accent),
            ),
          ),
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
          style: isDark
              ? AppTextStyles.headingDark
              : AppTextStyles.headingLight,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: playlists.isEmpty
              ? const Text("No hay playlists creadas")
              : ListView.builder(
                  shrinkWrap: true,
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
                            ? AppTextStyles.bodyDark
                            : AppTextStyles.bodyLight,
                      ),
                      onTap: () {
                        audio.addToPlaylist(name, song);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
        ],
      ),
    );
  }
}
