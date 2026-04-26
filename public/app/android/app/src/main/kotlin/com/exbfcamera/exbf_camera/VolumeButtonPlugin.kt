package com.exbfcamera.exbf_camera

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

class VolumeButtonPlugin : FlutterPlugin, EventChannel.StreamHandler {
    companion object {
        private var eventSink: EventChannel.EventSink? = null

        fun sendVolumeEvent(isVolumeDown: Boolean) {
            eventSink?.success(isVolumeDown)
        }
    }

    private var channel: EventChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = EventChannel(
            binding.binaryMessenger,
            "exbf_camera/volume_keydown"
        )
        channel?.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setStreamHandler(null)
        channel = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
