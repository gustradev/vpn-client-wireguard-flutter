import 'package:flutter/material.dart';

// Enum buat nandain sumber import profile
enum ImportSource {
  paste,
  file,
  qr,
}

// Widget selector sumber import config WireGuard
class ImportSourceSelector extends StatelessWidget {
  final ImportSource selectedSource;
  final ValueChanged<ImportSource> onSourceSelected;

  const ImportSourceSelector({
    super.key,
    required this.selectedSource,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih sumber import',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        _buildSourceButton(
          context,
          source: ImportSource.paste,
          icon: Icons.paste_rounded,
          label: 'Paste config',
          subtitle: 'Tempel konfigurasi WireGuard dari clipboard',
        ),
        const SizedBox(height: 8),
        _buildSourceButton(
          context,
          source: ImportSource.file,
          icon: Icons.file_open_rounded,
          label: 'Ambil dari file .conf',
          subtitle: 'Pilih file konfigurasi dari penyimpanan',
        ),
        const SizedBox(height: 8),
        _buildSourceButton(
          context,
          source: ImportSource.qr,
          icon: Icons.qr_code_scanner_rounded,
          label: 'Scan QR Code',
          subtitle: 'Scan kode QR dari perangkat lain',
        ),
      ],
    );
  }

  Widget _buildSourceButton(
    BuildContext context, {
    required ImportSource source,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = selectedSource == source;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.indigo : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => onSourceSelected(source),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.indigo.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.indigo : Colors.grey[600],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.indigo : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.indigo,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
