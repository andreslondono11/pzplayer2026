// import 'package:flutter/material.dart';
// import 'package:pzplayer/ui/screens/home_screens.dart';
// import '../widgets/animated_logo.dart';
// import '../widgets/gradient_background.dart';
// // import 'home_screen.dart'; // crea este archivo en ui/screens/

// class IntroScreen extends StatefulWidget {
//   const IntroScreen({super.key});

//   @override
//   State<IntroScreen> createState() => _IntroScreenState();
// }

// class _IntroScreenState extends State<IntroScreen> {
//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(const Duration(seconds: 3), () {
//       Navigator.pushReplacement(
//         // ignore: use_build_context_synchronously
//         context,
//         MaterialPageRoute(builder: (_) => const HomeScreen()),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: GradientBackground(child: Center(child: AnimatedLogo())),
//     );
//   }
// }
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// // Imports de PZ Player
// import 'package:pzplayer/ui/screens/home_screens.dart'; // Asegúrate que este path sea correcto
// import 'package:pzplayer/core/audio/audio_provider.dart';
// import 'package:pzplayer/ui/widgets/animated_logo.dart';
// import 'package:pzplayer/ui/widgets/gradient_background.dart';

// class IntroScreen extends StatefulWidget {
//   const IntroScreen({super.key});

//   @override
//   State<IntroScreen> createState() => _IntroScreenState();
// }

// class _IntroScreenState extends State<IntroScreen> {
//   // Tiempo mínimo de duración del splash para ver el logo bonito
//   static const Duration _splashDuration = Duration(seconds: 2);

//   @override
//   void initState() {
//     super.initState();
//     // Iniciamos la carga después de pintar el primer frame
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeApp();
//     });
//   }

//   Future<void> _initializeApp() async {
//     final audioProvider = Provider.of<AudioProvider>(context, listen: false);

//     try {
//       // 1. EJECUTAMOS AMBAS TAREAS EN PARALELO
//       // Esperamos a que la biblioteca cargue Y esperamos el tiempo mínimo del splash.
//       // Esto es crítico: el 'await' asegura que no navegamos hasta tener datos.
//       await Future.wait([
//         // audioProvider.loadLibrary(), // Carga Biblioteca + Playlists (Hive)
//         // audioProvider.loadFavorites(), // Carga Favoritos (Hive)
//         Future.delayed(_splashDuration), // Tiempo mínimo visual
//       ]);

//       debugPrint("✅ [Intro] Datos cargados y tiempo mínimo cumplido.");

//       // 2. VERIFICACIÓN DE MONTAJE
//       // Esto previene el error si el usuario cerró la app muy rápido
//       if (!mounted) return;

//       // 3. NAVEGACIÓN
//       if (context.mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const HomeScreen()),
//         );
//       }
//     } catch (e, stackTrace) {
//       debugPrint("🔴 [Intro] Error crítico iniciando: $e");
//       debugPrint("StackTrace: $stackTrace");

//       // Opcional: Mostrar un diálogo de error si falla todo,
//       // pero por ahora navegamos igual para que la app no se quede colgada en negro.
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const HomeScreen()),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       // UI ligera
//       body: GradientBackground(child: Center(child: AnimatedLogo())),
//     );
//   }
// }
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/ui/screens/home_screens.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:pzplayer/ui/screens/nopermiso.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../widgets/animated_logo.dart';
import '../widgets/gradient_background.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with WidgetsBindingObserver {
  late StreamSubscription _intentDataStreamSubscription;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.resumed) _checkPermissionsSilent();
      },
    );

    _initFileSharing();
    _checkInitialStatus();
  }

  // Determina el permiso de archivos según la versión de Android
  Future<Permission> _getMusicPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return (androidInfo.version.sdkInt >= 33)
          ? Permission.audio
          : Permission.storage;
    }
    return Permission.storage;
  }

  Future<void> _checkInitialStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _checkPermissionsSilent();
  }

  // Verificación silenciosa de ambos permisos
  Future<void> _checkPermissionsSilent() async {
    final musicPerm = await _getMusicPermission();
    final musicStatus = await musicPerm.status;
    final notificationStatus = await Permission.notification.status;

    // Si la música está concedida, entramos y cargamos la librería
    if (musicStatus.isGranted) {
      // ✅ TRIGGER 1: Carga precia si ya teníamos permisos
      Provider.of<AudioProvider>(context, listen: false).loadLibrary();

      await _processInitialIntent();
      _navigateToHome();
    } else if (musicStatus.isPermanentlyDenied) {
      _onPermissionDenied();
    } else {
      if (mounted) _showPermissionRationale();
    }
  }

  void _showPermissionRationale() {
    showDialog(
      context: context,
      barrierDismissible: false, // Obliga a interactuar con los botones
      builder: (context) => AlertDialog(
        title: const Text('Permisos Necesarios'),
        content: const Text(
          'Para una experiencia completa, PZPlayer necesita:\n\n'
          '• Acceso a tu música.\n'
          '• Permiso para mostrar controles en las notificaciones.',
        ),
        actions: [
          // Opción 1: El usuario no quiere dar permisos ahora
          TextButton(
            child: const Text('Ahora no'),
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              _onPermissionDenied(); // Lo envía sí o sí a la pantalla de NoPermission
            },
          ),
          // Opción 2: El usuario intenta concederlos
          ElevatedButton(
            child: const Text('Configurar'),
            onPressed: () {
              Navigator.pop(context);
              _requestPermissions();
            },
          ),
        ],
      ),
    );
  }

  // 👈 AQUÍ SE PIDEN AMBOS PERMISOS
  Future<void> _requestPermissions() async {
    final musicPerm = await _getMusicPermission();

    // Solicitamos ambos en una lista
    Map<Permission, PermissionStatus> statuses = await [
      musicPerm,
      Permission.notification,
    ].request();

    if (statuses[musicPerm]!.isGranted) {
      // ✅ TRIGGER 2: Carga precia si acaba de dar permisos
      Provider.of<AudioProvider>(context, listen: false).loadLibrary();

      await _processInitialIntent();
      _navigateToHome();
    } else {
      // Si rechazó lo vital (música), a la pantalla de error
      _onPermissionDenied();
    }
  }

  void _onPermissionDenied() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NoPermissionScreen()),
      );
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  // --- Lógica de compartir archivos ---
  void _initFileSharing() {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((value) {
          if (value.isNotEmpty) _handleSharedFile(value.first.path);
        });
  }

  Future<void> _processInitialIntent() async {
    final value = await ReceiveSharingIntent.instance.getInitialMedia();
    if (value.isNotEmpty) _handleSharedFile(value.first.path);
  }

  void _handleSharedFile(String path) async {
    final musicPerm = await _getMusicPermission();
    if (await musicPerm.isGranted) {
      if (!mounted) return;
      Provider.of<AudioProvider>(context, listen: false).loadAndPlayUri(path);
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GradientBackground(child: Center(child: AnimatedLogo())),
    );
  }
}
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:pzplayer/ui/screens/home_screens.dart';
// import 'package:pzplayer/core/audio/audio_provider.dart';
// import 'package:pzplayer/ui/screens/nopermiso.dart'; // Asegúrate que este import sea correcto
// import 'package:receive_sharing_intent/receive_sharing_intent.dart';
// import 'package:permission_handler/permission_handler.dart';
// import '../widgets/animated_logo.dart';
// import '../widgets/gradient_background.dart';

// class IntroScreen extends StatefulWidget {
//   const IntroScreen({super.key});

//   @override
//   State<IntroScreen> createState() => _IntroScreenState();
// }

// class _IntroScreenState extends State<IntroScreen> with WidgetsBindingObserver {
//   late StreamSubscription _intentDataStreamSubscription;

//   // Listener para detectar cuando la app regresa de segundo plano (configuración)
//   late final AppLifecycleListener _lifecycleListener;

//   @override
//   void initState() {
//     super.initState();
//     // Nos registramos como observador del ciclo de vida de la app
//     WidgetsBinding.instance.addObserver(this);

//     // Configuramos el listener para el ciclo de vida (Método moderno Flutter 3.13+)
//     _lifecycleListener = AppLifecycleListener(
//       onStateChange: _handleLifecycleStateChange,
//     );

//     _initFileSharing();

//     // Iniciamos el flujo
//     _checkInitialStatus();
//   }

//   // Detecta cambios: ej. el usuario sale a Configuración y vuelve
//   void _handleLifecycleStateChange(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       // La app volvió a primer plano.
//       // En lugar de mostrar el diálogo de nuevo, verificamos silenciosamente.
//       _checkPermissionsSilent();
//     }
//   }

//   // 1. Verificación inicial al arrancar
//   Future<void> _checkInitialStatus() async {
//     // Esperamos un frame para que el contexto esté listo
//     await Future.delayed(const Duration(milliseconds: 100));

//     if (mounted) {
//       _checkPermissionsSilent();
//     }
//   }

//   // 2. Verificación silenciosa (Evita el bucle de diálogos)
//   Future<void> _checkPermissionsSilent() async {
//     // Verificamos el estado actual del permiso
//     var status = await Permission.storage.status;

//     if (status.isGranted) {
//       // ✅ CASO 1: YA TIENE PERMISOS (Acaba de activarlos manualmente o ya los tenía)
//       // Procesamos archivo si vino por sharing y vamos al Home sin mostrar diálogos
//       await _processInitialIntent();
//       _navigateToHome();
//     } else if (status.isDenied) {
//       // ❌ CASO 2: AÚN NO HA DECIDIDO (o es la primera vez)
//       // Mostramos el diálogo explicativo
//       if (mounted) _showPermissionRationale();
//     } else if (status.isPermanentlyDenied) {
//       // ⛔ CASO 3: DENEGADO PERMANENTEMENTE (Marcó "No volver a preguntar")
//       // Enviamos directo a la pantalla de sin servicio
//       if (mounted) _onPermissionDenied();
//     }
//   }

//   // 3. Diálogo Explicativo (Solo se muestra si es necesario)
//   void _showPermissionRationale() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Permisos Necesarios'),
//           content: const SingleChildScrollView(
//             child: ListBody(
//               children: <Widget>[
//                 Text(
//                   'Para reproducir música y acceder a los archivos que compartes, necesitamos acceso al almacenamiento de tu dispositivo.',
//                 ),
//                 SizedBox(height: 10),
//                 Text('• No recopilamos datos personales.'),
//                 Text('• No enviamos información a servidores externos.'),
//                 Text('• El acceso es exclusivo para la reproducción local.'),
//               ],
//             ),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancelar'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _onPermissionDenied();
//               },
//             ),
//             TextButton(
//               child: const Text('Entendido, permitir'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _requestPermissions();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // 4. Solicitar permisos (Solo cuando el usuario toca "Aceptar")
//   Future<void> _requestPermissions() async {
//     var status = await Permission.storage.request();

//     if (status.isGranted) {
//       await _processInitialIntent();
//       _navigateToHome();
//     } else {
//       // Si deniega aquí, revisamos si es permanente
//       if (status.isPermanentlyDenied) {
//         _onPermissionDenied();
//       } else {
//         // Si solo dijo "Denegar" temporalmente, podrías mostrar un mensaje o ir a error
//         _onPermissionDenied();
//       }
//     }
//   }

//   void _onPermissionDenied() {
//     if (mounted) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const NoPermissionScreen()),
//       );
//     }
//   }

//   void _navigateToHome() {
//     // Simulamos tiempo de splash solo si no nos hemos ido ya
//     Timer(const Duration(seconds: 2), () {
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const HomeScreen()),
//         );
//       }
//     });
//   }

//   void _initFileSharing() {
//     _intentDataStreamSubscription = ReceiveSharingIntent.instance
//         .getMediaStream()
//         .listen((List<SharedMediaFile> value) {
//           if (value.isNotEmpty) {
//             _handleSharedFile(value.first.path);
//           }
//         }, onError: (err) => print("Error en stream de archivo: $err"));
//   }

//   Future<void> _processInitialIntent() async {
//     try {
//       final List<SharedMediaFile> value = await ReceiveSharingIntent.instance
//           .getInitialMedia();
//       if (value.isNotEmpty) {
//         _handleSharedFile(value.first.path);
//       }
//     } catch (e) {
//       print("Error procesando intent inicial: $e");
//     }
//   }

//   void _handleSharedFile(String path) {
//     // Verificación final antes de cargar
//     Permission.storage.status.then((status) {
//       if (status.isGranted) {
//         final audioProvider = Provider.of<AudioProvider>(
//           context,
//           listen: false,
//         );
//         audioProvider.loadAndPlayUri(path);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _lifecycleListener.dispose(); // Limpiamos el listener
//     WidgetsBinding.instance.removeObserver(this);
//     _intentDataStreamSubscription.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: GradientBackground(child: Center(child: AnimatedLogo())),
//     );
//   }
// }
