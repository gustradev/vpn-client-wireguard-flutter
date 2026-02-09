import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/presentation/providers/profile_providers.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/presentation/widgets/profile_card.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/presentation/providers/tunnel_providers.dart';

// Screen buat nampilin daftar profile WireGuard.
// Pakai Riverpod ConsumerWidget, data dari provider state.
// Bisa import, tambah, connect/disconnect, dan hapus profile.
class ProfileListScreen extends ConsumerWidget {
  const ProfileListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(defaultProfileBootstrapProvider);
    // Ambil daftar profile dari provider state
    final profiles = ref.watch(profilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Profile'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            tooltip: 'Import',
            onPressed: () => context.go('/import'),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: profiles.isEmpty
          // Kalau belum ada profile, tampilkan empty state
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.vpn_key,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada profile',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/import'),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Profile'),
                  ),
                ],
              ),
            )
          // Kalau ada profile, tampilkan list
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return ProfileCard(
                  profile: profile,
                  onTap: () => context.go('/profile/${profile.id}'),
                  onConnect: () {
                    // Toggle connect/disconnect
                    () async {
                      final tunnelRepo = ref.read(tunnelRepositoryProvider);
                      if (profile.isActive) {
                        final stop = await tunnelRepo.stopTunnel();
                        if (stop.isSuccess) {
                          ref
                              .read(tunnelStatusProvider.notifier)
                              .setStatus(stop.valueOrThrow);
                          ref
                              .read(profileListProvider.notifier)
                              .toggleActive(profile.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Disconnect dari ${profile.name}')),
                            );
                          }
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(stop.errorOrThrow)),
                          );
                        }
                        return;
                      }

                      final allowed = await ref
                          .read(wgPlatformChannelProvider)
                          .prepareVpn();
                      if (!context.mounted) return;
                      if (!allowed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Izin VPN ditolak')),
                        );
                        return;
                      }

                      final config = profile.rawConfig?.trim() ?? '';
                      if (config.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Config profile kosong')),
                        );
                        return;
                      }

                      final start = await tunnelRepo.startTunnelWithConfig(
                        profile.id,
                        config,
                      );
                      if (!start.isSuccess) {
                        ref
                            .read(tunnelStatusProvider.notifier)
                            .setError(start.errorOrThrow);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(start.errorOrThrow)),
                          );
                        }
                        return;
                      }

                      ref
                          .read(tunnelStatusProvider.notifier)
                          .setStatus(start.valueOrThrow);
                      ref
                          .read(profileListProvider.notifier)
                          .toggleActive(profile.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Connect ke ${profile.name}')),
                        );
                      }
                    }();
                  },
                  onDelete: () {
                    // Hapus profile dari list
                    ref
                        .read(profileListProvider.notifier)
                        .removeProfile(profile.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Profile ${profile.name} dihapus'),
                      ),
                    );
                  },
                );
              },
            ),
      // Tombol tambah profile (FAB)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/import'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
    );
  }
}
