// package com.pzplayer.co.pzplayer.widget

// import android.app.PendingIntent
// import android.appwidget.AppWidgetManager
// import android.content.ComponentName
// import android.content.Context
// import android.content.Intent
// import android.content.SharedPreferences
// import android.graphics.BitmapFactory
// import android.net.Uri
// import android.util.Base64
// import android.view.KeyEvent
// import android.widget.RemoteViews
// import com.pzplayer.co.pzplayer.R
// import es.antonborri.home_widget.HomeWidgetProvider

// class PlayerWidget : HomeWidgetProvider() {

//     /**
//      * Método principal que se ejecuta para dibujar/actualizar el widget.
//      */
//     override fun onUpdate(
//         context: Context,
//         appWidgetManager: AppWidgetManager,
//         appWidgetIds: IntArray,
//         widgetData: SharedPreferences
//     ) {
//         appWidgetIds.forEach { widgetId ->
            
//             // Creamos la vista remota del widget
//             val views = RemoteViews(context.packageName, R.layout.player_widget_layout).apply {
                
//                 // --- 1. ACTUALIZAR TEXTOS ---
//                 setTextViewText(R.id.widget_title, widgetData.getString("title", "PZ Player"))
//                 setTextViewText(R.id.widget_artist, widgetData.getString("artist", "PzStudio"))

//                 // --- 2. ACTUALIZAR ICONO PLAY/PAUSE ---
//                 val isPlaying = widgetData.getBoolean("isPlaying", false)
//                 val iconoRes = if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
//                 setImageViewResource(R.id.btn_play_pause, iconoRes)

//                 // --- 3. CONFIGURAR BOTONES (INTENTS) ---
//                 // Usamos MediaButtons para controlar el audio sin abrir la App
//                 setOnClickPendingIntent(R.id.btn_prev, crearMediaIntent(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS, 0))
//                 setOnClickPendingIntent(R.id.btn_play_pause, crearMediaIntent(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, 1))
//                 setOnClickPendingIntent(R.id.btn_next, crearMediaIntent(context, KeyEvent.KEYCODE_MEDIA_NEXT, 2))

//                 // --- 4. ACTUALIZAR CARÁTULA (IMAGEN) ---
//                 cargarCaratula(widgetData)
//             }

//             // Aplicar los cambios al widget
//             appWidgetManager.updateAppWidget(widgetId, views)
//         }
//     }

//     /**
//      * Función auxiliar para crear los Intents de control multimedia.
//      * Envía señales directas al servicio de audio (AudioService).
//      */
//     private fun crearMediaIntent(context: Context, keyCode: Int, requestId: Int): PendingIntent {
//         val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
//             // Apuntamos al receptor definido en el Manifest de audio_service
//             component = ComponentName(
//                 context.packageName, 
//                 "com.ryanheise.audioservice.MediaButtonReceiver"
//             )
//             // Simulamos la presión de un botón físico
//             putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
//         }
        
//         return PendingIntent.getBroadcast(
//             context, 
//             requestId, 
//             intent, 
//             PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
//         )
//     }

//     /**
//      * Función auxiliar para procesar y mostrar la imagen en Base64.
//      */
//        private fun RemoteViews.cargarCaratula(widgetData: SharedPreferences) {
//         val imagePath = widgetData.getString("imagePath", null)

//         // 🔍 DEPURACIÓN: Imprimimos en consola qué recibimos
//         android.util.Log.d("PlayerWidget", "📥 Datos recibidos. Longitud: ${if (imagePath != null) imagePath.length else 0}")
        
//         if (imagePath == null) {
//             android.util.Log.w("PlayerWidget", "⚠️ 'imagePath' es NULL. Flutter no envió nada.")
//         }

//         if (!imagePath.isNullOrEmpty() && imagePath.startsWith("data:image")) {
//             try {
//                 // Extraer datos puros del Base64
//                 val commaIndex = imagePath.indexOf(',')
//                 if (commaIndex != -1) {
//                     val base64String = imagePath.substring(commaIndex + 1)
//                     val imageBytes = Base64.decode(base64String, Base64.DEFAULT)
//                     val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                    
//                     if (bitmap != null) {
//                         android.util.Log.d("PlayerWidget", "✅ Imagen decodificada y lista para pintar")
//                         setImageViewBitmap(R.id.widget_image, bitmap)
//                     } else {
//                         android.util.Log.e("PlayerWidget", "❌ BitmapFactory devolvió NULL (imagen corrupta)")
//                         setImageViewResource(R.id.widget_image, R.mipmap.ic_launcher)
//                     }
//                 } else {
//                     android.util.Log.e("PlayerWidget", "❌ Formato Base64 inválido (sin coma)")
//                     setImageViewResource(R.id.widget_image, R.mipmap.ic_launcher)
//                 }
//             } catch (e: Exception) {
//                 android.util.Log.e("PlayerWidget", "❌ Error al decodificar: ${e.message}")
//                 setImageViewResource(R.id.widget_image, R.mipmap.ic_launcher)
//             }
//         } else {
//             android.util.Log.w("PlayerWidget", "⚠️ No hay datos válidos o no empieza con 'data:image'")
//             // Si no hay datos de imagen, mostrar icono por defecto
//             setImageViewResource(R.id.widget_image, R.mipmap.ic_launcher)
//         }
//     }

//     /**
//      * Receiver vacío ya que la lógica la manejan los Intents directamente
//      * hacia el servicio de audio.
//      */
//     override fun onReceive(context: Context, intent: Intent) {
//         super.onReceive(context, intent)
//     }
// }
package com.pzplayer.co.pzplayer.widget
import android.net.Uri
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.util.Base64
import android.view.KeyEvent
import android.widget.RemoteViews
import com.pzplayer.co.pzplayer.R
import com.pzplayer.co.pzplayer.MainActivity
import es.antonborri.home_widget.HomeWidgetProvider

class PlayerWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val currentSongId = widgetData.getString("id", null)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.player_widget_layout).apply {
                
                setTextViewText(R.id.widget_title, widgetData.getString("title", "PZ Player"))
                setTextViewText(R.id.widget_artist, widgetData.getString("artist", "PzStudio"))

                val isPlaying = widgetData.getBoolean("isPlaying", false)
                val iconoRes = if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
                setImageViewResource(R.id.btn_play_pause, iconoRes)

                // IDs únicos para evitar conflictos en el sistema
                setOnClickPendingIntent(R.id.btn_prev, crearMediaIntent(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS, 201))
                setOnClickPendingIntent(R.id.btn_play_pause, crearMediaIntent(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, 202))
                setOnClickPendingIntent(R.id.btn_next, crearMediaIntent(context, KeyEvent.KEYCODE_MEDIA_NEXT, 203))

                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_MAIN
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    putExtra("WIDGET_SONG_ID", currentSongId)
                    
                    // Si es un archivo externo, le pasamos la URI para re-validar el permiso
                    if (currentSongId != null && (currentSongId.contains("content://") || currentSongId.startsWith("msf:"))) {
                        data = Uri.parse(currentSongId)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                
                val pendingOpenApp = PendingIntent.getActivity(
                    context, 10, openAppIntent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_image, pendingOpenApp)

                cargarCaratula(widgetData)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun crearMediaIntent(context: Context, keyCode: Int, requestId: Int): PendingIntent {
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            component = ComponentName(context.packageName, "com.ryanheise.audioservice.MediaButtonReceiver")
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        }
        return PendingIntent.getBroadcast(context, requestId, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    private fun RemoteViews.cargarCaratula(widgetData: SharedPreferences) {
        val imagePath = widgetData.getString("imagePath", null)
        if (!imagePath.isNullOrEmpty() && imagePath.startsWith("data:image")) {
            try {
                val base64String = imagePath.substring(imagePath.indexOf(',') + 1)
                val imageBytes = Base64.decode(base64String, Base64.DEFAULT)
                val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                if (bitmap != null) {
                    setImageViewBitmap(R.id.widget_image, bitmap)
                    return
                }
            } catch (e: Exception) {}
        }
        setImageViewResource(R.id.widget_image, R.mipmap.ic_launcher)
    }
}