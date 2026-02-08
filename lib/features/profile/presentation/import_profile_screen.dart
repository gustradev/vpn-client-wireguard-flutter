import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/entities/profile.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/presentation/providers/profile_providers.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/presentation/widgets/config_preview_card.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/presentation/widgets/import_source_selector.dart';

// Screen import profile WireGuard.
// Sumber: paste, file .conf, atau scan QR.
class ImportProfileScreen extends ConsumerStatefulWidget {
  const ImportProfileScreen({super.key});

  @override
  ConsumerState<ImportProfileScreen> createState() =>
      _ImportProfileScreenState();
}

class _ImportProfileScreenState extends ConsumerState<ImportProfileScreen> {
  ImportSource _source = ImportSource.paste;
  final TextEditingController _pasteController = TextEditingController();
  String _config = '';
  String? _pickedFileName;
  ConfigValidationResult? _validation;
  Profile? _parsedProfile;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  void _setSource(ImportSource source) {
    setState(() => _source = source);
    if (source == ImportSource.file) {
      _pickFile();
    }
    if (source == ImportSource.qr) {
      _scanQr();
    }
  }

  void _updateConfig(String value) {
    setState(() => _config = value);
    _validateConfig();
  }

  void _clearConfig() {
    setState(() {
      _config = '';
      _pickedFileName = null;
      _validation = null;
      _parsedProfile = null;
    });
    _pasteController.clear();
  }

  void _validateConfig() {
    if (_config.trim().isEmpty) {
      setState(() {
        _validation = null;
        _parsedProfile = null;
      });
      return;
    }

    final parser = ref.read(wgConfigParserProvider);
    final result = parser.parse(_config);

    if (!result.isSuccess) {
      setState(() {
        _parsedProfile = null;
        _validation = ConfigValidationResult.invalid(result.errorOrThrow);
      });
      return;
    }

    final profile = result.valueOrThrow;
    setState(() {
      _parsedProfile = profile;
      _validation = ConfigValidationResult.valid(
        name: profile.name,
        endpoint: profile.firstPeer?.endpoint,
      );
    });
  }

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['conf', 'wg', 'txt'],
    );

    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.single;
    if (file.path == null) return;

    final content = await File(file.path!).readAsString();
    setState(() => _pickedFileName = file.name);
    _pasteController.text = content;
    _updateConfig(content);
  }

  Future<void> _scanQr() async {
    final permission = await Permission.camera.request();
    if (!mounted) return;
    if (!permission.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin kamera ditolak')),
        );
      }
      return;
    }

    var scanned = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) {
                  if (scanned) return;
                  final barcodes = capture.barcodes;
                  if (barcodes.isEmpty) return;
                  final rawValue = barcodes.first.rawValue;
                  if (rawValue == null || rawValue.trim().isEmpty) return;

                  scanned = true;
                  Navigator.of(ctx).pop();
                  _pasteController.text = rawValue;
                  _updateConfig(rawValue);
                },
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Scan QR WireGuard',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveProfile() {
    if (_parsedProfile == null) return;
    ref.read(profileListProvider.notifier).addProfile(_parsedProfile!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile ${_parsedProfile!.name} disimpan')),
    );
    context.go('/profiles');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ImportSourceSelector(
            selectedSource: _source,
            onSourceSelected: _setSource,
          ),
          const SizedBox(height: 16),
          if (_source == ImportSource.paste) ...[
            TextField(
              controller: _pasteController,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: 'Paste config di sini',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _updateConfig,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tips: format harus punya [Interface] dan [Peer]',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
          ],
          if (_source == ImportSource.file) ...[
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.file_open_rounded),
              label: const Text('Pilih file .conf'),
            ),
            if (_pickedFileName != null) ...[
              const SizedBox(height: 8),
              Text('File: $_pickedFileName'),
            ],
          ],
          if (_source == ImportSource.qr) ...[
            OutlinedButton.icon(
              onPressed: _scanQr,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Mulai scan QR'),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan QR berisi full config WireGuard',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
          const SizedBox(height: 16),
          ConfigPreviewCard(
            config: _config,
            validationResult: _validation,
            onSave: _validation?.isValid == true ? _saveProfile : null,
            onClear: _config.isNotEmpty ? _clearConfig : null,
          ),
        ],
      ),
    );
  }
}
