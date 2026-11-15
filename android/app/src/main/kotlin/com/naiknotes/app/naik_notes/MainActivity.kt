package com.naiknotes.app.naik_notes

import android.os.Bundle
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "naik_notes/android_stylus"
    private val EVENT_CHANNEL = "naik_notes/android_stylus/events"

    private var eventSink: EventChannel.EventSink? = null
    private var lastButtonState = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getStylusCapabilities") {
                    val capabilities = mapOf(
                        "hasPressure" to true,
                        "hasTilt" to true,
                        "hasHover" to true,
                        "hasEraserTip" to true,
                        "hasBarrelButtons" to true,
                        "hasDoubleTap" to false,
                        "hasSqueeze" to false,
                        "stylusType" to "sPen"
                    )
                    result.success(capabilities)
                } else {
                    result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        if (event.pointerCount > 0) {
            val toolType = event.getToolType(0)
            if (toolType == MotionEvent.TOOL_TYPE_STYLUS || toolType == MotionEvent.TOOL_TYPE_ERASER) {
                handleStylusMotionEvent(event)
            }
        }
        return super.dispatchGenericMotionEvent(event)
    }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        if (event.pointerCount > 0) {
            val toolType = event.getToolType(0)
            if (toolType == MotionEvent.TOOL_TYPE_STYLUS || toolType == MotionEvent.TOOL_TYPE_ERASER) {
                handleStylusMotionEvent(event)
            }
        }
        return super.dispatchTouchEvent(event)
    }

    private fun handleStylusMotionEvent(event: MotionEvent) {
        val sink = eventSink ?: return

        val currentButtonState = event.buttonState
        val buttonChanged = currentButtonState != lastButtonState
        val isPrimaryPressed = (currentButtonState and MotionEvent.BUTTON_STYLUS_PRIMARY) != 0
        val wasPrimaryPressed = (lastButtonState and MotionEvent.BUTTON_STYLUS_PRIMARY) != 0

        var typeStr: String? = null

        if (buttonChanged) {
            if (isPrimaryPressed && !wasPrimaryPressed) {
                typeStr = "buttonDown"
            } else if (!isPrimaryPressed && wasPrimaryPressed) {
                typeStr = "buttonUp"
            }
            lastButtonState = currentButtonState
        }

        if (typeStr == null) {
            when (event.actionMasked) {
                MotionEvent.ACTION_HOVER_ENTER -> typeStr = "hoverEnter"
                MotionEvent.ACTION_HOVER_MOVE -> typeStr = "hoverMove"
                MotionEvent.ACTION_HOVER_EXIT -> typeStr = "hoverExit"
            }
        }

        if (typeStr != null) {
            val payload = mapOf(
                "type" to typeStr,
                "x" to event.x.toDouble(),
                "y" to event.y.toDouble(),
                "pressure" to event.pressure.toDouble(),
                "tilt" to event.getAxisValue(MotionEvent.AXIS_TILT).toDouble(),
                "distance" to event.getAxisValue(MotionEvent.AXIS_DISTANCE).toDouble(),
                "button" to if (isPrimaryPressed) 1 else 0
            )
            sink.success(payload)
        }
    }
}
