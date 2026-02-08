import 'package:flutter/material.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/services/wg_config_parser.dart';

// Hasil validasi config
class ConfigValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? extractedName;
  final String? extractedEndpoint;

  ConfigValidationResult({
    required this.isValid,
    this.errorMessage,
    this.extractedName,
    this.extractedEndpoint,
  });

  factory ConfigValidationResult.invalid(String message) {
    return ConfigValidationResult(
      isValid: false,
      errorMessage: message,
    );
  }

  factory ConfigValidationResult.valid({
    String? name,
    String? endpoint,
  }) {
    return ConfigValidationResult(
      isValid: true,
      extractedName: name,
      extractedEndpoint: endpoint,
    );
  }
}

// Widget buat preview config WireGuard + status validasinya
class ConfigPreviewCard extends StatelessWidget {
  final String config;
  final ConfigValidationResult? validationResult;
  final VoidCallback? onSave;
  final VoidCallback? onClear;

  const ConfigPreviewCard({
    super.key,
    required this.config,
    this.validationResult,
    this.onSave,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getHeaderColor().withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getHeaderColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getHeaderIcon(),
                    color: _getHeaderColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitle(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (validationResult?.extractedName != null)
                        Text(
                          validationResult!.extractedName!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                    ],
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClear,
                    tooltip: 'Hapus',
                  ),
              ],
            ),
          ),
          // Preview config
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status validasi
                if (validationResult != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: validationResult!.isValid
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: validationResult!.isValid
                            ? Colors.green
                            : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          validationResult!.isValid
                              ? Icons.check_circle
                              : Icons.error,
                          color: validationResult!.isValid
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            validationResult!.isValid
                                ? 'Konfigurasi valid'
                                : validationResult!.errorMessage ??
                                    'Konfigurasi tidak valid',
                            style: TextStyle(
                              color: validationResult!.isValid
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (validationResult != null) const SizedBox(height: 16),
                // Preview isi config
                Text(
                  'Preview konfigurasi:',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      config.isEmpty ? '(Belum ada konfigurasi)' : config,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Info hasil ekstraksi
                if (validationResult?.extractedEndpoint != null)
                  Row(
                    children: [
                      const Icon(Icons.dns, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Endpoint: ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        validationResult!.extractedEndpoint!,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                // Tombol simpan
                if (onSave != null && validationResult?.isValid == true)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getHeaderColor() {
    if (config.isEmpty) return Colors.grey;
    if (validationResult == null) return Colors.blue;
    return validationResult!.isValid ? Colors.green : Colors.red;
  }

  IconData _getHeaderIcon() {
    if (config.isEmpty) return Icons.code;
    if (validationResult == null) return Icons.preview;
    return validationResult!.isValid ? Icons.check_circle : Icons.error;
  }

  String _getTitle() {
    if (config.isEmpty) return 'Belum ada konfigurasi';
    if (validationResult == null) return 'Preview';
    return validationResult!.isValid ? 'Konfigurasi Valid' : 'Error';
  }
}

// Parser config pakai WgConfigParser biar konsisten sama domain layer
ConfigValidationResult parseWireGuardConfig(String config) {
  final parser = WgConfigParser();
  final result = parser.parse(config);

  if (!result.isSuccess) {
    return ConfigValidationResult.invalid(result.errorOrThrow);
  }

  final profile = result.valueOrThrow;
  return ConfigValidationResult.valid(
    name: profile.name,
    endpoint: profile.firstPeer?.endpoint,
  );
}
