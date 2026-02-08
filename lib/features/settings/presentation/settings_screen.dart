import 'package:flutter/material.dart';
import 'package:vpn_client_wireguard_flutter/features/settings/presentation/widgets/setting_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SettingToggleTile(
            icon: Icons.dark_mode_rounded,
            title: 'Tema gelap',
            subtitle: 'Placeholder (belum disambungkan)',
          ),
          SizedBox(height: 8),
          SettingToggleTile(
            icon: Icons.lock_rounded,
            title: 'Kunci biometrik',
            subtitle: 'Placeholder',
          ),
          SizedBox(height: 8),
          SettingToggleTile(
            icon: Icons.refresh_rounded,
            title: 'Auto-reconnect',
            subtitle: 'Placeholder',
          ),
        ],
      ),
    );
  }
}
