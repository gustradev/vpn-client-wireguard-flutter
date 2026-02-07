import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/domain/entities/tunnel_status.dart';

/// Repository interface for managing WireGuard tunnel connections.
///
/// This interface defines the contract for tunnel operations including
/// starting, stopping, and monitoring tunnel status.
abstract class TunnelRepository {
  /// Starts a WireGuard tunnel for the specified profile.
  ///
  /// Returns a [Result] containing the initial [TunnelStatus] on success,
  /// or an error message on failure.
  ///
  /// The tunnel will be configured using the profile's settings and
  /// will attempt to establish a connection with the configured peers.
  Future<Result<TunnelStatus>> startTunnel(String profileId);

  /// Stops the currently active WireGuard tunnel.
  ///
  /// Returns a [Result] containing the final [TunnelStatus] on success,
  /// or an error message on failure.
  ///
  /// If no tunnel is active, this will return a success result with
  /// a disconnected status.
  Future<Result<TunnelStatus>> stopTunnel();

  /// Gets the current status of the tunnel.
  ///
  /// Returns a [Result] containing the current [TunnelStatus] on success,
  /// or an error message on failure.
  ///
  /// This method retrieves the latest tunnel state including connection
  /// status, handshake information, and transfer statistics.
  Future<Result<TunnelStatus>> getTunnelStatus();

  /// Gets the tunnel status for a specific profile.
  ///
  /// Returns a [Result] containing the [TunnelStatus] for the specified profile,
  /// or an error message if the profile is not found or an error occurs.
  Future<Result<TunnelStatus>> getTunnelStatusByProfile(String profileId);

  /// Restarts the tunnel for the specified profile.
  ///
  /// This is equivalent to stopping and then starting the tunnel.
  /// Returns a [Result] containing the new [TunnelStatus] on success,
  /// or an error message on failure.
  Future<Result<TunnelStatus>> restartTunnel(String profileId);

  /// Checks if a tunnel is currently active.
  ///
  /// Returns a [Result] containing true if a tunnel is active,
  /// false otherwise.
  Future<Result<bool>> isTunnelActive();

  /// Gets the profile ID of the currently active tunnel.
  ///
  /// Returns a [Result] containing the profile ID if a tunnel is active,
  /// or null if no tunnel is active.
  Future<Result<String?>> getActiveTunnelProfileId();

  /// Subscribes to tunnel status updates.
  ///
  /// Returns a [Stream] that emits [TunnelStatus] updates whenever
  /// the tunnel state changes.
  ///
  /// The stream will emit updates for:
  /// - Connection state changes (connecting, connected, disconnecting, disconnected)
  /// - Handshake events
  /// - Transfer statistics updates
  /// - Error states
  Stream<TunnelStatus> watchTunnelStatus();

  /// Gets the tunnel configuration for the specified profile.
  ///
  /// Returns a [Result] containing the configuration string on success,
  /// or an error message on failure.
  ///
  /// The configuration is in WireGuard config format and can be used
  /// for debugging or manual configuration.
  Future<Result<String>> getTunnelConfig(String profileId);

  /// Validates a tunnel configuration.
  ///
  /// Returns a [Result] containing true if the configuration is valid,
  /// or an error message describing the validation issues.
  Future<Result<bool>> validateTunnelConfig(String config);

  /// Gets the tunnel statistics for the specified profile.
  ///
  /// Returns a [Result] containing [TunnelStatistics] on success,
  /// or an error message on failure.
  Future<Result<TunnelStatistics>> getTunnelStatistics(String profileId);

  /// Resets the tunnel statistics for the specified profile.
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> resetTunnelStatistics(String profileId);

  /// Gets the list of active peer connections.
  ///
  /// Returns a [Result] containing a list of [PeerConnection] objects.
  Future<Result<List<PeerConnection>>> getActivePeers();

  /// Gets the connection quality metrics for the tunnel.
  ///
  /// Returns a [Result] containing [ConnectionQuality] metrics.
  Future<Result<ConnectionQuality>> getConnectionQuality();

  /// Sets the tunnel MTU (Maximum Transmission Unit).
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> setTunnelMtu(int mtu);

  /// Gets the current tunnel MTU.
  ///
  /// Returns a [Result] containing the MTU value.
  Future<Result<int>> getTunnelMtu();

  /// Enables or disables persistent keepalive for the tunnel.
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> setPersistentKeepalive(int? intervalSeconds);

  /// Gets the current persistent keepalive interval.
  ///
  /// Returns a [Result] containing the interval in seconds,
  /// or null if persistent keepalive is disabled.
  Future<Result<int?>> getPersistentKeepalive();
}

/// Represents tunnel statistics for a profile.
class TunnelStatistics {
  /// Total bytes received (download)
  final int totalRxBytes;

  /// Total bytes sent (upload)
  final int totalTxBytes;

  /// Total bytes transferred
  int get totalBytes => totalRxBytes + totalTxBytes;

  /// Timestamp when statistics collection started
  final DateTime startTime;

  /// Timestamp when statistics were last updated
  final DateTime lastUpdated;

  /// Number of successful handshakes
  final int handshakeCount;

  /// Number of connection errors
  final int errorCount;

  /// Average latency in milliseconds
  final double? averageLatencyMs;

  /// Peak latency in milliseconds
  final double? peakLatencyMs;

  const TunnelStatistics({
    required this.totalRxBytes,
    required this.totalTxBytes,
    required this.startTime,
    required this.lastUpdated,
    this.handshakeCount = 0,
    this.errorCount = 0,
    this.averageLatencyMs,
    this.peakLatencyMs,
  });

  /// Returns the duration since statistics collection started
  Duration get duration => lastUpdated.difference(startTime);

  /// Returns the download speed in bytes per second
  double get downloadSpeedBytesPerSecond {
    final seconds = duration.inSeconds;
    if (seconds <= 0) return 0;
    return totalRxBytes / seconds;
  }

  /// Returns the upload speed in bytes per second
  double get uploadSpeedBytesPerSecond {
    final seconds = duration.inSeconds;
    if (seconds <= 0) return 0;
    return totalTxBytes / seconds;
  }

  /// Returns the total speed in bytes per second
  double get totalSpeedBytesPerSecond =>
      downloadSpeedBytesPerSecond + uploadSpeedBytesPerSecond;
}

/// Represents an active peer connection.
class PeerConnection {
  /// Public key of the peer
  final String publicKey;

  /// Endpoint address of the peer
  final String? endpoint;

  /// Whether the peer is currently connected
  final bool isConnected;

  /// Timestamp of the last handshake
  final DateTime? lastHandshake;

  /// Bytes received from this peer
  final int rxBytes;

  /// Bytes sent to this peer
  final int txBytes;

  /// Allowed IPs for this peer
  final List<String> allowedIps;

  const PeerConnection({
    required this.publicKey,
    this.endpoint,
    required this.isConnected,
    this.lastHandshake,
    required this.rxBytes,
    required this.txBytes,
    this.allowedIps = const [],
  });

  /// Returns the total bytes transferred with this peer
  int get totalBytes => rxBytes + txBytes;

  /// Returns the time since the last handshake
  Duration? get timeSinceHandshake {
    if (lastHandshake == null) return null;
    return DateTime.now().difference(lastHandshake!);
  }
}

/// Represents connection quality metrics.
class ConnectionQuality {
  /// Overall connection quality score (0-100)
  final int score;

  /// Current latency in milliseconds
  final double latencyMs;

  /// Packet loss percentage (0-100)
  final double packetLossPercent;

  /// Jitter in milliseconds
  final double jitterMs;

  /// Signal strength (for mobile connections)
  final int? signalStrengthDbm;

  /// Connection type (e.g., WiFi, Cellular, Ethernet)
  final String? connectionType;

  const ConnectionQuality({
    required this.score,
    required this.latencyMs,
    required this.packetLossPercent,
    required this.jitterMs,
    this.signalStrengthDbm,
    this.connectionType,
  });

  /// Returns the connection quality level
  ConnectionQualityLevel get level {
    if (score >= 80) return ConnectionQualityLevel.excellent;
    if (score >= 60) return ConnectionQualityLevel.good;
    if (score >= 40) return ConnectionQualityLevel.fair;
    return ConnectionQualityLevel.poor;
  }

  /// Returns true if the connection quality is acceptable
  bool get isAcceptable => score >= 40;
}

/// Represents the connection quality level.
enum ConnectionQualityLevel {
  /// Excellent connection quality (80-100)
  excellent,

  /// Good connection quality (60-79)
  good,

  /// Fair connection quality (40-59)
  fair,

  /// Poor connection quality (0-39)
  poor,
}
