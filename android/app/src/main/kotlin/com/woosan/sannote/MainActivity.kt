package com.woosan.sannote

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import androidx.core.app.NotificationCompat
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
                    // 기록을 종료하는 걸 잊었을 때 깨워주는 알림. 문구는 Dart가 정한다.
                    "showReminder" -> {
                        showReminder(call.argument<String>("title") ?: "", call.argument<String>("body") ?: "")
                        result.success(null)
                    }
                    "cancelReminder" -> {
                        notificationManager().cancel(REMINDER_NOTIFICATION_ID)
                        result.success(null)
                    }
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

    private fun notificationManager() =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    /// 기록 중임을 다시 알리는 알림. 포그라운드 서비스 알림(geolocator, 상시 표시)과 별개로,
    /// 소리·진동이 있는 일반 알림이라 화면을 안 보고 있어도 알아챌 수 있다. 사용자가 지울 수 있다.
    private fun showReminder(title: String, body: String) {
        val nm = notificationManager()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(REMINDER_CHANNEL_ID, "산책 기록 확인", NotificationManager.IMPORTANCE_DEFAULT).apply {
                    description = "기록을 켜둔 채 잊었을 때 알려줍니다"
                },
            )
        }
        // 탭하면 앱으로 (종료는 앱에서 누른다)
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val n = NotificationCompat.Builder(this, REMINDER_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_sannote)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        nm.notify(REMINDER_NOTIFICATION_ID, n)
    }

    private companion object {
        // 플러그인들이 쓰는 코드와 겹치지 않는 값
        const val NOTIFICATION_PERMISSION_REQUEST = 4001
        const val REMINDER_NOTIFICATION_ID = 4101
        const val REMINDER_CHANNEL_ID = "sannote_reminder"
    }
}
