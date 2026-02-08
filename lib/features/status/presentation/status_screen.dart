import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/presentation/providers/profile_providers.dart';
import 'package:vpn_client_wireguard_flutter/features/status/presentation/widgets/status_metrics.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/presentation/providers/tunnel_providers.dart';

class StatusScreen extends ConsumerWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final profiles = ref.watch(profilesProvider);
    final status = ref.watch(tunnelStatusProvider);

    final activeProfile = profiles.firstWhereOrNull((p) => p.isActive);

    return Scaffold(
      appBar: AppBar(title: const Text('Status VPN')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_rounded, color: cs.primary),
                      const SizedBox(width: 10),
                      Text(
                        status?.isConnected == true
                            ? 'Connected'
                            : 'Disconnected',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StatusMetrics(status: status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              if (status?.isConnected == true) {
                ref.read(tunnelStatusProvider.notifier).disconnect();
                if (activeProfile != null) {
                  ref
                      .read(profileListProvider.notifier)
                      .toggleActive(activeProfile.id);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('VPN diputus')),
                );
                return;
              }

              if (activeProfile == null) {
                if (profiles.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Belum ada profile untuk dihubungkan')),
                  );
                  return;
                }
                final first = profiles.first;
                final allowed =
                    await ref.read(wgPlatformChannelProvider).prepareVpn();
                if (!context.mounted) return;
                if (!allowed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Izin VPN ditolak')),
                  );
                  return;
                }
                ref.read(profileListProvider.notifier).toggleActive(first.id);
                ref.read(tunnelStatusProvider.notifier).connect(first);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Connect ke ${first.name}')),
                );
                return;
              }

              final allowed =
                  await ref.read(wgPlatformChannelProvider).prepareVpn();
              if (!context.mounted) return;
              if (!allowed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Izin VPN ditolak')),
                );
                return;
              }
              ref.read(tunnelStatusProvider.notifier).connect(activeProfile);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Connect ke ${activeProfile.name}')),
              );
            },
            icon: Icon(
              status?.isConnected == true
                  ? Icons.stop_rounded
                  : Icons.play_arrow_rounded,
            ),
            label: Text(status?.isConnected == true ? 'Disconnect' : 'Connect'),
          ),
        ],
      ),
    );
  }
}
