package com.woosan.sannote

import android.content.Context
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 개발용 배터리 % 조회 (기록 시작/종료 로그). 패키지 없이 최소 구현.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sannote/battery")
            .setMethodCallHandler { call, result ->
                if (call.method == "level") {
                    val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                    result.success(bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY))
                } else {
                    result.notImplemented()
                }
            }
    }
}
