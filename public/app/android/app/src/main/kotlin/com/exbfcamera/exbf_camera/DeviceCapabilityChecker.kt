package com.exbfcamera.exbf_camera

import android.app.ActivityManager
import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build
import java.util.Locale

object DeviceCapabilityChecker {
    private const val MIN_SDK = 33
    private const val MIN_RAM_BYTES = 7_000_000_000L

    fun check(context: Context): Map<String, Any?> {
        val sdkOk = Build.VERSION.SDK_INT >= MIN_SDK
        val totalRam = totalRamBytes(context)
        val ramOk = totalRam >= MIN_RAM_BYTES
        val cameraLevel = bestBackCameraLevel(context)
        val cameraOk = cameraLevel == "FULL" || cameraLevel == "LEVEL_3"
        val chipset = chipsetName()
        val chipsetKnownFast = isKnownFastChipset(chipset)
        val abiOk = Build.SUPPORTED_64_BIT_ABIS.any { it == "arm64-v8a" }
        val nnapiAvailable = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1

        val failed = mutableListOf<String>()
        if (!sdkOk) failed += "Android 13 이상 필요"
        if (!ramOk) failed += "RAM 8GB급 이상 필요"
        if (!cameraOk) failed += "Camera2 FULL 또는 LEVEL_3 필요"
        if (!abiOk) failed += "arm64 기기 필요"
        if (!nnapiAvailable) failed += "NNAPI 사용 불가"

        return mapOf(
            "supported" to failed.isEmpty(),
            "failedReasons" to failed,
            "sdk" to Build.VERSION.SDK_INT,
            "minSdk" to MIN_SDK,
            "totalRamBytes" to totalRam,
            "minRamBytes" to MIN_RAM_BYTES,
            "camera2Level" to cameraLevel,
            "chipset" to chipset,
            "chipsetKnownFast" to chipsetKnownFast,
            "chipsetSupported" to chipsetKnownFast,
            "abi64" to Build.SUPPORTED_64_BIT_ABIS.joinToString(","),
            "nnapiAvailable" to nnapiAvailable,
            "gpuDelegateCandidate" to (abiOk && sdkOk),
        )
    }

    private fun totalRamBytes(context: Context): Long {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo()
        manager.getMemoryInfo(info)
        return info.totalMem
    }

    private fun bestBackCameraLevel(context: Context): String {
        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        var best = "UNKNOWN"
        for (cameraId in manager.cameraIdList) {
            val characteristics = manager.getCameraCharacteristics(cameraId)
            val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
            if (facing != CameraCharacteristics.LENS_FACING_BACK) continue
            val level = characteristics.get(
                CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL,
            )
            val name = hardwareLevelName(level)
            if (name == "LEVEL_3") return name
            if (name == "FULL") best = name
            if (best == "UNKNOWN") best = name
        }
        return best
    }

    private fun hardwareLevelName(level: Int?): String {
        return when (level) {
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_3 -> "LEVEL_3"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_FULL -> "FULL"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_LIMITED -> "LIMITED"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_LEGACY -> "LEGACY"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_EXTERNAL -> "EXTERNAL"
            else -> "UNKNOWN"
        }
    }

    private fun chipsetName(): String {
        val fields = listOf(
            Build.SOC_MODEL,
            Build.HARDWARE,
            Build.BOARD,
            Build.DEVICE,
            Build.PRODUCT,
        )
        return fields
            .filter { it.isNotBlank() }
            .joinToString(" / ")
    }

    private fun isKnownFastChipset(raw: String): Boolean {
        val value = raw.lowercase(Locale.US)
        val supportedTokens = listOf(
            "sm8450",
            "sm8475",
            "sm8550",
            "sm8650",
            "sm8750",
            "snapdragon 8",
            "taro",
            "kalama",
            "pineapple",
            "sun",
            "exynos 2200",
            "exynos 2300",
            "exynos 2400",
            "exynos 2500",
            "dimensity 9000",
            "dimensity 9200",
            "dimensity 9300",
            "dimensity 9400",
        )
        return supportedTokens.any { value.contains(it) }
    }
}
