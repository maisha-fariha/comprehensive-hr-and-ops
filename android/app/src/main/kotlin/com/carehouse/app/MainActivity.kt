package com.carehouse.app

import android.Manifest
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val channelName = "com.comprehensive_hr_and_ops/media_store"
    private val captureRequestCode = 0x4341
    private val cameraPermissionRequestCode = 0x4342
    private var captureResult: MethodChannel.Result? = null
    private var captureFile: File? = null
    private var pendingCaptureFront: Boolean? = null

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
                            openFile(uriString, filePath, "application/pdf", "Open PDF")
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    }
                    "openFile" -> {
                        val uriString = call.argument<String>("uri")
                        val filePath = call.argument<String>("filePath")
                        val mimeType =
                            call.argument<String>("mimeType") ?: "application/octet-stream"
                        val chooserTitle = call.argument<String>("chooserTitle") ?: "Open file"
                        try {
                            openFile(uriString, filePath, mimeType, chooserTitle)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    }
                    "captureImage" -> launchCapture(
                        front = call.argument<Boolean>("front") == true,
                        result = result,
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun launchCapture(front: Boolean, result: MethodChannel.Result) {
        if (captureResult != null || pendingCaptureFront != null) {
            result.error("already_active", "Camera is already open.", null)
            return
        }
        // The app declares CAMERA. Android blocks the camera intent when that
        // permission is revoked, which is the denial shown on Take photo.
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
            != PackageManager.PERMISSION_GRANTED
        ) {
            captureResult = result
            pendingCaptureFront = front
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CAMERA),
                cameraPermissionRequestCode,
            )
            return
        }
        startCamera(front, result)
    }

    @Deprecated("Camera permission is delivered through the activity result path.")
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (requestCode == cameraPermissionRequestCode) {
            val result = captureResult
            val front = pendingCaptureFront == true
            pendingCaptureFront = null
            captureResult = null
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            if (result != null) {
                if (granted) {
                    startCamera(front, result)
                } else {
                    result.error(
                        "camera_access_denied",
                        "Allow camera access in Settings, then try again.",
                        null,
                    )
                }
            }
        }
        @Suppress("DEPRECATION")
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    private fun startCamera(front: Boolean, result: MethodChannel.Result) {
        val file = try {
            File.createTempFile("capture_", ".jpg", cacheDir)
        } catch (e: Exception) {
            result.error("CAPTURE_FAILED", "The photo could not be saved. Please try again.", null)
            return
        }
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, uri)
            clipData = ClipData.newRawUri("", uri)
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
            if (front) {
                // CameraInfo.CAMERA_FACING_FRONT is 1. Lens facing constants are the reverse.
                putExtra("android.intent.extras.CAMERA_FACING", 1)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    putExtra("android.intent.extra.USE_FRONT_CAMERA", true)
                }
            }
        }
        val cameras = packageManager.queryIntentActivities(
            intent,
            PackageManager.MATCH_DEFAULT_ONLY,
        )
        if (cameras.isEmpty()) {
            file.delete()
            result.error("no_available_camera", "No cameras available for taking pictures.", null)
            return
        }
        for (info in cameras) {
            grantUriPermission(
                info.activityInfo.packageName,
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        }
        captureFile = file
        captureResult = result
        try {
            @Suppress("DEPRECATION")
            startActivityForResult(intent, captureRequestCode)
        } catch (e: Exception) {
            captureResult = null
            captureFile = null
            file.delete()
            val denied = e is SecurityException
            result.error(
                if (denied) "camera_access_denied" else "CAPTURE_FAILED",
                if (denied) {
                    "Allow camera access in Settings, then try again."
                } else {
                    e.message ?: "Camera unavailable"
                },
                null,
            )
        }
    }

    @Deprecated("Camera result is delivered through the activity result path.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == captureRequestCode) {
            val result = captureResult
            val file = captureFile
            captureResult = null
            captureFile = null
            if (result != null) {
                if (resultCode != RESULT_OK) {
                    file?.delete()
                    result.success(null)
                } else if (file == null || !file.exists() || file.length() == 0L) {
                    file?.delete()
                    result.error(
                        "CAPTURE_FAILED",
                        "The photo could not be saved. Please try again.",
                        null,
                    )
                } else {
                    thread {
                        try {
                            val path = downscaleCapturedJpeg(file)
                            runOnUiThread { result.success(path) }
                        } catch (e: Exception) {
                            file.delete()
                            runOnUiThread {
                                result.error(
                                    "CAPTURE_FAILED",
                                    e.message ?: "The photo could not be saved. Please try again.",
                                    null,
                                )
                            }
                        }
                    }
                }
            }
        }
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun downscaleCapturedJpeg(source: File): String {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(source.absolutePath, bounds)
        val longest = maxOf(bounds.outWidth, bounds.outHeight)
        if (longest <= 0) return source.absolutePath
        var sample = 1
        while (longest / sample > 3200) sample *= 2
        val decoded = BitmapFactory.decodeFile(
            source.absolutePath,
            BitmapFactory.Options().apply { inSampleSize = sample },
        ) ?: return source.absolutePath
        val oriented = applyExifOrientation(source, decoded)
        val edge = maxOf(oriented.width, oriented.height).coerceAtLeast(1)
        val bitmap = if (edge > 1600) {
            val scale = 1600f / edge
            Bitmap.createScaledBitmap(
                oriented,
                (oriented.width * scale).toInt().coerceAtLeast(1),
                (oriented.height * scale).toInt().coerceAtLeast(1),
                true,
            ).also { if (it != oriented) oriented.recycle() }
        } else {
            oriented
        }
        val out = File(cacheDir, "capture_${System.currentTimeMillis()}.jpg")
        FileOutputStream(out).use { bitmap.compress(Bitmap.CompressFormat.JPEG, 85, it) }
        bitmap.recycle()
        if (out.absolutePath != source.absolutePath) source.delete()
        return out.absolutePath
    }

    private fun applyExifOrientation(source: File, bitmap: Bitmap): Bitmap {
        val orientation = try {
            ExifInterface(source.absolutePath).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )
        } catch (_: Exception) {
            return bitmap
        }
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.preScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.preScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.postRotate(90f)
                matrix.preScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.postRotate(270f)
                matrix.preScale(-1f, 1f)
            }
            else -> return bitmap
        }
        val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        if (rotated != bitmap) bitmap.recycle()
        return rotated
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

    private fun openFile(
        uriString: String?,
        filePath: String?,
        mimeType: String,
        chooserTitle: String,
    ) {
        val uri: Uri = when {
            !uriString.isNullOrBlank() -> Uri.parse(uriString)
            !filePath.isNullOrBlank() -> {
                val file = File(filePath)
                if (!file.exists()) {
                    throw IllegalArgumentException("File not found: $filePath")
                }
                FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            }
            else -> throw IllegalArgumentException("uri or filePath required")
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val chooser = Intent.createChooser(intent, chooserTitle).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

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
            throw IllegalStateException("No app is installed to open this file", e)
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
