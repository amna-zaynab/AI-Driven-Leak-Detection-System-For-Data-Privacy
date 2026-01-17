package com.example.privacy_app

import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.privacy_app/permissions"
    private val FILE_CHANNEL = "com.example.privacy_app/files"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getPermissions") {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    try {
                        val pm = applicationContext.packageManager
                        val packageInfo = pm.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)

                        val requestedPermissions = packageInfo.requestedPermissions ?: arrayOf()
                        val grantedPermissions = mutableListOf<String>()

                        packageInfo.requestedPermissionsFlags?.let { flags ->
                            for (i in requestedPermissions.indices) {
                                if ((flags[i] and PackageInfo.REQUESTED_PERMISSION_GRANTED) != 0) {
                                    grantedPermissions.add(requestedPermissions[i])
                                }
                            }
                        }

                        val data = mapOf(
                            "requested" to requestedPermissions.toList(),
                            "granted" to grantedPermissions
                        )
                        result.success(data)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_PACKAGE", "Package name is null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openFile") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    try {
                        val file = File(filePath)
                        if (file.exists()) {
                            val uri = FileProvider.getUriForFile(
                                this,
                                "com.example.privacy_app.fileprovider",
                                file
                            )
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/pdf")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(intent)
                            result.success(null)
                        } else {
                            result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_PATH", "File path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
