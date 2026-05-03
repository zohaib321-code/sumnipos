package com.pos.app.sunmi_pos

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.sunmi.peripheral.printer.InnerPrinterManager
import com.sunmi.peripheral.printer.InnerPrinterCallback
import com.sunmi.peripheral.printer.SunmiPrinterService
import com.sunmi.peripheral.printer.InnerResultCallback

class MainActivity: FlutterActivity() {
    private val CHANNEL = "sunmi_printer"
    private var sunmiPrinterService: SunmiPrinterService? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "BIND_PRINTER_SERVICE" -> {
                    bindPrinterService(result)
                }
                "INIT_PRINTER" -> {
                    sunmiPrinterService?.updatePrinterState()
                    result.success(true)
                }
                "SET_ALIGNMENT" -> {
                    val alignment = call.argument<Int>("alignment") ?: 0
                    sunmiPrinterService?.setAlignment(alignment, null)
                    result.success(true)
                }
                "PRINT_TEXT" -> {
                    val text = call.argument<String>("text") ?: ""
                    val size = call.argument<Int>("size")
                    if (size != null) {
                        sunmiPrinterService?.setFontSize(size.toFloat(), null)
                    } else {
                        sunmiPrinterService?.setFontSize(24.0f, null) // Default
                    }
                    sunmiPrinterService?.printText(text, null)
                    result.success(true)
                }
                "LINE_WRAP" -> {
                    val lines = call.argument<Int>("lines") ?: 1
                    sunmiPrinterService?.lineWrap(lines, null)
                    result.success(true)
                }
                "CUT_PAPER" -> {
                    sunmiPrinterService?.cutPaper(null)
                    result.success(true)
                }
                "SEND_LCD_COMMAND" -> {
                    val command = call.argument<Int>("command") ?: 1
                    val text = call.argument<String>("text") ?: ""
                    if (command == 1) {
                        sunmiPrinterService?.sendLCDString(text, null)
                    }
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun bindPrinterService(result: MethodChannel.Result) {
        var responded = false
        val handler = android.os.Handler(android.os.Looper.getMainLooper())
        val timeoutRunnable = Runnable {
            if (!responded) {
                responded = true
                result.success(false)
            }
        }

        try {
            handler.postDelayed(timeoutRunnable, 1000) // 1 second timeout for non-Sunmi devices

            InnerPrinterManager.getInstance().bindService(this, object : InnerPrinterCallback() {
                override fun onConnected(service: SunmiPrinterService) {
                    if (!responded) {
                        responded = true
                        handler.removeCallbacks(timeoutRunnable)
                        sunmiPrinterService = service
                        result.success(true)
                    }
                }

                override fun onDisconnected() {
                    sunmiPrinterService = null
                }
            })
        } catch (e: Exception) {
            if (!responded) {
                responded = true
                handler.removeCallbacks(timeoutRunnable)
                result.success(false)
            }
        }
    }
}
