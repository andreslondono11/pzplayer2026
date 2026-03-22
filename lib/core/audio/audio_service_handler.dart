// import 'dart:io';
// import 'dart:typed_data';
// import 'package:audio_service/audio_service.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:path_provider/path_provider.dart';

// class AudioServiceHandler extends BaseAudioHandler {
//   final AudioPlayer _player = AudioPlayer();
//   final OnAudioQuery _audioQuery = OnAudioQuery();

//   AudioServiceHandler() {
//     // Escucha eventos de reproducción (play, pause, etc.)
//     _player.playbackEventStream.listen(_broadcastState);

//     // 🔑 ESCUCHA EL CAMBIO DE CANCIÓN (Crucial para la imagen en segundo plano)
//     // Usamos sequenceStateStream porque es más preciso que currentIndexStream
//     _player.sequenceStateStream.listen((sequenceState) {
//       final currentSource = sequenceState?.currentSource;
//       if (currentSource != null && currentSource.tag is MediaItem) {
//         mediaItem.add(currentSource.tag as MediaItem);
//       }
//     });

//     // Listener para cuando la canción termina
//     _player.processingStateStream.listen((state) {
//       if (state == ProcessingState.completed) {
//         skipToNext();
//       }
//     });
//   }

//   AudioPlayer get player => _player;
//   LoopMode get loopMode => _player.loopMode;
//   bool get shuffleEnabled => _player.shuffleModeEnabled;

//   // --- CONTROLES DE REPRODUCCIÓN ---

//   Future<void> toggleLoopMode() async {
//     LoopMode next;
//     switch (_player.loopMode) {
//       case LoopMode.off:
//         next = LoopMode.all;
//         break;
//       case LoopMode.all:
//         next = LoopMode.one;
//         break;
//       case LoopMode.one:
//         next = LoopMode.off;
//         break;
//     }
//     await _player.setLoopMode(next);
//     _broadcastState(_player.playbackEvent);
//   }

//   Future<void> toggleShuffle() async {
//     await _player.setShuffleModeEnabled(!_player.shuffleModeEnabled);
//     _broadcastState(_player.playbackEvent);
//   }

//   Future<void> setLoopMode(LoopMode mode) async {
//     await _player.setLoopMode(mode);
//   }

//   Stream<Duration> get positionStream => _player.positionStream;
//   Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
//   Stream<Duration?> get durationStream => _player.durationStream;

//   // --- GESTIÓN DE CARÁTULAS ---

//   Future<Uri?> _normalizeAndSaveCover(dynamic rawCover, String songId) async {
//     Uint8List? coverBytes;
//     if (rawCover is Uint8List) {
//       coverBytes = rawCover;
//     } else if (rawCover is List<int>) {
//       coverBytes = Uint8List.fromList(rawCover);
//     }

//     if (coverBytes != null) {
//       try {
//         final dir = await getTemporaryDirectory();
//         final file = File('${dir.path}/cover_$songId.png');

//         // Solo escribimos si no existe para mejorar el rendimiento
//         if (!await file.exists()) {
//           await file.writeAsBytes(coverBytes);
//         }
//         return Uri.file(file.path);
//       } catch (e) {
//         return null;
//       }
//     }
//     return null;
//   }

//   Future<List<MediaItem>> loadMediaItems() async {
//     await _audioQuery.permissionsRequest();
//     final songs = await _audioQuery.querySongs();

//     return Future.wait(
//       songs.map((song) async {
//         final artwork = await _audioQuery.queryArtwork(
//           song.id,
//           ArtworkType.AUDIO,
//           size: 500, // Tamaño optimizado para notificaciones
//         );

//         final Uint8List? coverBytes = artwork;

//         final artUri = coverBytes != null
//             ? await _normalizeAndSaveCover(coverBytes, song.id.toString())
//             : null;

//         return MediaItem(
//           id: song.data,
//           album: song.album ?? 'Desconocido',
//           title: song.title,
//           artist: song.artist ?? 'Desconocido',
//           duration: Duration(milliseconds: song.duration ?? 0),
//           artUri: artUri,
//           extras: {
//             if (coverBytes != null) 'coverBytes': coverBytes,
//             if (song.genre != null) 'genre': song.genre,
//           },
//         );
//       }),
//     );
//   }

//   // --- MÉTODOS DE REPRODUCCIÓN (CON EL FIX DE IMAGEN) ---

//   @override
//   Future<void> playItem(MediaItem item) async {
//     // 🔑 FIX: Pasamos el 'item' como tag para que el sistema vea la imagen
//     await _player.setAudioSource(AudioSource.file(item.id, tag: item));
//     queue.add([item]);
//     mediaItem.add(item);
//     await _player.play();
//   }

//   Future<void> playItems(List<MediaItem> items, {int initialIndex = 0}) async {
//     if (items.isEmpty) return;

//     // 🔑 FIX: Vinculamos cada AudioSource con su respectivo MediaItem mediante 'tag'
//     final sources = items
//         .map((item) => AudioSource.file(item.id, tag: item))
//         .toList();
//     final playlistSource = ConcatenatingAudioSource(children: sources);

//     queue.add(items);
//     await _player.setAudioSource(playlistSource, initialIndex: initialIndex);

//     // El listener de sequenceStateStream actualizará el mediaItem automáticamente
//     await _player.play();
//   }

//   @override
//   Future<void> play() => _player.play();
//   @override
//   Future<void> pause() => _player.pause();
//   @override
//   Future<void> stop() => _player.stop();
//   @override
//   Future<void> seek(Duration position) => _player.seek(position);

//   @override
//   Future<void> skipToNext() async {
//     if (_player.hasNext) {
//       await _player.seekToNext();
//     }
//   }

//   @override
//   Future<void> skipToPrevious() async {
//     if (_player.hasPrevious) {
//       await _player.seekToPrevious();
//     }
//   }

//   // --- SINCRONIZACIÓN CON EL SISTEMA (Notificación) ---

//   void _broadcastState(PlaybackEvent event) {
//     playbackState.add(
//       playbackState.value.copyWith(
//         controls: [
//           MediaControl.skipToPrevious,
//           _player.playing ? MediaControl.pause : MediaControl.play,
//           MediaControl.skipToNext,
//         ],
//         systemActions: const {
//           MediaAction.seek,
//           MediaAction.seekForward,
//           MediaAction.seekBackward,
//         },
//         androidCompactActionIndices: const [0, 1, 2],
//         processingState: const {
//           ProcessingState.idle: AudioProcessingState.idle,
//           ProcessingState.loading: AudioProcessingState.loading,
//           ProcessingState.buffering: AudioProcessingState.buffering,
//           ProcessingState.ready: AudioProcessingState.ready,
//           ProcessingState.completed: AudioProcessingState.completed,
//         }[_player.processingState]!,
//         playing: _player.playing,
//         updatePosition: _player.position,
//         bufferedPosition: _player.bufferedPosition,
//         speed: _player.speed,
//       ),
//     );
//   }
// }
import 'dart:io';
import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

class AudioServiceHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  AudioServiceHandler() {
    _player.playbackEventStream.listen(_broadcastState);

    // 🔑 ESCUCHA EL CAMBIO DE CANCIÓN
    _player.sequenceStateStream.listen((sequenceState) {
      final currentSource = sequenceState?.currentSource;
      if (currentSource != null && currentSource.tag is MediaItem) {
        mediaItem.add(currentSource.tag as MediaItem);
      }
    });

    // 🔑 ESCUCHA EL FINAL DE LA REPRODUCCIÓN (CORREGIDO)
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (_player.hasNext) {
          skipToNext();
        } else {
          stop(); // Se detiene al final para poder re-escuchar
        }
      }
    });
  }

  AudioPlayer get player => _player;

  // Getters para el AudioProvider
  LoopMode get loopMode => _player.loopMode;
  bool get shuffleEnabled => _player.shuffleModeEnabled;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  // --- CONTROLES DE REPRODUCCIÓN ---

  Future<void> toggleLoopMode() async {
    final modes = [LoopMode.off, LoopMode.all, LoopMode.one];
    final next = modes[(modes.indexOf(_player.loopMode) + 1) % modes.length];
    await _player.setLoopMode(next);
  }

  Future<void> toggleShuffle() async {
    await _player.setShuffleModeEnabled(!_player.shuffleModeEnabled);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero); // Reinicia posición
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() async {
    // 🔑 LÓGICA INTELIGENTE DE 3 SEGUNDOS
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else {
      if (_player.hasPrevious) await _player.seekToPrevious();
    }
  }

  // --- REPRODUCCIÓN DE ITEMS ---

  @override
  Future<void> playItem(MediaItem item) async {
    await _player.setAudioSource(AudioSource.file(item.id, tag: item));
    queue.add([item]);
    mediaItem.add(item);
    await _player.play();
  }

  Future<void> playItems(List<MediaItem> items, {int initialIndex = 0}) async {
    if (items.isEmpty) return;
    final sources = items
        .map((item) => AudioSource.file(item.id, tag: item))
        .toList();
    queue.add(items);
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: initialIndex,
    );
    await _player.play();
  }

  // --- GESTIÓN DE CARÁTULAS (Tu lógica mantenida y limpia) ---

  Future<Uri?> _normalizeAndSaveCover(Uint8List bytes, String songId) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cover_$songId.png');
      if (!await file.exists()) await file.writeAsBytes(bytes);
      return Uri.file(file.path);
    } catch (e) {
      return null;
    }
  }

  Future<List<MediaItem>> loadMediaItems() async {
    final songs = await _audioQuery.querySongs();
    return Future.wait(
      songs.map((song) async {
        final artwork = await _audioQuery.queryArtwork(
          song.id,
          ArtworkType.AUDIO,
          size: 500,
        );
        final artUri = artwork != null
            ? await _normalizeAndSaveCover(artwork, song.id.toString())
            : null;

        return MediaItem(
          id: song.data,
          album: song.album ?? 'Desconocido',
          title: song.title,
          artist: song.artist ?? 'Desconocido',
          duration: Duration(milliseconds: song.duration ?? 0),
          artUri: artUri,
          extras: {'genre': song.genre},
        );
      }),
    );
  }

  // --- NOTIFICACIÓN SISTEMA ---

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop, // Añadimos STOP a la notificación
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
      ),
    );
  }
}
