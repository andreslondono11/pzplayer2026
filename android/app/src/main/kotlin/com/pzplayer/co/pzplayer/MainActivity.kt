
// package com.pzplayer.co.pzplayer

// import android.content.Intent
// import androidx.annotation.NonNull
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodChannel
// import com.ryanheise.audioservice.AudioServiceActivity

// class MainActivity: AudioServiceActivity() {
    
//     private val CHANNEL = "com.pzplayer.co.pzplayer/widget_comm"

//     override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
//         // 1. IMPORTANTE: Primero llamamos al super para que el plugin de audio registre sus cosas
//         super.configureFlutterEngine(flutterEngine)

//         // 2. Luego registramos nuestro canal para el Widget
//         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
//             if (call.method == "getInitialIntent") {
//                 // Obtenemos los datos que vienen del Intent del Widget
//                 val songId = intent.getStringExtra("WIDGET_SONG_ID")
//                 val keyCode = intent.getIntExtra("WIDGET_KEY_CODE", -1)

//                 if (songId != null) {
//                     result.success(mapOf(
//                         "WIDGET_SONG_ID" to songId,
//                         "WIDGET_KEY_CODE" to keyCode
//                     ))
//                 } else {
//                     result.success(null)
//                 }
//             } else {
//                 result.notImplemented()
//             }
//         }
//     }

//     // Esto permite que si la app está abierta y tocas el widget, los datos se actualicen
//     override fun onNewIntent(intent: Intent) {
//         super.onNewIntent(intent)
//         setIntent(intent)
//     }
// }
package com.pzplayer.co.pzplayer

import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import com.ryanheise.audioservice.AudioServiceActivity // <--- IMPORTANTE: Importar esto

// DEBE EXTENDER DE AudioServiceActivity, NO de FlutterActivity
class MainActivity : AudioServiceActivity() {
    
    private val CHANNEL = "com.pzplayer.co.pzplayer/intent_data"
    private var eventSink: EventChannel.EventSink? = null

    // Usamos configureFlutterEngine en lugar de onCreate para mayor estabilidad
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    // Enviar el intent actual inmediatamente al conectar
                    intent?.let { handleIntent(it) }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val uri: Uri? = intent.data
        if (uri != null) {
            try {
                // Lógica de permisos que ya tenías
                val takeFlags: Int = Intent.FLAG_GRANT_READ_URI_PERMISSION
                contentResolver.takePersistableUriPermission(uri, takeFlags)
            } catch (e: Exception) {
                // Ignorar error si no se puede persistir
            }
            // Enviar la URI a Dart
            eventSink?.success(uri.toString())
        }
    }
}