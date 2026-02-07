import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/domain/entities/tunnel_status.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/domain/repositories/tunnel_repository.dart';

/// Use case buat disconnect dari tunnel WireGuard VPN.
///
/// Di sini proses disconnect, stop tunnel, dan bersihin resource.
class DisconnectTunnel {
  final TunnelRepository _repository;

  /// Bikin instance DisconnectTunnel use case.
  DisconnectTunnel(this._repository);

  /// Disconnect dari tunnel VPN yang lagi aktif.
  ///
  /// Return [Result] berisi [TunnelStatus] terakhir kalau sukses, atau error kalau gagal.
  Future<Result<TunnelStatus>> call() async {
    // Check if a tunnel is active
    final activeResult = await _repository.isTunnelActive();
    if (!activeResult.isSuccess) {
      return Result.failure(
        activeResult.errorOrNull ?? 'Failed to check tunnel status',
      );
    }

    if (!activeResult.valueOrThrow) {
      return Result.failure('No active tunnel to disconnect');
    }

    // Stop the tunnel
    return await _repository.stopTunnel();
  }

  /// Disconnect dari tunnel VPN dengan retry otomatis kalau gagal.
  ///
  /// [maxRetries] - Maksimal percobaan retry (default: 3)
  /// [retryDelay] - Jeda antar retry (ms, default: 1000)
  ///
  /// Return [Result] berisi [TunnelStatus] terakhir kalau sukses, atau error kalau gagal setelah semua retry.
  Future<Result<TunnelStatus>> disconnectWithRetry({
    int maxRetries = 3,
    int retryDelay = 1000,
  }) async {
    Result<TunnelStatus>? lastResult;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      lastResult = await call();

      if (lastResult.isSuccess) {
        return lastResult;
      }

      // Don't wait after the last attempt
      if (attempt < maxRetries) {
        await Future.delayed(Duration(milliseconds: retryDelay));
      }
    }

    return Result.failure(
      'Failed to disconnect after $maxRetries attempts: ${lastResult?.errorOrNull ?? "Unknown error"}',
    );
  }

  /// Checks if a tunnel is currently active.
  ///
  /// Returns a [Result] containing true if active,
  /// false otherwise.
  Future<Result<bool>> isActive() async {
    return await _repository.isTunnelActive();
  }

  /// Gets the current tunnel status.
  ///
  /// Returns a [Result] containing the current [TunnelStatus].
  Future<Result<TunnelStatus>> getStatus() async {
    return await _repository.getTunnelStatus();
  }

  /// Gets the profile ID of the currently active tunnel.
  ///
  /// Returns a [Result] containing the profile ID if active,
  /// or null if no tunnel is active.
  Future<Result<String?>> getActiveProfileId() async {
    return await _repository.getActiveTunnelProfileId();
  }

  /// Gets tunnel statistics before disconnecting.
  ///
  /// [profileId] - The ID of the profile to get statistics for
  ///
  /// Returns a [Result] containing [TunnelStatistics] on success,
  /// or an error message on failure.
  Future<Result<TunnelStatistics>> getStatistics(String profileId) async {
    return await _repository.getTunnelStatistics(profileId);
  }

  /// Resets tunnel statistics before disconnecting.
  ///
  /// [profileId] - The ID of the profile to reset statistics for
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> resetStatistics(String profileId) async {
    return await _repository.resetTunnelStatistics(profileId);
  }

  /// Gets the list of active peer connections before disconnecting.
  ///
  /// Returns a [Result] containing a list of [PeerConnection] objects.
  Future<Result<List<PeerConnection>>> getActivePeers() async {
    return await _repository.getActivePeers();
  }

  /// Disconnects and optionally saves statistics.
  ///
  /// [saveStatistics] - Whether to save statistics before disconnecting
  ///
  /// Returns a [Result] containing the final [TunnelStatus] on success,
  /// or an error message on failure.
  Future<Result<TunnelStatus>> disconnectAndSaveStatistics({
    bool saveStatistics = true,
  }) async {
    // Get the active profile ID
    final profileIdResult = await _repository.getActiveTunnelProfileId();
    if (!profileIdResult.isSuccess) {
      return Result.failure(
        profileIdResult.errorOrNull ?? 'Failed to get active profile',
      );
    }

    final profileId = profileIdResult.valueOrThrow;

    // Save statistics if requested
    if (saveStatistics && profileId != null) {
      final statsResult = await _repository.getTunnelStatistics(profileId);
      if (statsResult.isSuccess) {
        // Statistics are retrieved - in a real implementation,
        // you would save them to a log or database here
        final stats = statsResult.valueOrThrow;
        // TODO: Save statistics to log/database
      }
    }

    // Disconnect
    return await call();
  }

  /// Force disconnects the tunnel even if it's in an error state.
  ///
  /// This method attempts to stop the tunnel regardless of its current state.
  ///
  /// Returns a [Result] containing the final [TunnelStatus] on success,
  /// or an error message on failure.
  Future<Result<TunnelStatus>> forceDisconnect() async {
    // Try to stop the tunnel without checking if it's active
    return await _repository.stopTunnel();
  }
}
