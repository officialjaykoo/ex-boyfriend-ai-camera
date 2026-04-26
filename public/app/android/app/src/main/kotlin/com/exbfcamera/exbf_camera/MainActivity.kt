package com.exbfcamera.exbf_camera

import android.content.Intent
import android.provider.MediaStore
import android.view.KeyEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(VolumeButtonPlugin())
        flutterEngine.plugins.add(NativeCameraPlugin())
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "exbf_camera/gallery")
            .setMethodCallHandler { call, result ->
                if (call.method == "openGallery") {
                    openGallery()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                VolumeButtonPlugin.sendVolumeEvent(true)
                true
            }
            KeyEvent.KEYCODE_VOLUME_UP -> {
                VolumeButtonPlugin.sendVolumeEvent(false)
                true
            }
            else -> super.onKeyDown(keyCode, event)
        }
    }

    private fun openGallery() {
        val samsungGalleryIntent = packageManager.getLaunchIntentForPackage("com.sec.android.gallery3d")?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val galleryIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_APP_GALLERY)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val fallbackIntent = Intent(Intent.ACTION_VIEW, MediaStore.Images.Media.EXTERNAL_CONTENT_URI).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        try {
            startActivity(samsungGalleryIntent ?: galleryIntent)
        } catch (_: Exception) {
            startActivity(fallbackIntent)
        }
    }
}
