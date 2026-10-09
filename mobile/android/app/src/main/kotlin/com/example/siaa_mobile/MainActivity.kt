package com.example.siaa_mobile

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: requerida por local_auth para el diálogo biométrico (US-AUT-06).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val integridad = IntegridadChannel(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, IntegridadChannel.CANAL)
            .setMethodCallHandler(integridad)
    }
}
