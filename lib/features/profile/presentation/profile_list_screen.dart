import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileListScreen extends StatelessWidget {
  const ProfileListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Profile'),
        actions: [
          IconButton(
            tooltip: 'Import',
            onPressed: () => context.go('/import'),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final id = 'p${index + 1}';
          return Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.vpn_key_rounded)),
              title: Text('Profile ${index + 1}'),
              subtitle: const Text('Placeholder profile (dummy)'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/profile/$id'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/import'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
    );
  }
}
