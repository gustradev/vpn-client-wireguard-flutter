import 'package:flutter/material.dart';

class ImportProfileScreen extends StatelessWidget {
  const ImportProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pilih sumber import',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.paste_rounded),
                    label: const Text('Paste config'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_open_rounded),
                    label: const Text('Ambil dari file .conf'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan QR'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catatan',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  const Text(
                      'Step berikutnya (1.8) akan menghubungkan input ini dengan parser & validator.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
