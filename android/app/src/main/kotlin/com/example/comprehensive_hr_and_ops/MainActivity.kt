package com.example.comprehensive_hr_and_ops

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "com.comprehensive_hr_and_ops/media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveToDownloads") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val fileName = call.argument<String>("fileName")
                val bytes = call.argument<ByteArray>("bytes")
                val mimeType = call.argument<String>("mimeType") ?: "application/pdf"

                if (fileName.isNullOrBlank() || bytes == null) {
                    result.error("INVALID_ARGS", "fileName and bytes are required", null)
                    return@setMethodCallHandler
                }

                try {
                    val saved = saveToDownloads(fileName, bytes, mimeType)
                    result.success(saved)
                } catch (e: Exception) {
                    result.success(
                        mapOf(
                            "success" to false,
                            "error" to (e.message ?: "MediaStore save failed"),
                        ),
                    )
                }
            }
    }

    private fun saveToDownloads(
        fileName: String,
        bytes: ByteArray,
        mimeType: String,
    ): Map<String, Any?> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveViaMediaStore(fileName, bytes, mimeType)
        } else {
            saveViaLegacyDownloadDir(fileName, bytes)
        }
    }

    private fun saveViaMediaStore(
        fileName: String,
        bytes: ByteArray,
        mimeType: String,
    ): Map<String, Any?> {
        val resolver = applicationContext.contentResolver
        val uniqueName = uniqueDisplayName(fileName)

        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, uniqueName)
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = resolver.insert(collection, values)
            ?: return mapOf(
                "success" to false,
                "error" to "Could not create MediaStore Downloads entry.",
            )

        resolver.openOutputStream(uri)?.use { output ->
            output.write(bytes)
            output.flush()
        } ?: return mapOf(
            "success" to false,
            "error" to "Could not open MediaStore output stream.",
        )

        values.clear()
        values.put(MediaStore.Downloads.IS_PENDING, 0)
        resolver.update(uri, values, null, null)

        return mapOf(
            "success" to true,
            "uri" to uri.toString(),
            "path" to "${Environment.DIRECTORY_DOWNLOADS}/$uniqueName",
        )
    }

    private fun saveViaLegacyDownloadDir(
        fileName: String,
        bytes: ByteArray,
    ): Map<String, Any?> {
        val downloads = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS,
        )
        if (!downloads.exists() && !downloads.mkdirs()) {
            return mapOf(
                "success" to false,
                "error" to "Could not access Downloads folder.",
            )
        }

        var target = File(downloads, fileName)
        var counter = 1
        val base = fileName.substringBeforeLast('.', fileName)
        val ext = if (fileName.contains('.')) fileName.substringAfterLast('.') else "pdf"
        while (target.exists()) {
            target = File(downloads, "$base ($counter).$ext")
            counter++
        }

        FileOutputStream(target).use { it.write(bytes) }
        return mapOf(
            "success" to true,
            "path" to target.absolutePath,
        )
    }

    private fun uniqueDisplayName(fileName: String): String {
        val resolver = applicationContext.contentResolver
        val base = fileName.substringBeforeLast('.', fileName)
        val ext = if (fileName.contains('.')) fileName.substringAfterLast('.') else "pdf"
        var candidate = fileName
        var counter = 1

        while (true) {
            val cursor = resolver.query(
                MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY),
                arrayOf(MediaStore.Downloads._ID),
                "${MediaStore.Downloads.DISPLAY_NAME}=?",
                arrayOf(candidate),
                null,
            )
            val exists = cursor?.use { it.moveToFirst() } == true
            if (!exists) return candidate
            candidate = "$base ($counter).$ext"
            counter++
        }
    }
}
