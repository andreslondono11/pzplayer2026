// import 'dart:io';
// import 'package:audio_service/audio_service.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:path/path.dart' as path;

// class AudioServiceHandler extends BaseAudioHandler {
//   final AudioPlayer _player = AudioPlayer();
//   final OnAudioQuery _audioQuery = OnAudioQuery();

//   AudioServiceHandler() {
//     _player.playbackEventStream.listen(_broadcastState);

//     // 🔑 ESCUCHAR CAMBIOS DE CANCIÓN Y METADATA
//     _player.sequenceStateStream.listen((sequenceState) {
//       final currentSource = sequenceState?.currentSource;
//       if (currentSource != null && currentSource.tag is MediaItem) {
//         final item = currentSource.tag as MediaItem;

//         if (item.artUri == null && item.extras?['albumId'] != null) {
//           final updatedItem = item.copyWith(
//             artUri: Uri.parse(
//               'content://media/external/audio/albumart/${item.extras!['albumId']}',
//             ),
//           );
//           mediaItem.add(updatedItem);
//         } else {
//           mediaItem.add(item);
//         }
//       }
//     });

//     // 🔑 SOLUCIÓN AL PLAY INSERVIBLE:
//     _player.processingStateStream.listen((state) {
//       if (state == ProcessingState.completed) {
//         _player.pause();
//         _player.seek(Duration.zero);
//       }
//     });
//   }

//   AudioPlayer get player => _player;
//   Stream<Duration> get positionStream => _player.positionStream;
//   Stream<Duration?> get durationStream => _player.durationStream;

//   @override
//   Future<void> updateQueue(List<MediaItem> newQueue) async {
//     queue.add(newQueue);
//   }

//   @override
//   Future<void> addQueueItem(MediaItem item) async {
//     final currentQueue = queue.value;
//     queue.add([...currentQueue, item]);
//   }

//   @override
//   Future<void> play() => _player.play();

//   @override
//   Future<void> pause() => _player.pause();

//   @override
//   Future<void> seek(Duration position) => _player.seek(position);

//   @override
//   Future<void> skipToNext() => _player.seekToNext();

//   @override
//   Future<void> skipToPrevious() async {
//     if (_player.position.inSeconds > 3) {
//       await _player.seek(Duration.zero);
//     } else if (_player.hasPrevious) {
//       await _player.seekToPrevious();
//     } else {
//       await _player.seek(Duration.zero);
//     }
//   }

//   @override
//   Future<void> stop() async {
//     await _player.stop();
//     playbackState.add(
//       playbackState.value.copyWith(
//         playing: false,
//         processingState: AudioProcessingState.idle,
//       ),
//     );
//   }

//   // ---------------------------------------------------------
//   // 🔑 FUNCIÓN CORREGIDA: PROGRESO EN NOTIFICACIÓN (GESTOR)
//   // ---------------------------------------------------------
//   Future<void> prepareExternalFile(String filePath) async {
//     try {
//       String fileName = path.basename(filePath);
//       String title = path.basenameWithoutExtension(filePath);

//       // 1. Creamos el MediaItem inicial (sin duración conocida aún)
//       final tempMediaItem = MediaItem(
//         id: filePath,
//         title: title,
//         artist: "Archivo Local",
//         artUri: null,
//         duration: Duration.zero, // Inicialmente cero
//       );

//       // 2. Limpiamos la cola anterior
//       queue.add([]);

//       // 3. Cargamos la fuente
//       final AudioSource source = AudioSource.uri(
//         Uri.file(filePath),
//         tag: tempMediaItem,
//       );

//       // 4. 👇 CLAVE: Cargamos el audio en el jugador (PREPARE)
//       // Esto lee el archivo y obtiene la duración real, pero NO reproduce todavía.
//       await _player.setAudioSource(
//         source,
//         initialIndex: 0,
//         initialPosition: Duration.zero,
//       );

//       // 5. Esperamos un momento muy breve a que el jugador obtenga la duración
//       // (A veces es inmediato, a veces tarda unos milisegundos)
//       await _player.pause();

//       // 6. Obtenemos la duración real que el jugador acaba de leer del archivo
//       final Duration realDuration = _player.duration ?? Duration.zero;

//       // 7. Creamos un NUEVO MediaItem con la duración correcta
//       final finalMediaItem = tempMediaItem.copyWith(duration: realDuration);

//       // 8. 👇 ACTUALIZAMOS LA NOTIFICACIÓN con el MediaItem que ya tiene duración
//       mediaItem.add(finalMediaItem);

//       // 9. Ahora sí, reproducimos
//       await play();
//     } catch (e) {
//       print("❌ Error al cargar archivo externo: $e");
//     }
//   }

//   // 🔑 BROADCAST DE ESTADO
//   void _broadcastState(PlaybackEvent event) {
//     playbackState.add(
//       playbackState.value.copyWith(
//         controls: [
//           MediaControl.skipToPrevious,
//           _player.playing ? MediaControl.pause : MediaControl.play,
//           MediaControl.stop,
//           MediaControl.skipToNext,
//         ],
//         systemActions: const {
//           MediaAction.seek,
//           MediaAction.skipToNext,
//           MediaAction.skipToPrevious,
//         },
//         androidCompactActionIndices: const [0, 1, 3],
//         processingState:
//             const {
//               ProcessingState.idle: AudioProcessingState.idle,
//               ProcessingState.loading: AudioProcessingState.loading,
//               ProcessingState.buffering: AudioProcessingState.buffering,
//               ProcessingState.ready: AudioProcessingState.ready,
//               ProcessingState.completed: AudioProcessingState.completed,
//             }[_player.processingState] ??
//             AudioProcessingState.idle,
//         playing: _player.playing,
//         updatePosition: _player.position,
//         bufferedPosition: _player.bufferedPosition,
//         queueIndex: event.currentIndex,
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as path;

class AudioServiceHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  AudioServiceHandler() {
    _player.playbackEventStream.listen(_broadcastState);

    // 🔑 ESCUCHAR CAMBIOS DE CANCIÓN Y METADATA
    _player.sequenceStateStream.listen((sequenceState) {
      final currentSource = sequenceState?.currentSource;
      if (currentSource != null && currentSource.tag is MediaItem) {
        final item = currentSource.tag as MediaItem;

        if (item.artUri == null && item.extras?['albumId'] != null) {
          final updatedItem = item.copyWith(
            artUri: Uri.parse(
              'content://media/external/audio/albumart/${item.extras!['albumId']}',
            ),
          );
          mediaItem.add(updatedItem);
        } else {
          mediaItem.add(item);
        }
      }
    });

    // 🔑 SOLUCIÓN AL PLAY INSERVIBLE:
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
    });
  }

  AudioPlayer get player => _player;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    queue.add(newQueue);
  }

  @override
  Future<void> addQueueItem(MediaItem item) async {
    final currentQueue = queue.value;
    queue.add([...currentQueue, item]);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔑 FUNCIÓN CORREGIDA: PROGRESO EN NOTIFICACIÓN (GESTOR)
  // ---------------------------------------------------------
  Future<void> prepareExternalFile(String filePath) async {
    try {
      String fileName = path.basename(filePath);
      String title = path.basenameWithoutExtension(filePath);

      // 1. Creamos el MediaItem inicial (sin duración conocida aún)
      final tempMediaItem = MediaItem(
        id: filePath,
        title: title,
        artist: "Archivo Local",
        artUri: null,
        duration: Duration.zero, // Inicialmente cero
      );

      // 2. Limpiamos la cola anterior
      queue.add([]);

      // 3. Cargamos la fuente
      final AudioSource source = AudioSource.uri(
        Uri.file(filePath),
        tag: tempMediaItem,
      );

      // 4. 👇 CLAVE: Cargamos el audio en el jugador (PREPARE)
      // Esto lee el archivo y obtiene la duración real, pero NO reproduce todavía.
      await _player.setAudioSource(
        source,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );

      // 5. Esperamos un momento muy breve a que el jugador obtenga la duración
      // (A veces es inmediato, a veces tarda unos milisegundos)
      await _player.pause();

      // 6. Obtenemos la duración real que el jugador acaba de leer del archivo
      final Duration realDuration = _player.duration ?? Duration.zero;

      // 7. Creamos un NUEVO MediaItem con la duración correcta
      final finalMediaItem = tempMediaItem.copyWith(duration: realDuration);

      // 8. 👇 ACTUALIZAMOS LA NOTIFICACIÓN con el MediaItem que ya tiene duración
      mediaItem.add(finalMediaItem);

      // 9. Ahora sí, reproducimos
      await play();
    } catch (e) {
      print("❌ Error al cargar archivo externo: $e");
    }
  }

  // 🔑 BROADCAST DE ESTADO
  void _broadcastState(PlaybackEvent event) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState:
            const {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[_player.processingState] ??
            AudioProcessingState.idle,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        queueIndex: event.currentIndex,
      ),
    );
  }
}
