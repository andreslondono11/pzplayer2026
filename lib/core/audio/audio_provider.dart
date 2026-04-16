import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as p;
import 'package:just_audio/just_audio.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'audio_service_handler.dart';

// --- Extensión para serializar MediaItem ---
extension MediaItemJson on MediaItem {
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'artUri': artUri?.toString(),
    'genre': genre, // <--- AGREGADO AQUÍ
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
      genre: json['genre'] as String?, // <--- AGREGADO AQUÍ
      extras: extras,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
    );
  }
}

// --- Función Global para Isolate (compute) ---
// Esto permite procesar listas grandes sin congelar la UI
// --- Función Global para Isolate (compute) ---
// CORREGIDA: Ahora sí incluye el género al escanear
List<MediaItem> parseSongsToMediaItems(List<SongModel> fetchedSongs) {
  return fetchedSongs.map((song) {
    // --- PASO 1: Obtener el género del archivo original ---
    // on_audio_query lo entrega en song.genre.
    // Si es nulo o vacío, ponemos 'Desconocido' o null.
    String? songGenre = song.genre;
    if (songGenre != null && songGenre.trim().isEmpty) {
      songGenre = null;
    }

    // --- PASO 2: Crear el MediaItem CON el género ---
    return MediaItem(
      id: song.data,
      title: song.title,
      artist: song.artist ?? "Artista Desconocido",
      album: song.album ?? "Álbum Desconocido",
      genre: songGenre, // ✅ AQUÍ ESTABA EL FALTA: AGREGAR ESTO
      duration: Duration(milliseconds: song.duration ?? 0),
      // Es importante guardar el ID de la base de datos si necesitas consultas futuras
      extras: {
        'dbId': song.id,
        'albumId': song.albumId,
        // (Opcional) Si quieres redundancia, puedes ponerlo también en extras:
        // 'genre': songGenre,
      },
    );
  }).toList();
}

// ==========================================
// CLASE PRINCIPAL
// ==========================================

class AudioProvider extends ChangeNotifier {
  // --- DEPENDENCIAS ---
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioHandler handler;
  final _equalizer = AndroidEqualizer();

  // --- CAJAS DE HIVE (BOXES) ---
  late Box _libraryBox;
  late Box _playlistsBox;
  late Box _favoritesBox;
  late Box _statsBox;

  // --- VARIABLES DE ESTADO ---
  List<MediaItem> _items = [];
  List<AlbumModel> _albumModels = [];
  MediaItem? _current;
  bool _isPlaying = false;
  dynamic _currentSong;

  // --- PLAYLISTS ---
  final Map<String, List<MediaItem>> _playlists = {};

  // --- ECUALIZADOR ---
  bool _isEqualizerEnabled = true;
  List<double> _currentEGBands = [0.5, 0.5, 0.5, 0.5, 0.5];

  // --- SISTEMA ---
  Timer? _libraryCheckTimer;
  int _lastKnownCount = 0;
  Set<String> _favoriteAlbums = {};
  bool _isPlayingFile = false;

  // --- ESTADÍSTICAS ---
  List<dynamic> _mostPlayedItems = [];
  String _currentCategory = 'albums';
  bool _isLoadingMostPlayed = false;
  String? _lastRegisteredId;

  // --- FAVORITOS ---
  final Set<String> _favoriteSongs = {};

  // --- GETTERS ---
  List<MediaItem> get items => _items;
  List<AlbumModel> get albumModels => _albumModels;
  MediaItem? get current => _current;
  bool get isPlaying => _isPlaying;
  dynamic get currentSong => _currentSong;
  Map<String, List<MediaItem>> get playlists => _playlists;
  bool get isEqualizerEnabled => _isEqualizerEnabled;
  List<double> get currentEGBands => _currentEGBands;
  List<MediaItem> get currentQueue =>
      (handler as AudioServiceHandler).queue.value;
  List<MediaItem> get queue => currentQueue;
  List<dynamic> get mostPlayedItems => _mostPlayedItems;
  String get currentCategory => _currentCategory;
  bool get isLoadingMostPlayed => _isLoadingMostPlayed;

  Stream<Duration> get positionStream =>
      (handler as AudioServiceHandler).positionStream;
  Stream<Duration?> get durationStream =>
      (handler as AudioServiceHandler).durationStream;
  Duration get duration =>
      (handler as AudioServiceHandler).player.duration ?? Duration.zero;
  Duration get position => (handler as AudioServiceHandler).player.position;
  Duration get bufferedPosition =>
      (handler as AudioServiceHandler).player.bufferedPosition;
  bool get shuffleEnabled =>
      (handler as AudioServiceHandler).player.shuffleModeEnabled;
  LoopMode get loopMode => (handler as AudioServiceHandler).player.loopMode;

  // ==========================================
  // CONSTRUCTOR
  // ==========================================
  AudioProvider(this.handler) {
    final player = (handler as AudioServiceHandler).player;

    // Listeners de Audio
    player.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      if (wasPlaying != _isPlaying) _syncWidget();
      notifyListeners();
    });

    handler.mediaItem.listen((item) {
      _current = item;
      if (item != null) _syncWidget();
      notifyListeners();
    });

    player.loopModeStream.listen((_) => notifyListeners());
    player.shuffleModeEnabledStream.listen((_) => notifyListeners());

    // Inicialización en Background
    Future.microtask(() async {
      try {
        // 1. Abrimos todas las cajas de Hive una sola vez
        await _initHiveBoxes();

        // 2. Cargamos datos en paralelo
        await Future.wait([
          loadLibrary(),
          _loadPlaylists(),
          loadFavorites(),
          _loadStats(),
        ]);

        _initWidgetDefaults();
        _startPeriodicCheck();
        print("✅ Provider inicializado con Hive correctamente");
      } catch (e) {
        print("❌ Error en inicialización: $e");
      }
    });
  }

  // ==========================================
  // INICIALIZACIÓN HIVE
  // ==========================================
  Future<void> _initHiveBoxes() async {
    // Abrimos las cajas. Si no existen, Hive las crea.
    _libraryBox = await Hive.openBox('pz_library');
    _playlistsBox = await Hive.openBox('pz_playlists');
    _favoritesBox = await Hive.openBox('pz_favorites');
    _statsBox = await Hive.openBox('pz_stats');
    print("📦 Cajas de Hive abiertas correctamente");
  }

  // ==========================================
  // GESTIÓN DE LIBRERÍA (HIVE)
  // ==========================================
  Future<void> loadLibrary() async {
    try {
      final List? saved = _libraryBox.get('library_items');

      if (saved != null && saved.isNotEmpty) {
        // Mapeo seguro
        _items = saved.map((e) {
          final mapData = Map<String, dynamic>.from(e);
          return MediaItemJson.fromJson(mapData);
        }).toList();

        _lastKnownCount = _items.length;
        notifyListeners();
        print("⚡ [HIVE] Biblioteca recuperada: $_lastKnownCount canciones");
      } else {
        print("📂 Biblioteca vacía en Hive, escaneando...");
        await refreshLibrary();
      }
    } catch (e) {
      print("🔴 Error cargando librería de Hive: $e");
    }
  }

  Future<void> refreshLibrary() async {
    try {
      print("🔄 Escaneando archivos nativos...");
      final fetchedSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      print("⚡ Procesando ${fetchedSongs.length} canciones en Isolate...");
      final List<MediaItem> mappedItems = await compute(
        parseSongsToMediaItems,
        fetchedSongs,
      );

      _items = mappedItems;
      _lastKnownCount = _items.length;
      notifyListeners();
      print("✅ Biblioteca refrescada: ${_items.length} canciones");

      // Guardar en Hive en segundo plano
      _persistLibrary();
    } catch (e) {
      print("❌ Error refrescando librería: $e");
    }
  }

  Future<void> _persistLibrary() async {
    try {
      final dataToSave = _items
          .map(
            (e) => {
              'id': e.id,
              'title': e.title,
              'artist': e.artist,
              'album': e.album,
              // ✅ AGREGA ESTAS DOS LÍNEAS AQUÍ DENTRO DEL MAP
              'artUri': e.artUri?.toString(),
              'genre': e.genre, // <--- CLAVE PARA QUE PERSISTAN LOS GÉNEROS

              'duration': e.duration?.inMilliseconds,
              'extras': e.extras,
            },
          )
          .toList();

      await _libraryBox.put('library_items', dataToSave);
      print("💾 [HIVE] Biblioteca guardada");
    } catch (e) {
      print("❌ Error persistiendo en Hive: $e");
    }
  }

  // ==========================================
  // GESTIÓN DE PLAYLISTS (HIVE)
  // ==========================================
  Future<void> createPlaylist(String name) async {
    if (name.isNotEmpty && !_playlists.containsKey(name)) {
      _playlists[name] = [];
      notifyListeners();
      await _savePlaylists();
    }
  }

  Future<void> addToPlaylist(String name, MediaItem song) async {
    if (_playlists.containsKey(name)) {
      if (!_playlists[name]!.any((s) => s.id == song.id)) {
        _playlists[name]!.add(song);
        notifyListeners();
        await _savePlaylists();
      }
    }
  }

  Future<void> deletePlaylist(String name) async {
    if (_playlists.containsKey(name)) {
      _playlists.remove(name);
      notifyListeners();
      await _savePlaylists();
    }
  }

  Future<void> removeFromPlaylist(String playlistName, MediaItem song) async {
    if (_playlists.containsKey(playlistName)) {
      _playlists[playlistName]!.removeWhere((item) => item.id == song.id);
      notifyListeners();
      await _savePlaylists();
    }
  }

  Future<void> _loadPlaylists() async {
    try {
      final String? jsonStr = _playlistsBox.get('all_playlists');
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        _playlists.clear();
        decoded.forEach((name, list) {
          final List<MediaItem> songs = (list as List).map((item) {
            return MediaItemJson.fromJson(item as Map<String, dynamic>);
          }).toList();
          _playlists[name] = songs;
        });
        notifyListeners();
        print("📋 [HIVE] Playlists cargadas");
      }
    } catch (e) {
      print("❌ Error cargando playlists de Hive: $e");
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final Map<String, dynamic> data = {};
      _playlists.forEach((name, songs) {
        data[name] = songs.map((s) => s.toJson()).toList();
      });
      await _playlistsBox.put('all_playlists', jsonEncode(data));
    } catch (e) {
      print("❌ Error guardando playlists en Hive: $e");
    }
  }

  // ==========================================
  // FAVORITOS (HIVE)
  // ==========================================
  bool isSongFavorite(MediaItem song) {
    final id = song.extras?['dbId']?.toString();
    if (id == null) return false;
    return _favoriteSongs.contains(id);
  }

  Future<void> loadFavorites() async {
    try {
      final favList = _favoritesBox.get(
        'favorite_songs_ids',
        defaultValue: <String>[],
      );
      _favoriteSongs.addAll(favList.cast<String>());
      print("❤️ [HIVE] Favoritos cargados: ${_favoriteSongs.length}");
      notifyListeners();
    } catch (e) {
      print("❌ Error cargando favoritos: $e");
    }
  }

  Future<void> _saveFavorites() async {
    try {
      await _favoritesBox.put('favorite_songs_ids', _favoriteSongs.toList());
    } catch (e) {
      print("❌ Error guardando favoritos: $e");
    }
  }

  Future<void> toggleFavoriteSong(MediaItem song) async {
    final id = song.extras?['dbId']?.toString();
    if (id == null) return;

    if (_favoriteSongs.contains(id)) {
      _favoriteSongs.remove(id);
      print("🗑️ Quitado de favoritos");
    } else {
      _favoriteSongs.add(id);
      print("❤️ Añadido a favoritos");
    }

    await _saveFavorites();
    notifyListeners();
  }

  // ==========================================
  // ESTADÍSTICAS (HIVE - JSON Strings)
  // ==========================================
  Future<void> _loadStats() async {
    try {
      final favs = _statsBox.get('favorite_albums', defaultValue: <String>[]);
      _favoriteAlbums = favs.cast<String>().toSet();
    } catch (e) {
      print("❌ Error cargando stats: $e");
    }
  }

  Future<void> registrarReproduccionUniversal(MediaItem song) async {
    final String songId = song.extras?['dbId']?.toString() ?? song.id;

    if (_lastRegisteredId == songId) {
      return;
    }
    _lastRegisteredId = songId;

    try {
      // Definición de llaves en Hive
      const String keySongs = 'counts_songs';
      const String keyAlbums = 'counts_albums';
      const String keyArtists = 'counts_artists';
      const String keyGenres = 'counts_genres';

      // Lectura desde Hive (guardamos Maps como JSON strings)
      Map<String, dynamic> songsMap = jsonDecode(
        _statsBox.get(keySongs, defaultValue: '{}'),
      );
      Map<String, dynamic> albumsMap = jsonDecode(
        _statsBox.get(keyAlbums, defaultValue: '{}'),
      );
      Map<String, dynamic> artistsMap = jsonDecode(
        _statsBox.get(keyArtists, defaultValue: '{}'),
      );
      Map<String, dynamic> genresMap = jsonDecode(
        _statsBox.get(keyGenres, defaultValue: '{}'),
      );

      final String albumId = song.extras?['albumId']?.toString() ?? 'unknown';
      final String artistName = song.artist?.toLowerCase().trim() ?? 'unknown';
      final String genreName =
          song.extras?['genre']?.toLowerCase().trim() ?? 'unknown';

      songsMap[songId] = (songsMap[songId] ?? 0) + 1;
      albumsMap[albumId] = (albumsMap[albumId] ?? 0) + 1;
      artistsMap[artistName] = (artistsMap[artistName] ?? 0) + 1;
      genresMap[genreName] = (genresMap[genreName] ?? 0) + 1;

      // Guardado paralelo en Hive
      await Future.wait([
        _statsBox.put(keySongs, jsonEncode(songsMap)),
        _statsBox.put(keyAlbums, jsonEncode(albumsMap)),
        _statsBox.put(keyArtists, jsonEncode(artistsMap)),
        _statsBox.put(keyGenres, jsonEncode(genresMap)),
      ]);

      print("✅ [HIVE] Estadísticas actualizadas");
    } catch (e) {
      _lastRegisteredId = null;
      print("❌ Error registrando estadísticas: $e");
    }
  }

  Future<void> cargarMasEscuchados(String category) async {
    _currentCategory = category;
    _isLoadingMostPlayed = true;
    notifyListeners();

    try {
      List<dynamic> resultList = [];

      switch (category) {
        case 'songs':
          resultList = _getTopSongs();
          break;
        case 'albums':
          resultList = await _getTopAlbums();
          break;
        case 'artists':
          resultList = _getTopArtists();
          break;
        case 'genres':
          resultList = _getTopGenres();
          break;
      }

      _mostPlayedItems = resultList.take(20).toList();
      _isLoadingMostPlayed = false;
      notifyListeners();
    } catch (e) {
      print("❌ Error cargando $category: $e");
      _isLoadingMostPlayed = false;
      notifyListeners();
    }
  }

  List<dynamic> _getTopSongs() {
    Map<String, dynamic> counts = jsonDecode(
      _statsBox.get('counts_songs', defaultValue: '{}'),
    );
    List<MediaItem> allSongs = List.from(_items);

    allSongs.sort((a, b) {
      String idA = a.extras?['dbId']?.toString() ?? a.id;
      String idB = b.extras?['dbId']?.toString() ?? b.id;
      int countA = counts[idA] ?? 0;
      int countB = counts[idB] ?? 0;
      return countB.compareTo(countA);
    });
    return allSongs;
  }

  Future<List<AlbumModel>> _getTopAlbums() async {
    Map<String, dynamic> counts = jsonDecode(
      _statsBox.get('counts_albums', defaultValue: '{}'),
    );
    List<AlbumModel> albums = List.from(_albumModels);

    albums.sort((a, b) {
      String idA = a.id.toString();
      String idB = b.id.toString();
      int countA = counts[idA] ?? 0;
      int countB = counts[idB] ?? 0;
      return countB.compareTo(countA);
    });
    return albums;
  }

  List<String> _getTopArtists() {
    Map<String, dynamic> counts = jsonDecode(
      _statsBox.get('counts_artists', defaultValue: '{}'),
    );
    var sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((e) => e.key).toList();
  }

  List<String> _getTopGenres() {
    Map<String, dynamic> counts = jsonDecode(
      _statsBox.get('counts_genres', defaultValue: '{}'),
    );
    var sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((e) => e.key).toList();
  }

  // ==========================================
  // REPRODUCCIÓN Y CONTROLES
  // ==========================================
  void setCurrentSong(dynamic song) {
    _currentSong = song;
    notifyListeners();
  }

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
      print("❌ Error en playItems: $e");
    }
  }

  void playNext(MediaItem song) {
    final currentQueue = List<MediaItem>.from(queue);
    final currentIndex = currentQueue.indexOf(_current ?? song);
    if (currentIndex != -1 && currentIndex + 1 < currentQueue.length) {
      currentQueue.insert(currentIndex + 1, song);
    } else {
      currentQueue.add(song);
    }
    (handler as AudioServiceHandler).updateQueue(currentQueue);
    notifyListeners();
  }

  void addToQueue(MediaItem song) {
    (handler as AudioServiceHandler).addQueueItem(song);
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    final List<MediaItem> fullQueue = List.from(currentQueue);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = fullQueue.removeAt(oldIndex);
    fullQueue.insert(newIndex, item);
    (handler as AudioServiceHandler).updateQueue(fullQueue);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    final List<MediaItem> currentList = List.from(currentQueue);
    if (index >= 0 && index < currentList.length) {
      currentList.removeAt(index);
      (handler as AudioServiceHandler).updateQueue(currentList);
      notifyListeners();
    }
  }

  void clearQueue() {
    (handler as AudioServiceHandler).updateQueue([]);
    notifyListeners();
  }

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
    if (player.loopMode == LoopMode.off) {
      await player.setLoopMode(LoopMode.all);
    } else if (player.loopMode == LoopMode.all)
      await player.setLoopMode(LoopMode.one);
    else
      await player.setLoopMode(LoopMode.off);
    notifyListeners();
  }

  // ==========================================
  // ECUALIZADOR
  // ==========================================
  void setBandGain(int bandIndex, double sliderValue) {
    double safeValue = sliderValue.clamp(0.0, 1.0);
    _currentEGBands[bandIndex] = safeValue;
    if (_isEqualizerEnabled) _applyEffect(bandIndex, safeValue);
    notifyListeners();
  }

  void toggleEqualizer(bool value) {
    _isEqualizerEnabled = value;
    notifyListeners();
  }

  void _applyEffect(int index, double value) {
    double milliBelios = (value * 3000.0) - 1500.0;
    try {
      _equalizer.parameters.then((params) {
        if (index < params.bands.length) {
          params.bands[index].setGain(milliBelios);
        }
      });
    } catch (e) {
      print("⚠️ Error aplicando efecto ecualizador: $e");
    }
  }

  void setFullPreset(List<double> newBands) {
    _currentEGBands = List.from(newBands);
    if (_isEqualizerEnabled) {
      for (int i = 0; i < _currentEGBands.length; i++) {
        _applyEffect(i, _currentEGBands[i]);
      }
    }
    notifyListeners();
  }

  // ==========================================
  // AGRUPAMIENTOS (Biblioteca)
  // ==========================================
  Map<String, List<MediaItem>> get albums =>
      _groupItemsBy((item) => item.album ?? 'Desconocido');

  Map<String, List<MediaItem>> get artists =>
      _groupItemsBy((item) => item.artist ?? 'Desconocido');

  Map<String, List<MediaItem>> get folders {
    final Map<String, List<MediaItem>> grouped = {};
    for (var item in _items) {
      final path = item.id;
      final lastSlash = path.lastIndexOf('/');
      if (lastSlash != -1) {
        String fullPath = path.substring(0, lastSlash);
        String folderName = fullPath.substring(fullPath.lastIndexOf('/') + 1);
        grouped.putIfAbsent(folderName, () => []).add(item);
      } else {
        grouped.putIfAbsent("Raíz", () => []).add(item);
      }
    }
    return grouped;
  }

  Map<String, List<MediaItem>> get genres {
    final Map<String, List<MediaItem>> grouped = {};
    for (var item in _items) {
      // ✅ CAMBIO CLAVE: Usamos item.genre directamente (propiedad del objeto)
      // en lugar de item.extras?['genre']
      final genre = item.genre ?? 'Desconocido';

      // Opcional: Limpiar espacios o nombres raros
      String cleanGenre = genre.trim();
      if (cleanGenre.isEmpty) cleanGenre = 'Desconocido';

      grouped.putIfAbsent(cleanGenre, () => []).add(item);
    }
    return grouped;
  }

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

  // ==========================================
  // WIDGETS Y ARCHIVOS
  // ==========================================
  Future<void> _initWidgetDefaults() async {
    // Retrasamos un poco esto para asegurar que la UI haya pintado primero
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      await HomeWidget.saveWidgetData<String>('title', 'PZ Player');
      await HomeWidget.saveWidgetData<String>('artist', 'PzStudio');
      await HomeWidget.saveWidgetData<bool>('isPlaying', false);
      await HomeWidget.updateWidget(
        name: 'widget.PlayerWidget',
        androidName: 'widget.PlayerWidget',
      );
    } catch (e) {
      print("⚠️ [WIDGET] Error inicializando widget: $e");
    }
  }

  Future<void> _syncWidget() async {
    if (_current == null) return;
    try {
      await HomeWidget.saveWidgetData<String>('title', _current!.title);
      await HomeWidget.saveWidgetData<String>(
        'artist',
        _current!.artist ?? 'PzStudio',
      );
      await HomeWidget.saveWidgetData<bool>('isPlaying', _isPlaying);
      await _saveCoverArtToWidget(_current!);
      await HomeWidget.updateWidget(
        name: 'widget.PlayerWidget',
        androidName: 'widget.PlayerWidget',
      );
    } catch (e) {
      // Silenciamos errores de widget para no romper la app
    }
  }

  Future<void> guardarDatosWidget(MediaItem song, bool isPlaying) async {
    try {
      await HomeWidget.saveWidgetData<String>('title', song.title);
      await HomeWidget.saveWidgetData<String>('artist', song.artist ?? '');
      await HomeWidget.saveWidgetData<bool>('isPlaying', isPlaying);
      await HomeWidget.saveWidgetData<String>('id', song.id ?? song.title);
      await HomeWidget.updateWidget(
        name: '.widget.PlayerWidget',
        androidName: 'com.pzplayer.co.pzplayer.widget.PlayerWidget',
      );
    } catch (e) {
      print("⚠️ [WIDGET] Error guardando datos en widget: $e");
    }
  }

  Future<void> _saveCoverArtToWidget(MediaItem mediaItem) async {
    try {
      if (mediaItem.artUri != null) {
        final uri = mediaItem.artUri!;
        if (uri.scheme == 'data') {
          await HomeWidget.saveWidgetData<String>('imagePath', uri.toString());
          return;
        }
        try {
          final file = File.fromUri(uri);
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
            await HomeWidget.saveWidgetData<String>('imagePath', base64Image);
          } else {
            await HomeWidget.saveWidgetData<String>('imagePath', '');
          }
        } catch (e) {
          final id = mediaItem.extras?['dbId'] as int?;
          if (id != null) {
            final Uint8List? artBytes = await _audioQuery.queryArtwork(
              id,
              ArtworkType.AUDIO,
              size: 100,
              format: ArtworkFormat.JPEG,
            );
            if (artBytes != null) {
              await HomeWidget.saveWidgetData<String>(
                'imagePath',
                "data:image/jpeg;base64,${base64Encode(artBytes)}",
              );
            } else {
              await HomeWidget.saveWidgetData<String>('imagePath', '');
            }
          } else {
            await HomeWidget.saveWidgetData<String>('imagePath', '');
          }
        }
      } else {
        await HomeWidget.saveWidgetData<String>('imagePath', '');
      }
    } catch (e) {
      await HomeWidget.saveWidgetData<String>('imagePath', '');
    }
  }

  Future<void> escaneoUniversal(List<String> paths) async {
    for (String path in paths) {
      try {
        Uri? audioUri;
        if (path.startsWith('content://')) {
          audioUri = Uri.parse(path);
        } else if (path.startsWith('msf:')) {
          // Lógica MSF si se requiere
        } else {
          final file = File(path);
          if (await file.exists()) {
            audioUri = Uri.file(path);
          } else {
            continue;
          }
        }
      } catch (e) {
        print("❌ Error procesando canción individual: $e");
        continue;
      }
    }
  }

  Future<String?> _asegurarArchivoLocal(String uriString) async {
    if (!uriString.startsWith('content://')) return uriString;

    try {
      print("🛡️ Asegurando permiso para URI temporal...");
      final directory = await getTemporaryDirectory();
      // Creamos un nombre basado en el ID para no duplicar (msf_35.mp3)
      final fileName = uriString.split('%3A').last;
      final tempPath = '${directory.path}/temp_$fileName.mp3';
      final tempFile = File(tempPath);

      // Si ya lo copiamos antes, lo usamos de una vez
      if (await tempFile.exists()) return tempPath;

      // Aquí viene el truco: Usamos el MethodChannel o un plugin
      // para leer los bytes del URI y escribirlos en el archivo local
      // Si usas el plugin 'flutter_cache_manager' es más simple,
      // pero puedes intentar leerlo directamente:
      final originalFile = File(uriString);
      final bytes = await originalFile.readAsBytes();
      await tempFile.writeAsBytes(bytes);

      print("✅ Archivo asegurado en: $tempPath");
      return tempPath;
    } catch (e) {
      print("❌ Error al persistir archivo temporal: $e");
      return null;
    }
  }

  // --- CARGA DE ARCHIVOS EXTERNOS (OPTIMIZADA) ---
  Future<void> loadAndPlayUri(String path) async => await playFromFile(path);
  // Future<void> playFromFile(String path) async {
  //   final h = handler as AudioServiceHandler;

  //   try {
  //     // 1. Manejo de la ruta
  //     Uri audioUri = path.startsWith('content://') || path.startsWith('file://')
  //         ? Uri.parse(path)
  //         : Uri.file(path);

  //     // 2. Extracción del título desde el nombre del archivo (Tu lógica actual)
  //     String fileName = path.split(RegExp(r'[/\\]')).last;
  //     String decodedName = Uri.decodeFull(fileName);
  //     String cleanTitle = decodedName.contains('.')
  //         ? decodedName.substring(0, decodedName.lastIndexOf('.'))
  //         : decodedName;
  //     cleanTitle = cleanTitle.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  //     if (cleanTitle.isEmpty) cleanTitle = "Audio Externo";

  //     // 3. Crear el MediaItem INICIAL (Sin duración aún)
  //     final item = MediaItem(
  //       id: audioUri.toString(),
  //       title: cleanTitle,
  //       artist: "PZ Player",
  //       album: "Reproducción Externa",
  //       extras: {'source': 'universal_uri'},
  //     );

  //     // 4. Preparar y Reproducir
  //     await h.player.stop();

  //     // Suscripción temporal para obtener la duración real cuando esté lista
  //     StreamSubscription? durationSub;

  //     // Escuchamos el stream de duración UNA sola vez para actualizar la notificación
  //     durationSub = h.player.durationStream.listen((duration) {
  //       if (duration != null && h.mediaItem.value?.duration == null) {
  //         // Actualizamos el item en la notificación con la duración real
  //         h.mediaItem.add(item.copyWith(duration: duration));
  //         // Una vez actualizado, dejamos de escuchar para no gastar recursos
  //         durationSub?.cancel();
  //       }
  //     });

  //     await h.player.setAudioSource(
  //       AudioSource.uri(audioUri, tag: item),
  //       preload: true,
  //     );

  //     await h.player.play();

  //     debugPrint(
  //       "✅ PZ Player: Reproduciendo externo: $cleanTitle (Ruta segura)",
  //     );
  //   } catch (e) {
  //     debugPrint("🔴 Error al abrir archivo externo: $e");
  //   }
  // }
  // Constante del canal (Debe coincidir con Kotlin)
  static const _metadataChannel = MethodChannel(
    'com.pzplayer.co.pzplayer/metadata',
  );

  Future<void> playFromFile(String path) async {
    final h = handler as AudioServiceHandler;

    try {
      Uri audioUri = path.startsWith('content://') || path.startsWith('file://')
          ? Uri.parse(path)
          : Uri.file(path);

      String cleanTitle = "Audio Externo";
      String cleanArtist = "PZ Player";
      String cleanAlbum = "Reproducción Externa";
      Uri? artUri;

      // ✅ 1. Extraer datos completos (Título e Imagen) usando código NATIVO robusto
      try {
        final Map<dynamic, dynamic>? result = await _metadataChannel
            .invokeMethod('getFullMetadata', {'path': path});

        if (result != null && result['success'] == true) {
          // Título
          cleanTitle = result['title'] ?? cleanTitle;
          cleanArtist = result['artist'] ?? cleanArtist;
          cleanAlbum = result['album'] ?? cleanAlbum;

          // Imagen (Base64 -> Archivo Temporal)
          final String? base64Art = result['artBase64'];
          if (base64Art != null && base64Art.isNotEmpty) {
            final Uint8List imageBytes = base64Decode(base64Art);
            final tempDir = await getTemporaryDirectory();
            final artFile = File(
              '${tempDir.path}/art_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            await artFile.writeAsBytes(imageBytes);

            artUri = artFile.uri;
            print("🖼️ Carátula Nativa Extraída (Title: $cleanTitle)");
          }
        }
      } catch (e) {
        print("⚠️ Error extrayendo metadata nativa: $e");
        // Fallback simple al nombre de archivo
        try {
          String fileName = path.split(RegExp(r'[/\\]')).last;
          cleanTitle = Uri.decodeFull(
            fileName,
          ).split('.').first.replaceAll('_', ' ').trim();
        } catch (_) {}
      }

      // 2. Crear MediaItem
      final item = MediaItem(
        id: audioUri.toString(),
        title: cleanTitle,
        artist: cleanArtist,
        album: cleanAlbum,
        artUri: artUri, // Recibe Uri (File.uri)
        extras: {'source': 'universal_uri'},
      );

      await h.player.stop();

      // Listener de duración
      StreamSubscription? durationSub;
      durationSub = h.player.durationStream.listen((duration) {
        if (duration != null && h.mediaItem.value?.duration == null) {
          h.mediaItem.add(item.copyWith(duration: duration));
          durationSub?.cancel();
        }
      });

      await h.player.setAudioSource(
        AudioSource.uri(audioUri, tag: item),
        preload: true,
      );

      await h.player.play();

      debugPrint("✅ Reproduciendo: $cleanTitle (Arte: ${artUri != null})");
    } catch (e) {
      debugPrint("🔴 Error crítico al abrir archivo externo: $e");
    }
  }

  Future<String?> _copyToCache(String uriString) async {
    try {
      // Usamos el MethodChannel nativo o intentamos leer los bytes directamente
      // Nota: File.fromUri a veces falla en Android 11+, por lo que leer bytes es más seguro
      final tempDir = await getTemporaryDirectory();
      final fileId = DateTime.now().millisecondsSinceEpoch;
      final targetFile = File('${tempDir.path}/track_$fileId.mp3');

      // IMPORTANTE: Para leer 'content://' necesitas abrir un Stream de entrada
      // Si tienes problemas para leer bytes directamente, asegúrate de tener
      // permisos de lectura en el Manifest.
      final originalFile = File(uriString);

      // Si el sistema bloquea el acceso directo a bytes aquí,
      // la canción no se podrá copiar sin un plugin de FilePicker o similar.
      final bytes = await originalFile.readAsBytes();
      await targetFile.writeAsBytes(bytes);

      return targetFile.path;
    } catch (e) {
      print("⚠️ No se pudo clonar el archivo (Permiso denegado): $e");
      return null;
    }
  }

  Uint8List? normalizeCover(dynamic rawCover) {
    if (rawCover is Uint8List) return rawCover;
    if (rawCover is List<int>) return Uint8List.fromList(rawCover);
    return null;
  }

  void _startPeriodicCheck() {
    _libraryCheckTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      try {
        final songs = await _audioQuery.querySongs(uriType: UriType.EXTERNAL);
        if (songs.length != _lastKnownCount) {
          print("📂 Cambio detectado en archivos. Recargando...");
          _lastKnownCount = songs.length;
          await refreshLibrary();
        }
      } catch (e) {
        print("⚠️ Error verificando librería periódicamente: $e");
      }
    });
  }

  @override
  void dispose() {
    _libraryCheckTimer?.cancel();
    // Cerrar cajas es opcional, Hive las maneja, pero buena práctica si se destruye el provider permanentemente
    // _libraryBox.close();
    // _playlistsBox.close();
    // _favoritesBox.close();
    // _statsBox.close();
    super.dispose();
  }
}
