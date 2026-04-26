package com.exbfcamera.exbf_camera

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.graphics.ImageFormat
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CaptureRequest
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.SystemClock
import android.provider.MediaStore
import android.util.Range
import android.util.Log
import android.view.Surface
import android.view.View
import androidx.camera.core.AspectRatio
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.camera2.interop.Camera2CameraControl
import androidx.camera.camera2.interop.CaptureRequestOptions
import androidx.camera.core.Camera
import androidx.camera.core.CameraFilter
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.FocusMeteringAction
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.MeteringPointFactory
import androidx.camera.core.Preview
import androidx.camera.core.SurfaceOrientedMeteringPointFactory
import androidx.exifinterface.media.ExifInterface
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.FallbackStrategy
import androidx.camera.video.MediaStoreOutputOptions
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.core.content.PermissionChecker
import androidx.lifecycle.LifecycleOwner
import com.google.common.util.concurrent.ListenableFuture
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

object NativeCameraEngine {
    private var activity: Activity? = null
    private var previewView: PreviewView? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var providerFuture: ListenableFuture<ProcessCameraProvider>? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var imageCapture: ImageCapture? = null
    private var videoCapture: VideoCapture<Recorder>? = null
    private var recording: Recording? = null
    private var analysisSink: EventChannel.EventSink? = null
    private var visionAnalyzer: NativeVisionAnalyzer? = null
    private var selectedCameraId: String? = null
    private var selectedLensFacing: Int = CameraSelector.LENS_FACING_BACK
    private var captureMode: String = "photo"
    private var analysisMode: String = "full"
    private var resolutionPreset: String = "veryHigh"
    private var zoomRatio: Float = 1f
    private var lastAnalysisAt: Long = 0L
    private var analysisFrameCount: Long = 0L
    private var analysisInputFrameCount: Long = 0L
    private var analysisSkippedBusyCount: Long = 0L
    private var analysisSkippedThrottleCount: Long = 0L
    private var analysisFps: Double = 0.0
    private var analysisFpsFrameCounter: Int = 0
    private var analysisFpsTimestamp: Long = System.currentTimeMillis()
    private var lastProcessingMs: Int = 0
    private var lastRotationDegrees: Int = 0
    private var analysisBusy: Boolean = false
    private var aiEnabled: Boolean = true
    private var aiBlockedReason: String = ""
    private var benchmarkSummary: Map<String, Any?> = emptyMap()
    private var startedAtMs: Long = SystemClock.elapsedRealtime()
    private var bindCount: Long = 0L
    private var bindFailureCount: Long = 0L
    private var lastBindError: String = ""
    private var lastPhotoPath: String = ""
    private var lastPhotoBytes: Long = 0L
    private var lastCaptureError: String = ""
    private var lastVideoUri: String = ""
    private var lastVideoError: String = ""
    private var lastVideoEvent: String = "idle"
    private var lastVideoFinalizeAt: Long = 0L
    private var lastVideoBytes: Long = 0L
    private var lastVideoStatusBytes: Long = 0L
    private var lastVideoStatusDurationMs: Long = 0L
    private var videoStartedAt: Long = 0L
    private var videoRecordCount: Long = 0L
    private var videoFinalizeCount: Long = 0L
    private var lastVideoDurationMs: Long = 0L
    private var manualIso: Int? = null
    private var manualExposureTimeNs: Long? = null
    private var manualWhiteBalance: Int? = null
    private var targetFps: Int = 30
    private var targetVideoBitrate: Int = 10_000_000
    private var audioEnabled: Boolean = true
    private var lastFocusX: Double = 0.5
    private var lastFocusY: Double = 0.5
    private var lastFocusAt: Long = 0L
    private var lastFocusResult: String = ""
    private var lastGalleryUri: String = ""
    private var lastGalleryError: String = ""
    private var lastCameraState: String = "idle"
    private var lastCameraStateError: String = ""
    private val analysisExecutor = Executors.newSingleThreadExecutor()

    fun attachActivity(activity: Activity) {
        this.activity = activity
        if (visionAnalyzer == null) {
            visionAnalyzer = NativeVisionAnalyzer(activity.applicationContext)
        }
    }

    fun detachActivity() {
        stop()
        visionAnalyzer?.close()
        visionAnalyzer = null
        activity = null
    }

    fun attachPreview(view: PreviewView) {
        previewView = view
        view.scaleType = PreviewView.ScaleType.FILL_CENTER
        view.implementationMode = PreviewView.ImplementationMode.COMPATIBLE
        start()
    }

    fun attachTexture(entry: TextureRegistry.SurfaceTextureEntry) {
        textureEntry?.release()
        textureEntry = entry
        start()
    }

    fun detachPreview(view: PreviewView) {
        if (previewView == view) {
            previewView = null
        }
    }

    fun start() {
        val activity = activity ?: return
        val view = previewView
        if (view == null && textureEntry == null) return
        val lifecycleOwner = activity as? LifecycleOwner ?: return
        val existingProvider = cameraProvider
        if (existingProvider != null) {
            bind(existingProvider, lifecycleOwner, view)
            return
        }

        val future = providerFuture ?: ProcessCameraProvider.getInstance(activity).also {
            providerFuture = it
        }
        future.addListener(
            {
                cameraProvider = future.get()
                bind(cameraProvider ?: return@addListener, lifecycleOwner, view)
            },
            ContextCompat.getMainExecutor(activity),
        )
    }

    fun stop() {
        recording?.stop()
        recording = null
        analysisBusy = false
        cameraProvider?.unbindAll()
        camera = null
        imageCapture = null
        videoCapture = null
    }

    fun state(): Map<String, Any?> {
        val runtime = Runtime.getRuntime()
        val usedMemoryBytes = runtime.totalMemory() - runtime.freeMemory()
        val selectedSensor = selectedCameraId?.let { sensorCapability(it) }
        return mapOf(
            "ready" to (camera != null),
            "textureAttached" to (textureEntry != null),
            "previewViewAttached" to (previewView != null),
            "captureMode" to captureMode,
            "resolutionPreset" to resolutionPreset,
            "selectedCameraId" to selectedCameraId,
            "lensFacing" to if (selectedLensFacing == CameraSelector.LENS_FACING_FRONT) "front" else "back",
            "zoomRatio" to zoomRatio.toDouble(),
            "recording" to (recording != null),
            "imageCaptureReady" to (imageCapture != null),
            "videoCaptureReady" to (videoCapture != null),
            "analysisFrames" to analysisFrameCount,
            "analysisInputFrames" to analysisInputFrameCount,
            "analysisSkippedBusy" to analysisSkippedBusyCount,
            "analysisSkippedThrottle" to analysisSkippedThrottleCount,
            "analysisFps" to analysisFps,
            "analysisEnabled" to isAnalysisEnabled(),
            "analysisPolicy" to analysisPolicyLabel(),
            "analysisMode" to analysisMode,
            "aiEnabled" to aiEnabled,
            "aiBlockedReason" to aiBlockedReason,
            "aiBenchmark" to benchmarkSummary,
            "lastAnalysisAt" to lastAnalysisAt,
            "lastProcessingMs" to lastProcessingMs,
            "lastRotationDegrees" to lastRotationDegrees,
            "nativeVisionReady" to (visionAnalyzer != null),
            "nativeVisionDelegate" to (visionAnalyzer?.delegateName ?: "unavailable"),
            "startedAtMs" to startedAtMs,
            "uptimeMs" to (SystemClock.elapsedRealtime() - startedAtMs),
            "bindCount" to bindCount,
            "bindFailureCount" to bindFailureCount,
            "lastBindError" to lastBindError,
            "lastPhotoPath" to lastPhotoPath,
            "lastPhotoBytes" to lastPhotoBytes,
            "lastCaptureError" to lastCaptureError,
            "lastVideoUri" to lastVideoUri,
            "lastVideoError" to lastVideoError,
            "lastVideoEvent" to lastVideoEvent,
            "lastVideoFinalizeAt" to lastVideoFinalizeAt,
            "lastVideoBytes" to lastVideoBytes,
            "lastVideoStatusBytes" to lastVideoStatusBytes,
            "lastVideoStatusDurationMs" to lastVideoStatusDurationMs,
            "videoRecordCount" to videoRecordCount,
            "videoFinalizeCount" to videoFinalizeCount,
            "lastVideoDurationMs" to lastVideoDurationMs,
            "usedMemoryMb" to (usedMemoryBytes / 1024 / 1024),
            "maxMemoryMb" to (runtime.maxMemory() / 1024 / 1024),
            "thermalStatus" to thermalStatus(),
            "manualIso" to manualIso,
            "manualExposureTimeNs" to manualExposureTimeNs,
            "manualWhiteBalance" to manualWhiteBalanceLabel(manualWhiteBalance),
            "selectedSensor" to selectedSensor,
            "targetFps" to targetFps,
            "targetVideoBitrate" to targetVideoBitrate,
            "audioEnabled" to audioEnabled,
            "lastFocusX" to lastFocusX,
            "lastFocusY" to lastFocusY,
            "lastFocusAt" to lastFocusAt,
            "lastFocusResult" to lastFocusResult,
            "lastGalleryUri" to lastGalleryUri,
            "lastGalleryError" to lastGalleryError,
            "lastCameraState" to lastCameraState,
            "lastCameraStateError" to lastCameraStateError,
        )
    }

    fun setCaptureMode(mode: String) {
        captureMode = if (mode == "video") "video" else "photo"
        if (captureMode == "video") {
            analysisBusy = false
        }
        start()
    }

    fun setAnalysisMode(mode: String?) {
        analysisMode = when (mode) {
            "face_only" -> "face_only"
            "object_only" -> "object_only"
            else -> "full"
        }
        analysisBusy = false
    }

    fun setResolution(preset: String) {
        resolutionPreset = when (preset) {
            "high", "veryHigh", "ultraHigh" -> preset
            else -> "veryHigh"
        }
        start()
    }

    fun setAiEnabled(enabled: Boolean, reason: String?, delegate: String?) {
        aiEnabled = enabled
        aiBlockedReason = if (enabled) "" else (reason ?: "AI 비활성화")
        visionAnalyzer?.setDelegate(delegate ?: "CPU")
        if (!enabled) {
            analysisBusy = false
        }
    }

    fun runAiBenchmark(): Map<String, Any?> {
        val context = activity?.applicationContext ?: return mapOf(
            "aiEnabled" to false,
            "blockedReason" to "Activity missing",
        )
        benchmarkSummary = NativeAiBenchmark.run(context)
        val bestDelegate = benchmarkSummary["bestDelegate"]?.toString() ?: "CPU"
        val enabled = benchmarkSummary["aiEnabled"] == true
        setAiEnabled(
            enabled,
            benchmarkSummary["blockedReason"]?.toString(),
            bestDelegate,
        )
        return benchmarkSummary
    }

    fun setSensor(cameraId: String?) {
        selectedCameraId = cameraId
        selectedLensFacing = CameraSelector.LENS_FACING_BACK
        start()
    }

    fun switchCamera() {
        selectedCameraId = null
        selectedLensFacing =
            if (selectedLensFacing == CameraSelector.LENS_FACING_BACK) {
                CameraSelector.LENS_FACING_FRONT
            } else {
                CameraSelector.LENS_FACING_BACK
            }
        start()
    }

    fun setZoom(value: Double) {
        val zoomState = camera?.cameraInfo?.zoomState?.value
        val min = zoomState?.minZoomRatio ?: 1f
        val max = zoomState?.maxZoomRatio ?: 10f
        zoomRatio = value.toFloat().coerceIn(min, max)
        camera?.cameraControl?.setZoomRatio(zoomRatio)
    }

    fun setFlash(mode: String) {
        imageCapture?.flashMode = when (mode) {
            "always", "torch" -> ImageCapture.FLASH_MODE_ON
            "auto" -> ImageCapture.FLASH_MODE_AUTO
            else -> ImageCapture.FLASH_MODE_OFF
        }
        if (mode == "torch") {
            camera?.cameraControl?.enableTorch(true)
        } else {
            camera?.cameraControl?.enableTorch(false)
        }
    }

    fun setExposure(value: Double) {
        val exposure = camera?.cameraInfo?.exposureState ?: return
        val clamped = value.toInt().coerceIn(
            exposure.exposureCompensationRange.lower,
            exposure.exposureCompensationRange.upper,
        )
        camera?.cameraControl?.setExposureCompensationIndex(clamped)
    }

    fun setManualControls(
        iso: Int?,
        exposureTimeNs: Long?,
        whiteBalance: String?,
    ) {
        manualIso = iso?.takeIf { it > 0 }
        manualExposureTimeNs = exposureTimeNs?.takeIf { it > 0L }
        manualWhiteBalance = whiteBalanceMode(whiteBalance)
        applyManualControls()
    }

    fun setVideoOptions(fps: Int?, bitrate: Int?, audio: Boolean?) {
        fps?.let {
            targetFps = when {
                it <= 24 -> 24
                it <= 30 -> 30
                else -> 60
            }
        }
        bitrate?.let {
            targetVideoBitrate = it.coerceIn(3_000_000, 80_000_000)
        }
        audio?.let {
            audioEnabled = it
        }
        if (captureMode == "video" && recording == null) {
            start()
        }
    }

    fun focus(x: Double, y: Double) {
        val view = previewView
        val normalizedX = x.coerceIn(0.0, 1.0).toFloat()
        val normalizedY = y.coerceIn(0.0, 1.0).toFloat()
        val factory: MeteringPointFactory =
            if (view != null) {
                view.meteringPointFactory
            } else {
                SurfaceOrientedMeteringPointFactory(1f, 1f)
            }
        val point = if (view != null) {
            factory.createPoint(normalizedX * view.width, normalizedY * view.height, 0.12f)
        } else {
            factory.createPoint(normalizedX, normalizedY, 0.12f)
        }
        val action = FocusMeteringAction.Builder(point)
            .addPoint(point, FocusMeteringAction.FLAG_AE)
            .addPoint(point, FocusMeteringAction.FLAG_AWB)
            .setAutoCancelDuration(2, TimeUnit.SECONDS)
            .build()
        lastFocusX = normalizedX.toDouble()
        lastFocusY = normalizedY.toDouble()
        lastFocusAt = System.currentTimeMillis()
        lastFocusResult = "running"
        val future = camera?.cameraControl?.startFocusAndMetering(action) ?: return
        future.addListener(
            {
                lastFocusResult = try {
                    if (future.get().isFocusSuccessful) "locked" else "metered"
                } catch (exception: Exception) {
                    exception.message ?: exception.javaClass.simpleName
                }
            },
            ContextCompat.getMainExecutor(activity ?: return),
        )
    }

    fun saveImageToGallery(path: String, displayName: String?, mimeType: String?): Map<String, Any?> {
        val activity = activity ?: return saveError("Activity missing")
        val source = File(path)
        if (!source.exists() || source.length() <= 0) {
            return saveError("Image file is empty")
        }
        val name = displayName?.takeIf { it.isNotBlank() } ?: "EXBF_${timestamp()}.jpg"
        val mime = mimeType?.takeIf { it.isNotBlank() } ?: "image/jpeg"
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, mime)
            put(MediaStore.Images.Media.DATE_TAKEN, System.currentTimeMillis())
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Ex-Boyfriend Camera")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
        }
        val resolver = activity.contentResolver
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: return saveError("MediaStore insert failed")
        return try {
            resolver.openOutputStream(uri, "w")?.use { output ->
                FileInputStream(source).use { input -> input.copyTo(output) }
            } ?: throw IOException("Output stream missing")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            }
            lastGalleryUri = uri.toString()
            lastGalleryError = ""
            mapOf(
                "ok" to true,
                "uri" to uri.toString(),
                "path" to path,
                "bytes" to source.length(),
            )
        } catch (exception: Exception) {
            runCatching { resolver.delete(uri, null, null) }
            saveError(exception.message ?: exception.javaClass.simpleName)
        }
    }

    fun normalizeJpegExif(path: String): Map<String, Any?> {
        return try {
            val file = File(path)
            if (!file.exists() || file.length() <= 0) {
                return mapOf("ok" to false, "error" to "File missing")
            }
            val exif = ExifInterface(path)
            exif.setAttribute(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL.toString(),
            )
            exif.setAttribute(ExifInterface.TAG_SOFTWARE, "Ex-Boyfriend Camera")
            exif.setAttribute(
                ExifInterface.TAG_DATETIME,
                SimpleDateFormat("yyyy:MM:dd HH:mm:ss", Locale.US).format(Date()),
            )
            exif.saveAttributes()
            mapOf("ok" to true)
        } catch (exception: Exception) {
            mapOf("ok" to false, "error" to (exception.message ?: exception.javaClass.simpleName))
        }
    }

    fun takePhoto(result: MethodChannel.Result) {
        val activity = activity
        val capture = imageCapture
        if (activity == null || capture == null) {
            result.error("native_camera_unavailable", "CameraX is not ready", null)
            return
        }

        val outputFile = File(activity.cacheDir, "EXBF_${timestamp()}.jpg")
        val options = ImageCapture.OutputFileOptions.Builder(outputFile).build()

        capture.takePicture(
            options,
            ContextCompat.getMainExecutor(activity),
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                    lastPhotoPath = outputFile.absolutePath
                    lastPhotoBytes = outputFile.length()
                    lastCaptureError = ""
                    result.success(outputFile.absolutePath)
                }

                override fun onError(exception: ImageCaptureException) {
                    lastCaptureError = exception.message ?: exception.javaClass.simpleName
                    result.error("native_capture_error", exception.message, null)
                }
            },
        )
    }

    fun toggleVideo(result: MethodChannel.Result) {
        val activity = activity
        val capture = videoCapture
        if (activity == null || capture == null) {
            result.error("native_camera_unavailable", "CameraX video is not ready", null)
            return
        }
        val activeRecording = recording
        if (activeRecording != null) {
            lastVideoEvent = "stopping"
            activeRecording.stop()
            result.success("stopping")
            return
        }

        val values = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME, "EXBF_${timestamp()}.mp4")
            put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/Ex-Boyfriend Camera")
            }
        }
        val outputOptions = MediaStoreOutputOptions.Builder(
            activity.contentResolver,
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
        ).setContentValues(values).build()

        val pending = capture.output.prepareRecording(activity, outputOptions)
        val withAudio = if (
            audioEnabled &&
            PermissionChecker.checkSelfPermission(
                activity,
                android.Manifest.permission.RECORD_AUDIO,
            ) == PermissionChecker.PERMISSION_GRANTED
        ) {
            pending.withAudioEnabled()
        } else {
            pending
        }
        lastVideoEvent = "pending"
        recording = withAudio.start(ContextCompat.getMainExecutor(activity)) { event ->
            when (event) {
                is VideoRecordEvent.Start -> {
                    lastVideoEvent = "started"
                    videoStartedAt = System.currentTimeMillis()
                    videoRecordCount += 1
                }
                is VideoRecordEvent.Status -> {
                    lastVideoEvent = "status"
                    lastVideoStatusBytes = event.recordingStats.numBytesRecorded
                    lastVideoStatusDurationMs =
                        TimeUnit.NANOSECONDS.toMillis(event.recordingStats.recordedDurationNanos)
                }
                is VideoRecordEvent.Finalize -> {
                    recording = null
                    lastVideoEvent = "finalized"
                    lastVideoFinalizeAt = System.currentTimeMillis()
                    lastVideoUri = event.outputResults.outputUri.toString()
                    videoFinalizeCount += 1
                    lastVideoDurationMs =
                        if (lastVideoStatusDurationMs > 0L) {
                            lastVideoStatusDurationMs
                        } else {
                            (lastVideoFinalizeAt - videoStartedAt).coerceAtLeast(0)
                        }
                    lastVideoError = if (event.hasError()) {
                        "${event.error}:${event.cause?.message ?: "unknown"}"
                    } else {
                        ""
                    }
                    lastVideoBytes = mediaUriBytes(event.outputResults.outputUri)
                        .takeIf { it > 0L }
                        ?: lastVideoStatusBytes
                }
                is VideoRecordEvent.Pause -> lastVideoEvent = "paused"
                is VideoRecordEvent.Resume -> lastVideoEvent = "resumed"
            }
        }
        videoStartedAt = System.currentTimeMillis()
        lastVideoUri = ""
        lastVideoError = ""
        lastVideoBytes = 0L
        lastVideoStatusBytes = 0L
        lastVideoStatusDurationMs = 0L
        result.success("recording")
    }

    fun setAnalysisSink(sink: EventChannel.EventSink?) {
        analysisSink = sink
    }

    private fun bind(
        provider: ProcessCameraProvider,
        lifecycleOwner: LifecycleOwner,
        view: PreviewView?,
    ) {
        camera?.cameraInfo?.cameraState?.removeObservers(lifecycleOwner)
        provider.unbindAll()
        bindCount += 1
        val selector = cameraSelector()
        val rotation = targetRotation(view)
        val preview = Preview.Builder()
            .setTargetAspectRatio(AspectRatio.RATIO_4_3)
            .setTargetRotation(rotation)
            .build()
            .also { preview ->
            val entry = textureEntry
            if (entry != null) {
                preview.setSurfaceProvider { request ->
                    val resolution = request.resolution
                    val texture = entry.surfaceTexture()
                    texture.setDefaultBufferSize(resolution.width, resolution.height)
                    val surface = Surface(texture)
                    request.provideSurface(
                        surface,
                        ContextCompat.getMainExecutor(activity ?: return@setSurfaceProvider),
                    ) {
                        surface.release()
                    }
                }
            } else {
                preview.setSurfaceProvider(view?.surfaceProvider)
            }
        }
        imageCapture = ImageCapture.Builder()
            .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
            .setTargetAspectRatio(AspectRatio.RATIO_4_3)
            .setTargetRotation(rotation)
            .build()
        val recorder = Recorder.Builder()
            .setQualitySelector(
                QualitySelector.fromOrderedList(
                    videoQualityOrder(),
                    FallbackStrategy.lowerQualityOrHigherThan(Quality.SD),
                ),
            )
            .setTargetVideoEncodingBitRate(targetVideoBitrate)
            .build()
        videoCapture = VideoCapture.withOutput(recorder)
        val analysis = ImageAnalysis.Builder()
            .setTargetAspectRatio(AspectRatio.RATIO_4_3)
            .setTargetRotation(rotation)
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
            .also { imageAnalysis ->
                imageAnalysis.setAnalyzer(analysisExecutor) { proxy ->
                    analysisInputFrameCount += 1
                    lastRotationDegrees = proxy.imageInfo.rotationDegrees
                    val now = System.currentTimeMillis()
                    val analyzer = visionAnalyzer
                    val enabled = isAnalysisEnabled() && analyzer != null
                    val busy = analysisBusy
                    val throttled = now - lastAnalysisAt < analysisIntervalMs()
                    if (enabled && !busy && !throttled) {
                        analysisBusy = true
                        lastAnalysisAt = now
                        try {
                            val result = analyzer.analyze(
                                proxy,
                                mirrorHorizontal = selectedLensFacing == CameraSelector.LENS_FACING_FRONT,
                                mode = analysisMode,
                            )
                            analysisFrameCount += 1
                            updateAnalysisFps()
                            lastProcessingMs = result["processingMs"] as? Int ?: 0
                            lastRotationDegrees = result["rotationDegrees"] as? Int ?: 0
                            activity?.runOnUiThread {
                                analysisSink?.success(result)
                            }
                        } catch (exception: Exception) {
                            android.util.Log.e("NativeVision", "analysis failed", exception)
                            activity?.runOnUiThread {
                                analysisSink?.error("native_vision_error", exception.message, null)
                            }
                        } finally {
                            analysisBusy = false
                        }
                    } else if (enabled && busy) {
                        analysisSkippedBusyCount += 1
                    } else if (enabled && throttled) {
                        analysisSkippedThrottleCount += 1
                    }
                    proxy.close()
                }
            }
        camera = try {
            lastBindError = ""
            bindUseCases(provider, lifecycleOwner, selector, preview, analysis)
        } catch (exception: Exception) {
            bindFailureCount += 1
            lastBindError = exception.message ?: exception.javaClass.simpleName
            Log.w("NativeCamera", "bind failed for camera=$selectedCameraId, falling back", exception)
            selectedCameraId = null
            selectedLensFacing = CameraSelector.LENS_FACING_BACK
            bindUseCases(provider, lifecycleOwner, cameraSelector(), preview, analysis)
        }
        observeCameraState(camera, lifecycleOwner)
        camera?.cameraControl?.setZoomRatio(zoomRatio.coerceAtLeast(1f))
        applyManualControls()
    }

    private fun targetRotation(view: PreviewView?): Int {
        view?.display?.rotation?.let { return it }
        val activity = activity ?: return Surface.ROTATION_0
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.display?.rotation ?: Surface.ROTATION_0
        } else {
            @Suppress("DEPRECATION")
            activity.windowManager.defaultDisplay.rotation
        }
    }

    private fun updateAnalysisFps() {
        val frameWindow = 10
        analysisFpsFrameCounter += 1
        if (analysisFpsFrameCounter < frameWindow) return
        val now = System.currentTimeMillis()
        val delta = (now - analysisFpsTimestamp).coerceAtLeast(1)
        analysisFps = 1000.0 * frameWindow.toDouble() / delta.toDouble()
        analysisFpsTimestamp = now
        analysisFpsFrameCounter = 0
    }

    private fun observeCameraState(camera: Camera?, lifecycleOwner: LifecycleOwner) {
        val info = camera?.cameraInfo ?: return
        info.cameraState.observe(lifecycleOwner) { state ->
            lastCameraState = state.type.name.lowercase(Locale.US)
            lastCameraStateError = state.error?.let { error ->
                "${error.code}:${error.cause?.message ?: "camera_state_error"}"
            } ?: ""
        }
    }

    private fun bindUseCases(
        provider: ProcessCameraProvider,
        lifecycleOwner: LifecycleOwner,
        selector: CameraSelector,
        preview: Preview,
        analysis: ImageAnalysis,
    ): Camera {
        return if (captureMode == "video") {
            imageCapture = null
            val capture = videoCapture ?: throw IllegalStateException("VideoCapture missing")
            provider.bindToLifecycle(
                lifecycleOwner,
                selector,
                preview,
                capture,
            )
        } else {
            videoCapture = null
            val capture = imageCapture ?: throw IllegalStateException("ImageCapture missing")
            provider.bindToLifecycle(
                lifecycleOwner,
                selector,
                preview,
                capture,
                analysis,
            )
        }
    }

    private fun isAnalysisEnabled(): Boolean {
        return aiEnabled && captureMode != "video"
    }

    private fun analysisPolicyLabel(): String {
        if (!aiEnabled) return "ai_blocked_camera_only"
        return if (isAnalysisEnabled()) {
            "photo_mode_${analysisMode}_yuv_${visionAnalyzer?.delegateName ?: "unknown"}"
        } else {
            "paused_during_video"
        }
    }

    private fun analysisIntervalMs(): Long {
        val processing = lastProcessingMs
        val delegate = visionAnalyzer?.delegateName ?: ""
        return when {
            delegate.contains("GPU") -> when {
                processing > 180 -> 420L
                processing > 120 -> 260L
                else -> 190L
            }
            delegate.contains("NNAPI") -> when {
                processing > 320 -> 720L
                processing > 220 -> 500L
                else -> 390L
            }
            processing > 700 -> 1000L
            processing > 350 -> 720L
            else -> 520L
        }
    }

    private fun videoQualityOrder(): List<Quality> {
        return when (resolutionPreset) {
            "high" -> listOf(Quality.HD, Quality.FHD, Quality.SD)
            "ultraHigh" -> listOf(Quality.UHD, Quality.FHD, Quality.HD, Quality.SD)
            else -> listOf(Quality.FHD, Quality.UHD, Quality.HD, Quality.SD)
        }
    }

    private fun cameraSelector(): CameraSelector {
        val cameraId = selectedCameraId
        if (cameraId != null) {
            return CameraSelector.Builder()
                .addCameraFilter(CameraFilter { infos ->
                    infos.filter { info ->
                        Camera2CameraInfo.from(info).cameraId == cameraId
                    }
                })
                .build()
        }
        return CameraSelector.Builder()
            .requireLensFacing(selectedLensFacing)
            .build()
    }

    private fun applyManualControls() {
        val currentCamera = camera ?: return
        val builder = CaptureRequestOptions.Builder()
        if (manualIso != null || manualExposureTimeNs != null) {
            builder.setCaptureRequestOption(
                CaptureRequest.CONTROL_AE_MODE,
                CaptureRequest.CONTROL_AE_MODE_OFF,
            )
            manualIso?.let {
                builder.setCaptureRequestOption(CaptureRequest.SENSOR_SENSITIVITY, it)
            }
            manualExposureTimeNs?.let {
                builder.setCaptureRequestOption(CaptureRequest.SENSOR_EXPOSURE_TIME, it)
            }
        } else {
            builder.setCaptureRequestOption(
                CaptureRequest.CONTROL_AE_MODE,
                CaptureRequest.CONTROL_AE_MODE_ON,
            )
        }
        manualWhiteBalance?.let {
            builder.setCaptureRequestOption(CaptureRequest.CONTROL_AWB_MODE, it)
        } ?: builder.setCaptureRequestOption(
            CaptureRequest.CONTROL_AWB_MODE,
            CaptureRequest.CONTROL_AWB_MODE_AUTO,
        )
        builder.setCaptureRequestOption(
            CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE,
            fpsRange(),
        )
        try {
            Camera2CameraControl.from(currentCamera.cameraControl)
                .setCaptureRequestOptions(builder.build())
        } catch (exception: Exception) {
            lastCaptureError = exception.message ?: exception.javaClass.simpleName
            Log.w("NativeCamera", "manual control failed", exception)
        }
    }

    private fun fpsRange(): Range<Int> {
        val fps = targetFps
        return when {
            fps >= 60 -> Range(30, 60)
            fps <= 24 -> Range(24, 24)
            else -> Range(30, 30)
        }
    }

    private fun saveError(message: String): Map<String, Any?> {
        lastGalleryError = message
        return mapOf("ok" to false, "error" to message)
    }

    private fun whiteBalanceMode(value: String?): Int? {
        return when (value) {
            "incandescent" -> CaptureRequest.CONTROL_AWB_MODE_INCANDESCENT
            "fluorescent" -> CaptureRequest.CONTROL_AWB_MODE_FLUORESCENT
            "daylight" -> CaptureRequest.CONTROL_AWB_MODE_DAYLIGHT
            "cloudy" -> CaptureRequest.CONTROL_AWB_MODE_CLOUDY_DAYLIGHT
            "shade" -> CaptureRequest.CONTROL_AWB_MODE_SHADE
            else -> null
        }
    }

    private fun manualWhiteBalanceLabel(value: Int?): String {
        return when (value) {
            CaptureRequest.CONTROL_AWB_MODE_INCANDESCENT -> "incandescent"
            CaptureRequest.CONTROL_AWB_MODE_FLUORESCENT -> "fluorescent"
            CaptureRequest.CONTROL_AWB_MODE_DAYLIGHT -> "daylight"
            CaptureRequest.CONTROL_AWB_MODE_CLOUDY_DAYLIGHT -> "cloudy"
            CaptureRequest.CONTROL_AWB_MODE_SHADE -> "shade"
            else -> "auto"
        }
    }

    private fun sensorCapability(cameraId: String): Map<String, Any?>? {
        val context = activity?.applicationContext ?: return null
        return try {
            val manager = context.getSystemService(Context.CAMERA_SERVICE)
                as android.hardware.camera2.CameraManager
            val characteristics = manager.getCameraCharacteristics(cameraId)
            val exposureRange = characteristics.get(
                CameraCharacteristics.SENSOR_INFO_EXPOSURE_TIME_RANGE,
            )
            val isoRange = characteristics.get(
                CameraCharacteristics.SENSOR_INFO_SENSITIVITY_RANGE,
            )
            val compensationRange = characteristics.get(
                CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE,
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
                "hardwareLevel" to hardwareLevelName(
                    characteristics.get(CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL),
                ),
                "minIso" to isoRange?.lower,
                "maxIso" to isoRange?.upper,
                "minExposureTimeNs" to exposureRange?.lower,
                "maxExposureTimeNs" to exposureRange?.upper,
                "minExposureCompensation" to compensationRange?.lower,
                "maxExposureCompensation" to compensationRange?.upper,
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

    private fun mediaUriBytes(uri: Uri): Long {
        val context = activity?.applicationContext ?: return 0L
        return try {
            context.contentResolver.openAssetFileDescriptor(uri, "r")?.use {
                it.length.coerceAtLeast(0L)
            } ?: 0L
        } catch (_: Exception) {
            0L
        }
    }

    private fun supportedResolutionPresets(maxWidth: Int?): List<String> {
        val width = maxWidth ?: return listOf("high", "veryHigh")
        val presets = mutableListOf("high")
        if (width >= 1920) presets += "veryHigh"
        if (width >= 3840) presets += "ultraHigh"
        return presets.distinct()
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

    private fun thermalStatus(): Int {
        val context = activity?.applicationContext ?: return -1
        val manager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            manager?.currentThermalStatus ?: -1
        } else {
            -1
        }
    }

    private fun timestamp(): String {
        return SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
    }
}

class NativeCameraPreviewView(activity: Activity?) : io.flutter.plugin.platform.PlatformView {
    private val previewView = PreviewView(activity ?: throw IllegalStateException("Activity missing"))

    init {
        NativeCameraEngine.attachPreview(previewView)
    }

    override fun getView(): View = previewView

    override fun dispose() {
        NativeCameraEngine.detachPreview(previewView)
    }
}

class NativeCameraPreviewFactory(
    private val activityProvider: () -> Activity?,
) : io.flutter.plugin.platform.PlatformViewFactory(
    io.flutter.plugin.common.StandardMessageCodec.INSTANCE,
) {
    override fun create(
        context: android.content.Context?,
        viewId: Int,
        args: Any?,
    ): io.flutter.plugin.platform.PlatformView {
        return NativeCameraPreviewView(activityProvider())
    }
}
