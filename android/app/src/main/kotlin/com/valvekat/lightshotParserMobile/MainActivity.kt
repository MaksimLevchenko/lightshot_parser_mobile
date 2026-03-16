package com.valvekat.lightshotParserMobile

import android.content.ContentValues
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.valvekat.lightshotParserMobile/downloads"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidSdkInt" -> result.success(Build.VERSION.SDK_INT)
                "saveImageToDownloads" -> saveImageToDownloads(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun saveImageToDownloads(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        val fileName = call.argument<String>("fileName")

        if (sourcePath.isNullOrBlank() || fileName.isNullOrBlank()) {
            result.error("bad-args", "Missing sourcePath or fileName.", null)
            return
        }

        val sourceFile = File(sourcePath)
        if (!sourceFile.exists()) {
            result.error("source-missing", "Source file does not exist.", null)
            return
        }

        try {
            val savedPath = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveWithMediaStore(sourceFile, fileName)
            } else {
                saveToLegacyDownloads(sourceFile, fileName)
            }
            result.success(savedPath)
        } catch (error: SecurityException) {
            result.error("permission-denied", error.message, null)
        } catch (error: Exception) {
            result.error("save-failed", error.message, null)
        }
    }

    private fun saveWithMediaStore(sourceFile: File, fileName: String): String {
        val resolver = applicationContext.contentResolver
        val downloadsUri = MediaStore.Downloads.EXTERNAL_CONTENT_URI
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, "image/*")
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val itemUri = resolver.insert(downloadsUri, values)
            ?: throw IllegalStateException("Unable to create MediaStore record.")

        resolver.openOutputStream(itemUri)?.use { output ->
            FileInputStream(sourceFile).use { input ->
                input.copyTo(output)
            }
        } ?: throw IllegalStateException("Unable to open output stream.")

        values.clear()
        values.put(MediaStore.Downloads.IS_PENDING, 0)
        resolver.update(itemUri, values, null, null)

        return "${Environment.getExternalStorageDirectory().path}/${Environment.DIRECTORY_DOWNLOADS}/$fileName"
    }

    private fun saveToLegacyDownloads(sourceFile: File, fileName: String): String {
        val permissionState = ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.WRITE_EXTERNAL_STORAGE
        )
        if (permissionState != PackageManager.PERMISSION_GRANTED) {
            throw SecurityException("WRITE_EXTERNAL_STORAGE permission is required.")
        }

        val downloadDir = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS
        )
        if (!downloadDir.exists()) {
            downloadDir.mkdirs()
        }

        val targetFile = File(downloadDir, fileName)
        FileInputStream(sourceFile).use { input ->
            FileOutputStream(targetFile).use { output ->
                input.copyTo(output)
            }
        }

        return targetFile.absolutePath
    }
}
