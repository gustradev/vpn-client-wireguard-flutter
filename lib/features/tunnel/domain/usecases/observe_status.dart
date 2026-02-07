import 'dart:async';
import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/domain/entities/tunnel_status.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/domain/repositories/tunnel_repository.dart';

/// Use case buat observasi dan monitoring perubahan status tunnel.
///
/// Di sini ada interface stream buat monitoring status tunnel secara real-time.
class ObserveStatus {
  final TunnelRepository _repository;
  StreamSubscription<TunnelStatus>? _subscription;
  final List<Function(TunnelStatus)> _listeners = [];

  /// Bikin instance ObserveStatus use case.
  ObserveStatus(this._repository);

  /// Ambil status tunnel sekarang.
  ///
  /// Return [Result] berisi [TunnelStatus] kalau sukses, atau error kalau gagal.
  Future<Result<TunnelStatus>> call() async {
    return await _repository.getTunnelStatus();
  }

  /// Ambil status tunnel untuk profil tertentu.
  ///
  /// [profileId] - ID profil
  ///
  /// Return [Result] berisi [TunnelStatus] kalau sukses, atau error kalau gagal.
  Future<Result<TunnelStatus>> forProfile(String profileId) async {
    return await _repository.getTunnelStatusByProfile(profileId);
  }

  /// Subscribe ke update status tunnel.
  ///
  /// Return [Stream] yang ngirim update [TunnelStatus] setiap status tunnel berubah.
  Stream<TunnelStatus> watch() {
    return _repository.watchTunnelStatus();
  }

  /// Tambah listener buat update status tunnel.
  ///
  /// [listener] - Fungsi yang dipanggil tiap ada update status
  ///
  /// Return [StreamSubscription] buat cancel listener.
  StreamSubscription<TunnelStatus> addListener(
    void Function(TunnelStatus) listener,
  ) {
    _listeners.add(listener);
    _subscription ??= _repository.watchTunnelStatus().listen((status) {
      for (final l in _listeners) {
        l(status);
      }
    });
    return _subscription!;
  }

  /// Removes a listener.
  ///
  /// [listener] - The listener function to remove
  void removeListener(void Function(TunnelStatus) listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      _subscription?.cancel();
      _subscription = null;
    }
  }

  /// Removes all listeners and cancels the subscription.
  void dispose() {
    _listeners.clear();
    _subscription?.cancel();
    _subscription = null;
  }

  /// Checks if a tunnel is currently active.
  ///
  /// Returns a [Result] containing true if active,
  /// false otherwise.
  Future<Result<bool>> isActive() async {
    return await _repository.isTunnelActive();
  }

  /// Gets the profile ID of the currently active tunnel.
  ///
  /// Returns a [Result] containing the profile ID if active,
  /// or null if no tunnel is active.
  Future<Result<String?>> getActiveProfileId() async {
    return await _repository.getActiveTunnelProfileId();
  }

  /// Gets the connection quality metrics.
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

  /// Watches for connection state changes.
  ///
  /// Returns a [Stream] that emits [TunnelState] values when the
  /// connection state changes.
  Stream<TunnelState> watchConnectionState() {
    return _repository.watchTunnelStatus().map((status) => status.state);
  }

  /// Watches for handshake events.
  ///
  /// Returns a [Stream] that emits [HandshakeInfo] when a handshake occurs.
  Stream<HandshakeInfo> watchHandshakes() {
    return _repository
        .watchTunnelStatus()
        .where((status) => status.handshake != null)
        .map((status) => status.handshake!);
  }

  /// Watches for transfer statistics updates.
  ///
  /// Returns a [Stream] that emits [TransferStats] when statistics change.
  Stream<TransferStats> watchTransferStats() {
    return _repository
        .watchTunnelStatus()
        .map((status) => status.transferStats);
  }

  /// Watches for error states.
  ///
  /// Returns a [Stream] that emits error messages when the tunnel
  /// enters an error state.
  Stream<String> watchErrors() {
    return _repository
        .watchTunnelStatus()
        .where((status) => status.state == TunnelState.error)
        .map((status) => status.errorMessage ?? 'Unknown error');
  }

  /// Watches for connection quality changes.
  ///
  /// Returns a [Stream] that emits [ConnectionQuality] when quality metrics change.
  Stream<ConnectionQuality> watchConnectionQuality() {
    return _repository
        .watchTunnelStatus()
        .asyncMap((status) => _repository.getConnectionQuality())
        .where((result) => result.isSuccess)
        .map((result) => result.valueOrThrow);
  }

  /// Gets the current MTU setting.
  ///
  /// Returns a [Result] containing the MTU value.
  Future<Result<int>> getMtu() async {
    return await _repository.getTunnelMtu();
  }

  /// Gets the current persistent keepalive interval.
  ///
  /// Returns a [Result] containing the interval in seconds,
  /// or null if persistent keepalive is disabled.
  Future<Result<int?>> getPersistentKeepalive() async {
    return await _repository.getPersistentKeepalive();
  }

  /// Polls for status updates at a specified interval.
  ///
  /// [interval] - The polling interval
  ///
  /// Returns a [Stream] that emits [TunnelStatus] at the specified interval.
  Stream<TunnelStatus> poll(Duration interval) {
    return Stream.periodic(interval, (_) async {
      final result = await _repository.getTunnelStatus();
      return result.valueOrNull;
    }).where((status) => status != null).cast<TunnelStatus>();
  }

  /// Gets a summary of the current tunnel status.
  ///
  /// Returns a [Result] containing a [TunnelStatusSummary] on success.
  Future<Result<TunnelStatusSummary>> getSummary() async {
    final statusResult = await _repository.getTunnelStatus();
    if (!statusResult.isSuccess) {
      return Result.failure(
        statusResult.errorOrNull ?? 'Failed to get tunnel status',
      );
    }

    final status = statusResult.valueOrThrow;
    final qualityResult = await _repository.getConnectionQuality();
    final quality = qualityResult.isSuccess ? qualityResult.valueOrNull : null;

    return Result.success(TunnelStatusSummary(
      state: status.state,
      isConnected: status.isConnected,
      hasHandshake: status.hasHandshake,
      connectionQuality: quality,
      rxBytes: status.transferStats.rxBytes,
      txBytes: status.transferStats.txBytes,
      totalBytes: status.transferStats.totalBytes,
      lastStateChange: status.lastStateChange,
    ));
  }
}

/// Summary of tunnel status for quick display.
class TunnelStatusSummary {
  /// Current connection state
  final TunnelState state;

  /// Whether the tunnel is connected
  final bool isConnected;

  /// Whether a handshake has been completed
  final bool hasHandshake;

  /// Connection quality metrics (if available)
  final ConnectionQuality? connectionQuality;

  /// Bytes received
  final int rxBytes;

  /// Bytes sent
  final int txBytes;

  /// Total bytes transferred
  final int totalBytes;

  /// Timestamp of last state change
  final DateTime lastStateChange;

  const TunnelStatusSummary({
    required this.state,
    required this.isConnected,
    required this.hasHandshake,
    this.connectionQuality,
    required this.rxBytes,
    required this.txBytes,
    required this.totalBytes,
    required this.lastStateChange,
  });

  /// Returns the connection quality level
  ConnectionQualityLevel? get qualityLevel {
    return connectionQuality?.level;
  }

  /// Returns true if the connection quality is acceptable
  bool get isQualityAcceptable {
    return connectionQuality?.isAcceptable ?? false;
  }

  /// Returns the duration since the last state change
  Duration get durationSinceStateChange {
    return DateTime.now().difference(lastStateChange);
  }
}
