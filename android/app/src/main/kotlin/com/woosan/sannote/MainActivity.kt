package com.woosan.sannote

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /// 알림 권한 요청 결과를 기다리는 Dart 호출 (동시에 하나만)
    private var notificationPermissionResult: MethodChannel.Result? = null

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
        // 기록 중 상시 알림(포그라운드 서비스)이 화면에 보이려면 Android 13+ 에서 알림 권한이 필요하다.
        // 권한이 없어도 서비스와 기록 자체는 동작한다 — 알림만 안 보인다.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sannote/notifications")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(hasNotificationPermission())
                    "ensurePermission" -> ensureNotificationPermission(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasNotificationPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    private fun ensureNotificationPermission(result: MethodChannel.Result) {
        if (hasNotificationPermission()) {
            result.success(true)
            return
        }
        // 이미 요청 중이면 팝업을 겹치지 않는다
        if (notificationPermissionResult != null) {
            result.success(false)
            return
        }
        notificationPermissionResult = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != NOTIFICATION_PERMISSION_REQUEST) return
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        notificationPermissionResult?.success(granted)
        notificationPermissionResult = null
    }

    private companion object {
        // 플러그인들이 쓰는 코드와 겹치지 않는 값
        const val NOTIFICATION_PERMISSION_REQUEST = 4001
    }
}
