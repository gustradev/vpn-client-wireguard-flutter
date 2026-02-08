import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/presentation/providers/profile_providers.dart';

// Screen detail profile, pakai Riverpod ConsumerWidget
class ProfileDetailScreen extends ConsumerWidget {
  const ProfileDetailScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil profile berdasarkan ID dari provider
    final profile = ref.watch(profileByIdProvider(profileId));
    final textTheme = Theme.of(context).textTheme;

    // Kalau profile nggak ketemu, tampilkan error
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Profile'),
          backgroundColor: Colors.indigo,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Profile tidak ditemukan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    final peer = profile.firstPeer;

    // Tampilan detail profile: status, interface, peer, action
    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () {
              // Tombol edit (belum diimplementasi)
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kartu status VPN (terhubung/terputus)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: profile.isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      profile.isActive
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: profile.isActive ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.isActive ? 'Terhubung' : 'Terputus',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                profile.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.isActive
                              ? 'VPN sedang aktif'
                              : 'Klik tombol di bawah untuk terhubung',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info interface WireGuard
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        'Interface',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  _KeyValue(label: 'Nama', value: profile.interfaceName),
                  _KeyValue(label: 'Public Key', value: profile.publicKey),
                  if (profile.listenPort != null)
                    _KeyValue(
                        label: 'Listen Port', value: '${profile.listenPort}'),
                  if (profile.mtu != null)
                    _KeyValue(label: 'MTU', value: '${profile.mtu}'),
                  if (profile.dns.isNotEmpty)
                    _KeyValue(
                      label: 'DNS',
                      value: profile.dns.join(', '),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info peer WireGuard
          if (peer != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.router, color: Colors.indigo),
                        const SizedBox(width: 8),
                        Text(
                          'Peer',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _KeyValue(label: 'Nama', value: peer.name),
                    _KeyValue(label: 'Public Key', value: peer.publicKey),
                    if (peer.endpoint != null)
                      _KeyValue(label: 'Endpoint', value: peer.endpoint!),
                    if (peer.allowedIps.isNotEmpty)
                      _KeyValue(
                        label: 'Allowed IPs',
                        value: peer.allowedIps.join(', '),
                      ),
                    if (peer.persistentKeepalive != null)
                      _KeyValue(
                        label: 'Keepalive',
                        value: '${peer.persistentKeepalive}s',
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Tombol action connect/disconnect dan hapus
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Toggle connect/disconnect
                    ref
                        .read(profileListProvider.notifier)
                        .toggleActive(profile.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(profile.isActive
                            ? 'Disconnect dari ${profile.name}...'
                            : 'Connect ke ${profile.name}...'),
                      ),
                    );
                  },
                  icon: Icon(profile.isActive ? Icons.stop : Icons.play_arrow),
                  label: Text(profile.isActive ? 'Putuskan' : 'Hubungkan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        profile.isActive ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Tombol hapus
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus Profile'),
                        content: Text('Yakin mau hapus "${profile.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(profileListProvider.notifier)
                                  .removeProfile(profile.id);
                              context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Profile ${profile.name} dihapus'),
                                ),
                              );
                              context.pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
