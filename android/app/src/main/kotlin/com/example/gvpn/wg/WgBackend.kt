package com.example.gvpn.wg

import android.content.Context
import android.util.Log
import com.wireguard.android.backend.Backend
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.Config
import java.nio.charset.Charset

// Backend WireGuard Android (Go userspace)
object WgBackend {
    private const val TAG = "WgBackend"
    private var backend: Backend? = null
    private var tunnel: Tunnel? = null
    private var currentState: Tunnel.State = Tunnel.State.DOWN
    private var lastProfileId: String? = null
    private var lastConfig: Config? = null
    private var lastError: String? = null

    private fun ensureBackend(context: Context) {
        if (backend == null) {
            backend = GoBackend(context.applicationContext)
        }
        if (tunnel == null) {
            tunnel = object : Tunnel {
                override fun getName(): String = "wg0"

                override fun onStateChange(state: Tunnel.State) {
                    currentState = state
                }
            }
        }
    }

    fun startTunnel(context: Context, configText: String, profileId: String?): Boolean {
        return try {
            lastError = null
            if (configText.isBlank()) {
                lastError = "Config kosong"
                return false
            }
            ensureBackend(context)

            Log.i(TAG, "startTunnel profileId=${profileId ?: "-"} configChars=${configText.length}")

            val normalized = configText
                .replace("\r\n", "\n")
                .replace("\r", "\n")
                .trim()

            // Strip UTF-8 BOM if present
            val withoutBom = normalized.removePrefix("\uFEFF")

            if (!withoutBom.contains("[Interface]") || !withoutBom.contains("[Peer]")) {
                lastError = "Config harus punya [Interface] dan [Peer]"
                Log.w(TAG, "startTunnel rejected: missing sections")
                return false
            }

            val sanitized = withoutBom.replace(
                Regex("(?m)^\\s*PersistentKeepalive\\s*=\\s*0\\s*$", RegexOption.IGNORE_CASE),
                ""
            )

            val inputStream = sanitized.trim().toByteArray(Charset.forName("UTF-8")).inputStream()
            val config = Config.parse(inputStream)

            // Safe to log: counts/endpoints only (never keys)
            val peerCount = try { config.peers.size } catch (_: Exception) { -1 }
            val endpoint = try { config.peers.firstOrNull()?.endpoint?.toString() } catch (_: Exception) { null }
            Log.i(TAG, "parsed config peers=$peerCount endpoint=${endpoint ?: "-"}")

            val state = backend!!.setState(tunnel!!, Tunnel.State.UP, config)
            currentState = state
            lastConfig = config
            lastProfileId = profileId
            Log.i(TAG, "backend setState -> $state")
            state == Tunnel.State.UP
        } catch (e: Exception) {
            lastError = e.message ?: e.toString()
            Log.e(TAG, "startTunnel failed: ${lastError}", e)
            false
        }
    }

    fun stopTunnel(): Boolean {
        return try {
            lastError = null
            if (backend == null || tunnel == null) {
                currentState = Tunnel.State.DOWN
                return true
            }
            val state = backend!!.setState(tunnel!!, Tunnel.State.DOWN, null)
            currentState = state
            Log.i(TAG, "stopTunnel -> $state")
            true
        } catch (e: Exception) {
            lastError = e.message ?: e.toString()
            Log.e(TAG, "stopTunnel failed: ${lastError}", e)
            false
        }
    }

    fun getLastError(): String? = lastError

    fun getState(): Tunnel.State = currentState

    fun getActiveProfileId(): String? = lastProfileId

    fun getEndpoint(): String? {
        val peers = lastConfig?.peers ?: return null
        val endpoint = peers.firstOrNull()?.endpoint ?: return null
        return endpoint.toString()
    }
}
