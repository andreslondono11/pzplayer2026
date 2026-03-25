import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pzplayer/core/theme/theme_provider.dart';
import 'package:pzplayer/core/theme/app_theme.dart';
import 'package:pzplayer/core/theme/app_colors.dart';
// Asegúrate de que esta ruta sea la correcta en tu proyecto
import 'package:pzplayer/core/audio/audio_provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  // Diálogo personalizado con información del proyecto
  void _showVersionDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Music Player Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note, size: 50, color: AppColors.primary),
            const SizedBox(height: 15),
            const Text(
              "Versión: 4.2.3+4",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text("Build: 2026.03.21"),
            const Divider(height: 30),
            const Text(
              "Music Player es un proyecto dedicado a la reproducción de audio de alta fidelidad con una interfaz moderna y fluida.",
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
    // Usamos context.read para acciones puntuales (no redibuja el drawer innecesariamente)
    final audioProvider = context.read<AudioProvider>();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black26
                  : AppColors.primary.withOpacity(0.8),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.play_circle_fill,
                size: 40,
                color: isDark ? Colors.black : AppColors.primary,
              ),
            ),
            accountName: const Text(
              "Music Player",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text("v4.2.49 Stable"),
          ),

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

                // --- BOTÓN ACTUALIZAR LIBRERÍA ---
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: const Text("Actualizar Librería"),
                  subtitle: const Text(
                    "Escanear nuevos archivos de audio",
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () async {
                    // Cerramos el drawer antes de empezar
                    Navigator.pop(context);

                    // Notificamos al usuario
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Buscando nueva música..."),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    try {
                      // Ejecutamos la lógica de tu provider
                      await audioProvider.refreshLibrary();
                    } catch (e) {
                      // Por si ocurre un error con los permisos o archivos
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error al actualizar: $e")),
                      );
                    }
                  },
                ),

                const Divider(),

                // --- INFORMACIÓN LEGAL Y TECNOLOGÍA ---
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text("Políticas de Privacidad"),
                  onTap: () => debugPrint("Navegar a políticas"),
                ),

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
                      applicationName: "Music Player",
                      applicationVersion: "2.0.1+2",
                      applicationIcon: Icon(
                        Icons.play_circle_fill,
                        size: 45,
                        color: isDark ? Colors.blueGrey : AppColors.primary,
                      ),
                      applicationLegalese: "© 2026 PzStudio",
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Desarrollado con el SDK de Flutter. Este reproductor utiliza diversas librerías de la comunidad para la gestión de audio y permisos.",
                        ),
                      ],
                    );
                  },
                ),

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
