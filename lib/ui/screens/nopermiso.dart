import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pzplayer/ui/screens/intro_screen.dart'; // Para recargar el flujo si falla
import 'package:pzplayer/ui/screens/home_screens.dart'; // 👈 Importación añadida
import '../widgets/gradient_background.dart';

class NoPermissionScreen extends StatelessWidget {
  const NoPermissionScreen({super.key});

  // Método auxiliar para verificar permisos antes de navegar
  Future<void> _checkPermissionsAndNavigate(BuildContext context) async {
    // Verificamos el estado actual del permiso
    var status = await Permission.storage.status;

    if (status.isGranted) {
      // ✅ CASO EXITOSO: Si el usuario activó los permisos manualmente
      // Lo llevamos directo al HomeScreen, evitando el bucle del IntroScreen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      // ❌ CASO FALLIDO: Si todavía no hay permisos
      // Lo enviamos de vuelta al IntroScreen para que intente pedirlos de nuevo
      // o muestre el diálogo nuevamente.
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const IntroScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Servicio no disponible"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.no_accounts,
                  size: 80,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Permisos Denegados",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "PZPlayer no puede funcionar sin acceso a los archivos de audio. Necesitamos tu permiso para reproducir música.",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Botón para ir a configuración manual
                ElevatedButton.icon(
                  onPressed: () async {
                    // Abre la configuración de la app en el sistema operativo
                    await openAppSettings();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text("Abrir Configuración"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    // backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),

                const SizedBox(height: 20),

                // Botón para intentar reiniciar el flujo
                // Ahora usa la lógica inteligente para verificar si ya hay permisos
                TextButton(
                  onPressed: () {
                    _checkPermissionsAndNavigate(context);
                  },
                  child: const Text(
                    "Ya activé los permisos, reintentar",
                    style: TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 16,
                    ),
                  ),
                ),
                // const HomeScreen(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
