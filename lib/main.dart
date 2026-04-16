// // import 'dart:async';
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/scheduler.dart';
// // import 'package:provider/provider.dart';
// // import 'package:home_widget/home_widget.dart';
// // import 'package:receive_sharing_intent/receive_sharing_intent.dart';

// // import 'package:pzplayer/core/audio/manager.dart';
// // import 'core/theme/theme_provider.dart';
// // import 'core/audio/audio_provider.dart';
// // import 'ui/screens/intro_screen.dart';
// // import 'core/theme/app_theme.dart';

// // // --- PASO 1: HANDLER DE FONDO ---
// // @pragma('vm:entry-point')
// // Future<void> backgroundCallback(Uri? uri) async {
// //   if (uri?.scheme == 'pzplayer') {
// //     final String comando = uri!.host;
// //     final handler = await AudioServiceManager.createHandler();

// //     // Variable para saber el nuevo estado
// //     bool nuevoEstadoReproduccion = false;

// //     // 1. Ejecutar la acción correspondiente
// //     if (comando == "next") {
// //       await handler.skipToNext();
// //       nuevoEstadoReproduccion = true;

// //       // ✅ IMPORTANTE: Cuando saltas de canción, debes actualizar los datos del widget
// //       // Supongamos que tienes una forma de obtener la mediaItem actual del handler:
// //       final currentItem = handler.mediaItem.value;
// //       if (currentItem != null) {
// //         await WidgetSongInfo.saveCurrentSong(
// //           WidgetSongInfo(
// //             title: currentItem.title,
// //             artist: currentItem.artist ?? 'Desconocido',
// //             coverUrl: currentItem.artUri?.toString() ?? '',
// //           ),
// //         );
// //       }
// //     } else if (comando == "prev") {
// //       await handler.skipToPrevious();
// //       nuevoEstadoReproduccion = true;

// //       // ✅ Lo mismo para anterior
// //       final currentItem = handler.mediaItem.value;
// //       if (currentItem != null) {
// //         await WidgetSongInfo.saveCurrentSong(
// //           WidgetSongInfo(
// //             title: currentItem.title,
// //             artist: currentItem.artist ?? 'Desconocido',
// //             coverUrl: currentItem.artUri?.toString() ?? '',
// //           ),
// //         );
// //       }
// //     } else if (comando == "playpause") {
// //       if (handler.playbackState.value.playing) {
// //         await handler.pause();
// //         nuevoEstadoReproduccion = false;
// //       } else {
// //         await handler.play();
// //         nuevoEstadoReproduccion = true;
// //       }
// //     }

// //     // 2. Guardar el estado de reproducción
// //     await HomeWidget.saveWidgetData<bool>('isPlaying', nuevoEstadoReproduccion);

// //     // 3. Forzar la actualización visual del Widget
// //     await HomeWidget.updateWidget(
// //       name: 'PlayerWidget',
// //       androidName: 'widget.PlayerWidget',
// //     );
// //   }
// // }

// // void main() async {
// //   WidgetsFlutterBinding.ensureInitialized();

// //   // Registrar el callback para que el widget funcione en segundo plano
// //   HomeWidget.registerBackgroundCallback(backgroundCallback);

// //   final handler = await AudioServiceManager.createHandler();

// //   runApp(
// //     MultiProvider(
// //       providers: [
// //         ChangeNotifierProvider(create: (_) => ThemeProvider()),
// //         ChangeNotifierProvider(create: (_) => AudioProvider(handler)),
// //       ],
// //       child: const MyApp(),
// //     ),
// //   );
// // }

// // class MyApp extends StatefulWidget {
// //   const MyApp({super.key});

// //   @override
// //   State<MyApp> createState() => _MyAppState();
// // }

// // class _MyAppState extends State<MyApp> {
// //   late StreamSubscription _intentDataStreamSubscription;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _initSharingListener();
// //     // HomeWidget.registerBackgroundCallback(backgroundCallback);
// //   }

// //   void _initSharingListener() async {
// //     // Escuchar archivos mientras la app está en memoria
// //     _intentDataStreamSubscription = ReceiveSharingIntent.instance
// //         .getMediaStream()
// //         .listen((List<SharedMediaFile> files) {
// //           if (files.isNotEmpty && mounted) {
// //             _procesarAudioCompartido(files.first.path);
// //           }
// //         }, onError: (err) => print("🔴 Error Stream: $err"));

// //     // Escuchar comando inicial al abrir la app
// //     SchedulerBinding.instance.addPostFrameCallback((_) async {
// //       final initialMedia = await ReceiveSharingIntent.instance
// //           .getInitialMedia();

// //       if (initialMedia.isNotEmpty && mounted) {
// //         final String data = initialMedia.first.path;
// //         if (data.contains("pzplayer://")) {
// //           _procesarComandoWidget(data);
// //         } else {
// //           _procesarAudioCompartido(data);
// //         }
// //       }
// //       await ReceiveSharingIntent.instance.reset();
// //     });
// //   }

// //   void _procesarComandoWidget(String uri) {
// //     final audioProvider = Provider.of<AudioProvider>(context, listen: false);

// //     if (uri.contains("playpause")) {
// //       audioProvider.isPlaying ? audioProvider.pause() : audioProvider.resume();
// //     } else if (uri.contains("next")) {
// //       audioProvider.skipNext();
// //     } else if (uri.contains("prev")) {
// //       audioProvider.skipPrevious();
// //     }
// //   }

// //   void _procesarAudioCompartido(String filePath) {
// //     if (!mounted) return;
// //     final audioProvider = Provider.of<AudioProvider>(context, listen: false);
// //     if (audioProvider.current?.id == filePath) return;
// //     audioProvider.playFromFile(filePath);
// //   }

// //   @override
// //   void dispose() {
// //     _intentDataStreamSubscription.cancel();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final themeProvider = Provider.of<ThemeProvider>(context);
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       title: 'PZ Player',
// //       theme: AppTheme.lightTheme,
// //       darkTheme: AppTheme.darkTheme,
// //       themeMode: themeProvider.themeMode,
// //       home: const IntroScreen(),
// //     );
// //   }
// // }

// // class WidgetSongInfo {
// //   final String title;
// //   final String artist;
// //   final String
// //   coverUrl; // Asegúrate de que sea una URL válida o una ruta local accesible

// //   WidgetSongInfo({
// //     required this.title,
// //     required this.artist,
// //     required this.coverUrl,
// //   });

// //   // Método para guardar la canción actual en el almacenamiento del Widget
// //   static Future<void> saveCurrentSong(WidgetSongInfo info) async {
// //     await HomeWidget.saveWidgetData<String>('title', info.title);
// //     await HomeWidget.saveWidgetData<String>('artist', info.artist);
// //     await HomeWidget.saveWidgetData<String>('coverUrl', info.coverUrl);

// //     // Importante: Llamar a updateWidget para que el widget se redibuje con los nuevos datos
// //     await HomeWidget.updateWidget(
// //       name: 'PlayerWidget',
// //       androidName: 'widget.PlayerWidget',
// //     );
// //   }

// //   // Método para leer los datos (útil si necesitas saber qué hay guardado desde el código nativo)
// //   static Future<Map<String, dynamic>?> getSavedData() async {
// //     // Este método es opcional en Dart, ya que el Widget de Android/iOS leerá esto directamente.
// //     return null;
// //   }
// // }
// import 'dart:async';
// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:home_widget/home_widget.dart';
// import 'package:pzplayer/ui/screens/home_screens.dart';
// import 'package:receive_sharing_intent/receive_sharing_intent.dart';

// // Imports locales
// import 'package:pzplayer/core/audio/manager.dart';
// import 'core/theme/theme_provider.dart';
// import 'core/audio/audio_provider.dart';
// import 'ui/screens/intro_screen.dart';
// import 'core/theme/app_theme.dart';

// // --- CANALES ---
// const eventChannel = EventChannel('com.pzplayer.co.pzplayer/widget_comm');

// // --- MODELO DE DATOS DEL WIDGET ---
// class WidgetSongInfo {
//   final String title;
//   final String artist;
//   final String coverUrl;

//   WidgetSongInfo({
//     required this.title,
//     required this.artist,
//     required this.coverUrl,
//   });

//   static Future<void> saveCurrentSong(WidgetSongInfo info) async {
//     await HomeWidget.saveWidgetData<String>('title', info.title);
//     await HomeWidget.saveWidgetData<String>('artist', info.artist);
//     await HomeWidget.saveWidgetData<String>('coverUrl', info.coverUrl);

//     await HomeWidget.updateWidget(
//       name: 'widget.PlayerWidget',
//       androidName: 'widget.PlayerWidget',
//     );
//   }
// }

// // --- HANDLER DE FONDO ---
// @pragma('vm:entry-point')
// Future<void> backgroundCallback(Uri? uri) async {
//   if (uri?.scheme == 'pzplayer') {
//     await HomeWidget.updateWidget(
//       name: 'widget.PlayerWidget',
//       androidName: 'widget.PlayerWidget',
//     );
//   }
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // 1. Registrar callback para acciones en segundo plano
//   HomeWidget.registerBackgroundCallback(backgroundCallback);

//   // 2. Inicializar Audio Handler
//   final handler = await AudioServiceManager.createHandler();

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => ThemeProvider()),
//         ChangeNotifierProvider(create: (_) => AudioProvider(handler)),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   late StreamSubscription _intentDataStreamSubscription;
//   StreamSubscription<dynamic>? _intentChannelSubscription;

//   @override
//   void initState() {
//     super.initState();

//     // 1. Escuchar el canal de eventos nativos
//     _setupIntentChannelListener();

//     // 2. Escuchar archivos compartidos
//     _initSharingListener();

//     // 3. Revisar apertura inicial
//     _checkInitialSharing();
//   }

//   void _setupIntentChannelListener() {
//     try {
//       _intentChannelSubscription = eventChannel.receiveBroadcastStream().listen(
//         (dynamic eventData) async {
//           if (eventData != null && mounted) {
//             try {
//               final args = eventData is Map
//                   ? eventData
//                   : (eventData as Map)?['data']; // Ajuste por seguridad
//               if (args is Map) {
//                 await _processNativeIntent(args.cast<String, dynamic>());
//               }
//             } catch (e) {
//               print("🔴 ERROR PROCESANDO INTENT: $e");
//             }
//           }
//         },
//         onError: (dynamic error) => print("🔴 ERROR EVENT CHANNEL: $error"),
//       );
//     } catch (e) {
//       print("🔴 ERROR AL INICIAR LISTENER NATIVO: $e");
//     }
//   }

//   Future<void> _processNativeIntent(Map<String, dynamic> data) async {
//     if (!mounted) return;

//     final String? action = data['action'];
//     final String? songId = data['WIDGET_SONG_ID'];
//     final int? keyCode = data['WIDGET_KEY_CODE'];
//     final String? filePath = data['data'];

//     print("📥 Intent Nativo: $action | ID: $songId");

//     // CASO A: Apertura visual del widget
//     if (action == "android.intent.action.MAIN" && songId == null) return;

//     // CASO B: Botones del Widget
//     if (songId != null &&
//         songId.isNotEmpty &&
//         keyCode != null &&
//         keyCode != -1) {
//       // ✅ CAMBIO: Usamos un Timer asincrónico para NO BLOQUEAR
//       Timer(Duration.zero, () => _handleWidgetAction(songId, keyCode));
//       return;
//     }

//     // CASO C: Archivo compartido
//     if (filePath != null && filePath.isNotEmpty) {
//       if (filePath.contains("package:com.pzplayer.co.pzplayer")) return;
//       // ✅ CAMBIO: Ejecutar en el siguiente frame para no bloquear
//       Timer(Duration.zero, () => _playSharedFile(filePath));
//     }
//   }

//   /// ✅ MANEJO DE WIDGET SIN BLOQUEO (ELIMINADO EL WHILE)
//   Future<void> _handleWidgetAction(String songId, int keyCode) async {
//     if (!mounted) return;

//     final audioProvider = Provider.of<AudioProvider>(context, listen: false);

//     // 1. Buscar la canción directamente
//     MediaItem? targetSong;

//     // Intentamos buscar en la lista actual
//     try {
//       targetSong = audioProvider.items.firstWhere((c) => c.id == songId);
//     } catch (e) {
//       // Si no está, buscamos en la canción actual por si acaso
//       if (audioProvider.current?.id == songId) {
//         targetSong = audioProvider.current;
//       }
//     }

//     // 2. Si NO encontramos la canción (biblioteca vacía o aún cargando)
//     if (targetSong == null) {
//       print(
//         "⚠️ Canción $songId no encontrada inmediatamente. Intentando reproducir por ID...",
//       );

//       try {
//         // Intento directo: Si el ID es una ruta de archivo, reproducir como archivo externo
//         // Esto evita depender de que la lista cargue
//         if (songId.startsWith("/") || songId.startsWith("content")) {
//           await audioProvider.playFromFile(songId);
//           return;
//         }
//       } catch (e) {
//         print("🔴 Error reproduciendo directamente por ID: $e");
//       }

//       // Si falla todo, no hacemos nada para no crashear
//       return;
//     }

//     // 3. Ejecutar acción
//     try {
//       if (audioProvider.current?.id == targetSong.id) {
//         if (keyCode == 1) {
//           // Play/Pause
//           audioProvider.isPlaying
//               ? audioProvider.pause()
//               : audioProvider.resume();
//         } else if (keyCode == 0) {
//           // Prev
//           audioProvider.skipPrevious();
//         } else if (keyCode == 2) {
//           // Next
//           audioProvider.skipNext();
//         }
//       } else {
//         // Nueva canción
//         await audioProvider.playItems([targetSong]);
//       }
//     } catch (e) {
//       print("🔴 Error ejecutando acción widget: $e");
//     }
//   }

//   void _playSharedFile(String rawPath) {
//     if (!mounted) return;

//     String cleanPath = Uri.decodeFull(rawPath);
//     if (cleanPath.startsWith("file://")) {
//       cleanPath = cleanPath.replaceFirst("file://", "");
//     }

//     final audioProvider = Provider.of<AudioProvider>(context, listen: false);

//     if (audioProvider.current?.id == cleanPath) return;

//     print("▶️ Reproduciendo archivo: $cleanPath");
//     audioProvider.playFromFile(cleanPath);
//   }

//   void _initSharingListener() {
//     _intentDataStreamSubscription = ReceiveSharingIntent.instance
//         .getMediaStream()
//         .listen((List<SharedMediaFile> files) {
//           if (files.isNotEmpty && mounted) {
//             Timer(Duration.zero, () => _playSharedFile(files.first.path));
//           }
//         }, onError: (err) => print("🔴 Error Stream Sharing: $err"));
//   }

//   void _checkInitialSharing() {
//     SchedulerBinding.instance.addPostFrameCallback((_) async {
//       final initialMedia = await ReceiveSharingIntent.instance
//           .getInitialMedia();
//       if (initialMedia.isNotEmpty && mounted) {
//         final String path = initialMedia.first.path;
//         if (!path.contains("pzplayer://")) {
//           _playSharedFile(path);
//         }
//       }
//       await ReceiveSharingIntent.instance.reset();
//     });
//   }

//   @override
//   void dispose() {
//     _intentDataStreamSubscription.cancel();
//     _intentChannelSubscription?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'PZ Player',
//       theme: AppTheme.lightTheme,
//       darkTheme: AppTheme.darkTheme,
//       themeMode: themeProvider.themeMode,
//       home: const IntroScreen(),
//     );
//   }
// }
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:metadata_god/metadata_god.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

// Imports locales de PZ Player
import 'package:pzplayer/core/audio/manager.dart';
import 'core/theme/theme_provider.dart';
import 'core/audio/audio_provider.dart';
import 'ui/screens/intro_screen.dart';
import 'core/theme/app_theme.dart';

// --- CONFIGURACIÓN NATIVA ---
const eventChannel = EventChannel('com.pzplayer.co.pzplayer/widget_comm');

// --- MODELO DE DATOS DEL WIDGET ---
class WidgetSongInfo {
  final String title;
  final String artist;
  final String coverUrl;

  WidgetSongInfo({
    required this.title,
    required this.artist,
    required this.coverUrl,
  });

  static Future<void> saveCurrentSong(WidgetSongInfo info) async {
    await HomeWidget.saveWidgetData<String>('title', info.title);
    await HomeWidget.saveWidgetData<String>('artist', info.artist);
    await HomeWidget.saveWidgetData<String>('coverUrl', info.coverUrl);

    // El nombre debe coincidir exactamente con el definido en Android
    await HomeWidget.updateWidget(
      name: 'widget.PlayerWidget',
      androidName: 'widget.PlayerWidget',
    );
  }
}

// --- HANDLER DE FONDO (PARA EL WIDGET) ---
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.scheme == 'pzplayer') {
    // Aquí puedes manejar clics simples si no requieren lógica compleja de Provider
    await HomeWidget.updateWidget(
      name: 'widget.PlayerWidget',
      androidName: 'widget.PlayerWidget',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 2. Inicializa Hive
  await Hive.initFlutter();

  // 3. ABRE LA CAJA (Esto es lo que falta)
  // Usa el mismo nombre que pusiste en el AudioProvider
  await Hive.openBox('pz_library');
  await Hive.openBox('settings');

  // await MetadataGod.initialize();
  // 1. Registro de callback para interactividad del Widget
  HomeWidget.registerBackgroundCallback(backgroundCallback);

  // 2. Inicialización del motor de audio
  final handler = await AudioServiceManager.createHandler();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider(handler)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentDataStreamSubscription;
  StreamSubscription<dynamic>? _intentChannelSubscription;

  @override
  void initState() {
    super.initState();
    _setupIntentChannelListener();
    _initSharingListener();
    _checkInitialSharing();
  }

  // --- CANAL DE EVENTOS NATIVOS (WIDGET A APP) ---
  void _setupIntentChannelListener() {
    try {
      _intentChannelSubscription = eventChannel.receiveBroadcastStream().listen(
        (dynamic eventData) async {
          if (eventData != null && mounted) {
            final args = eventData is Map ? eventData : null;
            if (args != null) {
              await _processNativeIntent(args.cast<String, dynamic>());
            }
          }
        },
        onError: (error) => debugPrint("🔴 ERROR EVENT CHANNEL: $error"),
      );
    } catch (e) {
      debugPrint("🔴 ERROR AL INICIAR LISTENER NATIVO: $e");
    }
  }

  Future<void> _processNativeIntent(Map<String, dynamic> data) async {
    if (!mounted) return;

    try {
      final String? action = data['action'];
      final String? songId = data['WIDGET_SONG_ID'];
      final int? keyCode = data['WIDGET_KEY_CODE'];
      final String? filePath =
          data['data'] ?? data['path']; // A veces viene como 'path'

      // 1. Filtrar Intents de lanzamiento normal
      if (action == "android.intent.action.MAIN" &&
          songId == null &&
          filePath == null)
        return;

      final audioProvider = Provider.of<AudioProvider>(context, listen: false);

      // 2. Prioridad a archivos externos ("Abrir con...")
      if (filePath != null && filePath.isNotEmpty) {
        // Limpiamos el intent de compartir para que no se repita
        await ReceiveSharingIntent.instance.reset();

        debugPrint("📂 [File Intent] Detectado: $filePath");
        // Future.microtask(() => audioProvider.playFromFile(filePath));
        // Usamos un pequeño delay de 100ms.
        // Esto da tiempo a que el sistema operativo confirme los permisos del URI
        // antes de que el AudioHandler intente tomarlos.
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            audioProvider.playFromFile(filePath);
          }
        });
        return;
      }

      // 3. Comandos del Widget (Play/Pause/Next desde la pantalla de inicio)
      if (songId != null && keyCode != null && keyCode != -1) {
        debugPrint("🕹️ Widget Command: Song $songId, Key $keyCode");
        _handleWidgetAction(songId, keyCode);
      }
    } catch (e) {
      debugPrint("🔴 Error en el procesador de entrada de PZ Player: $e");
    }
  }

  // --- LÓGICA DE CONTROL DE AUDIO ---
  Future<void> _handleWidgetAction(String songId, int keyCode) async {
    if (!mounted) return;
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    MediaItem? targetSong;

    // Intentar localizar la canción en la lista cargada
    try {
      targetSong = audioProvider.items.firstWhere((c) => c.id == songId);
    } catch (e) {
      if (audioProvider.current?.id == songId) {
        targetSong = audioProvider.current;
      }
    }

    // Si no está en la lista (posiblemente un archivo externo o carga pendiente)
    if (targetSong == null) {
      if (songId.startsWith("/") || songId.startsWith("content")) {
        await audioProvider.playFromFile(songId);
        return;
      }
      return;
    }

    // Ejecutar acción según el KeyCode recibido del código nativo
    try {
      if (audioProvider.current?.id == targetSong.id) {
        switch (keyCode) {
          case 0: // Anterior
            audioProvider.skipPrevious();
            break;
          case 1: // Play/Pause
            audioProvider.isPlaying
                ? audioProvider.pause()
                : audioProvider.resume();
            break;
          case 2: // Siguiente
            audioProvider.skipNext();
            break;
        }
      } else {
        // Si el widget muestra una canción distinta a la actual, la reproducimos
        await audioProvider.playItems([targetSong]);
      }
    } catch (e) {
      debugPrint("🔴 Error ejecutando acción widget: $e");
    }
  }

  // --- MANEJO DE ARCHIVOS COMPARTIDOS ---
  void _playSharedFile(String rawPath) {
    if (!mounted) return;

    // Si es una ruta de archivo local clásica, limpiamos.
    // Si es content:// la dejamos intacta para que AudioSource.uri la maneje.
    String pathParaReproducir = rawPath;
    if (rawPath.startsWith("file://")) {
      pathParaReproducir = Uri.parse(rawPath).toFilePath();
    }

    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    // Evitar re-reproducir lo mismo si ya está sonando
    if (audioProvider.current?.id == pathParaReproducir) return;

    audioProvider.playFromFile(pathParaReproducir);
  }

  void _initSharingListener() {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> files) {
          if (files.isNotEmpty && mounted) {
            Timer(Duration.zero, () => _playSharedFile(files.first.path));
          }
        }, onError: (err) => debugPrint("🔴 Error Stream Sharing: $err"));
  }

  void _checkInitialSharing() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final initialMedia = await ReceiveSharingIntent.instance
          .getInitialMedia();
      if (initialMedia.isNotEmpty && mounted) {
        final String path = initialMedia.first.path;
        // Evitar procesar URIs de esquema propio si ya se manejan por EventChannel
        if (!path.contains("pzplayer://")) {
          _playSharedFile(path);
        }
      }
      await ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _intentChannelSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PZ Player',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const IntroScreen(),
    );
  }
}
