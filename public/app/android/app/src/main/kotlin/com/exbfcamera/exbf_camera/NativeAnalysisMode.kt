package com.exbfcamera.exbf_camera

enum class NativeAnalysisMode(val wireValue: String) {
    FULL("full"),
    FACE_ONLY("face_only"),
    OBJECT_ONLY("object_only");

    val isFaceOnly: Boolean
        get() = this == FACE_ONLY

    val isObjectOnly: Boolean
        get() = this == OBJECT_ONLY

    companion object {
        fun from(value: String?): NativeAnalysisMode {
            return when (value) {
                FACE_ONLY.wireValue -> FACE_ONLY
                OBJECT_ONLY.wireValue -> OBJECT_ONLY
                else -> FULL
            }
        }
    }
}
