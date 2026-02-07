 import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/data/datasources/profile_local_db.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/data/datasources/profile_secure_storage.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/entities/profile.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/repositories/profile_repository.dart';

/// Implementasi ProfileRepository pakai data source lokal.
///
/// Repo ini pakai ProfileLocalDB buat nyimpen metadata, dan ProfileSecureStorage buat data sensitif kayak private key.
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDB _localDB;
  final ProfileSecureStorage _secureStorage;
  final Uuid _uuid;

  /// Bikin instance ProfileRepositoryImpl baru
  ProfileRepositoryImpl({
    required ProfileLocalDB localDB,
    required ProfileSecureStorage secureStorage,
    Uuid? uuid,
  })  : _localDB = localDB,
        _secureStorage = secureStorage,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Result<Profile>> createProfile(Profile profile) async {
    try {
      // Store private key in secure storage
      final privateKeyResult =
          await _secureStorage.storePrivateKey(profile.id, profile.privateKey);
      if (!privateKeyResult.isSuccess) {
        return Result.failure(
            'Failed to store private key: ${privateKeyResult.errorOrNull}');
      }

      // Store pre-shared key if present
      if (profile.peers.isNotEmpty) {
        for (final peer in profile.peers) {
          if (peer.presharedKey != null && peer.presharedKey!.isNotEmpty) {
            await _secureStorage.storePeerPresharedKey(
                peer.id, peer.presharedKey!);
          }
        }
      }

      // Save profile metadata to local DB
      final result = await _localDB.saveProfile(profile);
      if (!result.isSuccess) {
        // Rollback: delete private key from secure storage
        await _secureStorage.deletePrivateKey(profile.id);
        return result;
      }

      return Result.success(profile);
    } catch (e) {
      return Result.failure('Failed to create profile: ${e.toString()}');
    }
  }

  @override
  Future<Result<Profile>> getProfileById(String id) async {
    try {
      // Get profile metadata from local DB
      final result = await _localDB.getProfileById(id);
      if (!result.isSuccess) {
        return result;
      }

      var profile = result.valueOrThrow;

      // Get private key from secure storage
      final privateKeyResult = await _secureStorage.getPrivateKey(id);
      if (privateKeyResult.isSuccess) {
        profile = profile.copyWith(privateKey: privateKeyResult.valueOrThrow);
      }

      // Get pre-shared keys for peers
      final updatedPeers = <Peer>[];
      for (final peer in profile.peers) {
        var updatedPeer = peer;
        final pskResult = await _secureStorage.getPeerPresharedKey(peer.id);
        if (pskResult.isSuccess) {
          updatedPeer = peer.copyWith(presharedKey: pskResult.valueOrThrow);
        }
        updatedPeers.add(updatedPeer);
      }

      profile = profile.copyWith(peers: updatedPeers);

      return Result.success(profile);
    } catch (e) {
      return Result.failure('Failed to get profile: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<Profile>>> getAllProfiles() async {
    try {
      final result = await _localDB.getAllProfiles();
      if (!result.isSuccess) {
        return result;
      }

      final profiles = result.valueOrThrow;
      final profilesWithKeys = <Profile>[];

      for (final profile in profiles) {
        // Get private key for each profile
        final privateKeyResult = await _secureStorage.getPrivateKey(profile.id);
        var updatedProfile = profile;
        if (privateKeyResult.isSuccess) {
          updatedProfile =
              profile.copyWith(privateKey: privateKeyResult.valueOrThrow);
        }

        // Get pre-shared keys for peers
        final updatedPeers = <Peer>[];
        for (final peer in profile.peers) {
          var updatedPeer = peer;
          final pskResult = await _secureStorage.getPeerPresharedKey(peer.id);
          if (pskResult.isSuccess) {
            updatedPeer = peer.copyWith(presharedKey: pskResult.valueOrThrow);
          }
          updatedPeers.add(updatedPeer);
        }

        updatedProfile = updatedProfile.copyWith(peers: updatedPeers);
        profilesWithKeys.add(updatedProfile);
      }

      return Result.success(profilesWithKeys);
    } catch (e) {
      return Result.failure('Failed to get all profiles: ${e.toString()}');
    }
  }

  @override
  Future<Result<Profile>> updateProfile(Profile profile) async {
    try {
      // Update private key if changed
      final privateKeyResult = await _secureStorage.getPrivateKey(profile.id);
      if (privateKeyResult.isSuccess &&
          privateKeyResult.valueOrThrow != profile.privateKey) {
        await _secureStorage.storePrivateKey(profile.id, profile.privateKey);
      }

      // Update pre-shared keys for peers
      for (final peer in profile.peers) {
        final pskResult = await _secureStorage.getPeerPresharedKey(peer.id);
        if (pskResult.isSuccess && peer.presharedKey != null) {
          if (pskResult.valueOrThrow != peer.presharedKey) {
            await _secureStorage.storePeerPresharedKey(
                peer.id, peer.presharedKey!);
          }
        } else if (peer.presharedKey != null && peer.presharedKey!.isNotEmpty) {
          await _secureStorage.storePeerPresharedKey(
              peer.id, peer.presharedKey!);
        }
      }

      // Update profile metadata in local DB
      final result = await _localDB.updateProfile(profile);
      return result;
    } catch (e) {
      return Result.failure('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<Result<bool>> deleteProfile(String id) async {
    try {
      // Delete from local DB
      final dbResult = await _localDB.deleteProfile(id);
      if (!dbResult.isSuccess) {
        return dbResult;
      }

      // Delete private key from secure storage
      await _secureStorage.deletePrivateKey(id);

      // Delete pre-shared key from secure storage
      await _secureStorage.deletePresharedKey(id);

      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to delete profile: ${e.toString()}');
    }
  }

  @override
  Future<Result<Profile>> importProfile(
      String configData, ProfileImportFormat format) async {
    try {
      Profile profile;

      switch (format) {
        case ProfileImportFormat.wgConfig:
          profile = _parseWgConfig(configData);
          break;
        case ProfileImportFormat.json:
          profile = _parseJsonConfig(configData);
          break;
        case ProfileImportFormat.qrCode:
          profile = _parseQrCode(configData);
          break;
      }

      // Generate ID if not present
      if (profile.id.isEmpty) {
        profile = profile.copyWith(id: _uuid.v4());
      }

      // Set timestamps
      final now = DateTime.now();
      profile = profile.copyWith(
        createdAt: now,
        updatedAt: now,
      );

      // Save the profile
      return await createProfile(profile);
    } catch (e) {
      return Result.failure('Failed to import profile: ${e.toString()}');
    }
  }

  @override
  Future<Result<String>> exportProfile(
      String id, ProfileExportFormat format) async {
    try {
      final profileResult = await getProfileById(id);
      if (!profileResult.isSuccess) {
        return Result.failure(
            'Failed to get profile: ${profileResult.errorOrNull}');
      }

      final profile = profileResult.valueOrThrow;

      switch (format) {
        case ProfileExportFormat.wgConfig:
          return Result.success(_toWgConfig(profile));
        case ProfileExportFormat.json:
          return Result.success(_toJson(profile));
        case ProfileExportFormat.qrCode:
          return Result.success(_toQrCode(profile));
      }
    } catch (e) {
      return Result.failure('Failed to export profile: ${e.toString()}');
    }
  }

  @override
  Future<Result<bool>> validateProfile(Profile profile) async {
    try {
      // Validate required fields
      if (profile.name.trim().isEmpty) {
        return Result.failure('Profile name is required');
      }

      if (profile.interfaceName.trim().isEmpty) {
        return Result.failure('Interface name is required');
      }

      if (profile.privateKey.trim().isEmpty) {
        return Result.failure('Private key is required');
      }

      if (profile.publicKey.trim().isEmpty) {
        return Result.failure('Public key is required');
      }

      // Validate private key format (WireGuard keys are 44 characters base64)
      if (profile.privateKey.length != 44) {
        return Result.failure('Invalid private key format');
      }

      // Validate public key format
      if (profile.publicKey.length != 44) {
        return Result.failure('Invalid public key format');
      }

      // Validate peers
      for (final peer in profile.peers) {
        if (peer.publicKey.trim().isEmpty) {
          return Result.failure('Peer public key is required');
        }

        if (peer.publicKey.length != 44) {
          return Result.failure('Invalid peer public key format');
        }

        if (peer.allowedIps.isEmpty) {
          return Result.failure('Peer allowed IPs are required');
        }
      }

      return Result.success(true);
    } catch (e) {
      return Result.failure('Validation failed: ${e.toString()}');
    }
  }

  @override
  Future<Result<KeyPair>> generateKeyPair() async {
    try {
      // In a real implementation, this would use the WireGuard native library
      // to generate a proper key pair. For now, we'll generate a placeholder.
      // TODO: Implement actual WireGuard key generation

      // Placeholder implementation - replace with actual WireGuard key generation
      final privateKey = _generatePlaceholderKey();
      final publicKey = _generatePlaceholderKey();

      return Result.success(KeyPair(
        privateKey: privateKey,
        publicKey: publicKey,
      ));
    } catch (e) {
      return Result.failure('Failed to generate key pair: ${e.toString()}');
    }
  }

  @override
  Future<Result<Profile>> setActiveProfile(String id) async {
    try {
      // Deactivate all profiles
      final allProfilesResult = await _localDB.getAllProfiles();
      if (allProfilesResult.isSuccess) {
        for (final profile in allProfilesResult.valueOrThrow) {
          if (profile.isActive) {
            await _localDB.updateProfile(
                profile.copyWith(isActive: false, updatedAt: DateTime.now()));
          }
        }
      }

      // Activate the specified profile
      final profileResult = await _localDB.getProfileById(id);
      if (!profileResult.isSuccess) {
        return Result.failure('Profile not found: $id');
      }

      final profile = profileResult.valueOrThrow;
      final updatedProfile =
          profile.copyWith(isActive: true, updatedAt: DateTime.now());

      final result = await _localDB.updateProfile(updatedProfile);
      return result;
    } catch (e) {
      return Result.failure('Failed to set active profile: ${e.toString()}');
    }
  }

  @override
  Future<Result<Profile?>> getActiveProfile() async {
    try {
      final result = await _localDB.getActiveProfiles();
      if (!result.isSuccess) {
        return Result.failure(
            result.errorOrNull ?? 'Failed to get active profile');
      }

      final activeProfiles = result.valueOrThrow;
      if (activeProfiles.isEmpty) {
        return Result.success(null);
      }

      // Get the first active profile with keys
      return await getProfileById(activeProfiles.first.id);
    } catch (e) {
      return Result.failure('Failed to get active profile: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<Profile>>> searchProfiles(String query) async {
    return await _localDB.searchProfiles(query);
  }

  @override
  Future<Result<int>> getProfileCount() async {
    return await _localDB.getProfileCount();
  }

  @override
  Future<Result<bool>> clearAllProfiles() async {
    try {
      // Clear all profiles from local DB
      final dbResult = await _localDB.clearAll();
      if (!dbResult.isSuccess) {
        return dbResult;
      }

      // Clear all keys from secure storage
      await _secureStorage.clearAll();

      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to clear all profiles: ${e.toString()}');
    }
  }

  /// Parses a WireGuard configuration file.
  Profile _parseWgConfig(String config) {
    // TODO: Implement actual WireGuard config parsing
    // This is a placeholder implementation
    return Profile(
      id: _uuid.v4(),
      name: 'Imported Profile',
      interfaceName: 'wg0',
      privateKey: _generatePlaceholderKey(),
      publicKey: _generatePlaceholderKey(),
      peers: [],
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Parses a JSON configuration.
  Profile _parseJsonConfig(String json) {
    // TODO: Implement actual JSON config parsing
    // This is a placeholder implementation
    return Profile(
      id: _uuid.v4(),
      name: 'Imported Profile',
      interfaceName: 'wg0',
      privateKey: _generatePlaceholderKey(),
      publicKey: _generatePlaceholderKey(),
      peers: [],
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Parses a QR code configuration.
  Profile _parseQrCode(String qrData) {
    // TODO: Implement actual QR code parsing
    // This is a placeholder implementation
    return Profile(
      id: _uuid.v4(),
      name: 'Imported Profile',
      interfaceName: 'wg0',
      privateKey: _generatePlaceholderKey(),
      publicKey: _generatePlaceholderKey(),
      peers: [],
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Converts a profile to WireGuard config format.
  String _toWgConfig(Profile profile) {
    final buffer = StringBuffer();
    buffer.writeln('[Interface]');
    buffer.writeln('PrivateKey = ${profile.privateKey}');
    buffer.writeln('Address = ${profile.interfaceName}');
    if (profile.listenPort != null) {
      buffer.writeln('ListenPort = ${profile.listenPort}');
    }
    if (profile.mtu != null) {
      buffer.writeln('MTU = ${profile.mtu}');
    }
    if (profile.dns.isNotEmpty) {
      buffer.writeln('DNS = ${profile.dns.join(', ')}');
    }

    for (final peer in profile.peers) {
      buffer.writeln();
      buffer.writeln('[Peer]');
      buffer.writeln('PublicKey = ${peer.publicKey}');
      if (peer.presharedKey != null && peer.presharedKey!.isNotEmpty) {
        buffer.writeln('PresharedKey = ${peer.presharedKey}');
      }
      if (peer.endpoint != null && peer.endpoint!.isNotEmpty) {
        buffer.writeln('Endpoint = ${peer.endpoint}');
      }
      if (peer.allowedIps.isNotEmpty) {
        buffer.writeln('AllowedIPs = ${peer.allowedIps.join(', ')}');
      }
      if (peer.persistentKeepalive != null) {
        buffer.writeln('PersistentKeepalive = ${peer.persistentKeepalive}');
      }
    }

    return buffer.toString();
  }

  /// Converts a profile to JSON format.
  String _toJson(Profile profile) {
    final json = {
      'id': profile.id,
      'name': profile.name,
      'interfaceName': profile.interfaceName,
      'privateKey': profile.privateKey,
      'publicKey': profile.publicKey,
      'listenPort': profile.listenPort,
      'mtu': profile.mtu,
      'dns': profile.dns,
      'peers': profile.peers
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'publicKey': p.publicKey,
                'presharedKey': p.presharedKey,
                'endpoint': p.endpoint,
                'allowedIps': p.allowedIps,
                'persistentKeepalive': p.persistentKeepalive,
              })
          .toList(),
      'isActive': profile.isActive,
      'createdAt': profile.createdAt.toIso8601String(),
      'updatedAt': profile.updatedAt.toIso8601String(),
      'notes': profile.notes,
    };
    return jsonEncode(json);
  }

  /// Converts a profile to QR code format.
  String _toQrCode(Profile profile) {
    // QR code format is typically the same as the config format
    return _toWgConfig(profile);
  }

  /// Generates a placeholder WireGuard key.
  ///
  /// TODO: Replace with actual WireGuard key generation
  String _generatePlaceholderKey() {
    // This is a placeholder - actual WireGuard keys are 44 characters base64
    return 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
  }
}
