import 'dart:async';

import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/data/datasources/wg_platform_channel.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/domain/entities/tunnel_status.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/domain/repositories/tunnel_repository.dart';

// Implementasi repository tunnel (MVP, stub + dummy data)
class TunnelRepositoryImpl implements TunnelRepository {
  TunnelRepositoryImpl({WgPlatformChannel? channel})
      : _channel = channel ?? WgPlatformChannel();

  final WgPlatformChannel _channel;
  TunnelStatus? _currentStatus;

  @override
  Future<Result<TunnelStatus>> startTunnel(String profileId) async {
    try {
      final data = await _channel.startTunnel(profileId: profileId);
      _currentStatus = _mapStatus(data, profileId);
      return Result.success(_currentStatus!);
    } catch (e) {
      return Result.failure('Gagal start tunnel: ${e.toString()}');
    }
  }

  Future<Result<TunnelStatus>> startTunnelWithConfig(
    String profileId,
    String config,
  ) async {
    try {
      final data = await _channel.startTunnel(
        profileId: profileId,
        config: config,
      );
      _currentStatus = _mapStatus(data, profileId);
      return Result.success(_currentStatus!);
    } catch (e) {
      return Result.failure('Gagal start tunnel: ${e.toString()}');
    }
  }

  @override
  Future<Result<TunnelStatus>> stopTunnel() async {
    try {
      final data = await _channel.stopTunnel();
      _currentStatus = _mapStatus(data, _currentStatus?.profileId ?? '-');
      return Result.success(_currentStatus!);
    } catch (e) {
      return Result.failure('Gagal stop tunnel: ${e.toString()}');
    }
  }

  @override
  Future<Result<TunnelStatus>> getTunnelStatus() async {
    try {
      if (_currentStatus != null) return Result.success(_currentStatus!);
      final data = await _channel.getStatus();
      _currentStatus = _mapStatus(data, data['profileId']?.toString() ?? '-');
      return Result.success(_currentStatus!);
    } catch (e) {
      return Result.failure('Gagal ambil status: ${e.toString()}');
    }
  }

  @override
  Future<Result<TunnelStatus>> getTunnelStatusByProfile(
      String profileId) async {
    final status = await getTunnelStatus();
    if (!status.isSuccess) return status;
    if (status.valueOrThrow.profileId != profileId) {
      return Result.failure('Status untuk profile tidak ditemukan');
    }
    return status;
  }

  @override
  Future<Result<TunnelStatus>> restartTunnel(String profileId) async {
    final stop = await stopTunnel();
    if (!stop.isSuccess) return stop;
    return startTunnel(profileId);
  }

  @override
  Future<Result<bool>> isTunnelActive() async {
    final status = await getTunnelStatus();
    if (!status.isSuccess) return Result.failure(status.errorOrThrow);
    return Result.success(status.valueOrThrow.isConnected);
  }

  @override
  Future<Result<String?>> getActiveTunnelProfileId() async {
    final status = await getTunnelStatus();
    if (!status.isSuccess) return Result.failure(status.errorOrThrow);
    return Result.success(status.valueOrThrow.profileId);
  }

  @override
  Stream<TunnelStatus> watchTunnelStatus() {
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) async => (await getTunnelStatus()).valueOrThrow);
  }

  @override
  Future<Result<String>> getTunnelConfig(String profileId) async {
    return Result.success('[Interface]\n# profileId=$profileId\n');
  }

  @override
  Future<Result<bool>> validateTunnelConfig(String config) async {
    if (config.contains('[Interface]') && config.contains('[Peer]')) {
      return Result.success(true);
    }
    return Result.failure('Config belum lengkap');
  }

  @override
  Future<Result<TunnelStatistics>> getTunnelStatistics(String profileId) async {
    final now = DateTime.now();
    return Result.success(TunnelStatistics(
      totalRxBytes: _currentStatus?.transferStats.rxBytes ?? 0,
      totalTxBytes: _currentStatus?.transferStats.txBytes ?? 0,
      startTime: now.subtract(const Duration(hours: 1)),
      lastUpdated: now,
      handshakeCount: _currentStatus?.handshake != null ? 1 : 0,
    ));
  }

  @override
  Future<Result<bool>> resetTunnelStatistics(String profileId) async {
    return Result.success(true);
  }

  @override
  Future<Result<List<PeerConnection>>> getActivePeers() async {
    return Result.success(const []);
  }

  @override
  Future<Result<ConnectionQuality>> getConnectionQuality() async {
    return Result.success(const ConnectionQuality(
      score: 0,
      latencyMs: 0,
      packetLossPercent: 0,
      jitterMs: 0,
    ));
  }

  @override
  Future<Result<bool>> setTunnelMtu(int mtu) async {
    return Result.success(true);
  }

  @override
  Future<Result<int>> getTunnelMtu() async {
    return Result.success(1420);
  }

  @override
  Future<Result<bool>> setPersistentKeepalive(int? intervalSeconds) async {
    return Result.success(true);
  }

  @override
  Future<Result<int?>> getPersistentKeepalive() async {
    return Result.success(25);
  }

  TunnelStatus _mapStatus(Map<String, dynamic> data, String profileId) {
    final now = DateTime.now();
    final stateRaw = (data['state'] ?? 'disconnected').toString();
    final state = _mapState(stateRaw);

    final handshake = state == TunnelState.connected
        ? HandshakeInfo(
            timestamp: now,
            peerPublicKey: data['peerPublicKey']?.toString() ?? '-',
            endpoint: data['endpoint']?.toString(),
            isSuccessful: true,
          )
        : null;

    return TunnelStatus(
      profileId: profileId,
      state: state,
      lastStateChange: now,
      handshake: handshake,
      transferStats: TransferStats(
        rxBytes: ((data['rxBytes'] ?? 0) as num).toInt(),
        txBytes: ((data['txBytes'] ?? 0) as num).toInt(),
        lastUpdated: now,
      ),
      updatedAt: now,
    );
  }

  TunnelState _mapState(String raw) {
    switch (raw) {
      case 'connected':
        return TunnelState.connected;
      case 'connecting':
        return TunnelState.connecting;
      case 'disconnecting':
        return TunnelState.disconnecting;
      case 'error':
        return TunnelState.error;
      case 'disconnected':
      default:
        return TunnelState.disconnected;
    }
  }
}
