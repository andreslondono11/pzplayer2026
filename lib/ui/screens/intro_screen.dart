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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/ui/screens/home_screens.dart';
import 'package:pzplayer/core/audio/audio_provider.dart'; // 🎵 Importa tu provider
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../widgets/animated_logo.dart';
import '../widgets/gradient_background.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initFileSharing();

    // Timer para la splash screen
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  void _initFileSharing() {
    // 1. Escucha archivos compartidos mientras la app está en segundo plano
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) {
          if (value.isNotEmpty) {
            _handleSharedFile(value.first.path);
          }
        }, onError: (err) => print("Error en stream de archivo: $err"));

    // 2. Revisa si la app se abrió desde cero con un archivo
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      if (value.isNotEmpty) {
        _handleSharedFile(value.first.path);
      }
    });
  }

  void _handleSharedFile(String path) {
    // Accedemos al AudioProvider y le pasamos la ruta del archivo
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    // NOTA: Asegúrate de tener un método en tu AudioProvider que reciba el path
    audioProvider.loadAndPlayUri(path);
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel(); // 🧹 Limpieza
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GradientBackground(child: Center(child: AnimatedLogo())),
    );
  }
}
