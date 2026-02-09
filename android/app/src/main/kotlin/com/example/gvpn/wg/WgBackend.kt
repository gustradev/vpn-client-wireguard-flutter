package com.example.gvpn.wg

import android.content.Context
import android.net.TrafficStats
import android.os.Process
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
    private var statsIntrospectionDumped: Boolean = false
    private var backendStatsMethodDumped: Boolean = false

    // Fallback stats: use per-app UID traffic (encrypted tunnel bytes).
    private var uidRxBase: Long? = null
    private var uidTxBase: Long? = null

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

            // Initialize fallback traffic baselines when we are UP.
            if (state == Tunnel.State.UP) {
                val uid = Process.myUid()
                uidRxBase = safeUidBytes { TrafficStats.getUidRxBytes(uid) }
                uidTxBase = safeUidBytes { TrafficStats.getUidTxBytes(uid) }
                Log.i(TAG, "TrafficStats baseline rx=${uidRxBase ?: -1} tx=${uidTxBase ?: -1}")
            }
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
                uidRxBase = null
                uidTxBase = null
                return true
            }
            val state = backend!!.setState(tunnel!!, Tunnel.State.DOWN, null)
            currentState = state
            Log.i(TAG, "stopTunnel -> $state")

            uidRxBase = null
            uidTxBase = null
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

    /**
     * Best-effort transfer stats (rxBytes, txBytes).
     *
     * WireGuard's Android Backend API exposes statistics, but the exact type/members
     * differ between versions. We use reflection to stay compatible.
     */
    fun getTransferStats(context: Context): Pair<Long, Long>? {
        return try {
            ensureBackend(context)
            val b = backend ?: return null
            val t = tunnel ?: return null

            val statsMethod = findStatsMethod(b, t)
            if (statsMethod == null) {
                if (!backendStatsMethodDumped) {
                    backendStatsMethodDumped = true
                    val statLike = b.javaClass.methods
                        .filter { it.name.contains("stat", ignoreCase = true) || it.name.contains("byte", ignoreCase = true) || it.name.contains("transfer", ignoreCase = true) }
                        .map { m -> "${m.name}(${m.parameterTypes.joinToString(";") { it.simpleName }})" }
                        .distinct()
                        .sorted()
                        .joinToString(",")
                    Log.w(TAG, "No statistics method found on backend=${b.javaClass.name}. Candidates: $statLike")
                }
                return fallbackUidDeltas()
            }

            Log.d(TAG, "Using stats method ${statsMethod.name} on ${b.javaClass.simpleName}")
            val stats = invokeStatsMethod(b, t, statsMethod) ?: return fallbackUidDeltas()

            val rx = readLongMember(stats, rxMemberNames())
            val tx = readLongMember(stats, txMemberNames())

            // Some library versions expose per-peer stats; aggregate them if totals aren't present.
            val aggregated = if (rx == null || tx == null) aggregatePeerStats(stats) else null
            val finalRx = rx ?: aggregated?.first
            val finalTx = tx ?: aggregated?.second

            if (finalRx == null || finalTx == null) {
                Log.w(TAG, "Statistics object missing rx/tx members: ${stats.javaClass.name}")
                if (!statsIntrospectionDumped) {
                    statsIntrospectionDumped = true
                    val methodNames = stats.javaClass.methods
                        .map { it.name }
                        .distinct()
                        .sorted()
                        .joinToString(",")
                    val fieldNames = stats.javaClass.fields
                        .map { it.name }
                        .distinct()
                        .sorted()
                        .joinToString(",")
                    Log.w(TAG, "Statistics methods: $methodNames")
                    Log.w(TAG, "Statistics fields: $fieldNames")
                }
                return fallbackUidDeltas()
            }
            Pair(finalRx, finalTx)
        } catch (e: Exception) {
            Log.w(TAG, "getTransferStats failed: ${e.message}")
            fallbackUidDeltas()
        }
    }

    private fun fallbackUidDeltas(): Pair<Long, Long>? {
        val uid = Process.myUid()
        val rxNow = safeUidBytes { TrafficStats.getUidRxBytes(uid) } ?: return null
        val txNow = safeUidBytes { TrafficStats.getUidTxBytes(uid) } ?: return null

        // If baseline isn't set (e.g., app started with tunnel already up), set it now.
        val rxBase = uidRxBase ?: rxNow.also { uidRxBase = it }
        val txBase = uidTxBase ?: txNow.also { uidTxBase = it }

        val rx = (rxNow - rxBase).coerceAtLeast(0L)
        val tx = (txNow - txBase).coerceAtLeast(0L)
        return Pair(rx, tx)
    }

    private fun safeUidBytes(getter: () -> Long): Long? {
        val v = try { getter() } catch (_: Exception) { -1L }
        return if (v < 0L) null else v
    }

    private fun rxMemberNames(): List<String> = listOf(
        "totalRx",
        "getTotalRx",
        "rxTotal",
        "getRxTotal",
        "rxBytes",
        "getRxBytes",
        "receivedBytes",
        "getReceivedBytes",
        "downloadBytes",
        "getDownloadBytes"
    )

    private fun txMemberNames(): List<String> = listOf(
        "totalTx",
        "getTotalTx",
        "txTotal",
        "getTxTotal",
        "txBytes",
        "getTxBytes",
        "sentBytes",
        "getSentBytes",
        "uploadBytes",
        "getUploadBytes"
    )

    private fun findStatsMethod(backend: Any, tunnel: Tunnel): java.lang.reflect.Method? {
        val candidates = mutableListOf<java.lang.reflect.Method>()
        candidates.addAll(backend.javaClass.methods)
        candidates.addAll(backend.javaClass.declaredMethods)

        fun matchesName(m: java.lang.reflect.Method): Boolean {
            val n = m.name
            return n.equals("getStatistics", ignoreCase = true) ||
                n.equals("getStats", ignoreCase = true) ||
                n.contains("statistic", ignoreCase = true) ||
                n.contains("stats", ignoreCase = true)
        }

        // Prefer exact getStatistics(Tunnel)
        val oneArg = candidates.firstOrNull { m ->
            matchesName(m) &&
                m.parameterTypes.size == 1 &&
                m.parameterTypes[0].isAssignableFrom(tunnel.javaClass)
        }
        if (oneArg != null) return oneArg

        // Fallback: any stats-like method with 1 arg assignable from Tunnel interface
        val oneArgTunnel = candidates.firstOrNull { m ->
            matchesName(m) &&
                m.parameterTypes.size == 1 &&
                Tunnel::class.java.isAssignableFrom(m.parameterTypes[0])
        }
        if (oneArgTunnel != null) return oneArgTunnel

        // Fallback: no-arg stats method (rare)
        val noArg = candidates.firstOrNull { m -> matchesName(m) && m.parameterTypes.isEmpty() }
        if (noArg != null) return noArg

        return null
    }

    private fun invokeStatsMethod(backend: Any, tunnel: Tunnel, method: java.lang.reflect.Method): Any? {
        return try {
            method.isAccessible = true
            if (method.parameterTypes.isEmpty()) method.invoke(backend) else method.invoke(backend, tunnel)
        } catch (e: Exception) {
            Log.w(TAG, "invokeStatsMethod failed: ${e.message}")
            null
        }
    }

    private fun aggregatePeerStats(stats: Any): Pair<Long, Long>? {
        return try {
            // Try to find a peer collection/map inside the stats object.
            val peerCarrier = findPeerCarrier(stats) ?: return null

            var sumRx = 0L
            var sumTx = 0L

            when (peerCarrier) {
                is Map<*, *> -> {
                    for (v in peerCarrier.values) {
                        if (v == null) continue
                        val rx = readLongMember(v, rxMemberNames())
                        val tx = readLongMember(v, txMemberNames())
                        if (rx != null) sumRx += rx
                        if (tx != null) sumTx += tx
                    }
                }
                is Iterable<*> -> {
                    for (v in peerCarrier) {
                        if (v == null) continue
                        val rx = readLongMember(v, rxMemberNames())
                        val tx = readLongMember(v, txMemberNames())
                        if (rx != null) sumRx += rx
                        if (tx != null) sumTx += tx
                    }
                }
                else -> {
                    val rx = readLongMember(peerCarrier, rxMemberNames())
                    val tx = readLongMember(peerCarrier, txMemberNames())
                    if (rx != null) sumRx += rx
                    if (tx != null) sumTx += tx
                }
            }

            if (sumRx == 0L && sumTx == 0L) null else Pair(sumRx, sumTx)
        } catch (_: Exception) {
            null
        }
    }

    private fun findPeerCarrier(stats: Any): Any? {
        val names = listOf(
            "peers",
            "getPeers",
            "peerStats",
            "getPeerStats",
            "peerMap",
            "getPeerMap"
        )
        for (name in names) {
            try {
                val m = stats.javaClass.methods.firstOrNull { it.name == name && it.parameterTypes.isEmpty() }
                if (m != null) {
                    val v = m.invoke(stats)
                    if (v != null) return v
                }
                val f = stats.javaClass.fields.firstOrNull { it.name == name }
                if (f != null) {
                    val v = f.get(stats)
                    if (v != null) return v
                }
            } catch (_: Exception) {
                // try next
            }
        }
        return null
    }

    private fun readLongMember(target: Any, names: List<String>): Long? {
        for (name in names) {
            try {
                // no-arg method
                val m = target.javaClass.methods.firstOrNull { it.name == name && it.parameterTypes.isEmpty() }
                if (m != null) {
                    val v = m.invoke(target) ?: continue
                    return (v as? Number)?.toLong() ?: continue
                }
                // field
                val f = target.javaClass.fields.firstOrNull { it.name == name }
                if (f != null) {
                    val v = f.get(target) ?: continue
                    return (v as? Number)?.toLong() ?: continue
                }
            } catch (_: Exception) {
                // try next name
            }
        }
        return null
    }
}
