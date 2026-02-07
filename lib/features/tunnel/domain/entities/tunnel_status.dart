import 'package:equatable/equatable.dart';

/// Ini model buat status tunnel WireGuard.
///
/// Di sini ada info soal status koneksi tunnel, handshake, sama statistik data yang lewat.
class TunnelStatus extends Equatable {
  /// ID profil yang punya status ini
  final String profileId;

  /// Status koneksi tunnel sekarang
  final TunnelState state;

  /// Kapan status tunnel terakhir berubah
  final DateTime lastStateChange;

  /// Info handshake tunnel
  final HandshakeInfo? handshake;

  /// Statistik data yang lewat tunnel
  final TransferStats transferStats;

  /// Pesan error kalau tunnel lagi error
  final String? errorMessage;

  /// Kapan status ini terakhir diupdate
  final DateTime updatedAt;

  const TunnelStatus({
    required this.profileId,
    required this.state,
    required this.lastStateChange,
    this.handshake,
    required this.transferStats,
    this.errorMessage,
    required this.updatedAt,
  });

  /// Bikin salinan status tunnel, bisa ganti beberapa field
  TunnelStatus copyWith({
    String? profileId,
    TunnelState? state,
    DateTime? lastStateChange,
    HandshakeInfo? handshake,
    TransferStats? transferStats,
    String? errorMessage,
    DateTime? updatedAt,
  }) {
    return TunnelStatus(
      profileId: profileId ?? this.profileId,
      state: state ?? this.state,
      lastStateChange: lastStateChange ?? this.lastStateChange,
      handshake: handshake ?? this.handshake,
      transferStats: transferStats ?? this.transferStats,
      errorMessage: errorMessage ?? this.errorMessage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// True kalau tunnel lagi konek
  bool get isConnected => state == TunnelState.connected;

  /// Returns true if the tunnel is currently connecting
  bool get isConnecting => state == TunnelState.connecting;

  /// Returns true if the tunnel is currently disconnecting
  bool get isDisconnecting => state == TunnelState.disconnecting;

  /// Returns true if the tunnel is in an error state
  bool get hasError => state == TunnelState.error;

  /// Returns true if the tunnel is disconnected
  bool get isDisconnected => state == TunnelState.disconnected;

  /// Returns true if a handshake has been completed
  bool get hasHandshake => handshake != null;

  /// Returns the duration since the last handshake
  Duration? get timeSinceHandshake {
    if (handshake == null) return null;
    return DateTime.now().difference(handshake!.timestamp);
  }

  /// Returns true if the handshake is stale (older than 3 minutes)
  bool get isHandshakeStale {
    if (handshake == null) return false;
    return timeSinceHandshake!.inMinutes > 3;
  }

  @override
  List<Object?> get props => [
        profileId,
        state,
        lastStateChange,
        handshake,
        transferStats,
        errorMessage,
        updatedAt,
      ];
}

/// Represents the possible states of a WireGuard tunnel.
enum TunnelState {
  /// Tunnel is disconnected
  disconnected,

  /// Tunnel is in the process of connecting
  connecting,

  /// Tunnel is connected and active
  connected,

  /// Tunnel is in the process of disconnecting
  disconnecting,

  /// Tunnel encountered an error
  error,

  /// Tunnel state is unknown
  unknown,
}

/// Represents handshake information for a WireGuard tunnel.
class HandshakeInfo extends Equatable {
  /// Timestamp when the handshake occurred
  final DateTime timestamp;

  /// Public key of the peer that completed the handshake
  final String peerPublicKey;

  /// Endpoint address of the peer
  final String? endpoint;

  /// Whether the handshake was successful
  final bool isSuccessful;

  /// Optional error message if handshake failed
  final String? errorMessage;

  const HandshakeInfo({
    required this.timestamp,
    required this.peerPublicKey,
    this.endpoint,
    required this.isSuccessful,
    this.errorMessage,
  });

  /// Creates a copy of this handshake info with some fields replaced
  HandshakeInfo copyWith({
    DateTime? timestamp,
    String? peerPublicKey,
    String? endpoint,
    bool? isSuccessful,
    String? errorMessage,
  }) {
    return HandshakeInfo(
      timestamp: timestamp ?? this.timestamp,
      peerPublicKey: peerPublicKey ?? this.peerPublicKey,
      endpoint: endpoint ?? this.endpoint,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Returns true if the handshake has an endpoint
  bool get hasEndpoint => endpoint != null && endpoint!.isNotEmpty;

  @override
  List<Object?> get props => [
        timestamp,
        peerPublicKey,
        endpoint,
        isSuccessful,
        errorMessage,
      ];
}

/// Represents data transfer statistics for a WireGuard tunnel.
class TransferStats extends Equatable {
  /// Total bytes received (download)
  final int rxBytes;

  /// Total bytes sent (upload)
  final int txBytes;

  /// Timestamp when these stats were last updated
  final DateTime lastUpdated;

  const TransferStats({
    required this.rxBytes,
    required this.txBytes,
    required this.lastUpdated,
  });

  /// Creates a copy of this transfer stats with some fields replaced
  TransferStats copyWith({
    int? rxBytes,
    int? txBytes,
    DateTime? lastUpdated,
  }) {
    return TransferStats(
      rxBytes: rxBytes ?? this.rxBytes,
      txBytes: txBytes ?? this.txBytes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Returns the total bytes transferred (rx + tx)
  int get totalBytes => rxBytes + txBytes;

  /// Returns the download speed in bytes per second (if available)
  double? get downloadSpeed {
    // This would need to be calculated based on previous stats
    // For now, return null as it requires historical data
    return null;
  }

  /// Returns the upload speed in bytes per second (if available)
  double? get uploadSpeed {
    // This would need to be calculated based on previous stats
    // For now, return null as it requires historical data
    return null;
  }

  /// Returns the rx bytes formatted as a human-readable string
  String get formattedRxBytes => _formatBytes(rxBytes);

  /// Returns the tx bytes formatted as a human-readable string
  String get formattedTxBytes => _formatBytes(txBytes);

  /// Returns the total bytes formatted as a human-readable string
  String get formattedTotalBytes => _formatBytes(totalBytes);

  /// Formats bytes to a human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  List<Object?> get props => [rxBytes, txBytes, lastUpdated];
}
