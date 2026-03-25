import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

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
    // Al terminar, pausamos y volvemos al inicio. Así el Play sigue funcionando.
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
    // 🔑 LÓGICA DE RETROCESO INTELIGENTE (3 segundos)
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
