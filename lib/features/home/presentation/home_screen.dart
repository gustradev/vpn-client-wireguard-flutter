import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GVPN'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded,
                      size: 40, color: cs.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WireGuard VPN Client',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: cs.onPrimaryContainer)),
                        const SizedBox(height: 4),
                        Text('MVP UI ready. Tinggal sambungin state & engine.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: cs.onPrimaryContainer)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _NavTile(
            icon: Icons.badge_rounded,
            title: 'Profiles',
            subtitle: 'Lihat & kelola konfigurasi WireGuard',
            onTap: () => context.go('/profiles'),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: Icons.download_rounded,
            title: 'Import Profile',
            subtitle: 'Paste / file / QR (next step)',
            onTap: () => context.go('/import'),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: Icons.monitor_heart_rounded,
            title: 'Status',
            subtitle: 'Connected/disconnected + metrics',
            onTap: () => context.go('/status'),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: Icons.receipt_long_rounded,
            title: 'Log',
            subtitle: 'Lihat aktivitas dan error (masked)',
            onTap: () => context.go('/log'),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Theme / auto-reconnect / biometric (placeholder)',
            onTap: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
