package com.example.lumio

import android.app.KeyguardManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val METHOD_CHANNEL = "lumio/alarm_controls"
        const val ENGINE_ID = "main_engine"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        val km = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            km.requestDismissKeyguard(this, null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Cache engine so AlarmForegroundService can send method calls to Flutter
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)

        // Flutter registers its own handler; Kotlin only invokes, never handles
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startAlarmService" -> {
                        val alarmId = call.argument<Int>("alarmId") ?: 0
                        startAlarmForegroundService(alarmId)
                        result.success(null)
                    }
                    "stopAlarmService" -> {
                        stopAlarmForegroundService()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startAlarmForegroundService(alarmId: Int) {
        val intent = Intent(this, AlarmForegroundService::class.java).apply {
            action = AlarmForegroundService.ACTION_START
            putExtra(AlarmForegroundService.EXTRA_ALARM_ID, alarmId)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopAlarmForegroundService() {
        val intent = Intent(this, AlarmForegroundService::class.java)
        stopService(intent)
    }
}
