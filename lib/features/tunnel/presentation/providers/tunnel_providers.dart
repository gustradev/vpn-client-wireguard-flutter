import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/entities/profile.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/data/datasources/wg_platform_channel.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/data/repositories/tunnel_repository_impl.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/domain/entities/tunnel_status.dart';

// State tunnel sederhana (MVP)
class TunnelStateNotifier extends StateNotifier<TunnelStatus?> {
  TunnelStateNotifier() : super(null);

  void connect(Profile profile) {
    final now = DateTime.now();
    state = TunnelStatus(
      profileId: profile.id,
      state: TunnelState.connected,
      lastStateChange: now,
      handshake: HandshakeInfo(
        timestamp: now,
        peerPublicKey: profile.firstPeer?.publicKey ?? '-',
        endpoint: profile.firstPeer?.endpoint,
        isSuccessful: true,
      ),
      transferStats: TransferStats(
        rxBytes: 0,
        txBytes: 0,
        lastUpdated: now,
      ),
      updatedAt: now,
    );
  }

  void disconnect() {
    if (state == null) return;
    final now = DateTime.now();
    state = state!.copyWith(
      state: TunnelState.disconnected,
      lastStateChange: now,
      updatedAt: now,
    );
  }

  void updateStats({int? rxBytes, int? txBytes}) {
    if (state == null) return;
    final now = DateTime.now();
    state = state!.copyWith(
      transferStats: state!.transferStats.copyWith(
        rxBytes: rxBytes ?? state!.transferStats.rxBytes,
        txBytes: txBytes ?? state!.transferStats.txBytes,
        lastUpdated: now,
      ),
      updatedAt: now,
    );
  }

  void setError(String message) {
    if (state == null) return;
    final now = DateTime.now();
    state = state!.copyWith(
      state: TunnelState.error,
      errorMessage: message,
      lastStateChange: now,
      updatedAt: now,
    );
  }

  void setStatus(TunnelStatus status) {
    state = status;
  }
}

// Provider status tunnel
final tunnelStatusProvider =
    StateNotifierProvider<TunnelStateNotifier, TunnelStatus?>((ref) {
  return TunnelStateNotifier();
});

// Provider channel native
final wgPlatformChannelProvider = Provider<WgPlatformChannel>((ref) {
  return WgPlatformChannel();
});

// Provider repository tunnel
final tunnelRepositoryProvider = Provider<TunnelRepositoryImpl>((ref) {
  return TunnelRepositoryImpl(channel: ref.read(wgPlatformChannelProvider));
});

// Helper buat request permission VPN (stub)
final vpnPermissionProvider = FutureProvider<bool>((ref) async {
  final channel = ref.read(wgPlatformChannelProvider);
  return channel.prepareVpn();
});

/// Listens to native WireGuard stats stream and syncs it into [tunnelStatusProvider].
///
/// Watched at app root to keep a single subscription alive.
final tunnelStatsSyncProvider = Provider<void>((ref) {
  final channel = ref.read(wgPlatformChannelProvider);
  final notifier = ref.read(tunnelStatusProvider.notifier);

  final sub = channel.observeStats().listen(
    (event) {
      final rx = (event['rxBytes'] as num?)?.toInt();
      final tx = (event['txBytes'] as num?)?.toInt();
      notifier.updateStats(rxBytes: rx, txBytes: tx);
    },
    onError: (Object e) {
      notifier.setError(e.toString());
    },
  );

  ref.onDispose(sub.cancel);
});
