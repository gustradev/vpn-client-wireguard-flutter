package com.example.gvpn

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channel = "gvpn/wireguard"
	private val statsChannel = "gvpn/wireguard_stats"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"startTunnel" -> {
						result.success(
							mapOf(
								"state" to "connected",
								"profileId" to (call.argument<String>("profileId") ?: "-"),
								"rxBytes" to 0,
								"txBytes" to 0
							)
						)
					}
					"stopTunnel" -> {
						result.success(
							mapOf(
								"state" to "disconnected",
								"rxBytes" to 0,
								"txBytes" to 0
							)
						)
					}
					"getStatus" -> {
						result.success(
							mapOf(
								"state" to "disconnected",
								"rxBytes" to 0,
								"txBytes" to 0
							)
						)
					}
					"prepareVpn" -> {
						result.success(true)
					}
					else -> result.notImplemented()
				}
			}

		EventChannel(flutterEngine.dartExecutor.binaryMessenger, statsChannel)
			.setStreamHandler(object : EventChannel.StreamHandler {
				override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
					events?.success(
						mapOf(
							"state" to "connected",
							"rxBytes" to 0,
							"txBytes" to 0
						)
					)
				}

				override fun onCancel(arguments: Any?) {
					// no-op
				}
			})
	}
}
