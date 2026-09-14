package com.example.comprehensive_hr_and_ops

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
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
                when (call.method) {
                    "saveToDownloads" -> {
                        val fileName = call.argument<String>("fileName")
                        val bytes = call.argument<ByteArray>("bytes")
                        val mimeType = call.argument<String>("mimeType") ?: "application/pdf"
                        if (fileName.isNullOrBlank() || bytes == null) {
                            result.error("INVALID_ARGS", "fileName and bytes are required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(saveToDownloads(fileName, bytes, mimeType))
                        } catch (e: Exception) {
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "error" to (e.message ?: "MediaStore save failed"),
                                ),
                            )
                        }
                    }
                    // Mirrors OUM_SECURITY_NEW: save PDF then return uri/filePath for openPdf.
                    "savePdfToDownloads" -> {
                        val fileName = call.argument<String>("fileName")
                        val bytes = call.argument<ByteArray>("bytes")
                        if (fileName.isNullOrBlank() || bytes == null) {
                            result.error("INVALID_ARGS", "fileName and bytes are required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(
                                savePdfToDownloads(fileName, bytes),
                            )
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    "openPdf" -> {
                        val uriString = call.argument<String>("uri")
                        val filePath = call.argument<String>("filePath")
                        try {
                            openPdf(uriString, filePath)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveToDownloads(
        fileName: String,
        bytes: ByteArray,
        mimeType: String,
    ): Map<String, Any?> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveViaMediaStore(fileName, bytes, mimeType, subFolder = null)
        } else {
            saveViaLegacyDownloadDir(fileName, bytes, subFolder = null)
        }
    }

    /** OUM-style PDF save into Downloads/HROps. */
    private fun savePdfToDownloads(
        fileName: String,
        bytes: ByteArray,
    ): Map<String, String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val saved = saveViaMediaStore(
                fileName,
                bytes,
                "application/pdf",
                subFolder = "HROps",
            )
            if (saved["success"] != true) {
                throw IllegalStateException(
                    (saved["error"] as? String) ?: "Could not save PDF",
                )
            }
            mapOf(
                "uri" to (saved["uri"] as? String).orEmpty(),
                "displayName" to fileName,
                "folder" to "Downloads/HROps",
            )
        } else {
            val saved = saveViaLegacyDownloadDir(fileName, bytes, subFolder = "HROps")
            if (saved["success"] != true) {
                throw IllegalStateException(
                    (saved["error"] as? String) ?: "Could not save PDF",
                )
            }
            mapOf(
                "uri" to (saved["uri"] as? String).orEmpty(),
                "filePath" to (saved["path"] as? String).orEmpty(),
                "displayName" to fileName,
                "folder" to "Downloads/HROps",
            )
        }
    }

    private fun saveViaMediaStore(
        fileName: String,
        bytes: ByteArray,
        mimeType: String,
        subFolder: String?,
    ): Map<String, Any?> {
        val resolver = applicationContext.contentResolver
        val uniqueName = uniqueDisplayName(fileName, subFolder)
        val relativePath = if (subFolder.isNullOrBlank()) {
            Environment.DIRECTORY_DOWNLOADS
        } else {
            Environment.DIRECTORY_DOWNLOADS + "/" + subFolder
        }

        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, uniqueName)
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
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
            "path" to "$relativePath/$uniqueName",
        )
    }

    private fun saveViaLegacyDownloadDir(
        fileName: String,
        bytes: ByteArray,
        subFolder: String?,
    ): Map<String, Any?> {
        val downloads = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS,
        )
        val folder = if (subFolder.isNullOrBlank()) {
            downloads
        } else {
            File(downloads, subFolder)
        }
        if (!folder.exists() && !folder.mkdirs()) {
            return mapOf(
                "success" to false,
                "error" to "Could not access Downloads folder.",
            )
        }

        var target = File(folder, fileName)
        var counter = 1
        val base = fileName.substringBeforeLast('.', fileName)
        val ext = if (fileName.contains('.')) fileName.substringAfterLast('.') else "pdf"
        while (target.exists()) {
            target = File(folder, "$base ($counter).$ext")
            counter++
        }

        FileOutputStream(target).use { it.write(bytes) }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, target.name)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
            put(MediaStore.MediaColumns.DATA, target.absolutePath)
        }
        val uri = contentResolver.insert(MediaStore.Files.getContentUri("external"), values)
            ?: FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                target,
            )

        return mapOf(
            "success" to true,
            "path" to target.absolutePath,
            "uri" to uri.toString(),
        )
    }

    private fun openPdf(uriString: String?, filePath: String?) {
        val uri: Uri = when {
            !uriString.isNullOrBlank() -> Uri.parse(uriString)
            !filePath.isNullOrBlank() -> {
                val file = File(filePath)
                FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            }
            else -> throw IllegalArgumentException("uri or filePath required")
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/pdf")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val chooser = Intent.createChooser(intent, "Open PDF").apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Grant read permission to all apps that can handle the chooser.
        val resInfoList = packageManager.queryIntentActivities(
            intent,
            android.content.pm.PackageManager.MATCH_DEFAULT_ONLY,
        )
        for (resolveInfo in resInfoList) {
            grantUriPermission(
                resolveInfo.activityInfo.packageName,
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        }

        try {
            startActivity(chooser)
        } catch (e: android.content.ActivityNotFoundException) {
            throw IllegalStateException("No PDF viewer app is installed", e)
        }
    }

    private fun uniqueDisplayName(fileName: String, subFolder: String?): String {
        val resolver = applicationContext.contentResolver
        val base = fileName.substringBeforeLast('.', fileName)
        val ext = if (fileName.contains('.')) fileName.substringAfterLast('.') else "pdf"
        var candidate = fileName
        var counter = 1
        val relativePath = if (subFolder.isNullOrBlank()) {
            Environment.DIRECTORY_DOWNLOADS
        } else {
            Environment.DIRECTORY_DOWNLOADS + "/" + subFolder
        }

        while (true) {
            val cursor = resolver.query(
                MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY),
                arrayOf(MediaStore.Downloads._ID),
                "${MediaStore.Downloads.DISPLAY_NAME}=? AND ${MediaStore.Downloads.RELATIVE_PATH}=?",
                arrayOf(candidate, "$relativePath/"),
                null,
            )
            val exists = cursor?.use { it.moveToFirst() } == true
            if (!exists) return candidate
            candidate = "$base ($counter).$ext"
            counter++
        }
    }
}
