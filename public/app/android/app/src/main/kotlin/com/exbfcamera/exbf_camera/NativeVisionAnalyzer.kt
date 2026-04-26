package com.exbfcamera.exbf_camera

import android.content.Context
import android.util.Log
import androidx.camera.core.ImageProxy
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetector
import com.google.mlkit.vision.face.FaceDetectorOptions
import com.google.mlkit.vision.face.FaceLandmark
import org.tensorflow.lite.Delegate
import org.tensorflow.lite.DataType
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.gpu.CompatibilityList
import org.tensorflow.lite.gpu.GpuDelegate
import org.tensorflow.lite.nnapi.NnApiDelegate
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import kotlin.math.max
import kotlin.math.min

class NativeVisionAnalyzer(private val context: Context) {
    var delegateName: String = "CPU / 2 threads"
        private set

    private var delegateMode: String = "CPU"
    private var yolo: Interpreter? = null
    private var moveNet: Interpreter? = null
    private var faceDetector: FaceDetector? = null
    private val delegates = mutableListOf<AutoCloseable>()
    private var analysisCount = 0
    private var lastObjects: List<Map<String, Any>> = emptyList()
    private var yoloShapeLogged = false

    fun analyze(
        image: ImageProxy,
        mirrorHorizontal: Boolean,
        mode: String = "full",
    ): Map<String, Any> {
        val started = System.currentTimeMillis()
        analysisCount += 1
        if (mode == "face_only") {
            val rawFaces = runFaceDetection(image)
            val faces = if (mirrorHorizontal) mirrorFaces(rawFaces) else rawFaces
            val processingMs = (System.currentTimeMillis() - started).toInt()
            if (analysisCount <= 3 || analysisCount % 10 == 0) {
                Log.d(
                    "NativeVision",
                    "analysis=$analysisCount faceOnly faces=${faces.size} ms=$processingMs",
                )
            }
            return mapOf(
                "type" to "face_only",
                "objects" to emptyList<Map<String, Any>>(),
                "pose" to emptyList<Map<String, Any>>(),
                "faces" to faces,
                "processingMs" to processingMs,
                "rotationDegrees" to image.imageInfo.rotationDegrees,
                "sourceWidth" to image.width,
                "sourceHeight" to image.height,
                "mirrored" to mirrorHorizontal,
            )
        }
        val shouldRunYolo = mode == "object_only" || analysisCount == 1 || analysisCount % 3 == 0
        val rawObjects = if (shouldRunYolo) {
            runYolo(image).also { lastObjects = it }
        } else {
            lastObjects
        }
        val rawPose = if (mode == "object_only") {
            emptyList()
        } else {
            runMoveNet(image)
        }
        val objects = if (mirrorHorizontal) mirrorObjects(rawObjects) else rawObjects
        val pose = if (mirrorHorizontal) mirrorPose(rawPose) else rawPose
        val processingMs = (System.currentTimeMillis() - started).toInt()
        if (analysisCount <= 3 || analysisCount % 10 == 0) {
            Log.d(
                "NativeVision",
                "analysis=$analysisCount mode=$mode objects=${objects.size} pose=${pose.size} ms=$processingMs",
            )
        }
        return mapOf(
            "type" to mode,
            "objects" to objects,
            "pose" to pose,
            "faces" to emptyList<Map<String, Any>>(),
            "processingMs" to processingMs,
            "rotationDegrees" to image.imageInfo.rotationDegrees,
            "sourceWidth" to image.width,
            "sourceHeight" to image.height,
            "mirrored" to mirrorHorizontal,
        )
    }

    fun close() {
        yolo?.close()
        moveNet?.close()
        faceDetector?.close()
        yolo = null
        moveNet = null
        faceDetector = null
        delegates.forEach { delegate ->
            try {
                delegate.close()
            } catch (_: Throwable) {
            }
        }
        delegates.clear()
    }

    fun setDelegate(delegate: String) {
        val next = when (delegate) {
            "GPU" -> "GPU"
            "NNAPI" -> "NNAPI"
            else -> "CPU"
        }
        if (delegateMode == next) return
        close()
        delegateMode = next
        delegateName = displayName(next)
    }

    private fun options(): Interpreter.Options {
        val options = Interpreter.Options().setNumThreads(2)
        when (delegateMode) {
            "NNAPI" -> {
                val delegate = NnApiDelegate()
                delegates += delegate
                options.addDelegate(delegate)
            }
            "GPU" -> {
                val compatibility = CompatibilityList()
                delegates += compatibility
                if (!compatibility.isDelegateSupportedOnThisDevice) {
                    throw IllegalStateException("GPU delegate unsupported")
                }
                val delegate = GpuDelegate(compatibility.bestOptionsForThisDevice)
                delegates += CloseableDelegate(delegate)
                options.addDelegate(delegate)
            }
        }
        return options
    }

    private fun displayName(delegate: String): String {
        return when (delegate) {
            "GPU" -> "GPU delegate"
            "NNAPI" -> "NNAPI delegate"
            else -> "CPU / 2 threads"
        }
    }

    private fun loadModel(assetPath: String): MappedByteBuffer {
        val descriptor = context.assets.openFd(assetPath)
        FileInputStream(descriptor.fileDescriptor).use { input ->
            return input.channel.map(
                FileChannel.MapMode.READ_ONLY,
                descriptor.startOffset,
                descriptor.declaredLength,
            )
        }
    }

    private fun runYolo(image: ImageProxy): List<Map<String, Any>> {
        val interpreter = yolo ?: Interpreter(
            loadModel("flutter_assets/assets/models/yolo11n_float32.tflite"),
            options(),
        ).also { yolo = it }
        val inputShape = interpreter.getInputTensor(0).shape()
        val outputShape = interpreter.getOutputTensor(0).shape()
        if (!yoloShapeLogged) {
            yoloShapeLogged = true
            Log.d(
                "NativeVision",
                "yolo input=${inputShape.joinToString("x")} output=${outputShape.joinToString("x")}",
            )
        }
        val inputSize = if (inputShape.size >= 3) inputShape[1] else 640
        val input = yuvToFloatBuffer(image, inputSize, inputSize, normalize = true)
        val output = Array(outputShape[0]) {
            Array(outputShape[1]) {
                FloatArray(outputShape[2])
            }
        }
        interpreter.run(input, output)
        return decodeYolo(output.first(), inputSize)
    }

    private fun runMoveNet(image: ImageProxy): List<Map<String, Any>> {
        val interpreter = moveNet ?: Interpreter(
            loadModel("flutter_assets/assets/models/movenet_thunder_float16.tflite"),
            options(),
        ).also { moveNet = it }
        val inputTensor = interpreter.getInputTensor(0)
        val inputShape = inputTensor.shape()
        val outputShape = interpreter.getOutputTensor(0).shape()
        val height = inputShape[1]
        val width = inputShape[2]
        val input = if (inputTensor.dataType() == DataType.UINT8) {
            yuvToByteBuffer(image, width, height)
        } else {
            yuvToFloatBuffer(image, width, height, normalize = false)
        }
        val output = Array(outputShape[0]) {
            Array(outputShape[1]) {
                Array(outputShape[2]) {
                    FloatArray(outputShape[3])
                }
            }
        }
        interpreter.run(input, output)
        return decodeMoveNet(output.first().first())
    }

    private fun runFaceDetection(image: ImageProxy): List<Map<String, Any>> {
        val mediaImage = image.image ?: return emptyList()
        val detector = faceDetector ?: FaceDetection.getClient(
            FaceDetectorOptions.Builder()
                .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
                .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
                .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_NONE)
                .setMinFaceSize(0.12f)
                .enableTracking()
                .build(),
        ).also { faceDetector = it }
        val input = InputImage.fromMediaImage(mediaImage, image.imageInfo.rotationDegrees)
        val faces = try {
            Tasks.await(detector.process(input))
        } catch (exception: Exception) {
            Log.w("NativeVision", "face detection failed", exception)
            emptyList()
        }
        return faces
            .sortedByDescending { face -> face.boundingBox.width() * face.boundingBox.height() }
            .take(4)
            .map { face -> face.toMap(image) }
    }

    private fun Face.toMap(image: ImageProxy): Map<String, Any> {
        val rotation = ((image.imageInfo.rotationDegrees % 360) + 360) % 360
        val normalizedWidth = if (rotation == 90 || rotation == 270) {
            image.height.toFloat()
        } else {
            image.width.toFloat()
        }.coerceAtLeast(1f)
        val normalizedHeight = if (rotation == 90 || rotation == 270) {
            image.width.toFloat()
        } else {
            image.height.toFloat()
        }.coerceAtLeast(1f)
        val box = boundingBox
        val leftEye = getLandmark(FaceLandmark.LEFT_EYE)?.position
        val rightEye = getLandmark(FaceLandmark.RIGHT_EYE)?.position
        val nose = getLandmark(FaceLandmark.NOSE_BASE)?.position
        fun pointMap(x: Float, y: Float): Map<String, Any> {
            return mapOf(
                "x" to (x / normalizedWidth).toDouble().coerceIn(0.0, 1.0),
                "y" to (y / normalizedHeight).toDouble().coerceIn(0.0, 1.0),
            )
        }
        val landmarks = mutableMapOf<String, Map<String, Any>>()
        leftEye?.let { landmarks["leftEye"] = pointMap(it.x, it.y) }
        rightEye?.let { landmarks["rightEye"] = pointMap(it.x, it.y) }
        nose?.let { landmarks["nose"] = pointMap(it.x, it.y) }
        return mapOf(
            "confidence" to 1.0,
            "trackingId" to (trackingId ?: -1),
            "x" to (box.left / normalizedWidth).toDouble().coerceIn(0.0, 1.0),
            "y" to (box.top / normalizedHeight).toDouble().coerceIn(0.0, 1.0),
            "width" to (box.width() / normalizedWidth).toDouble().coerceIn(0.0, 1.0),
            "height" to (box.height() / normalizedHeight).toDouble().coerceIn(0.0, 1.0),
            "headEulerY" to headEulerAngleY.toDouble(),
            "headEulerZ" to headEulerAngleZ.toDouble(),
            "landmarks" to landmarks,
        )
    }

    private fun decodeYolo(output: Array<FloatArray>, inputSize: Int): List<Map<String, Any>> {
        if (output.size < 5) return emptyList()
        val boxes = output[0].size
        val detections = mutableListOf<Map<String, Any>>()
        for (i in 0 until boxes) {
            var bestScore = 0f
            var bestClass = 0
            for (classIndex in 4 until output.size) {
                val score = output[classIndex][i]
                if (score > bestScore) {
                    bestScore = score
                    bestClass = classIndex - 4
                }
            }
            if (bestScore < 0.35f || bestClass >= cocoLabels.size) continue
            val rawCx = output[0][i]
            val rawCy = output[1][i]
            val rawWidth = output[2][i]
            val rawHeight = output[3][i]
            val scale = if (
                max(max(rawCx, rawCy), max(rawWidth, rawHeight)) <= 2f
            ) {
                1f
            } else {
                inputSize.toFloat()
            }
            val cx = rawCx / scale
            val cy = rawCy / scale
            val width = rawWidth / scale
            val height = rawHeight / scale
            if (width <= 0.01f || height <= 0.01f) continue
            detections.add(
                mapOf(
                    "label" to cocoLabels[bestClass],
                    "confidence" to bestScore.toDouble().coerceIn(0.0, 1.0),
                    "x" to (cx - width / 2f).toDouble().coerceIn(0.0, 1.0),
                    "y" to (cy - height / 2f).toDouble().coerceIn(0.0, 1.0),
                    "width" to width.toDouble().coerceIn(0.0, 1.0),
                    "height" to height.toDouble().coerceIn(0.0, 1.0),
                ),
            )
        }
        val sorted = detections.sortedByDescending { it["confidence"] as Double }.take(20)
        val firstPerson = sorted.firstOrNull { it["label"] == "person" }
        if (firstPerson != null && (analysisCount <= 3 || analysisCount % 10 == 0)) {
            Log.d(
                "NativeVision",
                "person box x=${firstPerson["x"]} y=${firstPerson["y"]} w=${firstPerson["width"]} h=${firstPerson["height"]} score=${firstPerson["confidence"]}",
            )
        }
        return sorted
    }

    private fun decodeMoveNet(output: Array<FloatArray>): List<Map<String, Any>> {
        val keypoints = mutableListOf<Map<String, Any>>()
        for (i in 0 until min(output.size, poseNames.size)) {
            val point = output[i]
            keypoints.add(
                mapOf(
                    "name" to poseNames[i],
                    "y" to point[0].toDouble().coerceIn(0.0, 1.0),
                    "x" to point[1].toDouble().coerceIn(0.0, 1.0),
                    "confidence" to point[2].toDouble().coerceIn(0.0, 1.0),
                ),
            )
        }
        return keypoints
    }

    private fun mirrorObjects(objects: List<Map<String, Any>>): List<Map<String, Any>> {
        return objects.map { objectMap ->
            val x = (objectMap["x"] as? Double) ?: 0.0
            val width = (objectMap["width"] as? Double) ?: 0.0
            objectMap + ("x" to (1.0 - x - width).coerceIn(0.0, 1.0))
        }
    }

    private fun mirrorPose(points: List<Map<String, Any>>): List<Map<String, Any>> {
        return points.map { pointMap ->
            val x = (pointMap["x"] as? Double) ?: 0.0
            pointMap + ("x" to (1.0 - x).coerceIn(0.0, 1.0))
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun mirrorFaces(faces: List<Map<String, Any>>): List<Map<String, Any>> {
        return faces.map { faceMap ->
            val x = (faceMap["x"] as? Double) ?: 0.0
            val width = (faceMap["width"] as? Double) ?: 0.0
            val landmarks = faceMap["landmarks"] as? Map<String, Map<String, Any>> ?: emptyMap()
            val mirroredLandmarks = landmarks.mapValues { (_, point) ->
                val pointX = (point["x"] as? Double) ?: 0.0
                point + ("x" to (1.0 - pointX).coerceIn(0.0, 1.0))
            }.let { mapped ->
                val left = mapped["leftEye"]
                val right = mapped["rightEye"]
                if (left != null && right != null) {
                    mapped + ("leftEye" to right) + ("rightEye" to left)
                } else {
                    mapped
                }
            }
            faceMap +
                ("x" to (1.0 - x - width).coerceIn(0.0, 1.0)) +
                ("headEulerY" to -((faceMap["headEulerY"] as? Double) ?: 0.0)) +
                ("landmarks" to mirroredLandmarks)
        }
    }

    private fun yuvToFloatBuffer(
        image: ImageProxy,
        targetWidth: Int,
        targetHeight: Int,
        normalize: Boolean,
    ): ByteBuffer {
        val buffer = ByteBuffer
            .allocateDirect(4 * targetWidth * targetHeight * 3)
            .order(ByteOrder.nativeOrder())
        writeRgb(image, targetWidth, targetHeight) { r, g, b ->
            val scale = if (normalize) 255f else 1f
            buffer.putFloat(r / scale)
            buffer.putFloat(g / scale)
            buffer.putFloat(b / scale)
        }
        buffer.rewind()
        return buffer
    }

    private fun yuvToByteBuffer(
        image: ImageProxy,
        targetWidth: Int,
        targetHeight: Int,
    ): ByteBuffer {
        val buffer = ByteBuffer
            .allocateDirect(targetWidth * targetHeight * 3)
            .order(ByteOrder.nativeOrder())
        writeRgb(image, targetWidth, targetHeight) { r, g, b ->
            buffer.put(r.toInt().coerceIn(0, 255).toByte())
            buffer.put(g.toInt().coerceIn(0, 255).toByte())
            buffer.put(b.toInt().coerceIn(0, 255).toByte())
        }
        buffer.rewind()
        return buffer
    }

    private inline fun writeRgb(
        image: ImageProxy,
        targetWidth: Int,
        targetHeight: Int,
        write: (Float, Float, Float) -> Unit,
    ) {
        val rotation = ((image.imageInfo.rotationDegrees % 360) + 360) % 360
        for (y in 0 until targetHeight) {
            for (x in 0 until targetWidth) {
                val source = mapTargetToSource(
                    x,
                    y,
                    targetWidth,
                    targetHeight,
                    image.width,
                    image.height,
                    rotation,
                )
                val rgb = yuvAt(image, source.first, source.second)
                write(rgb[0], rgb[1], rgb[2])
            }
        }
    }

    private fun mapTargetToSource(
        x: Int,
        y: Int,
        targetWidth: Int,
        targetHeight: Int,
        sourceWidth: Int,
        sourceHeight: Int,
        rotation: Int,
    ): Pair<Int, Int> {
        val nx = if (targetWidth <= 1) 0f else x.toFloat() / (targetWidth - 1)
        val ny = if (targetHeight <= 1) 0f else y.toFloat() / (targetHeight - 1)
        val sx: Float
        val sy: Float
        when (rotation) {
            90 -> {
                sx = ny * (sourceWidth - 1)
                sy = (1f - nx) * (sourceHeight - 1)
            }
            180 -> {
                sx = (1f - nx) * (sourceWidth - 1)
                sy = (1f - ny) * (sourceHeight - 1)
            }
            270 -> {
                sx = (1f - ny) * (sourceWidth - 1)
                sy = nx * (sourceHeight - 1)
            }
            else -> {
                sx = nx * (sourceWidth - 1)
                sy = ny * (sourceHeight - 1)
            }
        }
        return Pair(sx.toInt().coerceIn(0, sourceWidth - 1), sy.toInt().coerceIn(0, sourceHeight - 1))
    }

    private fun yuvAt(image: ImageProxy, x: Int, y: Int): FloatArray {
        val yPlane = image.planes[0]
        val uPlane = image.planes[1]
        val vPlane = image.planes[2]
        val yValue = yPlane.buffer.get(y * yPlane.rowStride + x).toInt() and 0xff
        val chromaX = x / 2
        val chromaY = y / 2
        val uIndex = chromaY * uPlane.rowStride + chromaX * uPlane.pixelStride
        val vIndex = chromaY * vPlane.rowStride + chromaX * vPlane.pixelStride
        val uValue = (uPlane.buffer.get(uIndex).toInt() and 0xff) - 128
        val vValue = (vPlane.buffer.get(vIndex).toInt() and 0xff) - 128
        val yf = max(0, yValue - 16) * 1.164f
        val r = (yf + 1.596f * vValue).coerceIn(0f, 255f)
        val g = (yf - 0.813f * vValue - 0.391f * uValue).coerceIn(0f, 255f)
        val b = (yf + 2.018f * uValue).coerceIn(0f, 255f)
        return floatArrayOf(r, g, b)
    }

    companion object {
        private class CloseableDelegate(private val delegate: Delegate) : AutoCloseable {
            override fun close() {
                if (delegate is AutoCloseable) {
                    delegate.close()
                }
            }
        }

        private val poseNames = listOf(
            "nose",
            "left_eye",
            "right_eye",
            "left_ear",
            "right_ear",
            "left_shoulder",
            "right_shoulder",
            "left_elbow",
            "right_elbow",
            "left_wrist",
            "right_wrist",
            "left_hip",
            "right_hip",
            "left_knee",
            "right_knee",
            "left_ankle",
            "right_ankle",
        )

        private val cocoLabels = listOf(
            "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck",
            "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench",
            "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra",
            "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
            "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove",
            "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup",
            "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange",
            "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch",
            "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse",
            "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink",
            "refrigerator", "book", "clock", "vase", "scissors", "teddy bear",
            "hair drier", "toothbrush",
        )
    }
}
