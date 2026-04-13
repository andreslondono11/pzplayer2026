// import 'package:audio_service/audio_service.dart';
// import 'package:pzplayer/core/audio/audio_service_handler.dart';

// class AudioServiceManager {
//   static Future<AudioHandler> createHandler() async {
//     return await AudioService.init(
//       builder: () => AudioServiceHandler(),
//       config: const AudioServiceConfig(
//         androidNotificationChannelId: 'com.pzplayer.co.pzplayer',
//         androidNotificationChannelName: 'PZ Player',
//         androidNotificationOngoing: true,
//         androidNotificationIcon:
//             'drawable/ic_notification', // ícono en res/drawable
//         androidShowNotificationBadge: false,
//       ),
//     );
//   }
// }
// import 'package:audio_service/audio_service.dart';
// import 'package:pzplayer/core/audio/audio_service_handler.dart';

// class AudioServiceManager {
//   static Future<AudioHandler> createHandler() async {
//     return await AudioService.init(
//       builder: () => AudioServiceHandler(),
//       config: const AudioServiceConfig(
//         // Cambiamos el ID a uno más genérico de canal de audio para evitar conflictos
//         androidNotificationChannelId: 'com.pzplayer.co.pzplayer.audio',
//         androidNotificationChannelName: 'PZ Player Playback',
//         androidNotificationOngoing: true,
//         // Asegúrate de que este ícono exista en android/app/src/main/res/drawable/ic_notification.png
//         androidNotificationIcon: 'drawable/ic_notification',
//         androidShowNotificationBadge: false,
//         // Esta línea permite que al tocar la notificación se abra tu MainActivity corregida
//         androidStopForegroundOnPause: true,
//       ),
//     );
//   }
// }
import 'package:audio_service/audio_service.dart';
import 'package:pzplayer/core/audio/audio_service_handler.dart';

class AudioServiceManager {
  static Future<AudioHandler> createHandler() async {
    return await AudioService.init(
      builder: () => AudioServiceHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.pzplayer.co.pzplayer.audio',
        androidNotificationChannelName: 'PZ Player Playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/ic_notification',
        androidShowNotificationBadge: false,

        // HABILITAMOS EL CLICK
        androidNotificationClickStartsActivity: true,

        // --- ELIMINA ESTA LÍNEA O COMÉNTALA ---
        // androidNotificationActivityClass: 'com.pzplayer.co.pzplayer.MainActivity',
        // ----------------------------------------------------
        androidStopForegroundOnPause: true,
      ),
    );
  }
}
