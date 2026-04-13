// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:provider/provider.dart';
// import 'package:home_widget/home_widget.dart';
// import 'package:receive_sharing_intent/receive_sharing_intent.dart';

// import 'package:pzplayer/core/audio/manager.dart';
// import 'core/theme/theme_provider.dart';
// import 'core/audio/audio_provider.dart';
// import 'ui/screens/intro_screen.dart';
// import 'core/theme/app_theme.dart';

// // --- PASO 1: HANDLER DE FONDO ---
// @pragma('vm:entry-point')
// Future<void> backgroundCallback(Uri? uri) async {
//   if (uri?.scheme == 'pzplayer') {
//     final String comando = uri!.host;
//     final handler = await AudioServiceManager.createHandler();

//     // Variable para saber el nuevo estado
//     bool nuevoEstadoReproduccion = false;

//     // 1. Ejecutar la acción correspondiente
//     if (comando == "next") {
//       await handler.skipToNext();
//       nuevoEstadoReproduccion = true;

//       // ✅ IMPORTANTE: Cuando saltas de canción, debes actualizar los datos del widget
//       // Supongamos que tienes una forma de obtener la mediaItem actual del handler:
//       final currentItem = handler.mediaItem.value;
//       if (currentItem != null) {
//         await WidgetSongInfo.saveCurrentSong(
//           WidgetSongInfo(
//             title: currentItem.title,
//             artist: currentItem.artist ?? 'Desconocido',
//             coverUrl: currentItem.artUri?.toString() ?? '',
//           ),
//         );
//       }
//     } else if (comando == "prev") {
//       await handler.skipToPrevious();
//       nuevoEstadoReproduccion = true;

//       // ✅ Lo mismo para anterior
//       final currentItem = handler.mediaItem.value;
//       if (currentItem != null) {
//         await WidgetSongInfo.saveCurrentSong(
//           WidgetSongInfo(
//             title: currentItem.title,
//             artist: currentItem.artist ?? 'Desconocido',
//             coverUrl: currentItem.artUri?.toString() ?? '',
//           ),
//         );
//       }
//     } else if (comando == "playpause") {
//       if (handler.playbackState.value.playing) {
//         await handler.pause();
//         nuevoEstadoReproduccion = false;
//       } else {
//         await handler.play();
//         nuevoEstadoReproduccion = true;
//       }
//     }

//     // 2. Guardar el estado de reproducción
//     await HomeWidget.saveWidgetData<bool>('isPlaying', nuevoEstadoReproduccion);

//     // 3. Forzar la actualización visual del Widget
//     await HomeWidget.updateWidget(
//       name: 'PlayerWidget',
//       androidName: 'widget.PlayerWidget',
//     );
//   }
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Registrar el callback para que el widget funcione en segundo plano
//   HomeWidget.registerBackgroundCallback(backgroundCallback);

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

//   @override
//   void initState() {
//     super.initState();
//     _initSharingListener();
//     // HomeWidget.registerBackgroundCallback(backgroundCallback);
//   }

//   void _initSharingListener() async {
//     // Escuchar archivos mientras la app está en memoria
//     _intentDataStreamSubscription = ReceiveSharingIntent.instance
//         .getMediaStream()
//         .listen((List<SharedMediaFile> files) {
//           if (files.isNotEmpty && mounted) {
//             _procesarAudioCompartido(files.first.path);
//           }
//         }, onError: (err) => print("🔴 Error Stream: $err"));

//     // Escuchar comando inicial al abrir la app
//     SchedulerBinding.instance.addPostFrameCallback((_) async {
//       final initialMedia = await ReceiveSharingIntent.instance
//           .getInitialMedia();

//       if (initialMedia.isNotEmpty && mounted) {
//         final String data = initialMedia.first.path;
//         if (data.contains("pzplayer://")) {
//           _procesarComandoWidget(data);
//         } else {
//           _procesarAudioCompartido(data);
//         }
//       }
//       await ReceiveSharingIntent.instance.reset();
//     });
//   }

//   void _procesarComandoWidget(String uri) {
//     final audioProvider = Provider.of<AudioProvider>(context, listen: false);

//     if (uri.contains("playpause")) {
//       audioProvider.isPlaying ? audioProvider.pause() : audioProvider.resume();
//     } else if (uri.contains("next")) {
//       audioProvider.skipNext();
//     } else if (uri.contains("prev")) {
//       audioProvider.skipPrevious();
//     }
//   }

//   void _procesarAudioCompartido(String filePath) {
//     if (!mounted) return;
//     final audioProvider = Provider.of<AudioProvider>(context, listen: false);
//     if (audioProvider.current?.id == filePath) return;
//     audioProvider.playFromFile(filePath);
//   }

//   @override
//   void dispose() {
//     _intentDataStreamSubscription.cancel();
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

// class WidgetSongInfo {
//   final String title;
//   final String artist;
//   final String
//   coverUrl; // Asegúrate de que sea una URL válida o una ruta local accesible

//   WidgetSongInfo({
//     required this.title,
//     required this.artist,
//     required this.coverUrl,
//   });

//   // Método para guardar la canción actual en el almacenamiento del Widget
//   static Future<void> saveCurrentSong(WidgetSongInfo info) async {
//     await HomeWidget.saveWidgetData<String>('title', info.title);
//     await HomeWidget.saveWidgetData<String>('artist', info.artist);
//     await HomeWidget.saveWidgetData<String>('coverUrl', info.coverUrl);

//     // Importante: Llamar a updateWidget para que el widget se redibuje con los nuevos datos
//     await HomeWidget.updateWidget(
//       name: 'PlayerWidget',
//       androidName: 'widget.PlayerWidget',
//     );
//   }

//   // Método para leer los datos (útil si necesitas saber qué hay guardado desde el código nativo)
//   static Future<Map<String, dynamic>?> getSavedData() async {
//     // Este método es opcional en Dart, ya que el Widget de Android/iOS leerá esto directamente.
//     return null;
//   }
// }
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

// Imports locales
import 'package:pzplayer/core/audio/manager.dart';
import 'core/theme/theme_provider.dart';
import 'core/audio/audio_provider.dart';
import 'ui/screens/intro_screen.dart';
import 'core/theme/app_theme.dart';

// --- CANALES ---
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

    await HomeWidget.updateWidget(
      name: 'widget.PlayerWidget',
      androidName: 'widget.PlayerWidget',
    );
  }
}

// --- HANDLER DE FONDO ---
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.scheme == 'pzplayer') {
    await HomeWidget.updateWidget(
      name: 'widget.PlayerWidget',
      androidName: 'widget.PlayerWidget',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Registrar callback para acciones en segundo plano
  HomeWidget.registerBackgroundCallback(backgroundCallback);

  // 2. Inicializar Audio Handler
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

    // 1. Escuchar el canal de eventos nativos (Widget, Archivos, Notificación)
    _setupIntentChannelListener();

    // 2. Escuchar archivos compartidos vía "Share Sheet"
    _initSharingListener();

    // 3. Revisar si la app abrió por un archivo estando cerrada
    _checkInitialSharing();
  }

  /// --- LISTENER DEL EVENT CHANNEL NATIVO ---
  void _setupIntentChannelListener() {
    try {
      _intentChannelSubscription = eventChannel.receiveBroadcastStream().listen(
        (dynamic eventData) async {
          if (eventData != null && mounted) {
            try {
              final args = eventData as Map<dynamic, dynamic>;
              await _processNativeIntent(args);
            } catch (e) {
              print("🔴 ERROR PROCESANDO INTENT: $e");
            }
          }
        },
        onError: (dynamic error) => print("🔴 ERROR EVENT CHANNEL: $error"),
      );
    } catch (e) {
      print("🔴 ERROR AL INICIAR LISTENER NATIVO: $e");
    }
  }

  /// --- PROCESADOR DE INTENTS INTELIGENTE ---
  Future<void> _processNativeIntent(Map<dynamic, dynamic> data) async {
    if (!mounted) return;

    final String? action = data['action'];
    final String? songId = data['WIDGET_SONG_ID'];
    final int? keyCode = data['WIDGET_KEY_CODE'];
    final String? filePath = data['data'];

    print("📥 Intent Nativo Recibido: $action");

    // CASO A: Toque en la imagen/contenedor del Widget (Abrir App)
    if (action == "android.intent.action.MAIN" && songId == null) {
      print("📱 App abierta desde el widget (Visualización)");
      return;
    }

    // CASO B: Comandos del Widget (Botones Play/Next/Prev)
    if (songId != null &&
        songId.isNotEmpty &&
        keyCode != null &&
        keyCode != -1) {
      await _handleWidgetAction(songId, keyCode);
      return;
    }

    // CASO C: Apertura desde Gestor de Archivos (ACTION_VIEW)
    if (filePath != null && filePath.isNotEmpty) {
      // Ignorar si el intent es el de lanzamiento de la app
      if (filePath.contains("package:com.pzplayer.co.pzplayer")) return;
      _playSharedFile(filePath);
    }
  }

  /// --- MANEJO DE ACCIONES DEL WIDGET ---
  Future<void> _handleWidgetAction(String songId, int keyCode) async {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    // Esperar a que la lista cargue si la app acaba de abrirse
    int intentos = 0;
    while (audioProvider.items.isEmpty && intentos < 5) {
      await Future.delayed(const Duration(milliseconds: 300));
      intentos++;
    }

    if (!mounted) return;

    try {
      // Buscar la canción en la lista
      final targetSong = audioProvider.items.firstWhere(
        (c) => c.id == songId,
        orElse: () => audioProvider.current ?? audioProvider.items.first,
      );

      // Si es la canción actual, procesar el comando
      if (audioProvider.current?.id == targetSong.id) {
        if (keyCode == 1) {
          // Play/Pause
          audioProvider.isPlaying
              ? audioProvider.pause()
              : audioProvider.resume();
        } else if (keyCode == 0) {
          // Prev
          audioProvider.skipPrevious();
        } else if (keyCode == 2) {
          // Next
          audioProvider.skipNext();
        }
      } else {
        // Si es otra canción del widget, reproducirla
        await audioProvider.playItems([targetSong]);
      }
    } catch (e) {
      print("🔴 Error en acción de widget: $e");
    }
  }

  /// --- REPRODUCTOR UNIFICADO (Limpia rutas de archivos) ---
  void _playSharedFile(String rawPath) {
    if (!mounted) return;

    // Decodificar URI (Arregla el msf%3A35 -> msf:35)
    String cleanPath = Uri.decodeFull(rawPath);

    if (cleanPath.startsWith("file://")) {
      cleanPath = cleanPath.replaceFirst("file://", "");
    }

    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    if (audioProvider.current?.id == cleanPath) return;

    print("▶️ Reproduciendo desde gestor: $cleanPath");
    audioProvider.playFromFile(cleanPath);
  }

  /// --- RECEIVE SHARING INTENT (COLD START & STREAM) ---
  void _initSharingListener() {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> files) {
          if (files.isNotEmpty && mounted) {
            _playSharedFile(files.first.path);
          }
        }, onError: (err) => print("🔴 Error Stream Sharing: $err"));
  }

  void _checkInitialSharing() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final initialMedia = await ReceiveSharingIntent.instance
          .getInitialMedia();
      if (initialMedia.isNotEmpty && mounted) {
        final String path = initialMedia.first.path;
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
