import 'package:audio_service/audio_service.dart';
import 'package:pzplayer/core/audio/audio_service_handler.dart';

class AudioServiceManager {
  static Future<AudioHandler> createHandler() async {
    return await AudioService.init(
      builder: () => AudioServiceHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.pzplayer.co.pzplayer',
        androidNotificationChannelName: 'PZ Player',
        androidNotificationOngoing: true,
        androidNotificationIcon:
            'drawable/ic_notification', // ícono en res/drawable
        androidShowNotificationBadge: false,
      ),
    );
  }
}
