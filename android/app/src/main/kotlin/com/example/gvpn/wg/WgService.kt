package com.example.gvpn.wg

import android.net.VpnService
import android.content.Intent
import android.os.ParcelFileDescriptor

// Service stub buat VPN (placeholder)
class WgService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // TODO: Integrasi backend WireGuard asli
        return START_STICKY
    }

    override fun onDestroy() {
        vpnInterface?.close()
        vpnInterface = null
        super.onDestroy()
    }
}
