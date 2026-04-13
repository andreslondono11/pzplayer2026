package com.pzplayer.co.pzplayer // 👈 CAMBIA ESTO

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri

class PlayerBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Al tocar el widget, abrimos la App
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(launchIntent)
    }
}


