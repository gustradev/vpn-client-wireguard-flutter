import 'package:uuid/uuid.dart';
import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/entities/profile.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/repositories/profile_repository.dart';

/// Use case for saving (creating or updating) VPN profiles.
///
/// This use case handles both creating new profiles and updating existing ones,
/// with validation and automatic timestamp management.
class SaveProfile {
  final ProfileRepository _repository;
  final Uuid _uuid;

  /// Creates a new SaveProfile use case.
  SaveProfile(this._repository) : _uuid = const Uuid();

  /// Saves a profile (creates new or updates existing).
  ///
  /// [profile] - The profile to save. If the profile has an ID, it will be updated.
  ///              If the ID is null or empty, a new profile will be created.
  ///
  /// Returns a [Result] containing the saved [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> call(Profile profile) async {
    // Validate the profile before saving
    final validationResult = await _repository.validateProfile(profile);
    if (!validationResult.isSuccess) {
      return Result.failure(
        validationResult.errorOrNull ?? 'Profile validation failed',
      );
    }

    // Check if this is a new profile or an update
    if (profile.id.isEmpty) {
      return await _createNewProfile(profile);
    } else {
      return await _updateExistingProfile(profile);
    }
  }

  /// Creates a new profile.
  ///
  /// [profile] - The profile data to create (without an ID)
  ///
  /// Returns a [Result] containing the created [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> _createNewProfile(Profile profile) async {
    final now = DateTime.now();

    // Create a new profile with generated ID and timestamps
    final newProfile = Profile(
      id: _uuid.v4(),
      name: profile.name,
      interfaceName: profile.interfaceName,
      privateKey: profile.privateKey,
      publicKey: profile.publicKey,
      listenPort: profile.listenPort,
      mtu: profile.mtu,
      dns: profile.dns,
      peers: profile.peers,
      isActive: profile.isActive,
      createdAt: now,
      updatedAt: now,
      notes: profile.notes,
    );

    return await _repository.createProfile(newProfile);
  }

  /// Updates an existing profile.
  ///
  /// [profile] - The profile data to update (with an existing ID)
  ///
  /// Returns a [Result] containing the updated [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> _updateExistingProfile(Profile profile) async {
    // Check if the profile exists
    final existingResult = await _repository.getProfileById(profile.id);
    if (!existingResult.isSuccess) {
      return Result.failure(
        existingResult.errorOrNull ?? 'Profile not found',
      );
    }

    // Update the profile with new timestamp
    final updatedProfile = profile.copyWith(
      updatedAt: DateTime.now(),
    );

    return await _repository.updateProfile(updatedProfile);
  }

  /// Creates a new profile from scratch.
  ///
  /// [name] - The name of the profile
  /// [interfaceName] - The interface name (e.g., wg0)
  /// [privateKey] - The private key
  /// [publicKey] - The public key
  /// [listenPort] - Optional listen port
  /// [mtu] - Optional MTU
  /// [dns] - Optional DNS servers
  /// [peers] - Optional list of peers
  /// [notes] - Optional notes
  ///
  /// Returns a [Result] containing the created [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> create({
    required String name,
    required String interfaceName,
    required String privateKey,
    required String publicKey,
    int? listenPort,
    int? mtu,
    List<String> dns = const [],
    List<Peer> peers = const [],
    String? notes,
  }) async {
    final now = DateTime.now();

    final profile = Profile(
      id: _uuid.v4(),
      name: name,
      interfaceName: interfaceName,
      privateKey: privateKey,
      publicKey: publicKey,
      listenPort: listenPort,
      mtu: mtu,
      dns: dns,
      peers: peers,
      isActive: false,
      createdAt: now,
      updatedAt: now,
      notes: notes,
    );

    return await _repository.createProfile(profile);
  }

  /// Updates an existing profile by ID.
  ///
  /// [id] - The ID of the profile to update
  /// [updates] - A function that returns the updated profile
  ///
  /// Returns a [Result] containing the updated [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> update(
    String id,
    Profile Function(Profile current) updates,
  ) async {
    final existingResult = await _repository.getProfileById(id);
    if (!existingResult.isSuccess) {
      return Result.failure(
        existingResult.errorOrNull ?? 'Profile not found',
      );
    }

    final current = existingResult.valueOrThrow;
    final updated = updates(current).copyWith(
      updatedAt: DateTime.now(),
    );

    return await _repository.updateProfile(updated);
  }

  /// Sets a profile as active.
  ///
  /// [id] - The ID of the profile to activate
  ///
  /// Returns a [Result] containing the updated [Profile] on success,
  /// or an error message on failure.
  Future<Result<Profile>> setActive(String id) async {
    return await _repository.setActiveProfile(id);
  }

  /// Deactivates all profiles.
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> deactivateAll() async {
    final result = await _repository.getAllProfiles();
    if (!result.isSuccess) {
      return Result.failure(
        result.errorOrNull ?? 'Failed to get profiles',
      );
    }

    final profiles = result.valueOrThrow;
    for (final profile in profiles) {
      if (profile.isActive) {
        final updated = profile.copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );
        await _repository.updateProfile(updated);
      }
    }

    return Result.success(true);
  }

  /// Deletes a profile by ID.
  ///
  /// [id] - The ID of the profile to delete
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> delete(String id) async {
    return await _repository.deleteProfile(id);
  }

  /// Deletes multiple profiles by their IDs.
  ///
  /// [ids] - The list of profile IDs to delete
  ///
  /// Returns a [Result] containing the number of deleted profiles on success,
  /// or an error message on failure.
  Future<Result<int>> deleteMultiple(List<String> ids) async {
    var deletedCount = 0;
    final errors = <String>[];

    for (final id in ids) {
      final result = await _repository.deleteProfile(id);
      if (result.isSuccess) {
        deletedCount++;
      } else {
        errors.add(result.errorOrNull ?? 'Failed to delete profile $id');
      }
    }

    if (errors.isNotEmpty) {
      return Result.failure(
        'Deleted $deletedCount profiles. Errors: ${errors.join(', ')}',
      );
    }

    return Result.success(deletedCount);
  }
}
