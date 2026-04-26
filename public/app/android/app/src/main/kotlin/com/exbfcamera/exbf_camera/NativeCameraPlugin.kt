package com.exbfcamera.exbf_camera

import android.content.Context
import android.app.Activity
import android.graphics.ImageFormat
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build
import android.util.SizeF
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

class NativeCameraPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var analysisChannel: EventChannel
    private lateinit var context: Context
    private lateinit var textures: TextureRegistry
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        textures = binding.textureRegistry
        channel = MethodChannel(binding.binaryMessenger, "exbf_camera/native_camera")
        channel.setMethodCallHandler(this)
        analysisChannel = EventChannel(binding.binaryMessenger, "exbf_camera/native_analysis")
        analysisChannel.setStreamHandler(this)
        binding.platformViewRegistry.registerViewFactory(
            "exbf_camera/native_preview",
            NativeCameraPreviewFactory { activity },
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        analysisChannel.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceCapability" -> result.success(DeviceCapabilityChecker.check(context))
            "runAiBenchmark" -> result.success(NativeCameraEngine.runAiBenchmark())
            "setAiEnabled" -> {
                NativeCameraEngine.setAiEnabled(
                    call.argument<Boolean>("enabled") ?: true,
                    call.argument<String>("reason"),
                    call.argument<String>("delegate"),
                )
                result.success(null)
            }
            "getSensors" -> result.success(getSensors())
            "start" -> {
                NativeCameraEngine.start()
                result.success(null)
            }
            "getState" -> result.success(NativeCameraEngine.state())
            "setCaptureMode" -> {
                NativeCameraEngine.setCaptureMode(call.argument<String>("mode") ?: "photo")
                result.success(null)
            }
            "setAnalysisMode" -> {
                NativeCameraEngine.setAnalysisMode(call.argument<String>("mode"))
                result.success(null)
            }
            "setResolution" -> {
                NativeCameraEngine.setResolution(call.argument<String>("preset") ?: "veryHigh")
                result.success(null)
            }
            "createPreviewTexture" -> {
                val entry = textures.createSurfaceTexture()
                NativeCameraEngine.attachTexture(entry)
                result.success(entry.id())
            }
            "stop" -> {
                NativeCameraEngine.stop()
                result.success(null)
            }
            "switchCamera" -> {
                NativeCameraEngine.switchCamera()
                result.success(null)
            }
            "setSensor" -> {
                NativeCameraEngine.setSensor(call.argument<String>("id"))
                result.success(null)
            }
            "setZoom" -> {
                NativeCameraEngine.setZoom(call.argument<Double>("zoom") ?: 1.0)
                result.success(null)
            }
            "setFlash" -> {
                NativeCameraEngine.setFlash(call.argument<String>("mode") ?: "off")
                result.success(null)
            }
            "setExposure" -> {
                NativeCameraEngine.setExposure(call.argument<Double>("value") ?: 0.0)
                result.success(null)
            }
            "setManualControls" -> {
                NativeCameraEngine.setManualControls(
                    call.argument<Int>("iso"),
                    call.argument<Number>("exposureTimeNs")?.toLong(),
                    call.argument<String>("whiteBalance"),
                )
                result.success(null)
            }
            "setVideoOptions" -> {
                NativeCameraEngine.setVideoOptions(
                    call.argument<Number>("fps")?.toInt(),
                    call.argument<Number>("bitrate")?.toInt(),
                    call.argument<Boolean>("audio"),
                )
                result.success(null)
            }
            "saveImageToGallery" -> {
                result.success(
                    NativeCameraEngine.saveImageToGallery(
                        call.argument<String>("path") ?: "",
                        call.argument<String>("displayName"),
                        call.argument<String>("mimeType"),
                    ),
                )
            }
            "normalizeJpegExif" -> {
                result.success(
                    NativeCameraEngine.normalizeJpegExif(
                        call.argument<String>("path") ?: "",
                    ),
                )
            }
            "focus" -> {
                NativeCameraEngine.focus(
                    call.argument<Double>("x") ?: 0.5,
                    call.argument<Double>("y") ?: 0.5,
                )
                result.success(null)
            }
            "takePhoto" -> NativeCameraEngine.takePhoto(result)
            "toggleVideo" -> NativeCameraEngine.toggleVideo(result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        NativeCameraEngine.setAnalysisSink(events)
    }

    override fun onCancel(arguments: Any?) {
        NativeCameraEngine.setAnalysisSink(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        NativeCameraEngine.attachActivity(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        NativeCameraEngine.attachActivity(binding.activity)
    }

    override fun onDetachedFromActivity() {
        NativeCameraEngine.detachActivity()
        activity = null
    }

    private fun getSensors(): List<Map<String, Any?>> {
        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        return manager.cameraIdList.mapNotNull { cameraId ->
            try {
                val characteristics = manager.getCameraCharacteristics(cameraId)
                val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
                val focalLengths =
                    characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
                        ?: floatArrayOf()
                val physicalSize =
                    characteristics.get(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE)
                val focalLength = focalLengths.minOrNull()
                val equivalent35mm = focalLength?.let {
                    equivalent35mmFocalLength(it, physicalSize)
                }
                val capabilities =
                    characteristics.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)
                        ?: intArrayOf()
                val isLogical = capabilities.contains(
                    CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_LOGICAL_MULTI_CAMERA
                )
                val exposureRange = characteristics.get(
                    CameraCharacteristics.SENSOR_INFO_EXPOSURE_TIME_RANGE,
                )
                val isoRange = characteristics.get(
                    CameraCharacteristics.SENSOR_INFO_SENSITIVITY_RANGE,
                )
                val compensationRange = characteristics.get(
                    CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE,
                )
                val compensationStep = characteristics.get(
                    CameraCharacteristics.CONTROL_AE_COMPENSATION_STEP,
                )
                val zoomRange = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    characteristics.get(CameraCharacteristics.CONTROL_ZOOM_RATIO_RANGE)
                } else {
                    null
                }
                val streamMap = characteristics.get(
                    CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP,
                )
                val maxJpegSize = streamMap
                    ?.getOutputSizes(ImageFormat.JPEG)
                    ?.maxByOrNull { it.width.toLong() * it.height.toLong() }
                val fpsValues = characteristics.get(
                    CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES,
                )
                    ?.flatMap { listOf(it.lower, it.upper) }
                    ?.filter { it == 24 || it == 30 || it == 60 }
                    ?.distinct()
                    ?.sorted()
                    ?: listOf(30)

                mapOf(
                    "id" to cameraId,
                    "position" to positionName(facing),
                    "type" to sensorType(facing, equivalent35mm, isLogical),
                    "hardwareLevel" to hardwareLevelName(
                        characteristics.get(CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL),
                    ),
                    "focalLength" to focalLength,
                    "equivalent35mm" to equivalent35mm,
                    "flashAvailable" to (
                        characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) ?: false
                    ),
                    "isLogical" to isLogical,
                    "manualSensor" to capabilities.contains(
                        CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_MANUAL_SENSOR,
                    ),
                    "manualPostProcessing" to capabilities.contains(
                        CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_MANUAL_POST_PROCESSING,
                    ),
                    "raw" to capabilities.contains(
                        CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_RAW,
                    ),
                    "minIso" to isoRange?.lower,
                    "maxIso" to isoRange?.upper,
                    "minExposureTimeNs" to exposureRange?.lower,
                    "maxExposureTimeNs" to exposureRange?.upper,
                    "minExposureCompensation" to compensationRange?.lower,
                    "maxExposureCompensation" to compensationRange?.upper,
                    "exposureCompensationStep" to compensationStep?.toDouble(),
                    "minZoomRatio" to zoomRange?.lower?.toDouble(),
                    "maxZoomRatio" to zoomRange?.upper?.toDouble(),
                    "maxDigitalZoom" to (
                        characteristics.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM)
                            ?: 1f
                        ).toDouble(),
                    "supportedFps" to fpsValues,
                    "supportedResolutionPresets" to supportedResolutionPresets(maxJpegSize?.width),
                    "maxJpegWidth" to maxJpegSize?.width,
                    "maxJpegHeight" to maxJpegSize?.height,
                )
            } catch (_: Exception) {
                null
            }
        }
    }

    private fun equivalent35mmFocalLength(focalLength: Float, physicalSize: SizeF?): Double? {
        val sensorWidth = physicalSize?.width ?: return null
        if (sensorWidth <= 0f) return null
        return focalLength.toDouble() * 36.0 / sensorWidth.toDouble()
    }

    private fun positionName(facing: Int?): String {
        return when (facing) {
            CameraCharacteristics.LENS_FACING_FRONT -> "front"
            CameraCharacteristics.LENS_FACING_BACK -> "back"
            CameraCharacteristics.LENS_FACING_EXTERNAL -> "external"
            else -> "unknown"
        }
    }

    private fun sensorType(
        facing: Int?,
        equivalent35mm: Double?,
        isLogical: Boolean,
    ): String {
        if (facing == CameraCharacteristics.LENS_FACING_FRONT) return "front"
        if (equivalent35mm == null) return if (isLogical) "logical" else "unknown"
        return when {
            equivalent35mm < 20.0 -> "ultraWide"
            equivalent35mm > 55.0 -> "telephoto"
            isLogical -> "logical"
            else -> "wide"
        }
    }

    private fun hardwareLevelName(level: Int?): String {
        return when (level) {
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_LEGACY -> "LEGACY"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_LIMITED -> "LIMITED"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_FULL -> "FULL"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_3 -> "LEVEL_3"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_EXTERNAL -> "EXTERNAL"
            else -> "UNKNOWN"
        }
    }

    private fun supportedResolutionPresets(maxWidth: Int?): List<String> {
        val width = maxWidth ?: return listOf("high", "veryHigh")
        val presets = mutableListOf("high")
        if (width >= 1920) presets += "veryHigh"
        if (width >= 3840) presets += "ultraHigh"
        return presets.distinct()
    }
}
