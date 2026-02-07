import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/entities/profile.dart';

/// Repository interface for managing VPN profiles.
///
/// This interface defines the contract for CRUD operations on profiles,
/// including creation, retrieval, update, and deletion of profile data.
abstract class ProfileRepository {
  /// Creates a new profile.
  ///
  /// Returns a [Result] containing the created [Profile] on success,
  /// or an error message on failure.
  ///
  /// The profile will be stored with encrypted sensitive data.
  Future<Result<Profile>> createProfile(Profile profile);

  /// Retrieves a profile by its ID.
  ///
  /// Returns a [Result] containing the [Profile] on success,
  /// or an error message if the profile is not found or an error occurs.
  Future<Result<Profile>> getProfileById(String id);

  /// Retrieves all profiles.
  ///
  /// Returns a [Result] containing a list of all [Profile] objects on success,
  /// or an error message on failure.
  Future<Result<List<Profile>>> getAllProfiles();

  /// Updates an existing profile.
  ///
  /// Returns a [Result] containing the updated [Profile] on success,
  /// or an error message on failure.
  ///
  /// Only the fields provided in the [profile] parameter will be updated.
  Future<Result<Profile>> updateProfile(Profile profile);

  /// Deletes a profile by its ID.
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> deleteProfile(String id);

  /// Imports a profile from a configuration file.
  ///
  /// Supports importing from:
  /// - WireGuard configuration files (.conf)
  /// - QR code scan
  /// - JSON format
  ///
  /// Returns a [Result] containing the imported [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> importProfile(
      String configData, ProfileImportFormat format);

  /// Exports a profile to a configuration file.
  ///
  /// Returns a [Result] containing the configuration string on success,
  /// or an error message on failure.
  Future<Result<String>> exportProfile(String id, ProfileExportFormat format);

  /// Validates a profile configuration.
  ///
  /// Returns a [Result] containing true if the profile is valid,
  /// or an error message describing the validation issues.
  Future<Result<bool>> validateProfile(Profile profile);

  /// Generates a new key pair for a profile.
  ///
  /// Returns a [Result] containing a [KeyPair] with private and public keys.
  Future<Result<KeyPair>> generateKeyPair();

  /// Sets a profile as active.
  ///
  /// Only one profile can be active at a time.
  /// Returns a [Result] containing the updated [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> setActiveProfile(String id);

  /// Gets the currently active profile.
  ///
  /// Returns a [Result] containing the active [Profile] on success,
  /// or an error message if no profile is active.
  Future<Result<Profile?>> getActiveProfile();

  /// Searches for profiles by name.
  ///
  /// Returns a [Result] containing a list of matching [Profile] objects.
  Future<Result<List<Profile>>> searchProfiles(String query);

  /// Gets the count of profiles.
  ///
  /// Returns a [Result] containing the number of profiles.
  Future<Result<int>> getProfileCount();

  /// Clears all profiles.
  ///
  /// This is a destructive operation and cannot be undone.
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> clearAllProfiles();
}

/// Represents a WireGuard key pair.
class KeyPair {
  /// The private key
  final String privateKey;

  /// The public key derived from the private key
  final String publicKey;

  const KeyPair({
    required this.privateKey,
    required this.publicKey,
  });
}

/// Supported formats for importing profiles.
enum ProfileImportFormat {
  /// WireGuard configuration file format (.conf)
  wgConfig,

  /// JSON format
  json,

  /// QR code format (decoded from QR scan)
  qrCode,
}

/// Supported formats for exporting profiles.
enum ProfileExportFormat {
  /// WireGuard configuration file format (.conf)
  wgConfig,

  /// JSON format
  json,

  /// QR code format (for sharing)
  qrCode,
}
