import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AudioServiceHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  AudioServiceHandler() {
    _player.playbackEventStream.listen(_broadcastState);

    // 🔑 CORRECCIÓN 1: Escuchar cambios de canción y asegurar la metadata
    _player.sequenceStateStream.listen((sequenceState) {
      final currentSource = sequenceState?.currentSource;
      if (currentSource != null && currentSource.tag is MediaItem) {
        final item = currentSource.tag as MediaItem;

        // Si el item tiene un albumId en extras, le creamos la artUri al vuelo
        // para que la notificación la detecte.
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

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _player.hasNext ? skipToNext() : stop();
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

  // 🔑 CORRECCIÓN 2: Asegurar que el broadcast de estado incluya la metadata actual
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
        queueIndex: event.currentIndex, // 👈 Importante añadir esto
      ),
    );
  }
}
