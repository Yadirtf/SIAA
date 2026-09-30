package com.example.siaa_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val integridad = IntegridadChannel(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, IntegridadChannel.CANAL)
            .setMethodCallHandler(integridad)
    }
}
