package com.kkfc.pos

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kkfc.pos/app_updates")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installedBuildNumber" -> {
                        @Suppress("DEPRECATION")
                        val info = packageManager.getPackageInfo(packageName, 0)
                        val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            info.longVersionCode
                        } else {
                            @Suppress("DEPRECATION")
                            info.versionCode.toLong()
                        }
                        result.success(code)
                    }
                    "openUpdateDownload" -> {
                        val uri = call.argument<String>("url")?.let { Uri.parse(it) }
                        if (uri == null || uri.scheme != "https" || uri.host != "github.com" ||
                            !uri.path.orEmpty().contains("/releases/download/") ||
                            !uri.path.orEmpty().endsWith("/kkfc-pos.apk")) {
                            result.success(false)
                        } else {
                            try {
                                startActivity(Intent(Intent.ACTION_VIEW, uri))
                                result.success(true)
                            } catch (_: ActivityNotFoundException) {
                                result.success(false)
                            } catch (_: SecurityException) {
                                result.success(false)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
