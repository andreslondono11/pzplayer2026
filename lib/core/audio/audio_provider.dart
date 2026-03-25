import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'audio_service_handler.dart';

// --- Extension para serializar MediaItem ---
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
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioHandler handler;

  AudioProvider(this.handler) {
    final player = (handler as AudioServiceHandler).player;

    player.loopModeStream.listen((_) => notifyListeners());
    player.shuffleModeEnabledStream.listen((_) => notifyListeners());
    player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    handler.mediaItem.listen((item) {
      if (item != null) {
        _current = item;
        notifyListeners();
      }
    });
  }

  List<MediaItem> _items = [];
  MediaItem? _current;
  bool _isPlaying = false;
  final Map<String, List<MediaItem>> _playlists = {};
  List<AlbumModel> _albumModels = [];

  // Getters
  List<MediaItem> get items => _items;
  MediaItem? get current => _current;
  bool get isPlaying => _isPlaying;
  Map<String, List<MediaItem>> get playlists => _playlists;
  List<AlbumModel> get albumModels => _albumModels;

  Stream<Duration> get positionStream =>
      (handler as AudioServiceHandler).positionStream;
  Stream<Duration?> get durationStream =>
      (handler as AudioServiceHandler).durationStream;

  // --- LÓGICA DE CARGA Y REFRESH (CORREGIDA Y COMPLETA) ---
  Future<void> loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('library_items');

    if (saved != null) {
      _items = saved.map((e) => MediaItemJson.fromJson(jsonDecode(e))).toList();

      // 🕵️ AUTO-DIAGNÓSTICO: Si el primer item no tiene ID, forzamos refresh
      if (_items.isNotEmpty && _items.first.extras?['dbId'] == null) {
        debugPrint("⚠️ Datos viejos detectados sin IDs. Refrescando...");
        await refreshLibrary();
        return;
      }
    } else {
      await refreshLibrary();
    }
    notifyListeners();
  }

  Future<void> refreshLibrary() async {
    try {
      // 1. Escaneamos todas las canciones de una sola vez (Mucho más rápido)
      final List<SongModel> fetchedSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      // 2. Escaneamos álbumes
      _albumModels = await _audioQuery.queryAlbums(
        sortType: AlbumSortType.ALBUM,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );

      // 3. Convertimos SongModel a MediaItem guardando el albumId
      _items = fetchedSongs.map((song) {
        return MediaItem(
          id: song.data,
          title: song.title,
          artist: song.artist ?? "Artista Desconocido",
          album: song.album ?? "Álbum Desconocido",
          duration: Duration(milliseconds: song.duration ?? 0),
          extras: {
            'dbId': song.id, // ID real de la canción (int)
            'albumId': song.albumId, // ID real del álbum (int)
            'genre': song.genre,
          },
        );
      }).toList();

      // ¡NO OLVIDES ESTO!
      await _persistLibrary();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error al refrescar librería: $e");
    }
  }

  Future<void> _persistLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'library_items',
      _items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  // Este método lo mantengo por si abres un archivo suelto desde el explorador
  Future<MediaItem> _buildMediaItem(String path) async {
    try {
      final List<SongModel> songs = await _audioQuery.querySongs(
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final song = songs.firstWhere(
        (s) => s.data == path,
        orElse: () => songs.isNotEmpty ? songs.first : null as dynamic,
      );

      final metadata = await MetadataRetriever.fromFile(File(path));

      return MediaItem(
        id: path,
        title: metadata.trackName ?? path.split('/').last,
        artist: metadata.trackArtistNames?.first ?? "Artista Desconocido",
        album: metadata.albumName ?? "Álbum Desconocido",
        duration: metadata.trackDuration != null
            ? Duration(milliseconds: metadata.trackDuration!)
            : null,
        extras: {
          'dbId': song.id,
          'albumId': song.albumId, // 🔑 También aquí
          'genre': metadata.genre,
        },
      );
    } catch (e) {
      return MediaItem(
        id: path,
        title: path.split('/').last,
        extras: {'dbId': 0, 'albumId': 0},
      );
    }
  }

  // Dentro de tu clase AudioProvider
  // void setBandGain(int bandIndex, double gain) {
  //   // Aquí es donde el plugin hace la magia
  //   // Ejemplo: _equalizer.setBandGain(bandIndex, gain);
  //   notifyListeners(); // Opcional, si quieres que la UI reaccione
  // }

  // --- SECCIÓN DEL ECUALIZADOR DENTRO DEL PROVIDER ---

  bool _isEqualizerEnabled = true;

  // 1. IMPORTANTE: Esta lista SIEMPRE debe tener valores entre 0.0 y 1.0
  List<double> _currentEGBands = [0.5, 0.5, 0.5, 0.5, 0.5];

  bool get isEqualizerEnabled => _isEqualizerEnabled;
  List<double> get currentEGBands => _currentEGBands;

  // Método para el switch de encendido/apagado
  void toggleEqualizer(bool value) {
    _isEqualizerEnabled = value;
    // Aquí va la conexión a tu motor (ej: _equalizer.setEnabled(value))
    notifyListeners();
  }

  // 2. MÉTODO CORREGIDO: setBandGain
  void setBandGain(int bandIndex, double sliderValue) {
    // EL ESCUDO: Esto evita el error de "Value -4.48 is not between 0.0 and 1.0"
    double safeValue = sliderValue.clamp(0.0, 1.0);

    // Guardamos el valor seguro para la UI
    _currentEGBands[bandIndex] = safeValue;

    if (_isEqualizerEnabled) {
      // 3. CONVERSIÓN PARA EL OÍDO:
      // De 0.0...1.0 a -1500...1500 mB (esto es lo que SÍ se siente)
      int milliBelios = ((safeValue * 3000) - 1500).toInt();

      // --- CONEXIÓN REAL AL MOTOR ---
      // Si usas just_audio con AndroidEqualizer sería:
      // _equalizer.setBandLevel(bandIndex, milliBelios);

      print("PZ Player -> Banda $bandIndex ajustada a $milliBelios mB");
    }

    // Ojo: No pongas notifyListeners() aquí si llamas a esta función
    // desde el onChanged del Slider, porque causará saltos (lag).
  }

  // --- REPRODUCCIÓN ---

  Future<void> play(MediaItem item) async => await playItems([item]);

  Future<void> playItems(List<MediaItem> items, {int startIndex = 0}) async {
    if (items.isEmpty) return;
    final h = handler as AudioServiceHandler;
    final sources = items
        .map((item) => AudioSource.file(item.id, tag: item))
        .toList();

    try {
      h.updateQueue(items);
      await h.player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: startIndex,
      );
      await h.player.play();
    } catch (e) {
      debugPrint("Error en playItems: $e");
    }
  }

  Future<void> playFromFile(String path) async {
    final h = handler as AudioServiceHandler;
    try {
      final item = _items.firstWhere(
        (e) => e.id == path,
        orElse: () => MediaItem(id: path, title: path.split('/').last),
      );
      await h.player.setAudioSource(AudioSource.file(path, tag: item));
      h.playMediaItem(item);
      await h.player.play();
    } catch (e) {
      debugPrint("Error en playFromFile: $e");
    }
  }

  // --- AGRUPAMIENTOS ---

  Map<String, List<MediaItem>> get albums =>
      _groupItemsBy((item) => item.album ?? 'Desconocido');
  Map<String, List<MediaItem>> get artists =>
      _groupItemsBy((item) => item.artist ?? 'Desconocido');

  Map<String, List<MediaItem>> _groupItemsBy(
    String Function(MediaItem) keySelector,
  ) {
    final Map<String, List<MediaItem>> grouped = {};
    for (var item in _items) {
      final key = keySelector(item);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  // --- CONTROLES Y OTROS ---

  void pause() => handler.pause();
  void resume() => handler.play();
  void skipNext() => handler.skipToNext();
  void skipPrevious() => handler.skipToPrevious();
  void seek(Duration pos) => handler.seek(pos);

  Future<void> toggleShuffle() async {
    final player = (handler as AudioServiceHandler).player;
    await player.setShuffleModeEnabled(!player.shuffleModeEnabled);
    notifyListeners();
  }

  Future<void> toggleLoopMode() async {
    final player = (handler as AudioServiceHandler).player;
    if (player.loopMode == LoopMode.off)
      await player.setLoopMode(LoopMode.all);
    else if (player.loopMode == LoopMode.all)
      await player.setLoopMode(LoopMode.one);
    else
      await player.setLoopMode(LoopMode.off);
    notifyListeners();
  }

  void createPlaylist(String name) {
    if (name.isNotEmpty && !_playlists.containsKey(name)) {
      _playlists[name] = [];
      notifyListeners();
    }
  }

  void addToPlaylist(String name, MediaItem song) {
    if (_playlists.containsKey(name) && !_playlists[name]!.contains(song)) {
      _playlists[name]!.add(song);
      notifyListeners();
    }
  }

  //  GESTIÓN DE LA COLA (QUEUE) ---

  /// Getter para obtener la cola actual desde el handler
  List<MediaItem> get queue => (handler as AudioServiceHandler).queue.value;

  /// Inserta una canción para que suene justo después de la actual
  void playNext(MediaItem song) {
    final currentQueue = List<MediaItem>.from(queue);
    final currentIndex = currentQueue.indexOf(_current ?? song);

    // Insertamos en la posición siguiente a la actual
    if (currentIndex != -1 && currentIndex + 1 < currentQueue.length) {
      currentQueue.insert(currentIndex + 1, song);
    } else {
      currentQueue.add(song);
    }

    // Actualizamos el handler
    (handler as AudioServiceHandler).updateQueue(currentQueue);
    notifyListeners();
  }

  /// Añade una canción al final de la cola
  // --- TIEMPOS DE REPRODUCCIÓN ---

  /// Obtiene la duración total de la canción actual
  Duration get duration =>
      (handler as AudioServiceHandler).player.duration ?? Duration.zero;

  /// Obtiene la posición actual de la reproducción
  Duration get position => (handler as AudioServiceHandler).player.position;

  /// Obtiene cuánto se ha cargado (buffer) de la canción
  Duration get bufferedPosition =>
      (handler as AudioServiceHandler).player.bufferedPosition;

  // --- GESTIÓN DE CONTENIDO EN PLAYLISTS ---

  /// Elimina una canción específica de una playlist
  void removeFromPlaylist(String playlistName, MediaItem song) {
    if (_playlists.containsKey(playlistName)) {
      _playlists[playlistName]!.removeWhere((item) => item.id == song.id);
      notifyListeners();
    }
  }

  /// Limpia toda la cola actual
  void clearQueue() {
    (handler as AudioServiceHandler).updateQueue([]);
    notifyListeners();
  }

  //   // --- GESTIÓN DE PLAYLISTS ---

  void deletePlaylist(String name) {
    _playlists.remove(name);
    notifyListeners();
  }

  // --- AGRUPAMIENTOS (FOLDERS, GENRES, ETC) ---

  Map<String, List<MediaItem>> get folders {
    final Map<String, List<MediaItem>> grouped = {};
    for (var item in _items) {
      final folder = item.id.substring(0, item.id.lastIndexOf('/'));
      grouped.putIfAbsent(folder, () => []).add(item);
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

  void addToQueue(MediaItem song) {
    (handler as AudioServiceHandler).addQueueItem(song);
    notifyListeners();
  }

  // --- MODOS DE REPRODUCCIÓN ---

  bool get shuffleEnabled =>
      (handler as AudioServiceHandler).player.shuffleModeEnabled;
  LoopMode get loopMode => (handler as AudioServiceHandler).player.loopMode;

  // --- UTILIDADES ---

  Uint8List? normalizeCover(dynamic rawCover) {
    if (rawCover is Uint8List) return rawCover;
    if (rawCover is List<int>) return Uint8List.fromList(rawCover);
    return null;
  }

  Future<void> loadAndPlayUri(String path) async => await playFromFile(path);
}


// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:audio_service/audio_service.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:flutter_media_metadata/flutter_media_metadata.dart';
// import 'audio_service_handler.dart';









// // --- Extension para serializar MediaItem ---
// extension MediaItemJson on MediaItem {
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'title': title,
//     'artist': artist,
//     'album': album,
//     'artUri': artUri?.toString(),
//     'duration': duration?.inMilliseconds,
//     'extras': extras,
//   };

//   static MediaItem fromJson(Map<String, dynamic> json) {
//     final extras = (json['extras'] as Map?)?.cast<String, dynamic>();
//     return MediaItem(
//       id: json['id'] as String,
//       title: json['title'] as String,
//       artist: json['artist'] as String?,
//       album: json['album'] as String?,
//       artUri: json['artUri'] != null ? Uri.parse(json['artUri']) : null,
//       extras: extras,
//       duration: json['duration'] != null
//           ? Duration(milliseconds: json['duration'] as int)
//           : null,
//     );
//   }
// }

// class AudioProvider extends ChangeNotifier {
//   final OnAudioQuery _audioQuery = OnAudioQuery();

//   final AudioHandler handler;

//   AudioProvider(this.handler) {
//     final player = (handler as AudioServiceHandler).player;

//     // Listeners de estado y cambios
//     player.loopModeStream.listen((_) => notifyListeners());
//     player.shuffleModeEnabledStream.listen((_) => notifyListeners());
//     player.playerStateStream.listen((state) {
//       _isPlaying = state.playing;
//       notifyListeners();
//     });

//     handler.mediaItem.listen((item) {
//       if (item != null) {
//         _current = item;
//         notifyListeners();
//       }
//     });
//   }

//   List<MediaItem> _items = [];
//   MediaItem? _current;
//   bool _isPlaying = false;
//   final Map<String, List<MediaItem>> _playlists = {};

//   // Getters básicos
//   List<MediaItem> get items => _items;
//   MediaItem? get current => _current;
//   bool get isPlaying => _isPlaying;
//   Map<String, List<MediaItem>> get playlists => _playlists;

//   // Streams de posición para la UI
//   Stream<Duration> get positionStream =>
//       (handler as AudioServiceHandler).positionStream;
//   Stream<Duration?> get durationStream =>
//       (handler as AudioServiceHandler).durationStream;

//   // --- MÉTODOS DE REPRODUCCIÓN Y COLA ---

//   Future<void> play(MediaItem item) async {
//     await playItems([item]);
//   }

//   Future<void> playItems(List<MediaItem> items, {int startIndex = 0}) async {
//     if (items.isEmpty) return;
//     final h = handler as AudioServiceHandler;
//     final sources = items
//         .map((item) => AudioSource.file(item.id, tag: item))
//         .toList();

//     try {
//       h.updateQueue(items); // Método necesario en tu handler
//       await h.player.setAudioSource(
//         ConcatenatingAudioSource(children: sources),
//         initialIndex: startIndex,
//       );
//       await h.player.play();
//     } catch (e) {
//       debugPrint("Error en playItems: $e");
//     }
//   }

//   final Map<int, Uint8List?> _artworkCache = {};

//   Future<Uint8List?> _getAndCacheImage(int songId) async {
//     // Si ya está en caché, la devolvemos directamente
//     if (_artworkCache.containsKey(songId)) {
//       return _artworkCache[songId];
//     }

//     try {
//       final artwork = await _audioQuery.queryArtwork(
//         songId,
//         ArtworkType.AUDIO,
//         format: ArtworkFormat.PNG, // puedes usar JPEG si prefieres
//         size: 200, // tamaño en píxeles
//       );

//       // Guardamos en caché
//       _artworkCache[songId] = artwork;
//       return artwork;
//     } catch (e) {
//       debugPrint("❌ Error obteniendo carátula: $e");
//       _artworkCache[songId] = null;
//       return null;
//     }
//   }

//   Future<void> loadAndPlayUri(String path) async => await playFromFile(path);

//   Future<void> playFromFile(String path) async {
//     final h = handler as AudioServiceHandler;
//     try {
//       final item = _items.firstWhere(
//         (e) => e.id == path,
//         orElse: () => MediaItem(id: path, title: path.split('/').last),
//       );

//       await h.player.setAudioSource(AudioSource.file(path, tag: item));
//       h.playMediaItem(item); // Método necesario en tu handler
//       await h.player.play();
//     } catch (e) {
//       debugPrint("Error en playFromFile: $e");
//     }
//   }

//   void addToQueue(MediaItem song) {
//     (handler as AudioServiceHandler).addQueueItem(song);
//     notifyListeners();
//   }

//   // --- MODOS DE REPRODUCCIÓN ---

//   bool get shuffleEnabled =>
//       (handler as AudioServiceHandler).player.shuffleModeEnabled;
//   LoopMode get loopMode => (handler as AudioServiceHandler).player.loopMode;

//   Future<void> toggleShuffle() async {
//     final player = (handler as AudioServiceHandler).player;
//     await player.setShuffleModeEnabled(!player.shuffleModeEnabled);
//     notifyListeners();
//   }

//   Future<void> toggleLoopMode() async {
//     final player = (handler as AudioServiceHandler).player;
//     switch (player.loopMode) {
//       case LoopMode.off:
//         await player.setLoopMode(LoopMode.all);
//         break;
//       case LoopMode.all:
//         await player.setLoopMode(LoopMode.one);
//         break;
//       case LoopMode.one:
//         await player.setLoopMode(LoopMode.off);
//         break;
//     }
//     notifyListeners();
//   }

//   // --- GESTIÓN DE PLAYLISTS ---

//   void createPlaylist(String name) {
//     if (name.isNotEmpty && !_playlists.containsKey(name)) {
//       _playlists[name] = [];
//       notifyListeners();
//     }
//   }

//   void deletePlaylist(String name) {
//     _playlists.remove(name);
//     notifyListeners();
//   }

//   void addToPlaylist(String name, MediaItem song) {
//     if (_playlists.containsKey(name) && !_playlists[name]!.contains(song)) {
//       _playlists[name]!.add(song);
//       notifyListeners();
//     }
//   }

//   // --- AGRUPAMIENTOS (FOLDERS, GENRES, ETC) ---

//   Map<String, List<MediaItem>> get folders {
//     final Map<String, List<MediaItem>> grouped = {};
//     for (var item in _items) {
//       final folder = item.id.substring(0, item.id.lastIndexOf('/'));
//       grouped.putIfAbsent(folder, () => []).add(item);
//     }
//     return grouped;
//   }

//   Map<String, List<MediaItem>> get genres {
//     final Map<String, List<MediaItem>> grouped = {};
//     for (var item in _items) {
//       final genre = item.extras?['genre'] ?? 'Desconocido';
//       grouped.putIfAbsent(genre, () => []).add(item);
//     }
//     return grouped;
//   }

//   Map<String, List<MediaItem>> get albums =>
//       _groupItemsBy((item) => item.album ?? 'Desconocido');
//   Map<String, List<MediaItem>> get artists =>
//       _groupItemsBy((item) => item.artist ?? 'Desconocido');

//   Map<String, List<MediaItem>> _groupItemsBy(
//     String Function(MediaItem) keySelector,
//   ) {
//     final Map<String, List<MediaItem>> grouped = {};
//     for (var item in _items) {
//       final key = keySelector(item);
//       grouped.putIfAbsent(key, () => []).add(item);
//     }
//     return grouped;
//   }

//   // --- UTILIDADES ---

//   Uint8List? normalizeCover(dynamic rawCover) {
//     if (rawCover is Uint8List) return rawCover;
//     if (rawCover is List<int>) return Uint8List.fromList(rawCover);
//     return null;
//   }

//   // --- LÓGICA DE CARGA Y REFRESH (YA OPTIMIZADA) ---

//   Future<void> loadLibrary() async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getStringList('library_items');
//     if (saved != null) {
//       _items = saved.map((e) => MediaItemJson.fromJson(jsonDecode(e))).toList();
//     } else {
//       await refreshLibrary();
//     }
//     notifyListeners();
//   }

//   // Future<void> refreshLibrary() async {
//   //   final scannedPaths = await (handler as AudioServiceHandler).scanPaths();
//   //   final Map<String, MediaItem> currentMap = {
//   //     for (var item in _items) item.id: item,
//   //   };
//   //   List<MediaItem> updatedList = [];

//   //   for (String path in scannedPaths) {
//   //     updatedList.add(
//   //       currentMap.containsKey(path)
//   //           ? currentMap[path]!
//   //           : await _buildMediaItem(path),
//   //     );
//   //   }

//   //   _items = updatedList..sort((a, b) => a.title.compareTo(b.title));
//   //   await _persistLibrary();
//   //   notifyListeners();
//   // }
//   // --- En la parte de arriba de tu clase AudioProvider ---

//   // --- MODIFICA EL MÉTODO DE CARGA ---

//   // 1. Agrega estas variables arriba en tu AudioProvider
//   List<AlbumModel> _albumModels = [];
//   List<AlbumModel> get albumModels => _albumModels;

//   // 2. Modifica el método que escanea
//   Future<void> refreshLibrary() async {
//     // Escaneamos los álbumes directamente (Esto nunca falla)
//     _albumModels = await _audioQuery.queryAlbums(
//       sortType: AlbumSortType.ALBUM,
//       orderType: OrderType.ASC_OR_SMALLER,
//       uriType: UriType.EXTERNAL,
//     );

//     // ... (Tu código actual para cargar canciones sigue igual abajo)
//     notifyListeners();
//   }

//   Future<void> _persistLibrary() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList(
//       'library_items',
//       _items.map((e) => jsonEncode(e.toJson())).toList(),
//     );
//   }

//   Future<MediaItem> _buildMediaItem(String path) async {
//     try {
//       // 🔍 Buscamos la canción por su ruta exacta para obtener el ID real de Android
//       final List<SongModel> songs = await _audioQuery.querySongs(
//         sortType: null, // No necesitamos ordenar para un solo archivo
//         orderType: OrderType.ASC_OR_SMALLER,
//         uriType: UriType.EXTERNAL,
//         ignoreCase: true,
//       );

//       // Filtramos la lista para encontrar el archivo exacto por su path
//       final song = songs.firstWhere(
//         (s) => s.data == path,
//         orElse: () => songs.isNotEmpty ? songs.first : null as dynamic,
//       );

//       final metadata = await MetadataRetriever.fromFile(File(path));

//       // 🔑 GUARDAMOS EL ID NUMÉRICO (IMPORTANTE)
//       final int realId = (song != null) ? song.id : 0;

//       return MediaItem(
//         id: path,
//         title: metadata.trackName ?? path.split('/').last,
//         artist: metadata.trackArtistNames?.first ?? "Artista Desconocido",
//         album: metadata.albumName ?? "Álbum Desconocido",
//         duration: metadata.trackDuration != null
//             ? Duration(milliseconds: metadata.trackDuration!)
//             : null,
//         extras: {
//           'dbId': realId, // 👈 Esto es lo que lee la carátula
//           'genre': metadata.genre,
//         },
//       );
//     } catch (e) {
//       debugPrint("Error construyendo MediaItem: $e");
//       return MediaItem(
//         id: path,
//         title: path.split('/').last,
//         extras: {'dbId': 0},
//       );
//     }
  // } // --- GESTIÓN DE LA COLA (QUEUE) ---

  // /// Getter para obtener la cola actual desde el handler
  // List<MediaItem> get queue => (handler as AudioServiceHandler).queue.value;

  // /// Inserta una canción para que suene justo después de la actual
  // void playNext(MediaItem song) {
  //   final currentQueue = List<MediaItem>.from(queue);
  //   final currentIndex = currentQueue.indexOf(_current ?? song);

  //   // Insertamos en la posición siguiente a la actual
  //   if (currentIndex != -1 && currentIndex + 1 < currentQueue.length) {
  //     currentQueue.insert(currentIndex + 1, song);
  //   } else {
  //     currentQueue.add(song);
  //   }

  //   // Actualizamos el handler
  //   (handler as AudioServiceHandler).updateQueue(currentQueue);
  //   notifyListeners();
  // }

//   /// Añade una canción al final de la cola
//   // --- TIEMPOS DE REPRODUCCIÓN ---

//   /// Obtiene la duración total de la canción actual
//   Duration get duration =>
//       (handler as AudioServiceHandler).player.duration ?? Duration.zero;

//   /// Obtiene la posición actual de la reproducción
//   Duration get position => (handler as AudioServiceHandler).player.position;

//   /// Obtiene cuánto se ha cargado (buffer) de la canción
//   Duration get bufferedPosition =>
//       (handler as AudioServiceHandler).player.bufferedPosition;

//   // --- GESTIÓN DE CONTENIDO EN PLAYLISTS ---

//   /// Elimina una canción específica de una playlist
//   void removeFromPlaylist(String playlistName, MediaItem song) {
//     if (_playlists.containsKey(playlistName)) {
//       _playlists[playlistName]!.removeWhere((item) => item.id == song.id);
//       notifyListeners();
//     }
//   }

//   /// Limpia toda la cola actual
//   void clearQueue() {
//     (handler as AudioServiceHandler).updateQueue([]);
//     notifyListeners();
//   }

//   // Controles básicos
//   void pause() => handler.pause();
//   void resume() => handler.play();
//   void skipNext() => handler.skipToNext();
//   void skipPrevious() => handler.skipToPrevious();
//   void seek(Duration pos) => handler.seek(pos);
// }



