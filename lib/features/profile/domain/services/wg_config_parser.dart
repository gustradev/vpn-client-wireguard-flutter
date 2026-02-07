import 'package:uuid/uuid.dart';
import 'package:vpn_client_wireguard_flutter/core/validators.dart';
import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/entities/profile.dart';

/// Parser dan validator config WireGuard ([Interface]/[Peer])
class WgConfigParser {
  final Uuid uuid;
  WgConfigParser({Uuid? uuid}) : uuid = uuid ?? const Uuid();

  /// Parse config string ke Profile
  Result<Profile> parse(String config, {String? name}) {
    if (config.trim().isEmpty) {
      return Result.failure('Config tidak boleh kosong');
    }
    final sections = _parseSections(config);
    if (!sections.containsKey('Interface')) {
      return Result.failure('Config harus ada section [Interface]');
    }
    final interfaceResult = _parseInterface(sections['Interface']!);
    if (interfaceResult.isFailure) {
      return Result.failure(interfaceResult.error);
    }
    final interfaceConfig = interfaceResult.value;
    final peers = <Peer>[];
    if (sections.containsKey('Peer')) {
      for (final peerFields in sections['Peer']!) {
        final peerResult = _parsePeer(peerFields);
        if (peerResult.isFailure) {
          return Result.failure(peerResult.error);
        }
        peers.add(peerResult.value);
      }
    }
    if (peers.isEmpty) {
      return Result.failure('Config harus punya minimal satu [Peer]');
    }
    final profile = Profile(
      id: uuid.v4(),
      name: name ?? interfaceConfig['Address'] ?? 'WG Profile',
      interfaceName: interfaceConfig['Address'] ?? '',
      privateKey: interfaceConfig['PrivateKey'] ?? '',
      publicKey: interfaceConfig['PublicKey'] ?? '',
      listenPort: int.tryParse(interfaceConfig['ListenPort'] ?? ''),
      mtu: int.tryParse(interfaceConfig['MTU'] ?? ''),
      dns: (interfaceConfig['DNS'] ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      peers: peers,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return Result.success(profile);
  }

  /// Parse section config ke map
  Map<String, List<Map<String, String>>> _parseSections(String config) {
    final sections = <String, List<Map<String, String>>>{};
    String? currentSection;
    List<Map<String, String>> currentFields = [];
    final lines = config.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        if (currentSection != null && currentFields.isNotEmpty) {
          sections[currentSection] = [
            ...sections[currentSection] ?? [],
            currentFields
          ];
        }
        currentSection = trimmed.substring(1, trimmed.length - 1);
        currentFields = [];
        continue;
      }
      final parts = trimmed.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        currentFields.add({key: value});
      }
    }
    if (currentSection != null && currentFields.isNotEmpty) {
      sections[currentSection] = [
        ...sections[currentSection] ?? [],
        currentFields
      ];
    }
    return sections;
  }

  /// Parse field [Interface]
  Result<Map<String, String>> _parseInterface(
      List<Map<String, String>> fields) {
    final result = <String, String>{};
    for (final field in fields) {
      field.forEach((key, value) {
        result[key] = value;
      });
    }
    // Validasi
    if (!validatePrivateKey(result['PrivateKey'] ?? '')) {
      return Result.failure('PrivateKey tidak valid');
    }
    if (!validateAddress(result['Address'] ?? '')) {
      return Result.failure('Address tidak valid');
    }
    // PublicKey opsional (bisa diisi dari privateKey jika perlu)
    return Result.success(result);
  }

  /// Parse field [Peer]
  Result<Peer> _parsePeer(List<Map<String, String>> fields) {
    String? publicKey;
    String? presharedKey;
    String? endpoint;
    final allowedIps = <String>[];
    int? persistentKeepalive;
    for (final field in fields) {
      field.forEach((key, value) {
        switch (key.toLowerCase()) {
          case 'publickey':
            publicKey = value;
            break;
          case 'presharedkey':
            presharedKey = value;
            break;
          case 'endpoint':
            endpoint = value;
            break;
          case 'allowedips':
            allowedIps.addAll(value.split(',').map((s) => s.trim()));
            break;
          case 'persistentkeepalive':
            persistentKeepalive = int.tryParse(value);
            break;
        }
      });
    }
    if (!validatePublicKey(publicKey ?? '')) {
      return Result.failure('PublicKey peer tidak valid');
    }
    if (allowedIps.isEmpty) {
      return Result.failure('AllowedIPs peer tidak boleh kosong');
    }
    return Result.success(Peer(
      id: uuid.v4(),
      publicKey: publicKey!,
      presharedKey: presharedKey,
      endpoint: endpoint,
      allowedIps: allowedIps,
      persistentKeepalive: persistentKeepalive,
    ));
  }
}
