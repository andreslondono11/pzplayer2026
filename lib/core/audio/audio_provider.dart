import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_service_handler.dart';

extension MediaItemJson on MediaItem {
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'artUri': artUri?.toString(),
    'duration': duration?.inMilliseconds,
    'extras': extras,
  };

  static MediaItem fromJson(Map<String, dynamic> json) {
    final extras = (json['extras'] as Map?)?.cast<String, dynamic>();
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      artUri: json['artUri'] != null ? Uri.parse(json['artUri']) : null,
      extras: extras,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
    );
  }
}

class AudioProvider extends ChangeNotifier {
  final AudioHandler handler;
  AudioProvider(this.handler) {
    final player = (handler as AudioServiceHandler).player;

    player.loopModeStream.listen((mode) {
      notifyListeners();
    });

    player.shuffleModeEnabledStream.listen((enabled) {
      notifyListeners();
    });

    // 🔑 ACTUALIZACIÓN 1: Sincronizar 'current' desde el stream del handler
    // Esto asegura que la UI y la notificación de segundo plano vean lo mismo.
    handler.mediaItem.listen((item) {
      if (item != null) {
        _current = item;
        notifyListeners();
      }
    });

    player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  List<MediaItem> _items = [];
  List<MediaItem> _queue = [];
  MediaItem? _current;
  bool _isPlaying = false;

  List<MediaItem> get items => _items;
  List<MediaItem> get queue => _queue;
  MediaItem? get current => _current;
  bool get isPlaying => _isPlaying;

  Uint8List? normalizeCover(dynamic rawCover) {
    if (rawCover is Uint8List) return rawCover;
    if (rawCover is List<int>) return Uint8List.fromList(rawCover);
    if (rawCover is List<dynamic>) {
      return Uint8List.fromList(List<int>.from(rawCover));
    }
    return null;
  }

  Duration get position => (handler as AudioServiceHandler).player.position;
  Duration get bufferedPosition =>
      (handler as AudioServiceHandler).player.bufferedPosition;
  Duration? get duration => (handler as AudioServiceHandler).player.duration;

  Stream<Duration> get positionStream =>
      (handler as AudioServiceHandler).positionStream;
  Stream<Duration> get bufferedPositionStream =>
      (handler as AudioServiceHandler).bufferedPositionStream;
  Stream<Duration?> get durationStream =>
      (handler as AudioServiceHandler).durationStream;

  Future<void> loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('library_items');
    if (saved != null && saved.isNotEmpty) {
      _items = saved.map((e) => MediaItemJson.fromJson(jsonDecode(e))).toList();
    } else {
      _items = await (handler as AudioServiceHandler).loadMediaItems();
      await _persistLibrary();
    }
    notifyListeners();
  }

  Future<void> _persistLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'library_items',
      _items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> refreshLibrary() async {
    final scannedItems = await (handler as AudioServiceHandler)
        .loadMediaItems();
    final Map<String, MediaItem> merged = {
      for (var item in _items) item.id: item,
      for (var item in scannedItems) item.id: item,
    };
    _items = merged.values.toList()..sort((a, b) => a.title.compareTo(b.title));
    await _persistLibrary();
    notifyListeners();
  }

  Map<String, List<MediaItem>> get albums {
    final Map<String, List<MediaItem>> grouped = {};
    for (var item in _items) {
      final album = item.album ?? 'Desconocido';
      grouped.putIfAbsent(album, () => []).add(item);
    }
    return grouped;
  }

  Map<String, List<MediaItem>> get artists {
    final Map<String, List<MediaItem>> grouped = {};
    for (var item in _items) {
      final artist = item.artist ?? 'Desconocido';
      grouped.putIfAbsent(artist, () => []).add(item);
    }
    return grouped;
  }

  Map<String, List<MediaItem>> get genres {
    final Map<String, List<MediaItem>> grouped = {};
    for (var item in _items) {
      final genre = item.extras?['genre'] ?? 'Desconocido';
      grouped.putIfAbsent(genre, () => []).add(item);
    }
    return grouped;
  }

  Map<String, List<MediaItem>> get folders {
    final Map<String, List<MediaItem>> grouped = {};
    for (var item in _items) {
      final folderPath = item.id.substring(0, item.id.lastIndexOf('/'));
      grouped.putIfAbsent(folderPath, () => []).add(item);
    }
    return grouped;
  }

  final Map<String, List<MediaItem>> _playlists = {};
  Map<String, List<MediaItem>> get playlists => _playlists;

  void createPlaylist(String name) {
    if (name.isNotEmpty && !_playlists.containsKey(name)) {
      _playlists[name] = [];
      notifyListeners();
    }
  }

  void deletePlaylist(String name) {
    _playlists.remove(name);
    notifyListeners();
  }

  void addToPlaylist(String name, MediaItem song) {
    if (_playlists.containsKey(name)) {
      _playlists[name]!.add(song);
      notifyListeners();
    }
  }

  void removeFromPlaylist(String name, MediaItem song) {
    _playlists[name]?.remove(song);
    notifyListeners();
  }

  Future<void> playPlaylist(String name) async {
    final songs = _playlists[name];
    if (songs != null && songs.isNotEmpty) {
      await playItems(songs);
    }
  }

  Future<void> loadAndPlayUri(String path) async {
    final handler = this.handler as AudioServiceHandler;
    final player = handler.player;

    try {
      // 🔑 ACTUALIZACIÓN 2: Usar el MediaItem como 'tag' para que se vea la imagen
      final item = _items.firstWhere(
        (e) => e.id == path,
        orElse: () => MediaItem(
          id: path,
          title: path.split('/').last,
          artist: 'Desconocido',
          album: 'Desconocido',
          artUri: null,
        ),
      );

      await player.setAudioSource(AudioSource.uri(Uri.parse(path), tag: item));
      await player.play();

      _current = item;
      _queue = [item];
      handler.queue.add([item]);
      handler.mediaItem.add(item);
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Error al reproducir el URI: $e");
    }
  }

  Future<void> playFromFile(String path) async {
    notifyListeners();
  }

  void play(MediaItem item) {
    _current = item;
    (handler as AudioServiceHandler).playItem(item);
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> playItems(List<MediaItem> items, {int startIndex = 0}) async {
    if (items.isEmpty) return;
    final handler = this.handler as AudioServiceHandler;

    // 🔑 ACTUALIZACIÓN 3: IMPORTANTE - Vincular MediaItem como 'tag' en cada source
    // Sin esto, la notificación de segundo plano no sabrá qué imagen mostrar.
    final sources = items
        .map((item) => AudioSource.file(item.id, tag: item))
        .toList();
    final playlistSource = ConcatenatingAudioSource(children: sources);

    await handler.player.setAudioSource(
      playlistSource,
      initialIndex: startIndex,
    );
    await handler.player.setLoopMode(LoopMode.off);
    await handler.player.play();

    _queue = List<MediaItem>.from(items);
    handler.queue.add(items);

    final firstItem = items[startIndex];
    handler.mediaItem.add(firstItem);
    _current = firstItem;
    _isPlaying = true;
    notifyListeners();
  }

  bool get shuffleEnabled => (handler as AudioServiceHandler).shuffleEnabled;
  Future<void> toggleShuffle() =>
      (handler as AudioServiceHandler).toggleShuffle();

  LoopMode get loopMode => (handler as AudioServiceHandler).loopMode;
  Future<void> toggleLoopMode() =>
      (handler as AudioServiceHandler).toggleLoopMode();

  void addToQueue(MediaItem song) {
    (handler as AudioServiceHandler).addQueueItem(song);
    _queue.add(song);
    notifyListeners();
  }

  void playNext(MediaItem song) {
    final currentIndex = _queue.indexOf(_current ?? song);
    (handler as AudioServiceHandler).insertQueueItem(currentIndex + 1, song);
    _queue.insert(currentIndex + 1, song);
    notifyListeners();
  }

  void pause() {
    handler.pause();
    _isPlaying = false;
    notifyListeners();
  }

  void resume() {
    handler.play();
    _isPlaying = true;
    notifyListeners();
  }

  void skipNext() => handler.skipToNext();
  void skipPrevious() => handler.skipToPrevious();

  void seek(Duration position) => handler.seek(position);
}
