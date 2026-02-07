import 'package:uuid/uuid.dart';
import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/entities/profile.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/repositories/profile_repository.dart';

/// Use case for importing a WireGuard profile from configuration data.
///
/// This use case handles the import of profiles from various sources
/// including configuration files, QR codes, and JSON data.
class ImportProfile {
  final ProfileRepository _repository;
  final Uuid _uuid;

  /// Creates a new ImportProfile use case.
  ImportProfile(this._repository) : _uuid = const Uuid();

  /// Imports a profile from configuration data.
  ///
  /// [configData] - The configuration data to import
  /// [format] - The format of the configuration data
  /// [name] - Optional custom name for the profile (defaults to auto-generated)
  ///
  /// Returns a [Result] containing the imported [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> call(
    String configData,
    ProfileImportFormat format, {
    String? name,
  }) async {
    // Import the profile from the repository
    final importResult = await _repository.importProfile(configData, format);

    if (!importResult.isSuccess) {
      return Result.failure(
          importResult.errorOrNull ?? 'Failed to import profile');
    }

    final profile = importResult.valueOrThrow;

    // If a custom name is provided, update the profile
    if (name != null && name.isNotEmpty) {
      final updatedProfile = profile.copyWith(name: name);
      final updateResult = await _repository.updateProfile(updatedProfile);

      if (!updateResult.isSuccess) {
        return Result.failure(
          updateResult.errorOrNull ?? 'Failed to update profile name',
        );
      }

      return Result.success(updateResult.valueOrThrow);
    }

    return Result.success(profile);
  }

  /// Imports a profile from a WireGuard configuration file content.
  ///
  /// [configContent] - The content of the .conf file
  /// [name] - Optional custom name for the profile
  ///
  /// Returns a [Result] containing the imported [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> fromConfigFile(
    String configContent, {
    String? name,
  }) {
    return call(configContent, ProfileImportFormat.wgConfig, name: name);
  }

  /// Imports a profile from a QR code scan result.
  ///
  /// [qrData] - The decoded QR code data
  /// [name] - Optional custom name for the profile
  ///
  /// Returns a [Result] containing the imported [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> fromQrCode(
    String qrData, {
    String? name,
  }) {
    return call(qrData, ProfileImportFormat.qrCode, name: name);
  }

  /// Imports a profile from JSON data.
  ///
  /// [jsonData] - The JSON string containing profile data
  /// [name] - Optional custom name for the profile
  ///
  /// Returns a [Result] containing the imported [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> fromJson(
    String jsonData, {
    String? name,
  }) {
    return call(jsonData, ProfileImportFormat.json, name: name);
  }

  /// Validates configuration data before importing.
  ///
  /// [configData] - The configuration data to validate
  /// [format] - The format of the configuration data
  ///
  /// Returns a [Result] containing true if valid,
  /// or an error message describing validation issues.
  Future<Result<bool>> validate(
    String configData,
    ProfileImportFormat format,
  ) async {
    // Try to parse the configuration to validate it
    final importResult = await _repository.importProfile(configData, format);

    if (!importResult.isSuccess) {
      return Result.failure(
          importResult.errorOrNull ?? 'Invalid configuration');
    }

    // Clean up the imported profile since we were just validating
    final profile = importResult.valueOrThrow;
    await _repository.deleteProfile(profile.id);

    return Result.success(true);
  }
}
