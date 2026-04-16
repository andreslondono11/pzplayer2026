// import 'package:flutter/material.dart';
// import 'package:home_widget/home_widget.dart';
// import 'package:provider/provider.dart';
// import 'package:pzplayer/core/theme/theme_provider.dart';
// import 'package:pzplayer/core/theme/app_theme.dart';
// import 'package:pzplayer/core/theme/app_colors.dart';
// // Asegúrate de que esta ruta sea la correcta en tu proyecto
// import 'package:pzplayer/core/audio/audio_provider.dart';
// import 'package:url_launcher/url_launcher.dart';

// class MainDrawer extends StatelessWidget {
//   const MainDrawer({super.key});

//   // Diálogo personalizado con información del proyecto
//   void _showVersionDialog(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         title: const Text("PZ Player Info"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.music_note, size: 50, color: AppColors.primary),
//             const SizedBox(height: 15),
//             const Text(
//               "Versión: 13.28.0+13",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const Text("Build: 2026.03.21"),
//             const Divider(height: 30),
//             const Text(
//               "Pz Player es un proyecto dedicado a la reproducción de audio de alta fidelidad con una interfaz moderna y fluida.",
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               "Cerrar",
//               style: TextStyle(
//                 color: isDark ? Colors.blueGrey : AppColors.primary,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     // Usamos context.read para acciones puntuales (no redibuja el drawer innecesariamente)
//     final audioProvider = context.read<AudioProvider>();

//     return Drawer(
//       child: Column(
//         children: [
//           UserAccountsDrawerHeader(
//             decoration: BoxDecoration(
//               color: isDark
//                   ? Colors.black26
//                   // ignore: deprecated_member_use
//                   : AppColors.primary.withOpacity(0.8),
//             ),
//             currentAccountPicture: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(
//                 Icons.play_circle_fill,
//                 size: 40,
//                 color: isDark ? Colors.black : AppColors.primary,
//               ),
//             ),
//             accountName: const Text(
//               "PZ Player",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             accountEmail: const Text("v12.25.1+12 Stable"),
//           ),

//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.zero,
//               children: [
//                 // --- APARIENCIA ---
//                 ExpansionTile(
//                   leading: const Icon(Icons.palette_outlined),
//                   title: const Text("Apariencia"),
//                   subtitle: Text(
//                     themeProvider.themeMode == ThemeMode.system
//                         ? "Sistema"
//                         : (themeProvider.themeMode == ThemeMode.dark
//                               ? "Modo Oscuro"
//                               : "Modo Claro"),
//                     style: const TextStyle(fontSize: 12),
//                   ),
//                   children: [
//                     RadioListTile<ThemeMode>(
//                       title: const Text("Modo Claro"),
//                       value: ThemeMode.light,
//                       // ignore: deprecated_member_use
//                       groupValue: themeProvider.themeMode,
//                       // ignore: deprecated_member_use
//                       onChanged: (val) =>
//                           themeProvider.setTheme(AppTheme.lightTheme),
//                     ),
//                     RadioListTile<ThemeMode>(
//                       title: const Text("Modo Oscuro"),
//                       value: ThemeMode.dark,
//                       // ignore: deprecated_member_use
//                       groupValue: themeProvider.themeMode,
//                       // ignore: deprecated_member_use
//                       onChanged: (val) =>
//                           themeProvider.setTheme(AppTheme.darkTheme),
//                     ),
//                     RadioListTile<ThemeMode>(
//                       title: const Text("Usar Sistema"),
//                       value: ThemeMode.system,
//                       // ignore: deprecated_member_use
//                       groupValue: themeProvider.themeMode,
//                       // ignore: deprecated_member_use
//                       onChanged: (val) => themeProvider.setSystemTheme(),
//                     ),
//                   ],
//                 ),

//                 // --- BOTÓN ACTUALIZAR LIBRERÍA ---
//                 ListTile(
//                   leading: const Icon(Icons.refresh_rounded),
//                   title: const Text("Actualizar Librería"),
//                   subtitle: const Text(
//                     "Escanear nuevos archivos de audio",
//                     style: TextStyle(fontSize: 11),
//                   ),
//                   onTap: () async {
//                     // Cerramos el drawer antes de empezar
//                     Navigator.pop(context);

//                     // Notificamos al usuario
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text("Buscando nueva música..."),
//                         duration: Duration(seconds: 2),
//                       ),
//                     );

//                     try {
//                       // Ejecutamos la lógica de tu provider
//                       await audioProvider.refreshLibrary();
//                     } catch (e) {
//                       // Por si ocurre un error con los permisos o archivos
//                       // ignore: use_build_context_synchronously
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text("Error al actualizar: $e")),
//                       );
//                     }
//                   },
//                 ),

//                 const Divider(),

//                 // --- INFORMACIÓN LEGAL Y TECNOLOGÍA ---
//                 ListTile(
//                   leading: const Icon(Icons.privacy_tip_outlined),
//                   title: const Text("Políticas de Privacidad"),
//                   onTap: () async {
//                     final Uri url = Uri.parse(
//                       'https://sites.google.com/view/actualizacionpzplayer/p%C3%A1gina-principal',
//                     );
//                     if (!await launchUrl(
//                       url,
//                       mode: LaunchMode.inAppBrowserView,
//                     )) {
//                       debugPrint('error al abrir la URL: $url');
//                     }
//                     ;
//                   },
//                 ),

//                 ListTile(
//                   leading: const Icon(Icons.code_rounded),
//                   title: const Text("Tecnologías y Licencias"),
//                   subtitle: const Text(
//                     "Software de código abierto",
//                     style: TextStyle(fontSize: 11),
//                   ),
//                   onTap: () {
//                     showAboutDialog(
//                       context: context,
//                       applicationName: "PZ Player",
//                       applicationVersion: "13.28.0+13",
//                       applicationIcon: Icon(
//                         Icons.play_circle_fill,
//                         size: 45,
//                         color: isDark ? Colors.blueGrey : AppColors.primary,
//                       ),
//                       applicationLegalese: "© 2026 PzStudio",
//                       children: [
//                         const SizedBox(height: 20),
//                         const Text(
//                           "Desarrollado con el SDK de Flutter. Este reproductor utiliza diversas librerías de la comunidad para la gestión de audio y permisos. CODE VERSION 12",
//                         ),
//                       ],
//                     );
//                   },
//                 ),

//                 ListTile(
//                   leading: const Icon(Icons.info_outline),
//                   title: const Text("Acerca de Music Player"),
//                   onTap: () => _showVersionDialog(context),
//                 ),
//                 // ElevatedButton(
//                 //   onPressed: () async {
//                 //     print("Enviando prueba al widget...");
//                 //     await HomeWidget.saveWidgetData<String>(
//                 //       'title',
//                 //       'Canción de Prueba',
//                 //     );
//                 //     await HomeWidget.saveWidgetData<String>(
//                 //       'artist',
//                 //       'PZ Studio Test',
//                 //     );
//                 //     await HomeWidget.updateWidget(
//                 //       name: 'PlayerWidget',
//                 //       androidName: 'PlayerWidget',
//                 //     );
//                 //   },
//                 //   child: Text("FORZAR ACTUALIZACIÓN WIDGET"),
//                 // ),
//               ],
//             ),
//           ),

//           const Padding(
//             padding: EdgeInsets.all(16.0),
//             child: Text(
//               "PzStudio © 2026",
//               style: TextStyle(fontSize: 10, color: Colors.grey),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:pzplayer/core/theme/theme_provider.dart';
import 'package:pzplayer/core/theme/app_theme.dart';
import 'package:pzplayer/core/theme/app_colors.dart';
import 'package:pzplayer/core/audio/audio_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  void _showVersionDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("PZ Player Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note, size: 50, color: AppColors.primary),
            const SizedBox(height: 15),
            const Text(
              "Versión: 13.28.0+13",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text("Build: 2026.03.21"),
            const Divider(height: 30),
            const Text(
              "Pz Player es un proyecto dedicado a la reproducción de audio de alta fidelidad con una interfaz moderna y fluida.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cerrar",
              style: TextStyle(
                color: isDark ? Colors.blueGrey : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final audioProvider = context.read<AudioProvider>();

    final currentItem = audioProvider.current;
    final songTitle = currentItem?.title ?? "PZ Player";
    final artistName = currentItem?.artist ?? "Sin Música";

    final dynamic rawId = currentItem?.extras?['dbId'];
    final int songId = (rawId is int)
        ? rawId
        : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    return Drawer(
      child: Column(
        children: [
          // --- HEADER CON FONDO DE IMAGEN COMPLETA ---
          Container(
            height: 300, // Aumentamos la altura para que se vea más inmersivo
            decoration: const BoxDecoration(
              // Fondo negro por seguridad mientras carga la imagen
              color: Colors.black,
            ),
            child: Stack(
              children: [
                // 1. Fondo: Carátula expandida
                Positioned.fill(
                  child: QueryArtworkWidget(
                    id: songId,
                    type: ArtworkType.AUDIO,
                    artworkWidth: 800, // Alta calidad
                    artworkHeight: 800,
                    artworkFit: BoxFit.cover, // Cubre todo el contenedor
                    nullArtworkWidget: Container(
                      color: isDark ? Colors.black : AppColors.primary,
                      child: const Icon(
                        Icons.music_note,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                // 2. Capa oscura para legibilidad del texto
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1), // Más claro arriba
                          Colors.black.withOpacity(
                            0.9,
                          ), // Más oscuro abajo para fundir con la lista
                        ],
                      ),
                    ),
                  ),
                ),
                // 3. Contenido Texto superpuesto
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 30, // Un poco más abajo para que se sienta profundo
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        songTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22, // Un poco más grande
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              // Sombra suave para que resalte
                              blurRadius: 4.0,
                              color: Colors.black45,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        artistName,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ---------------------------------------
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // --- APARIENCIA ---
                ExpansionTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text("Apariencia"),
                  subtitle: Text(
                    themeProvider.themeMode == ThemeMode.system
                        ? "Sistema"
                        : (themeProvider.themeMode == ThemeMode.dark
                              ? "Modo Oscuro"
                              : "Modo Claro"),
                    style: const TextStyle(fontSize: 12),
                  ),
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text("Modo Claro"),
                      value: ThemeMode.light,
                      groupValue: themeProvider.themeMode,
                      onChanged: (val) =>
                          themeProvider.setTheme(AppTheme.lightTheme),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text("Modo Oscuro"),
                      value: ThemeMode.dark,
                      groupValue: themeProvider.themeMode,
                      onChanged: (val) =>
                          themeProvider.setTheme(AppTheme.darkTheme),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text("Usar Sistema"),
                      value: ThemeMode.system,
                      groupValue: themeProvider.themeMode,
                      onChanged: (val) => themeProvider.setSystemTheme(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // --- BOTÓN ACTUALIZAR LIBRERÍA ---
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: const Text("Actualizar Librería"),
                  subtitle: const Text(
                    "Escanear nuevos archivos de audio",
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Buscando nueva música..."),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    try {
                      await audioProvider.refreshLibrary();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error al actualizar: $e")),
                      );
                    }
                  },
                ),

                // const Divider(),
                const SizedBox(height: 10),
                // --- INFORMACIÓN LEGAL Y TECNOLOGÍA ---
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text("Políticas de Privacidad"),
                  onTap: () async {
                    final Uri url = Uri.parse(
                      'https://sites.google.com/view/actualizacionpzplayer/p%C3%A1gina-principal',
                    );
                    if (!await launchUrl(
                      url,
                      mode: LaunchMode.inAppBrowserView,
                    )) {
                      debugPrint('error al abrir la URL: $url');
                    }
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: const Text("Tecnologías y Licencias"),
                  subtitle: const Text(
                    "Software de código abierto",
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: "PZ Player",
                      applicationVersion: "13.28.0+13",
                      applicationIcon: Icon(
                        Icons.play_circle_fill,
                        size: 45,
                        color: isDark ? Colors.blueGrey : AppColors.primary,
                      ),
                      applicationLegalese: "© 2026 PzStudio",
                      children: const [
                        SizedBox(height: 20),
                        Text(
                          "Desarrollado con el SDK de Flutter. Este reproductor utiliza diversas librerías de la comunidad para la gestión de audio y permisos. CODE VERSION 12",
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text("Acerca de Music Player"),
                  onTap: () => _showVersionDialog(context),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "PzStudio © 2026",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
