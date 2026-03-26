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
//     _initData();
//   }

//   List<MediaItem> _items = [];
//   MediaItem? _current;
//   bool _isPlaying = false;
//   final Map<String, List<MediaItem>> _playlists = {};
//   List<AlbumModel> _albumModels = [];

//   // Getters
//   List<MediaItem> get items => _items;
//   MediaItem? get current => _current;
//   bool get isPlaying => _isPlaying;
//   Map<String, List<MediaItem>> get playlists => _playlists;
//   List<AlbumModel> get albumModels => _albumModels;

//   Stream<Duration> get positionStream =>
//       (handler as AudioServiceHandler).positionStream;
//   Stream<Duration?> get durationStream =>
//       (handler as AudioServiceHandler).durationStream;

//   // --- LÓGICA DE CARGA Y REFRESH (CORREGIDA Y COMPLETA) ---
//   Future<void> loadLibrary() async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getStringList('library_items');

//     if (saved != null) {
//       _items = saved.map((e) => MediaItemJson.fromJson(jsonDecode(e))).toList();

//       // 🕵️ AUTO-DIAGNÓSTICO: Si el primer item no tiene ID, forzamos refresh
//       if (_items.isNotEmpty && _items.first.extras?['dbId'] == null) {
//         debugPrint("⚠️ Datos viejos detectados sin IDs. Refrescando...");
//         await refreshLibrary();
//         return;
//       }
//     } else {
//       await refreshLibrary();
//     }
//     notifyListeners();
//   }

//   Future<void> refreshLibrary() async {
//     try {
//       // 1. Escaneamos todas las canciones de una sola vez (Mucho más rápido)
//       final List<SongModel> fetchedSongs = await _audioQuery.querySongs(
//         sortType: SongSortType.TITLE,
//         orderType: OrderType.ASC_OR_SMALLER,
//         uriType: UriType.EXTERNAL,
//         ignoreCase: true,
//       );

//       // 2. Escaneamos álbumes
//       _albumModels = await _audioQuery.queryAlbums(
//         sortType: AlbumSortType.ALBUM,
//         orderType: OrderType.ASC_OR_SMALLER,
//         uriType: UriType.EXTERNAL,
//       );

//       // 3. Convertimos SongModel a MediaItem guardando el albumId
//       _items = fetchedSongs.map((song) {
//         return MediaItem(
//           id: song.data,
//           title: song.title,
//           artist: song.artist ?? "Artista Desconocido",
//           album: song.album ?? "Álbum Desconocido",
//           duration: Duration(milliseconds: song.duration ?? 0),
//           extras: {
//             'dbId': song.id, // ID real de la canción (int)
//             'albumId': song.albumId, // ID real del álbum (int)
//             'genre': song.genre,
//           },
//         );
//       }).toList();

//       // ¡NO OLVIDES ESTO!
//       await _persistLibrary();
//       notifyListeners();
//     } catch (e) {
//       debugPrint("❌ Error al refrescar librería: $e");
//     }
//   }

//   Future<void> _persistLibrary() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList(
//       'library_items',
//       _items.map((e) => jsonEncode(e.toJson())).toList(),
//     );
//   }

//   // Este método lo mantengo por si abres un archivo suelto desde el explorador
//   Future<MediaItem> _buildMediaItem(String path) async {
//     try {
//       final List<SongModel> songs = await _audioQuery.querySongs(
//         uriType: UriType.EXTERNAL,
//         ignoreCase: true,
//       );

//       final song = songs.firstWhere(
//         (s) => s.data == path,
//         orElse: () => songs.isNotEmpty ? songs.first : null as dynamic,
//       );

//       final metadata = await MetadataRetriever.fromFile(File(path));

//       return MediaItem(
//         id: path,
//         title: metadata.trackName ?? path.split('/').last,
//         artist: metadata.trackArtistNames?.first ?? "Artista Desconocido",
//         album: metadata.albumName ?? "Álbum Desconocido",
//         duration: metadata.trackDuration != null
//             ? Duration(milliseconds: metadata.trackDuration!)
//             : null,
//         extras: {
//           'dbId': song.id,
//           'albumId': song.albumId, // 🔑 También aquí
//           'genre': metadata.genre,
//         },
//       );
//     } catch (e) {
//       return MediaItem(
//         id: path,
//         title: path.split('/').last,
//         extras: {'dbId': 0, 'albumId': 0},
//       );
//     }
//   }
//   // Dentro de tu clase AudioProvider

//   // 1. La variable privada que guarda la canción actual
//   dynamic _currentSong;

//   // 2. El Getter para que la Screen y el PlaylistButton puedan acceder
//   dynamic get currentSong => _currentSong;

//   // 3. El método para cambiar la canción (La lógica Pro)
//   void setCurrentSong(dynamic song) {
//     _currentSong = song;

//     // Notificamos a toda la app que la canción cambió
//     // Esto hará que el PlaylistButton se refresque y marque la nueva canción
//     notifyListeners();

//     // Aquí es donde normalmente cargarías el audio:
//     // _player.setAudioSource(AudioSource.uri(Uri.parse(song.url)));
//   }

//   // 1. Asegúrate de NO tener otra variable llamada 'queue' arriba.
//   // 2. Usa este getter único:
//   List<MediaItem> get currentQueue =>
//       (handler as AudioServiceHandler).queue.value;

//   // 3. Y tu función de reordenar debe usar el handler para que el cambio
//   // se vea reflejado en las notificaciones del celular:
//   void reorderQueue(int oldIndex, int newIndex) {
//     final List<MediaItem> fullQueue = List.from(currentQueue);

//     if (newIndex > oldIndex) newIndex -= 1;

//     final item = fullQueue.removeAt(oldIndex);
//     fullQueue.insert(newIndex, item);

//     // IMPORTANTE: Le avisamos al handler del cambio
//     handler.updateQueue(fullQueue);
//     notifyListeners();
//   }

//   // --- GESTIÓN DE LA COLA EN AUDIO SERVICE ---

//   void removeFromQueue(int index) {
//     // 1. Obtenemos la lista actual desde el handler de forma segura
//     final List<MediaItem> currentList = List.from(
//       (handler as AudioServiceHandler).queue.value,
//     );

//     // 2. Escudo de seguridad: verificar que el índice existe
//     if (index >= 0 && index < currentList.length) {
//       // 3. Si la canción que vamos a quitar es la que está sonando,
//       // podrías decidir si saltar a la siguiente o simplemente quitarla.
//       // Por ahora, simplemente la removemos de la lista:
//       currentList.removeAt(index);

//       // 4. ACTUALIZACIÓN CRÍTICA: Enviamos la nueva lista al handler
//       // Esto actualiza el sistema de Android/iOS y la notificación
//       (handler as AudioServiceHandler).updateQueue(currentList);

//       // 5. Notificamos a los widgets (como tu PlaylistButton)
//       notifyListeners();

//       debugPrint("PZ Player -> Canción eliminada del índice: $index");
//     }
//   }

//   // Dentro de tu clase AudioProvider
//   // void setBandGain(int bandIndex, double gain) {
//   //   // Aquí es donde el plugin hace la magia
//   //   // Ejemplo: _equalizer.setBandGain(bandIndex, gain);
//   //   notifyListeners(); // Opcional, si quieres que la UI reaccione
//   // }

//   // --- SECCIÓN DEL ECUALIZADOR DENTRO DEL PROVIDER ---

//   bool _isEqualizerEnabled = true;

//   // 1. IMPORTANTE: Esta lista SIEMPRE debe tener valores entre 0.0 y 1.0
//   List<double> _currentEGBands = [0.5, 0.5, 0.5, 0.5, 0.5];

//   bool get isEqualizerEnabled => _isEqualizerEnabled;
//   List<double> get currentEGBands => _currentEGBands;

//   // Método para el switch de encendido/apagado

//   // 2. MÉTODO CORREGIDO: setBandGain
//   // 1. DECLARACIÓN (Asegúrate de tener el import de just_audio)
//   final _equalizer = AndroidEqualizer();

//   // ... (tus variables _isEqualizerEnabled y _currentEGBands)

//   // 1. EL MÉTODO PÚBLICO (Lo llama el Slider)
//   void setBandGain(int bandIndex, double sliderValue) {
//     // Tu escudo de seguridad
//     double safeValue = sliderValue.clamp(0.0, 1.0);
//     _currentEGBands[bandIndex] = safeValue;

//     if (_isEqualizerEnabled) {
//       // LLAMAMOS a la función de hardware (Esto quita la línea naranja)
//       _applyEffect(bandIndex, safeValue);
//     }
//   }

//   void toggleEqualizer(bool value) {
//     _isEqualizerEnabled = value;
//     // Aquí va la conexión a tu motor (ej: _equalizer.setEnabled(value))
//     notifyListeners();
//   }

//   void _applyEffect(int index, double value) {
//     // 0.0 -> -2000 mB (Bajo)
//     // 0.5 -> 0 mB (Plano/Normal)
//     // 1.0 -> +2000 mB (Alto)
//     double milliBelios = (value * 3000.0) - 1500.0;

//     try {
//       _equalizer.parameters.then((params) {
//         if (index < params.bands.length) {
//           // Aplicamos la ganancia real
//           params.bands[index].setGain(milliBelios);
//         }
//       });

//       debugPrint("PZ Player -> Banda $index a ${milliBelios.toInt()} mB");
//     } catch (e) {
//       debugPrint("Error en hardware: $e");
//     }
//   }

//   // 3. EL MÉTODO PARA PRESETS (Para que Rock/Pop también impriman)
//   void setFullPreset(List<double> newBands) {
//     _currentEGBands = List.from(newBands);

//     if (_isEqualizerEnabled) {
//       for (int i = 0; i < _currentEGBands.length; i++) {
//         // Reutilizamos la lógica
//         _applyEffect(i, _currentEGBands[i]);
//       }
//     }
//     notifyListeners();
//   }

//   // --- REPRODUCCIÓN ---
//   Future<void> _initData() async {
//     await loadLibrary(); // Primero tu música
//     await _loadPlaylists(); // Luego tus playlists
//     debugPrint("PZ Player -> Sistema de persistencia listo.");
//   }

//   Future<void> play(MediaItem item) async => await playItems([item]);

//   Future<void> playItems(List<MediaItem> items, {int startIndex = 0}) async {
//     if (items.isEmpty) return;
//     final h = handler as AudioServiceHandler;
//     final sources = items
//         .map((item) => AudioSource.file(item.id, tag: item))
//         .toList();

//     try {
//       h.updateQueue(items);
//       await h.player.setAudioSource(
//         ConcatenatingAudioSource(children: sources),
//         initialIndex: startIndex,
//       );
//       await h.player.play();
//     } catch (e) {
//       debugPrint("Error en playItems: $e");
//     }
//   }

//   Future<void> playFromFile(String path) async {
//     final h = handler as AudioServiceHandler;
//     try {
//       final item = _items.firstWhere(
//         (e) => e.id == path,
//         orElse: () => MediaItem(id: path, title: path.split('/').last),
//       );
//       await h.player.setAudioSource(AudioSource.file(path, tag: item));
//       h.playMediaItem(item);
//       await h.player.play();
//     } catch (e) {
//       debugPrint("Error en playFromFile: $e");
//     }
//   }

//   // --- AGRUPAMIENTOS ---

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

//   // --- CONTROLES Y OTROS ---

//   void pause() => handler.pause();
//   void resume() => handler.play();
//   void skipNext() => handler.skipToNext();
//   void skipPrevious() => handler.skipToPrevious();
//   void seek(Duration pos) => handler.seek(pos);

//   Future<void> toggleShuffle() async {
//     final player = (handler as AudioServiceHandler).player;
//     await player.setShuffleModeEnabled(!player.shuffleModeEnabled);
//     notifyListeners();
//   }

//   Future<void> toggleLoopMode() async {
//     final player = (handler as AudioServiceHandler).player;
//     if (player.loopMode == LoopMode.off)
//       await player.setLoopMode(LoopMode.all);
//     else if (player.loopMode == LoopMode.all)
//       await player.setLoopMode(LoopMode.one);
//     else
//       await player.setLoopMode(LoopMode.off);
//     notifyListeners();
//   }

//   // void createPlaylist(String name) {
//   //   if (name.isNotEmpty && !_playlists.containsKey(name)) {
//   //     _playlists[name] = [];
//   //     notifyListeners();
//   //   }
//   // }

//   // void addToPlaylist(String name, MediaItem song) {
//   //   if (_playlists.containsKey(name) && !_playlists[name]!.contains(song)) {
//   //     _playlists[name]!.add(song);
//   //     notifyListeners();
//   //   }
//   // }

//   //playlist
//   void createPlaylist(String name) {
//     if (name.isNotEmpty && !_playlists.containsKey(name)) {
//       _playlists[name] = [];
//       notifyListeners();
//       _savePlaylists(); // 👈 Guardar cambio
//     }
//   }

//   void addToPlaylist(String name, MediaItem song) {
//     if (_playlists.containsKey(name)) {
//       if (!_playlists[name]!.any((s) => s.id == song.id)) {
//         _playlists[name]!.add(song);
//         notifyListeners();
//         _savePlaylists(); // 👈 Guardar cambio
//       }
//     }
//   }

//   // void removeFromPlaylist(String playlistName, MediaItem song) {
//   //   if (_playlists.containsKey(playlistName)) {
//   //     _playlists[playlistName]!.removeWhere((item) => item.id == song.id);
//   //     notifyListeners();
//   //     _savePlaylistsToDisk(); // 💾 Guardar
//   //   }
//   // }

//   void deletePlaylist(String name) {
//     _playlists.remove(name);
//     notifyListeners();
//     _savePlaylists(); // 👈 Guardar cambio
//   }

//   // 💾 Función para guardar en disco
//   // 💾 Guardar en "archivo" virtual (SharedPreferences)
//   Future<void> _savePlaylists() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final Map<String, dynamic> data = {};

//       _playlists.forEach((name, songs) {
//         // Usamos tu extensión .toJson() que ya definiste arriba
//         data[name] = songs.map((s) => s.toJson()).toList();
//       });

//       await prefs.setString('saved_playlists_pz', jsonEncode(data));
//       debugPrint("✅ Playlists sincronizadas");
//     } catch (e) {
//       debugPrint("❌ Error guardando playlists: $e");
//     }
//   }

//   // 📂 Cargar al iniciar
//   // Future<void> _loadPlaylists() async {
//   //   try {
//   //     final prefs = await SharedPreferences.getInstance();
//   //     final String? jsonStr = prefs.getString('saved_playlists_pz');

//   //     if (jsonStr != null) {
//   //       final Map<String, dynamic> decoded = jsonDecode(jsonStr);
//   //       _playlists.clear();

//   //       decoded.forEach((name, list) {
//   //         final List<MediaItem> songs = (list as List).map((item) {
//   //           return MediaItemJson.fromJson(item as Map<String, dynamic>);
//   //         }).toList();
//   //         _playlists[name] = songs;
//   //       });

//   //       notifyListeners(); // 📢 Avisa a PlaylistScreen que ya hay datos
//   //     }
//   //   } catch (e) {
//   //     debugPrint("❌ Error cargando playlists: $e");
//   //   }
//   // }

//   Future<void> _loadPlaylists() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final String? jsonStr = prefs.getString('saved_playlists_pz');

//       if (jsonStr != null) {
//         final Map<String, dynamic> decoded = jsonDecode(jsonStr);
//         _playlists.clear();

//         decoded.forEach((name, list) {
//           final List<MediaItem> songs = (list as List).map((item) {
//             return MediaItemJson.fromJson(item as Map<String, dynamic>);
//           }).toList();
//           _playlists[name] = songs;
//         });

//         notifyListeners();
//         debugPrint("📂 Playlists cargadas con éxito: ${_playlists.length}");
//       }
//     } catch (e) {
//       debugPrint("❌ Error crítico cargando playlists: $e");
//     }
//   }

//   // 💾 Función para guardar en disco
//   // Future<void> _savePlaylistsToDisk() async {
//   //   try {
//   //     final prefs = await SharedPreferences.getInstance();
//   //     final Map<String, dynamic> exportable = {};

//   //     _playlists.forEach((name, songs) {
//   //       // Usamos tu extensión MediaItemJson para convertir a Map
//   //       exportable[name] = songs.map((s) => s.toJson()).toList();
//   //     });

//   //     await prefs.setString('saved_playlists_data', jsonEncode(exportable));
//   //     debugPrint("✅ Playlists de PZ Player guardadas.");
//   //   } catch (e) {
//   //     debugPrint("❌ Error al guardar playlists: $e");
//   //   }
//   // }

//   // 📂 Función para cargar desde disco
//   Future<void> loadPlaylistsFromDisk() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final String? rawData = prefs.getString('saved_playlists_data');

//       if (rawData != null) {
//         final Map<String, dynamic> decoded = jsonDecode(rawData);
//         _playlists.clear();

//         decoded.forEach((name, list) {
//           final List<MediaItem> songs = (list as List).map((item) {
//             return MediaItemJson.fromJson(item as Map<String, dynamic>);
//           }).toList();
//           _playlists[name] = songs;
//         });

//         notifyListeners();
//         debugPrint("📂 Se cargaron ${_playlists.length} playlists.");
//       }
//     } catch (e) {
//       debugPrint('❌ Error al cargar playlists: $e');
//     }
//   }
//   // 📂 Función para cargar desde disco
//   // Future<void> loadPlaylistsFromDisk() async {
//   //   try {
//   //     final prefs = await SharedPreferences.getInstance();
//   //     final String? rawData = prefs.getString('saved_playlists_data');

//   //     if (rawData != null) {
//   //       final Map<String, dynamic> decoded = jsonDecode(rawData);
//   //       _playlists.clear();

//   //       decoded.forEach((name, list) {
//   //         final List<MediaItem> songs = (list as List).map((item) {
//   //           return MediaItemJson.fromJson(item as Map<String, dynamic>);
//   //         }).toList();
//   //         _playlists[name] = songs;
//   //       });

//   //       notifyListeners();
//   //       debugPrint("📂 Se cargaron ${_playlists.length} playlists.");
//   //     }
//   //   } catch (e) {
//   //     debugPrint('❌ Error al cargar playlists: $e');
//   //   }
//   // }
//   //  GESTIÓN DE LA COLA (QUEUE) ---

//   /// Getter para obtener la cola actual desde el handler
//   List<MediaItem> get queue => (handler as AudioServiceHandler).queue.value;

//   /// Inserta una canción para que suene justo después de la actual
//   void playNext(MediaItem song) {
//     final currentQueue = List<MediaItem>.from(queue);
//     final currentIndex = currentQueue.indexOf(_current ?? song);

//     // Insertamos en la posición siguiente a la actual
//     if (currentIndex != -1 && currentIndex + 1 < currentQueue.length) {
//       currentQueue.insert(currentIndex + 1, song);
//     } else {
//       currentQueue.add(song);
//     }

//     // Actualizamos el handler
//     (handler as AudioServiceHandler).updateQueue(currentQueue);
//     notifyListeners();
//   }

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
//   // void removeFromPlaylist(String playlistName, MediaItem song) {
//   //   if (_playlists.containsKey(playlistName)) {
//   //     _playlists[playlistName]!.removeWhere((item) => item.id == song.id);
//   //     notifyListeners();
//   //   }
//   // }

//   /// Limpia toda la cola actual
//   void clearQueue() {
//     (handler as AudioServiceHandler).updateQueue([]);
//     notifyListeners();
//   }

//   //   // --- GESTIÓN DE PLAYLISTS ---

//   // void deletePlaylist(String name) {
//   //   _playlists.remove(name);
//   //   notifyListeners();
//   // }

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

//   void addToQueue(MediaItem song) {
//     (handler as AudioServiceHandler).addQueueItem(song);
//     notifyListeners();
//   }

//   // --- MODOS DE REPRODUCCIÓN ---

//   bool get shuffleEnabled =>
//       (handler as AudioServiceHandler).player.shuffleModeEnabled;
//   LoopMode get loopMode => (handler as AudioServiceHandler).player.loopMode;

//   // --- UTILIDADES ---

//   Uint8List? normalizeCover(dynamic rawCover) {
//     if (rawCover is Uint8List) return rawCover;
//     if (rawCover is List<int>) return Uint8List.fromList(rawCover);
//     return null;
//   }

//   Future<void> loadAndPlayUri(String path) async => await playFromFile(path);
// }

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

import 'dart:convert';
// import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
// import 'package:flutter_media_metadata/flutter_media_metadata.dart';
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

  AudioProvider(this.handler) {
    final player = (handler as AudioServiceHandler).player;

    // Listeners de Streams
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

    // Inicialización de datos persistentes
    _initData();
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

  // --- LIBRERÍA Y PERSISTENCIA ---
  Future<void> loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('library_items');

    if (saved != null) {
      _items = saved.map((e) => MediaItemJson.fromJson(jsonDecode(e))).toList();
      if (_items.isNotEmpty && _items.first.extras?['dbId'] == null) {
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

  // --- GESTIÓN DE PLAYLISTS (OPTIMIZADA) ---
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
      debugPrint("✅ Playlists sincronizadas en disco");
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
        if (index < params.bands.length)
          params.bands[index].setGain(milliBelios);
      });
    } catch (e) {
      debugPrint("Error en hardware EQ: $e");
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

  Future<void> loadAndPlayUri(String path) async => await playFromFile(path);

  Future<void> playFromFile(String path) async {
    final h = handler as AudioServiceHandler;
    try {
      final item = _items.firstWhere(
        (e) => e.id == path,
        orElse: () => MediaItem(id: path, title: path.split('/').last),
      );

      await h.player.setAudioSource(AudioSource.file(path, tag: item));
      h.playMediaItem(item); // Método necesario en tu handler
      await h.player.play();
    } catch (e) {
      debugPrint("Error en playFromFile: $e");
    }
  }
}
