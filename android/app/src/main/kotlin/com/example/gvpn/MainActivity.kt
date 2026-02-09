package com.example.gvpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.util.Log
import com.example.gvpn.wg.WgBackend
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
	private val tag = "MainActivity"
    private val channel = "gvpn/wireguard"
    private val statsChannel = "gvpn/wireguard_stats"

	// WireGuard (GoBackend) does blocking work and must not run on the main thread.
	private val wgExecutor = Executors.newSingleThreadExecutor()

	private val vpnPermissionRequestCode = 9723
	private var pendingVpnPermissionResult: MethodChannel.Result? = null

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
		super.onActivityResult(requestCode, resultCode, data)
		if (requestCode != vpnPermissionRequestCode) return
		val granted = resultCode == Activity.RESULT_OK
		Log.i(tag, "VPN permission result granted=$granted")
		pendingVpnPermissionResult?.success(granted)
		pendingVpnPermissionResult = null
	}

	override fun onDestroy() {
		try {
			wgExecutor.shutdown()
		} catch (_: Exception) {
			// no-op
		}
		super.onDestroy()
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"startTunnel" -> {
						val rawConfig = call.argument<String>("config") ?: ""
						if (rawConfig.isBlank()) {
							Log.w(tag, "startTunnel rejected: blank config")
							result.error("WG_START_FAILED", "Config kosong / tidak terbaca", null)
							return@setMethodCallHandler
						}

						val normalizedConfig = rawConfig
							.replace("\r\n", "\n")
							.replace("\r", "\n")
							.trim()

						val profileId = call.argument<String>("profileId") ?: "gvpn_default"
						Log.i(tag, "startTunnel profileId=$profileId configChars=${normalizedConfig.length}")

						// Run WireGuard startup off the UI thread.
						val resultRef = result
						wgExecutor.execute {
							val ok = WgBackend.startTunnel(applicationContext, normalizedConfig, profileId)
							val detail = if (!ok) (WgBackend.getLastError() ?: "WireGuard start failed") else null
							val endpoint = if (ok) WgBackend.getEndpoint() else null
							runOnUiThread {
								if (!ok) {
									Log.e(tag, "WG_START_FAILED: $detail")
									resultRef.error("WG_START_FAILED", detail, null)
								} else {
									resultRef.success(
										mapOf(
											"state" to "connected",
											"profileId" to profileId,
											"endpoint" to endpoint,
											"rxBytes" to 0,
											"txBytes" to 0
										)
									)
								}
							}
						}
					}
					"stopTunnel" -> {
						Log.i(tag, "stopTunnel")
						val resultRef = result
						wgExecutor.execute {
							val ok = WgBackend.stopTunnel()
							val state = if (ok) "disconnected" else "error"
							runOnUiThread {
								resultRef.success(
									mapOf(
										"state" to state,
										"rxBytes" to 0,
										"txBytes" to 0
									)
								)
							}
						}
					}
					"getStatus" -> {
						val state = WgBackend.getState()
						val stateRaw = when (state) {
							com.wireguard.android.backend.Tunnel.State.UP -> "connected"
							com.wireguard.android.backend.Tunnel.State.DOWN -> "disconnected"
							else -> "connecting"
						}
						result.success(
							mapOf(
								"state" to stateRaw,
								"profileId" to (WgBackend.getActiveProfileId() ?: "-"),
								"endpoint" to WgBackend.getEndpoint(),
								"rxBytes" to 0,
								"txBytes" to 0
							)
						)
					}
					"prepareVpn" -> {
						val intent = VpnService.prepare(this)
						if (intent != null) {
							if (pendingVpnPermissionResult != null) {
								result.error(
									"VPN_PERMISSION_IN_PROGRESS",
									"VPN permission request already in progress",
									null
								)
								return@setMethodCallHandler
							}
							Log.i(tag, "Requesting VPN permission")
							pendingVpnPermissionResult = result
							startActivityForResult(intent, vpnPermissionRequestCode)
						} else {
							Log.i(tag, "VPN permission already granted")
							result.success(true)
						}
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
