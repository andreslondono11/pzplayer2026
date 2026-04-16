// package com.pzplayer.co.pzplayer

// import android.content.Intent
// import android.net.Uri
// import androidx.annotation.NonNull
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.EventChannel
// import com.ryanheise.audioservice.AudioServiceActivity
// import java.io.File
// import java.io.FileOutputStream

// class MainActivity : AudioServiceActivity() {

//     private val CHANNEL = "com.pzplayer.co.pzplayer/widget_comm"
//     private var eventSink: EventChannel.EventSink? = null

//     override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
//         super.configureFlutterEngine(flutterEngine)
        
//         // Limpiamos archivos antiguos al iniciar para no llenar la memoria
//         cleanOldCacheFiles()

//         EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setStreamHandler(
//             object : EventChannel.StreamHandler {
//                 override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
//                     eventSink = events
//                     intent?.let { handleIntent(it) }
//                 }
//                 override fun onCancel(arguments: Any?) {
//                     eventSink = null
//                 }
//             }
//         )
//     }

//     override fun onNewIntent(intent: Intent) {
//         super.onNewIntent(intent)
//         setIntent(intent)
//         handleIntent(intent)
//     }

//     private fun handleIntent(intent: Intent) {
//         val action = intent.action
//         val uri = intent.data
//         val dataString = intent.dataString
//         val songId = intent.getStringExtra("WIDGET_SONG_ID")
//         val keyCode = intent.getIntExtra("WIDGET_KEY_CODE", -1)

//         if (action == null && uri == null && songId == null) return

//         // Procesamos en segundo plano para no bloquear la UI
//         Thread {
//             try {
//                 val dataMap = mutableMapOf<String, Any?>()
//                 dataMap["action"] = action
                
//                 var finalPath = dataString 

//                 if (uri != null) {
//                     try {
//                         val takeFlags: Int = Intent.FLAG_GRANT_READ_URI_PERMISSION
//                         contentResolver.takePersistableUriPermission(uri, takeFlags)
//                         // Si funciona, mantenemos el URI content://...
//                         println("PZ Player: Permiso universal concedido")
//                     } catch (e: Exception) {
//                         // Si falla, usamos la copia interna segura
//                         val safeFile = copyUriToInternalStorage(uri)
//                         if (safeFile != null) {
//                             finalPath = safeFile.absolutePath
//                             println("PZ Player: Permiso denegado, usando copia interna segura: $finalPath")
//                         }
//                     }
//                 }

//                 dataMap["data"] = finalPath
//                 dataMap["WIDGET_SONG_ID"] = songId
//                 dataMap["WIDGET_KEY_CODE"] = keyCode

//                 runOnUiThread {
//                     eventSink?.success(dataMap)
//                 }
//             } catch (e: Exception) {
//                 runOnUiThread {
//                     eventSink?.error("INTENT_ERROR", e.message, null)
//                 }
//             }
//         }.start()
//     }

//     private fun copyUriToInternalStorage(uri: Uri): File? {
//         return try {
//             contentResolver.openInputStream(uri)?.use { input ->
//                 // ✅ MEJORA CLAVE: Usamos timestamp para crear un nombre ÚNICO.
//                 // Esto evita que se borre el archivo si el usuario abre otro muy rápido.
//                 val timestamp = System.currentTimeMillis()
//                 val tempFileName = "external_track_$timestamp.mp3"
//                 val tempFile = File(cacheDir, tempFileName)
                
//                 FileOutputStream(tempFile).use { output ->
//                     input.copyTo(output)
//                     output.flush()
//                 }
//                 tempFile
//             }
//         } catch (e: Exception) {
//             e.printStackTrace()
//             null
//         }
//     }

//     // ✅ AYUDA: Limpieza opcional para no llenar la memoria del teléfono con archivos antiguos
//     private fun cleanOldCacheFiles() {
//         try {
//             val cacheDir = cacheDir
//             val files = cacheDir.listFiles { _, name -> name.startsWith("external_track_") }
//             // Borramos archivos más viejos de 1 hora para ahorrar espacio
//             val oneHourAgo = System.currentTimeMillis() - (60 * 60 * 1000)
            
//             files?.forEach { file ->
//                 if (file.lastModified() < oneHourAgo) {
//                     file.delete()
//                 }
//             }
//         } catch (e: Exception) {
//             // Ignorar error de limpieza
//         }
//     }
// }


package com.pzplayer.co.pzplayer

import android.content.Intent
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

// ✅ CORRECCIÓN: Usamos la librería nativa de Android
import android.util.Base64

class MainActivity : AudioServiceActivity() {

    private val CHANNEL_INTENT = "com.pzplayer.co.pzplayer/widget_comm"
    private val CHANNEL_METADATA = "com.pzplayer.co.pzplayer/metadata"
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        cleanOldCacheFiles()

        // --- CANAL 1: INTENTS (Tu código actual) ---
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_INTENT).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    intent?.let { handleIntent(it) }
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        // --- CANAL 2: METADATA (Nueva versión robusta) ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_METADATA).setMethodCallHandler { call, result ->
            if (call.method == "getFullMetadata") {
                val path = call.argument<String>("path")
                if (path != null) {
                    val metadata = extractMetadataRobust(path)
                    result.success(metadata)
                } else {
                    result.error("NO_PATH", "Ruta vacía", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val uri = intent.data
        val dataString = intent.dataString
        val songId = intent.getStringExtra("WIDGET_SONG_ID")
        val keyCode = intent.getIntExtra("WIDGET_KEY_CODE", -1)

        if (action == null && uri == null && songId == null) return

        Thread {
            try {
                val dataMap = mutableMapOf<String, Any?>()
                dataMap["action"] = action
                var finalPath = dataString

                if (uri != null) {
                    try {
                        val takeFlags: Int = Intent.FLAG_GRANT_READ_URI_PERMISSION
                        contentResolver.takePersistableUriPermission(uri, takeFlags)
                        println("PZ Player: Permiso universal concedido")
                    } catch (e: Exception) {
                        val safeFile = copyUriToInternalStorage(uri)
                        if (safeFile != null) {
                            finalPath = safeFile.absolutePath
                            println("PZ Player: Copia interna usada: $finalPath")
                        }
                    }
                }

                dataMap["data"] = finalPath
                dataMap["WIDGET_SONG_ID"] = songId
                dataMap["WIDGET_KEY_CODE"] = keyCode

                runOnUiThread {
                    eventSink?.success(dataMap)
                }
            } catch (e: Exception) {
                runOnUiThread {
                    eventSink?.error("INTENT_ERROR", e.message, null)
                }
            }
        }.start()
    }

    private fun copyUriToInternalStorage(uri: Uri): File? {
        return try {
            contentResolver.openInputStream(uri)?.use { input ->
                val timestamp = System.currentTimeMillis()
                val tempFileName = "external_track_$timestamp.mp3"
                val tempFile = File(cacheDir, tempFileName)
                FileOutputStream(tempFile).use { output ->
                    input.copyTo(output)
                    output.flush()
                }
                tempFile
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    // ✅ SOLUCIÓN DEFINITIVA: Extractor Robusto usando FileInputStream
    private fun extractMetadataRobust(path: String): Map<String, Any?> {
        val retriever = MediaMetadataRetriever()
        val file = File(path)
        
        if (!file.exists()) {
            return mapOf("success" to false)
        }

        return try {
            // 🔑 CLAVE: Usamos FileInputStream + FD en lugar de pasar el String path
            val fis = FileInputStream(file)
            retriever.setDataSource(fis.fd)

            // 1. Extraer Título
            var title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
            val artist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST)
            val album = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM)

            // Si no hay título, usamos el nombre del archivo
            if (title.isNullOrEmpty()) {
                title = file.nameWithoutExtension
            }

            // 2. Extraer Imagen
            val picture = retriever.embeddedPicture
            var artBase64: String? = null

            if (picture != null) {
                // Convertimos bytes a Base64 usando la librería CORRECTA de Android
                artBase64 = android.util.Base64.encodeToString(picture, android.util.Base64.NO_WRAP)
            }

            fis.close()
            retriever.release()

            mapOf(
                "success" to true,
                "title" to (title ?: "Desconocido"),
                "artist" to (artist ?: "PZ Player"),
                "album" to (album ?: "Desconocido"),
                "artBase64" to artBase64
            )

        } catch (e: Exception) {
            e.printStackTrace()
            mapOf("success" to false)
        } finally {
            retriever.release()
        }
    }

    private fun cleanOldCacheFiles() {
        try {
            val cacheDir = cacheDir
            val files = cacheDir.listFiles { _, name -> name.startsWith("external_track_") }
            val oneHourAgo = System.currentTimeMillis() - (60 * 60 * 1000)
            files?.forEach { file ->
                if (file.lastModified() < oneHourAgo) {
                    file.delete()
                }
            }
        } catch (e: Exception) {}
    }
}