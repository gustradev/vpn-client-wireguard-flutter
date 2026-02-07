import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/domain/entities/tunnel_status.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/domain/repositories/tunnel_repository.dart';

/// Use case for connecting to a WireGuard VPN tunnel.
///
/// This use case handles the connection process including validation,
/// starting the tunnel, and monitoring the connection state.
class ConnectTunnel {
  final TunnelRepository _repository;

  /// Creates a new ConnectTunnel use case.
  ConnectTunnel(this._repository);

  /// Connects to a VPN tunnel using the specified profile.
  ///
  /// [profileId] - The ID of the profile to connect to
  ///
  /// Returns a [Result] containing the initial [TunnelStatus] on success,
  /// or an error message on failure.
  Future<Result<TunnelStatus>> call(String profileId) async {
    // Check if a tunnel is already active
    final activeResult = await _repository.isTunnelActive();
    if (activeResult.isSuccess && activeResult.valueOrThrow) {
      // Get the active profile ID
      final activeProfileResult = await _repository.getActiveTunnelProfileId();
      if (activeProfileResult.isSuccess) {
        final activeProfileId = activeProfileResult.valueOrThrow;
        if (activeProfileId == profileId) {
          return Result.failure(
            'Tunnel is already connected to this profile',
          );
        } else {
          // Disconnect the existing tunnel first
          final disconnectResult = await _repository.stopTunnel();
          if (!disconnectResult.isSuccess) {
            return Result.failure(
              'Failed to disconnect existing tunnel: ${disconnectResult.errorOrNull}',
            );
          }
        }
      }
    }

    // Start the tunnel
    return await _repository.startTunnel(profileId);
  }

  /// Connects to a VPN tunnel with automatic retry on failure.
  ///
  /// [profileId] - The ID of the profile to connect to
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [retryDelay] - Delay between retries in milliseconds (default: 1000)
  ///
  /// Returns a [Result] containing the [TunnelStatus] on success,
  /// or an error message on failure after all retries.
  Future<Result<TunnelStatus>> connectWithRetry(
    String profileId, {
    int maxRetries = 3,
    int retryDelay = 1000,
  }) async {
    Result<TunnelStatus>? lastResult;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      lastResult = await call(profileId);

      if (lastResult.isSuccess) {
        return lastResult;
      }

      // Don't wait after the last attempt
      if (attempt < maxRetries) {
        await Future.delayed(Duration(milliseconds: retryDelay));
      }
    }

    return Result.failure(
      'Failed to connect after $maxRetries attempts: ${lastResult?.errorOrNull ?? "Unknown error"}',
    );
  }

  /// Validates that a profile can be connected to.
  ///
  /// [profileId] - The ID of the profile to validate
  ///
  /// Returns a [Result] containing true if valid,
  /// or an error message describing validation issues.
  Future<Result<bool>> validateConnection(String profileId) async {
    // Get the tunnel configuration
    final configResult = await _repository.getTunnelConfig(profileId);
    if (!configResult.isSuccess) {
      return Result.failure(
        configResult.errorOrNull ?? 'Failed to get tunnel configuration',
      );
    }

    // Validate the configuration
    final validationResult = await _repository.validateTunnelConfig(
      configResult.valueOrThrow,
    );

    return validationResult;
  }

  /// Gets the connection status for a specific profile.
  ///
  /// [profileId] - The ID of the profile
  ///
  /// Returns a [Result] containing the [TunnelStatus] on success,
  /// or an error message on failure.
  Future<Result<TunnelStatus>> getStatus(String profileId) async {
    return await _repository.getTunnelStatusByProfile(profileId);
  }

  /// Checks if a tunnel is connected for a specific profile.
  ///
  /// [profileId] - The ID of the profile to check
  ///
  /// Returns a [Result] containing true if connected,
  /// false otherwise.
  Future<Result<bool>> isConnected(String profileId) async {
    final statusResult = await _repository.getTunnelStatusByProfile(profileId);
    if (!statusResult.isSuccess) {
      return Result.failure(
        statusResult.errorOrNull ?? 'Failed to get tunnel status',
      );
    }

    final status = statusResult.valueOrThrow;
    return Result.success(status.isConnected);
  }

  /// Gets the connection quality for the active tunnel.
  ///
  /// Returns a [Result] containing [ConnectionQuality] on success,
  /// or an error message on failure.
  Future<Result<ConnectionQuality>> getConnectionQuality() async {
    return await _repository.getConnectionQuality();
  }

  /// Gets the tunnel statistics for a specific profile.
  ///
  /// [profileId] - The ID of the profile
  ///
  /// Returns a [Result] containing [TunnelStatistics] on success,
  /// or an error message on failure.
  Future<Result<TunnelStatistics>> getStatistics(String profileId) async {
    return await _repository.getTunnelStatistics(profileId);
  }

  /// Gets the list of active peer connections.
  ///
  /// Returns a [Result] containing a list of [PeerConnection] objects.
  Future<Result<List<PeerConnection>>> getActivePeers() async {
    return await _repository.getActivePeers();
  }

  /// Restarts the tunnel for a specific profile.
  ///
  /// This is equivalent to disconnecting and then reconnecting.
  ///
  /// [profileId] - The ID of the profile to restart
  ///
  /// Returns a [Result] containing the new [TunnelStatus] on success,
  /// or an error message on failure.
  Future<Result<TunnelStatus>> restart(String profileId) async {
    return await _repository.restartTunnel(profileId);
  }

  /// Sets the MTU for the tunnel.
  ///
  /// [mtu] - The MTU value to set
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> setMtu(int mtu) async {
    return await _repository.setTunnelMtu(mtu);
  }

  /// Sets the persistent keepalive interval.
  ///
  /// [intervalSeconds] - The keepalive interval in seconds, or null to disable
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> setPersistentKeepalive(int? intervalSeconds) async {
    return await _repository.setPersistentKeepalive(intervalSeconds);
  }
}
