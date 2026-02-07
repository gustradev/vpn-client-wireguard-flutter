import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vpn_client_wireguard_flutter/core/result.dart';

/// Data source buat nyimpen data sensitif profile dengan aman.
///
/// Di sini kita pakai flutter_secure_storage buat nyimpen info penting kayak private key sama pre-shared key, semuanya dienkripsi biar aman.
class ProfileSecureStorage {
  final FlutterSecureStorage _storage;

  /// Prefix key buat private key profile
  static const String _privateKeyPrefix = 'profile_private_key_';

  /// Prefix key buat pre-shared key profile
  static const String _presharedKeyPrefix = 'profile_preshared_key_';

  /// Prefix key buat pre-shared key peer
  static const String _peerPresharedKeyPrefix = 'peer_preshared_key_';

  /// Bikin instance ProfileSecureStorage baru
  ProfileSecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Simpen private key buat profile.
  ///
  /// [profileId] = ID profile
  /// [privateKey] = private key yang mau disimpen
  ///
  /// Return [Result] true kalau sukses, atau error kalau gagal.
  Future<Result<bool>> storePrivateKey(
      String profileId, String privateKey) async {
    try {
      final key = _privateKeyPrefix + profileId;
      await _storage.write(key: key, value: privateKey);
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to store private key: ${e.toString()}');
    }
  }

  /// Ambil private key dari profile.
  ///
  /// [profileId] = ID profile
  ///
  /// Return [Result] private key kalau sukses, atau error kalau gagal.
  Future<Result<String>> getPrivateKey(String profileId) async {
    try {
      final key = _privateKeyPrefix + profileId;
      final privateKey = await _storage.read(key: key);

      if (privateKey == null) {
        return Result.failure('Private key not found for profile: $profileId');
      }

      return Result.success(privateKey);
    } catch (e) {
      return Result.failure('Failed to retrieve private key: ${e.toString()}');
    }
  }

  /// Hapus private key dari profile.
  ///
  /// [profileId] = ID profile
  ///
  /// Return [Result] true kalau sukses, atau error kalau gagal.
  Future<Result<bool>> deletePrivateKey(String profileId) async {
    try {
      final key = _privateKeyPrefix + profileId;
      await _storage.delete(key: key);
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to delete private key: ${e.toString()}');
    }
  }

  /// Simpen pre-shared key buat profile.
  ///
  /// [profileId] = ID profile
  /// [presharedKey] = pre-shared key yang mau disimpen
  ///
  /// Return [Result] true kalau sukses, atau error kalau gagal.
  Future<Result<bool>> storePresharedKey(
      String profileId, String presharedKey) async {
    try {
      final key = _presharedKeyPrefix + profileId;
      await _storage.write(key: key, value: presharedKey);
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to store pre-shared key: ${e.toString()}');
    }
  }

  /// Ambil pre-shared key dari profile.
  ///
  /// [profileId] = ID profile
  ///
  /// Return [Result] pre-shared key kalau sukses, atau error kalau gagal.
  Future<Result<String>> getPresharedKey(String profileId) async {
    try {
      final key = _presharedKeyPrefix + profileId;
      final presharedKey = await _storage.read(key: key);

      if (presharedKey == null) {
        return Result.failure(
            'Pre-shared key not found for profile: $profileId');
      }

      return Result.success(presharedKey);
    } catch (e) {
      return Result.failure(
          'Failed to retrieve pre-shared key: ${e.toString()}');
    }
  }

  /// Deletes a pre-shared key for a profile.
  ///
  /// [profileId] - The ID of the profile
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> deletePresharedKey(String profileId) async {
    try {
      final key = _presharedKeyPrefix + profileId;
      await _storage.delete(key: key);
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to delete pre-shared key: ${e.toString()}');
    }
  }

  /// Stores a pre-shared key for a peer.
  ///
  /// [peerId] - The ID of the peer
  /// [presharedKey] - The pre-shared key to store
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> storePeerPresharedKey(
      String peerId, String presharedKey) async {
    try {
      final key = _peerPresharedKeyPrefix + peerId;
      await _storage.write(key: key, value: presharedKey);
      return Result.success(true);
    } catch (e) {
      return Result.failure(
          'Failed to store peer pre-shared key: ${e.toString()}');
    }
  }

  /// Retrieves a pre-shared key for a peer.
  ///
  /// [peerId] - The ID of the peer
  ///
  /// Returns a [Result] containing the pre-shared key on success,
  /// or an error message on failure.
  Future<Result<String>> getPeerPresharedKey(String peerId) async {
    try {
      final key = _peerPresharedKeyPrefix + peerId;
      final presharedKey = await _storage.read(key: key);

      if (presharedKey == null) {
        return Result.failure('Pre-shared key not found for peer: $peerId');
      }

      return Result.success(presharedKey);
    } catch (e) {
      return Result.failure(
          'Failed to retrieve peer pre-shared key: ${e.toString()}');
    }
  }

  /// Deletes a pre-shared key for a peer.
  ///
  /// [peerId] - The ID of the peer
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> deletePeerPresharedKey(String peerId) async {
    try {
      final key = _peerPresharedKeyPrefix + peerId;
      await _storage.delete(key: key);
      return Result.success(true);
    } catch (e) {
      return Result.failure(
          'Failed to delete peer pre-shared key: ${e.toString()}');
    }
  }

  /// Deletes all keys for a profile.
  ///
  /// [profileId] - The ID of the profile
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> deleteAllKeysForProfile(String profileId) async {
    try {
      await _storage.delete(key: _privateKeyPrefix + profileId);
      await _storage.delete(key: _presharedKeyPrefix + profileId);
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to delete profile keys: ${e.toString()}');
    }
  }

  /// Deletes all keys for a peer.
  ///
  /// [peerId] - The ID of the peer
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> deleteAllKeysForPeer(String peerId) async {
    try {
      await _storage.delete(key: _peerPresharedKeyPrefix + peerId);
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to delete peer keys: ${e.toString()}');
    }
  }

  /// Clears all stored keys.
  ///
  /// This is a destructive operation and cannot be undone.
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> clearAll() async {
    try {
      await _storage.deleteAll();
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to clear all keys: ${e.toString()}');
    }
  }

  /// Checks if a private key exists for a profile.
  ///
  /// [profileId] - The ID of the profile
  ///
  /// Returns a [Result] containing true if the key exists,
  /// false otherwise.
  Future<Result<bool>> hasPrivateKey(String profileId) async {
    try {
      final key = _privateKeyPrefix + profileId;
      final privateKey = await _storage.read(key: key);
      return Result.success(privateKey != null);
    } catch (e) {
      return Result.failure('Failed to check private key: ${e.toString()}');
    }
  }

  /// Checks if a pre-shared key exists for a profile.
  ///
  /// [profileId] - The ID of the profile
  ///
  /// Returns a [Result] containing true if the key exists,
  /// false otherwise.
  Future<Result<bool>> hasPresharedKey(String profileId) async {
    try {
      final key = _presharedKeyPrefix + profileId;
      final presharedKey = await _storage.read(key: key);
      return Result.success(presharedKey != null);
    } catch (e) {
      return Result.failure('Failed to check pre-shared key: ${e.toString()}');
    }
  }

  /// Checks if a pre-shared key exists for a peer.
  ///
  /// [peerId] - The ID of the peer
  ///
  /// Returns a [Result] containing true if the key exists,
  /// false otherwise.
  Future<Result<bool>> hasPeerPresharedKey(String peerId) async {
    try {
      final key = _peerPresharedKeyPrefix + peerId;
      final presharedKey = await _storage.read(key: key);
      return Result.success(presharedKey != null);
    } catch (e) {
      return Result.failure(
          'Failed to check peer pre-shared key: ${e.toString()}');
    }
  }

  /// Gets all keys stored in secure storage.
  ///
  /// Returns a [Result] containing a map of all keys and their values.
  Future<Result<Map<String, String>>> getAllKeys() async {
    try {
      final allData = await _storage.readAll();
      return Result.success(allData);
    } catch (e) {
      return Result.failure('Failed to get all keys: ${e.toString()}');
    }
  }

  /// Stores a custom key-value pair.
  ///
  /// [key] - The key to store
  /// [value] - The value to store
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> storeCustomKey(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to store custom key: ${e.toString()}');
    }
  }

  /// Retrieves a custom key-value pair.
  ///
  /// [key] - The key to retrieve
  ///
  /// Returns a [Result] containing the value on success,
  /// or an error message on failure.
  Future<Result<String>> getCustomKey(String key) async {
    try {
      final value = await _storage.read(key: key);

      if (value == null) {
        return Result.failure('Key not found: $key');
      }

      return Result.success(value);
    } catch (e) {
      return Result.failure('Failed to retrieve custom key: ${e.toString()}');
    }
  }

  /// Deletes a custom key-value pair.
  ///
  /// [key] - The key to delete
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> deleteCustomKey(String key) async {
    try {
      await _storage.delete(key: key);
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to delete custom key: ${e.toString()}');
    }
  }
}
