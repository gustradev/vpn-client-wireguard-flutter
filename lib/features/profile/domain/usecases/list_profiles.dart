import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/entities/profile.dart';
import 'package:vpn_client_wireguard_flutter/features/profile/domain/repositories/profile_repository.dart';

/// Use case for listing and retrieving VPN profiles.
///
/// This use case provides methods to retrieve profiles from the repository
/// with various filtering and sorting options.
class ListProfiles {
  final ProfileRepository _repository;

  /// Creates a new ListProfiles use case.
  ListProfiles(this._repository);

  /// Gets all profiles.
  ///
  /// Returns a [Result] containing a list of all [Profile] objects on success,
  /// or an error message on failure.
  Future<Result<List<Profile>>> call() async {
    return await _repository.getAllProfiles();
  }

  /// Gets all profiles sorted by name.
  ///
  /// [ascending] - Whether to sort in ascending order (default: true)
  ///
  /// Returns a [Result] containing a sorted list of [Profile] objects.
  Future<Result<List<Profile>>> sortedByName({bool ascending = true}) async {
    final result = await _repository.getAllProfiles();

    if (!result.isSuccess) {
      return result;
    }

    final profiles = result.valueOrThrow;
    final sorted = List<Profile>.from(profiles)
      ..sort((a, b) => ascending
          ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
          : b.name.toLowerCase().compareTo(a.name.toLowerCase()));

    return Result.success(sorted);
  }

  /// Gets all profiles sorted by creation date.
  ///
  /// [ascending] - Whether to sort in ascending order (default: false, newest first)
  ///
  /// Returns a [Result] containing a sorted list of [Profile] objects.
  Future<Result<List<Profile>>> sortedByDate({bool ascending = false}) async {
    final result = await _repository.getAllProfiles();

    if (!result.isSuccess) {
      return result;
    }

    final profiles = result.valueOrThrow;
    final sorted = List<Profile>.from(profiles)
      ..sort((a, b) => ascending
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt));

    return Result.success(sorted);
  }

  /// Gets all profiles sorted by last modified date.
  ///
  /// [ascending] - Whether to sort in ascending order (default: false, newest first)
  ///
  /// Returns a [Result] containing a sorted list of [Profile] objects.
  Future<Result<List<Profile>>> sortedByLastModified(
      {bool ascending = false}) async {
    final result = await _repository.getAllProfiles();

    if (!result.isSuccess) {
      return result;
    }

    final profiles = result.valueOrThrow;
    final sorted = List<Profile>.from(profiles)
      ..sort((a, b) => ascending
          ? a.updatedAt.compareTo(b.updatedAt)
          : b.updatedAt.compareTo(a.updatedAt));

    return Result.success(sorted);
  }

  /// Gets only active profiles.
  ///
  /// Returns a [Result] containing a list of active [Profile] objects.
  Future<Result<List<Profile>>> activeOnly() async {
    final result = await _repository.getAllProfiles();

    if (!result.isSuccess) {
      return result;
    }

    final profiles = result.valueOrThrow;
    final active = profiles.where((p) => p.isActive).toList();

    return Result.success(active);
  }

  /// Gets only inactive profiles.
  ///
  /// Returns a [Result] containing a list of inactive [Profile] objects.
  Future<Result<List<Profile>>> inactiveOnly() async {
    final result = await _repository.getAllProfiles();

    if (!result.isSuccess) {
      return result;
    }

    final profiles = result.valueOrThrow;
    final inactive = profiles.where((p) => !p.isActive).toList();

    return Result.success(inactive);
  }

  /// Gets profiles that have at least one peer configured.
  ///
  /// Returns a [Result] containing a list of [Profile] objects with peers.
  Future<Result<List<Profile>>> withPeers() async {
    final result = await _repository.getAllProfiles();

    if (!result.isSuccess) {
      return result;
    }

    final profiles = result.valueOrThrow;
    final withPeers = profiles.where((p) => p.hasPeers).toList();

    return Result.success(withPeers);
  }

  /// Gets profiles that have no peers configured.
  ///
  /// Returns a [Result] containing a list of [Profile] objects without peers.
  Future<Result<List<Profile>>> withoutPeers() async {
    final result = await _repository.getAllProfiles();

    if (!result.isSuccess) {
      return result;
    }

    final profiles = result.valueOrThrow;
    final withoutPeers = profiles.where((p) => !p.hasPeers).toList();

    return Result.success(withoutPeers);
  }

  /// Searches for profiles by name.
  ///
  /// [query] - The search query string
  ///
  /// Returns a [Result] containing a list of matching [Profile] objects.
  Future<Result<List<Profile>>> search(String query) async {
    if (query.trim().isEmpty) {
      return await _repository.getAllProfiles();
    }

    return await _repository.searchProfiles(query);
  }

  /// Gets a profile by its ID.
  ///
  /// [id] - The unique identifier of the profile
  ///
  /// Returns a [Result] containing the [Profile] on success,
  /// or an error message if not found.
  Future<Result<Profile>> byId(String id) async {
    return await _repository.getProfileById(id);
  }

  /// Gets the currently active profile.
  ///
  /// Returns a [Result] containing the active [Profile] on success,
  /// or an error message if no profile is active.
  Future<Result<Profile?>> activeProfile() async {
    return await _repository.getActiveProfile();
  }

  /// Gets the count of profiles.
  ///
  /// Returns a [Result] containing the number of profiles.
  Future<Result<int>> count() async {
    return await _repository.getProfileCount();
  }

  /// Gets profiles with a specific interface name.
  ///
  /// [interfaceName] - The interface name to filter by
  ///
  /// Returns a [Result] containing a list of matching [Profile] objects.
  Future<Result<List<Profile>>> byInterfaceName(String interfaceName) async {
    final result = await _repository.getAllProfiles();

    if (!result.isSuccess) {
      return result;
    }

    final profiles = result.valueOrThrow;
    final filtered = profiles
        .where(
            (p) => p.interfaceName.toLowerCase() == interfaceName.toLowerCase())
        .toList();

    return Result.success(filtered);
  }

  /// Gets profiles with a specific DNS server.
  ///
  /// [dnsServer] - The DNS server to filter by
  ///
  /// Returns a [Result] containing a list of matching [Profile] objects.
  Future<Result<List<Profile>>> byDnsServer(String dnsServer) async {
    final result = await _repository.getAllProfiles();

    if (!result.isSuccess) {
      return result;
    }

    final profiles = result.valueOrThrow;
    final filtered = profiles
        .where((p) =>
            p.dns.any((dns) => dns.toLowerCase() == dnsServer.toLowerCase()))
        .toList();

    return Result.success(filtered);
  }
}
