package com.exbfcamera.exbf_camera

import android.content.Context
import android.os.Build
import android.util.Log
import org.tensorflow.lite.DataType
import org.tensorflow.lite.Delegate
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.gpu.CompatibilityList
import org.tensorflow.lite.gpu.GpuDelegate
import org.tensorflow.lite.nnapi.NnApiDelegate
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import kotlin.math.roundToInt

object NativeAiBenchmark {
    private const val PASS_AVERAGE_MS = 220
    private const val GOOD_AVERAGE_MS = 120

    fun run(context: Context): Map<String, Any?> {
        val candidates = mutableListOf("CPU")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) candidates += "NNAPI"
        val gpuSupported = gpuSupported()
        if (gpuSupported) candidates += "GPU"

        val results = candidates.map { delegate ->
            benchmarkDelegate(context, delegate)
        }
        val successful = results.filter { it.ok }
        val best = successful.minByOrNull { it.averageMs }
        val aiEnabled = best != null && best.averageMs <= PASS_AVERAGE_MS
        val grade = when {
            best == null -> "blocked"
            best.averageMs <= GOOD_AVERAGE_MS -> "high"
            best.averageMs <= PASS_AVERAGE_MS -> "standard"
            else -> "camera_only"
        }

        Log.d(
            "NativeAiBenchmark",
            "best=${best?.delegate ?: "NONE"} avg=${best?.averageMs ?: 0} enabled=$aiEnabled results=${results.joinToString { "${it.delegate}:${if (it.ok) it.averageMs else it.error}" }}",
        )

        return mapOf(
            "aiEnabled" to aiEnabled,
            "bestDelegate" to (best?.delegate ?: "NONE"),
            "averageMs" to (best?.averageMs ?: 0),
            "grade" to grade,
            "passAverageMs" to PASS_AVERAGE_MS,
            "goodAverageMs" to GOOD_AVERAGE_MS,
            "gpuSupported" to gpuSupported,
            "results" to results.map { it.toMap() },
            "blockedReason" to if (aiEnabled) "" else "AI 벤치마크 기준 미달",
        )
    }

    private fun benchmarkDelegate(context: Context, delegateName: String): Result {
        val delegates = mutableListOf<AutoCloseable>()
        return try {
            val yolo = Interpreter(
                loadModel(context, "flutter_assets/assets/models/yolo11n_float32.tflite"),
                options(delegateName, delegates),
            )
            val moveNet = Interpreter(
                loadModel(context, "flutter_assets/assets/models/movenet_thunder_float16.tflite"),
                options(delegateName, delegates),
            )
            val yoloInput = inputFor(yolo, normalize = true)
            val yoloOutput = outputFor(yolo)
            val moveNetInput = inputFor(moveNet, normalize = false)
            val moveNetOutput = outputFor(moveNet)

            yolo.run(yoloInput, yoloOutput)
            moveNet.run(moveNetInput, moveNetOutput)

            val samples = mutableListOf<Int>()
            repeat(3) {
                yoloInput.rewind()
                moveNetInput.rewind()
                val started = System.nanoTime()
                yolo.run(yoloInput, yoloOutput)
                moveNet.run(moveNetInput, moveNetOutput)
                samples += ((System.nanoTime() - started) / 1_000_000.0).roundToInt()
            }
            yolo.close()
            moveNet.close()
            Result(
                delegate = delegateName,
                ok = true,
                averageMs = samples.average().roundToInt(),
                samples = samples,
            )
        } catch (error: Throwable) {
            Result(
                delegate = delegateName,
                ok = false,
                averageMs = Int.MAX_VALUE,
                samples = emptyList(),
                error = error.message ?: error.javaClass.simpleName,
            )
        } finally {
            delegates.forEach { delegate ->
                try {
                    delegate.close()
                } catch (_: Throwable) {
                }
            }
        }
    }

    private fun options(
        delegateName: String,
        delegates: MutableList<AutoCloseable>,
    ): Interpreter.Options {
        val options = Interpreter.Options().setNumThreads(2)
        when (delegateName) {
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

    private fun gpuSupported(): Boolean {
        return try {
            CompatibilityList().use { compatibility ->
                compatibility.isDelegateSupportedOnThisDevice
            }
        } catch (_: Throwable) {
            false
        }
    }

    private fun loadModel(context: Context, assetPath: String): MappedByteBuffer {
        val descriptor = context.assets.openFd(assetPath)
        FileInputStream(descriptor.fileDescriptor).use { input ->
            return input.channel.map(
                FileChannel.MapMode.READ_ONLY,
                descriptor.startOffset,
                descriptor.declaredLength,
            )
        }
    }

    private fun inputFor(interpreter: Interpreter, normalize: Boolean): ByteBuffer {
        val tensor = interpreter.getInputTensor(0)
        val shape = tensor.shape()
        val height = shape.getOrElse(1) { 1 }
        val width = shape.getOrElse(2) { 1 }
        val channels = shape.getOrElse(3) { 3 }
        val elementCount = height * width * channels
        val isByte = tensor.dataType() == DataType.UINT8
        val buffer = ByteBuffer
            .allocateDirect((if (isByte) 1 else 4) * elementCount)
            .order(ByteOrder.nativeOrder())
        if (isByte) {
            repeat(elementCount) {
                buffer.put(128.toByte())
            }
        } else {
            val value = if (normalize) 0.45f else 128f
            repeat(elementCount) {
                buffer.putFloat(value)
            }
        }
        buffer.rewind()
        return buffer
    }

    private fun outputFor(interpreter: Interpreter): Any {
        val shape = interpreter.getOutputTensor(0).shape()
        return when (shape.size) {
            3 -> Array(shape[0]) { Array(shape[1]) { FloatArray(shape[2]) } }
            4 -> Array(shape[0]) { Array(shape[1]) { Array(shape[2]) { FloatArray(shape[3]) } } }
            else -> throw IllegalStateException("Unsupported output shape ${shape.joinToString("x")}")
        }
    }

    private class CloseableDelegate(private val delegate: Delegate) : AutoCloseable {
        override fun close() {
            if (delegate is AutoCloseable) {
                delegate.close()
            }
        }
    }

    private data class Result(
        val delegate: String,
        val ok: Boolean,
        val averageMs: Int,
        val samples: List<Int>,
        val error: String = "",
    ) {
        fun toMap(): Map<String, Any?> {
            return mapOf(
                "delegate" to delegate,
                "ok" to ok,
                "averageMs" to if (averageMs == Int.MAX_VALUE) 0 else averageMs,
                "samples" to samples,
                "error" to error,
            )
        }
    }
}
