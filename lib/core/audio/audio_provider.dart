import 'dart:async';
import 'dart:convert'; // Necesario para base64Encode
import 'dart:io';
import 'dart:typed_data'; // Necesario para Uint8List
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:home_widget/home_widget.dart';
import 'audio_service_handler.dart';

// --- Extensión para serializar MediaItem ---
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

  final _equalizer = AndroidEqualizer();

  // Variables de estado
  List<MediaItem> _items = [];
  MediaItem? _current;
  bool _isPlaying = false;
  final Map<String, List<MediaItem>> _playlists = {};
  List<AlbumModel> _albumModels = [];
  bool _isEqualizerEnabled = true;
  List<double> _currentEGBands = [0.5, 0.5, 0.5, 0.5, 0.5];
  dynamic _currentSong;

  Timer? _libraryCheckTimer;
  int _lastKnownCount = 0;

  AudioProvider(this.handler) {
    final player = (handler as AudioServiceHandler).player;

    // 1. Escuchar cambios de reproducción (Play/Pause) para actualizar el icono del widget
    player.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;

      // Si el estado cambió, sincronizamos el widget
      if (wasPlaying != _isPlaying) {
        _syncWidget();
      }
      notifyListeners();
    });

    // 2. Escuchar cambios de canción (MediaItem) para actualizar texto e imagen
    handler.mediaItem.listen((item) {
      _current = item;
      if (item != null) {
        _syncWidget();
      }
      notifyListeners();
    });

    player.loopModeStream.listen((_) => notifyListeners());
    player.shuffleModeEnabledStream.listen((_) => notifyListeners());

    _initData();
    _startPeriodicCheck();
    _initWidgetDefaults(); // Inicializar widget con valores por defecto
  }

  // --- GETTERS ---
  List<MediaItem> get items => _items;
  MediaItem? get current => _current;
  bool get isPlaying => _isPlaying;
  Map<String, List<MediaItem>> get playlists => _playlists;
  List<AlbumModel> get albumModels => _albumModels;
  dynamic get currentSong => _currentSong;
  bool get isEqualizerEnabled => _isEqualizerEnabled;
  List<double> get currentEGBands => _currentEGBands;
  List<MediaItem> get currentQueue =>
      (handler as AudioServiceHandler).queue.value;
  List<MediaItem> get queue => currentQueue;

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

  // --- INICIALIZACIÓN ---
  Future<void> _initData() async {
    await loadLibrary();
    await _loadPlaylists();
    debugPrint("🚀 PZ Player: Datos cargados correctamente");
  }

  Future<void> _initWidgetDefaults() async {
    try {
      // Valores iniciales para que el widget no esté vacío
      await HomeWidget.saveWidgetData<String>('title', 'PZ Player');
      await HomeWidget.saveWidgetData<String>('artist', 'PzStudio');
      await HomeWidget.saveWidgetData<bool>('isPlaying', false);

      await HomeWidget.updateWidget(
        name: 'widget.PlayerWidget',
        androidName: 'widget.PlayerWidget',
      );
    } catch (e) {
      debugPrint("Error inicializando widget: $e");
    }
  }

  // --- FUNCIÓN UNIFICADA DE SINCRONIZACIÓN ---
  // Esta maneja: Texto, Artista, Imagen (Base64) y Estado Play/Pause
  Future<void> _syncWidget() async {
    if (_current == null) return;

    try {
      // 1. Guardar Textos
      await HomeWidget.saveWidgetData<String>('title', _current!.title);
      await HomeWidget.saveWidgetData<String>(
        'artist',
        _current!.artist ?? 'PzStudio',
      );

      // 2. Guardar Estado (Play/Pause) para el icono
      await HomeWidget.saveWidgetData<bool>('isPlaying', _isPlaying);

      // 3. Procesar y Guardar Imagen (Base64)
      await _saveCoverArtToWidget(_current!);

      // 4. Forzar actualización visual en Android
      await HomeWidget.updateWidget(
        name: 'widget.PlayerWidget',
        androidName: 'widget.PlayerWidget',
      );

      debugPrint(
        "✅ Widget Sincronizado: ${_current!.title} | Playing: $_isPlaying",
      );
    } catch (e) {
      debugPrint("❌ Error actualizando widget: $e");
    }
  }

  // // --- LÓGICA DE IMAGEN ---
  // Future<void> _saveCoverArtToWidget(MediaItem mediaItem) async {
  //   try {
  //     if (mediaItem.artUri != null) {
  //       final uri = mediaItem.artUri!;

  //       if (uri.scheme == 'data') {
  //         // Si ya es base64, guardarlo directo
  //         await HomeWidget.saveWidgetData<String>('imagePath', uri.toString());
  //       } else {
  //         // Si es ruta de archivo, extraer bytes y convertir a Base64 pequeño
  //         final Uint8List? bytes = await _audioQuery.queryArtwork(
  //           int.tryParse(mediaItem.id) ?? 0,
  //           ArtworkType.AUDIO,
  //           size: 100, // Tamaño pequeño para no saturar
  //           format: ArtworkFormat.JPEG,
  //         );

  //         if (bytes != null && bytes.isNotEmpty) {
  //           final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
  //           await HomeWidget.saveWidgetData<String>('imagePath', base64Image);
  //         } else {
  //           await HomeWidget.saveWidgetData<String>('imagePath', '');
  //         }
  //       }
  //     } else {
  //       await HomeWidget.saveWidgetData<String>('imagePath', '');
  //     }
  //   } catch (e) {
  //     debugPrint("Error procesando carátula: $e");
  //   }
  // }
  Future<void> guardarDatosWidget(MediaItem song, bool isPlaying) async {
    await HomeWidget.saveWidgetData<String>('title', song.title);
    await HomeWidget.saveWidgetData<String>('artist', song.artist ?? '');
    await HomeWidget.saveWidgetData<bool>('isPlaying', isPlaying);

    // ✅ OBLIGATORIO: Guardar la ID para que el widget sepa qué cancion es
    // Asegúrate que 'song.id' no sea nulo. Si no tienes ID, usa el título o una URL única.
    await HomeWidget.saveWidgetData<String>('id', song.id ?? song.title);

    // ... guardar imagen base64 ...

    await HomeWidget.updateWidget(
      name: 'PlayerWidget',
      androidName: 'com.pzplayer.co.pzplayer.widget.PlayerWidget',
    );
  }
  // --- LÓGICA DE IMAGEN (DEBUG TOTAL) ---
  // <--- ASEGÚRATE DE AGREGAR ESTE IMPORT ARRIBA DEL ARCHIVO

  // --- LÓGICA DE IMAGEN (SOLUCIÓN FINAL) ---
  Future<void> _saveCoverArtToWidget(MediaItem mediaItem) async {
    try {
      if (mediaItem.artUri != null) {
        final uri = mediaItem.artUri!;

        // CASO 1: Si ya viene en Base64 (poco común, pero posible)
        if (uri.scheme == 'data') {
          await HomeWidget.saveWidgetData<String>('imagePath', uri.toString());
          print("✅ [Widget] Guardado (Base64 directo)");
          return;
        }

        // CASO 2: Si es 'content://' o 'file://' (LO NORMAL)
        // En lugar de buscar con ID (que falla), leemos el archivo que Android ya nos dio
        print("🔍 [Widget] Leyendo imagen desde: $uri");

        try {
          // Usamos 'File' de dart:io para leer la ruta
          final file = File.fromUri(uri);
          final bytes = await file.readAsBytes();

          if (bytes.isNotEmpty) {
            final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
            await HomeWidget.saveWidgetData<String>('imagePath', base64Image);
            print(
              "✅ [Widget] Imagen leída y convertida a Base64. Tamaño: ${bytes.length}",
            );
          } else {
            print("⚠️ [Widget] El archivo de imagen está vacío.");
            await HomeWidget.saveWidgetData<String>('imagePath', '');
          }
        } catch (e) {
          // A veces falla si es una ruta 'content://' restringida, intentamos plan B
          print(
            "⚠️ [Widget] Error leyendo archivo directo ($e). Intentando plan B...",
          );

          // PLAN B: Intentar buscar por ID numérico usando 'dbId' si existe en los extras
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
              print("✅ [Widget] Imagen recuperada por ID (Plan B)");
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
      debugPrint("❌ [Widget] Error general: $e");
      await HomeWidget.saveWidgetData<String>('imagePath', '');
    }
  }

  void _startPeriodicCheck() {
    _libraryCheckTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      try {
        final songs = await _audioQuery.querySongs(uriType: UriType.EXTERNAL);
        if (songs.length != _lastKnownCount) {
          debugPrint("📂 Cambio detectado en archivos. Recargando...");
          _lastKnownCount = songs.length;
          await refreshLibrary();
        }
      } catch (e) {
        debugPrint("Error verificando librería: $e");
      }
    });
  }

  // --- LIBRERÍA Y PERSISTENCIA ---
  // Future<void> loadLibrary() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final saved = prefs.getStringList('library_items');

  //   if (saved != null) {
  //     _items = saved.map((e) => MediaItemJson.fromJson(jsonDecode(e))).toList();
  //     _lastKnownCount = _items.length;
  //     if (_items.isNotEmpty && _items.first.extras?['dbId'] == null) {
  //       await refreshLibrary();
  //       return;
  //     }
  //   } else {
  //     await refreshLibrary();
  //   }
  //   notifyListeners();
  // }
  Future<void> loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('library_items');

    if (saved != null) {
      _items = saved.map((e) => MediaItemJson.fromJson(jsonDecode(e))).toList();
      _lastKnownCount = _items.length;
      if (_items.isNotEmpty && _items.first.extras?['dbId'] == null) {
        await refreshLibrary();
        return;
      }
    } else {
      await refreshLibrary();
    }

    // --- ✅ PRECARGAR LA PRIMERA CANCIÓN DE LA BIBLIOTECA ---
    if (_items.isNotEmpty) {
      // Tomamos la primera canción de la lista cargada
      final firstSong = _items.first;

      try {
        final h = handler as AudioServiceHandler;

        // 1. Creamos el source con la ruta del archivo y le adjuntamos la canción completa como 'tag'
        // Uri.file es mejor que Uri.parse para rutas locales de Android
        final source = AudioSource.uri(
          Uri.file(firstSong.id),
          tag: firstSong, // Esto pasa el título, artista, etc., al servicio
        );

        // 2. Cargamos en el reproductor
        await h.player.setAudioSource(source);

        // 3. Detener inmediatamente (Queda en Pause, lista para reproducir)
        await h.player.stop();

        print(
          "✅ Primera canción de la biblioteca precargada: ${firstSong.title}",
        );
      } catch (e) {
        print("⚠️ Error precargando biblioteca: $e");
      }
    }
    // ---------------------------------------------------------

    notifyListeners();
  }

  Future<void> refreshLibrary() async {
    try {
      final List<SongModel> fetchedSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      _albumModels = await _audioQuery.queryAlbums(
        sortType: AlbumSortType.ALBUM,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );

      _items = fetchedSongs.map((song) {
        return MediaItem(
          id: song.data,
          title: song.title,
          artist: song.artist ?? "Artista Desconocido",
          album: song.album ?? "Álbum Desconocido",
          duration: Duration(milliseconds: song.duration ?? 0),
          extras: {
            'dbId': song.id,
            'albumId': song.albumId,
            'genre': song.genre,
          },
        );
      }).toList();

      _lastKnownCount = _items.length;
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

  // --- GESTIÓN DE PLAYLISTS ---
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

  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {};
      _playlists.forEach((name, songs) {
        data[name] = songs.map((s) => s.toJson()).toList();
      });
      await prefs.setString('saved_playlists_pz', jsonEncode(data));
    } catch (e) {
      debugPrint("❌ Error guardando playlists: $e");
    }
  }

  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('saved_playlists_pz');
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
      }
    } catch (e) {
      debugPrint("❌ Error cargando playlists: $e");
    }
  }

  // --- REPRODUCCIÓN Y COLA ---
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
      // La actualización del widget es automática via listener (mediaItem)
    } catch (e) {
      debugPrint("Error en playItems: $e");
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

  // --- CONTROLES ---
  void pause() {
    handler.pause();
    // La actualización del widget es automática vía listener de estado (playerStateStream)
  }

  void resume() {
    handler.play();
  }

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

  // --- ECUALIZADOR ---
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
      debugPrint("Error aplicando efecto: $e");
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

  // --- AGRUPAMIENTOS ---
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
        // Obtenemos toda la ruta de la carpeta (ej: /Music/Rock)
        String fullPath = path.substring(0, lastSlash);

        // ✅ CAMBIO CLAVE: Obtenemos SOLO el nombre de la última carpeta (ej: Rock)
        String folderName = fullPath.substring(fullPath.lastIndexOf('/') + 1);

        // Usamos el nombre simple como clave
        grouped.putIfAbsent(folderName, () => []).add(item);
      } else {
        // Caso raro: archivo en la raíz
        grouped.putIfAbsent("Raíz", () => []).add(item);
      }
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

  // --- UTILIDADES ---
  Uint8List? normalizeCover(dynamic rawCover) {
    if (rawCover is Uint8List) return rawCover;
    if (rawCover is List<int>) return Uint8List.fromList(rawCover);
    return null;
  }

  // --- CARGA DE ARCHIVOS EXTERNOS (OPTIMIZADA) ---
  Future<void> loadAndPlayUri(String path) async => await playFromFile(path);
  Future<void> playFromFile(String path) async {
    final h = handler as AudioServiceHandler;

    try {
      // 1. LIMPIEZA DEL TÍTULO (Mantenemos tu lógica, es buena)
      String cleanTitle = "Archivo Local";

      if (!path.startsWith('msf:') && !path.startsWith('content:')) {
        String fileName = path.split('/').last;
        cleanTitle = fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;
        cleanTitle = cleanTitle.replaceFirst(RegExp(r'^\d+\s*[-\.]?\s*'), '');
        cleanTitle = cleanTitle.replaceAll('_', ' ');
        cleanTitle = cleanTitle.replaceAll(RegExp(r'\s+'), ' ').trim();
      }

      final item = MediaItem(
        id: path,
        title: cleanTitle,
        artist: "PZ Player",
        artUri: null, // Evita null errors
      );

      // 2. CONSTRUCCIÓN CORRECTA DE LA FUENTE (Aquí estaba el crash)
      Uri audioUri;

      if (path.startsWith('content://')) {
        // Ya es un content URI, úsalo directo
        audioUri = Uri.parse(path);
      } else if (path.startsWith('msf:')) {
        // CORRECCIÓN CRÍTICA PARA MSF:
        // El ID viene codificado (ej: msf%3A35). Debemos decodificarlo.
        // Y la URI correcta para descargas es estricta.
        String decodedId = Uri.decodeComponent(path); // Convierte %3A a :

        // Construimos la URI exacta que pide el proveedor de descargas
        audioUri = Uri.parse(
          "content://com.android.providers.downloads.documents/document/$decodedId",
        );
      } else {
        // Archivo local normal
        audioUri = Uri.file(path);
      }

      // 3. REPRODUCCIÓN SEGURA (Usando ConcatenatingAudioSource si es posible, o set individual)
      // Nota: setAudioSource BORRA la cola actual. Si quieres mantener la cola,
      // deberías usar h.addQueueItem.
      // Asumiremos que quieres reproducir este archivo YA MISMO.

      // Creamos la fuente
      final source = AudioSource.uri(audioUri, tag: item);

      // OPCIÓN A: Reproducir inmediatamente (borra lo anterior)
      // await h.player.setAudioSource(source);
      // await h.player.play();

      // OPCIÓN B: Agregar a la cola y reproducir (Más seguro para no romper el estado del handler)
      // Esto es lo que AudioService prefiere
      if (h.playbackState.value.playing) {
        await h.player.stop(); // Paramos lo actual suavemente
      }

      await h.player.setAudioSource(
        source,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      await h.player.play();

      // Actualizamos el mediaItem del handler manualmente para que la UI y Notificación sepan qué es
      // (setAudioSource con 'tag' debería hacerlo, pero por seguridad forzamos la actualización del item si el handler lo soporta)
      // No uses h.mediaItem.add(item) si ya lo pasaste en el 'tag', puede causar duplicados visuales.
    } catch (e) {
      debugPrint("🔴 ERROR CRÍTICO en playFromFile: $e");
      // Si falla, intentamos al menos no crashear la app
    }
  }

  @override
  void dispose() {
    _libraryCheckTimer?.cancel();
    super.dispose();
  }
}
