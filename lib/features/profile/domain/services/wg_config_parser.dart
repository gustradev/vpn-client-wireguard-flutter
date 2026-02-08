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
    final interfaceResult = _parseInterface(sections['Interface']!.first);
    if (!interfaceResult.isSuccess) {
      return Result.failure(interfaceResult.errorOrThrow);
    }
    final interfaceConfig = interfaceResult.valueOrThrow;
    final peers = <Peer>[];
    if (sections.containsKey('Peer')) {
      for (final peerFields in sections['Peer']!) {
        final peerResult = _parsePeer(peerFields);
        if (!peerResult.isSuccess) {
          return Result.failure(peerResult.errorOrThrow);
        }
        peers.add(peerResult.valueOrThrow);
      }
    }
    if (peers.isEmpty) {
      return Result.failure('Config harus punya minimal satu [Peer]');
    }

    final interfaceConfigName = interfaceConfig['Name']?.trim();
    final interfaceName =
        (interfaceConfigName != null && interfaceConfigName.isNotEmpty)
            ? interfaceConfigName
            : 'wg0';

    final cleanedName = name?.trim();

    final profile = Profile(
      id: uuid.v4(),
      name: (cleanedName != null && cleanedName.isNotEmpty)
          ? cleanedName
          : (interfaceConfig['Address'] ?? 'WG Profile'),
      interfaceName: interfaceName,
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

    Map<String, String> currentFields = {};

    void flushCurrent() {
      if (currentSection == null) return;
      if (currentFields.isEmpty) return;
      sections.putIfAbsent(currentSection, () => <Map<String, String>>[]);
      sections[currentSection]!.add(currentFields);
      currentFields = {};
    }

    final lines = config.split('\n');
    for (final line in lines) {
      var trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Buang comment (inline juga) dengan gaya WireGuard: '#' atau ';'
      final hashIndex = trimmed.indexOf('#');
      final semiIndex = trimmed.indexOf(';');
      final cutIndex = _minPositive(hashIndex, semiIndex);
      if (cutIndex >= 0) {
        trimmed = trimmed.substring(0, cutIndex).trim();
        if (trimmed.isEmpty) continue;
      }

      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        flushCurrent();
        currentSection = trimmed.substring(1, trimmed.length - 1).trim();
        continue;
      }

      // Field wajib punya '='. Jangan split semua '=' karena base64 key sering ada '=' di value.
      final eqIndex = trimmed.indexOf('=');
      if (eqIndex <= 0) continue;
      if (currentSection == null) continue;

      final key = trimmed.substring(0, eqIndex).trim();
      final value = trimmed.substring(eqIndex + 1).trim();
      if (key.isEmpty) continue;
      currentFields[key] = value;
    }
    flushCurrent();
    return sections;
  }

  int _minPositive(int a, int b) {
    if (a < 0) return b;
    if (b < 0) return a;
    return a < b ? a : b;
  }

  /// Parse field [Interface]
  Result<Map<String, String>> _parseInterface(Map<String, String> fields) {
    final result = <String, String>{...fields};
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
  Result<Peer> _parsePeer(Map<String, String> fields) {
    String? publicKey;
    String? presharedKey;
    String? endpoint;
    final allowedIps = <String>[];
    int? persistentKeepalive;
    fields.forEach((key, value) {
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

    if (!validatePublicKey(publicKey ?? '')) {
      return Result.failure('PublicKey peer tidak valid');
    }
    if (!validateEndpoint(endpoint ?? '')) {
      return Result.failure(
          'Endpoint kosong. Jika server tidak punya public IP, gunakan relay/VPS sebagai endpoint.');
    }
    if (allowedIps.isEmpty) {
      return Result.failure('AllowedIPs peer tidak boleh kosong');
    }

    final peerName =
        (endpoint ?? '').trim().isNotEmpty ? endpoint!.trim() : 'Peer';

    return Result.success(
      Peer(
        id: uuid.v4(),
        name: peerName,
        publicKey: publicKey!,
        presharedKey: presharedKey,
        endpoint: endpoint,
        allowedIps: allowedIps,
        persistentKeepalive: persistentKeepalive,
      ),
    );
  }
}
