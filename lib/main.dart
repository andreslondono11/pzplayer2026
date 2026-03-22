import 'dart:async'; // 👈 Importante para el StreamSubscription
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/core/audio/manager.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart'; // 👈 Importa el plugin
import 'core/theme/theme_provider.dart';
import 'core/audio/audio_provider.dart';
import 'ui/screens/intro_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  // 👈 Cambiamos a StatefulWidget para manejar el listener
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    // 1. Escuchar archivos compartidos mientras la app está ABIERTA en segundo plano
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((value) {
          if (value.isNotEmpty) {
            _procesarAudioCompartido(value.first.path);
          }
        });

    // 2. Escuchar archivos compartidos cuando la app se abre desde CERO
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        _procesarAudioCompartido(value.first.path);
      }
    });
  }

  void _procesarAudioCompartido(String path) {
    // 🚀 Usamos el AudioProvider para cargar el archivo automáticamente
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.playFromFile(
      path,
    ); // Asegúrate de tener este método en tu AudioProvider
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
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
