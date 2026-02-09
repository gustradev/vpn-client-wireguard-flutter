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
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
	private val tag = "MainActivity"
    private val channel = "gvpn/wireguard"
    private val statsChannel = "gvpn/wireguard_stats"

	// WireGuard (GoBackend) does blocking work and must not run on the main thread.
	private val wgExecutor = Executors.newSingleThreadExecutor()
	private val statsExecutor = Executors.newSingleThreadScheduledExecutor()
	private var statsFuture: ScheduledFuture<*>? = null
	private var statsTickCount: Long = 0

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
			statsFuture?.cancel(true)
			statsExecutor.shutdown()
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
							val stats = if (ok) WgBackend.getTransferStats(applicationContext) else null
							val rx = stats?.first ?: 0L
							val tx = stats?.second ?: 0L
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
											"rxBytes" to rx,
											"txBytes" to tx
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
						val resultRef = result
						wgExecutor.execute {
							val state = WgBackend.getState()
							val stateRaw = when (state) {
								com.wireguard.android.backend.Tunnel.State.UP -> "connected"
								com.wireguard.android.backend.Tunnel.State.DOWN -> "disconnected"
								else -> "connecting"
							}
							val stats = WgBackend.getTransferStats(applicationContext)
							val rx = stats?.first ?: 0L
							val tx = stats?.second ?: 0L
							runOnUiThread {
								resultRef.success(
									mapOf(
										"state" to stateRaw,
										"profileId" to (WgBackend.getActiveProfileId() ?: "-"),
										"endpoint" to WgBackend.getEndpoint(),
										"rxBytes" to rx,
										"txBytes" to tx
									)
								)
							}
						}
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
					if (events == null) return
					Log.i(tag, "stats onListen")
					statsFuture?.cancel(true)
					statsTickCount = 0
					statsFuture = statsExecutor.scheduleAtFixedRate({
						statsTickCount += 1
						val state = WgBackend.getState()
						val stateRaw = when (state) {
							com.wireguard.android.backend.Tunnel.State.UP -> "connected"
							com.wireguard.android.backend.Tunnel.State.DOWN -> "disconnected"
							else -> "connecting"
						}
						val stats = WgBackend.getTransferStats(applicationContext)
						val rx = stats?.first ?: 0L
						val tx = stats?.second ?: 0L
						if (statsTickCount == 1L || statsTickCount % 10L == 0L) {
							Log.d(tag, "stats tick#$statsTickCount state=$stateRaw rx=$rx tx=$tx")
						}
						runOnUiThread {
							try {
								events.success(
									mapOf(
										"state" to stateRaw,
										"profileId" to (WgBackend.getActiveProfileId() ?: "-"),
										"endpoint" to WgBackend.getEndpoint(),
										"rxBytes" to rx,
										"txBytes" to tx
									)
								)
							} catch (e: Exception) {
								Log.w(tag, "stats stream send failed: ${e.message}")
							}
						}
					}, 0, 1, TimeUnit.SECONDS)
				}

				override fun onCancel(arguments: Any?) {
					Log.i(tag, "stats onCancel")
					statsFuture?.cancel(true)
					statsFuture = null
				}
			})
	}
}
