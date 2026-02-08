import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SwitchTile(
            icon: Icons.dark_mode_rounded,
            title: 'Tema gelap',
            subtitle: 'Placeholder (belum disambungkan)',
          ),
          SizedBox(height: 8),
          _SwitchTile(
            icon: Icons.lock_rounded,
            title: 'Kunci biometrik',
            subtitle: 'Placeholder',
          ),
          SizedBox(height: 8),
          _SwitchTile(
            icon: Icons.refresh_rounded,
            title: 'Auto-reconnect',
            subtitle: 'Placeholder',
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatefulWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  bool value = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        secondary: CircleAvatar(child: Icon(widget.icon)),
        value: value,
        onChanged: (v) => setState(() => value = v),
        title: Text(widget.title),
        subtitle: Text(widget.subtitle),
      ),
    );
  }
}
